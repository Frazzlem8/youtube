const { execFileSync } = require("child_process");
const http = require("http");
const https = require("https");

const microvmId = process.argv[2];
const localPort = Number(process.env.LOCAL_PORT || 8080);

if (!microvmId) {
  console.error("Usage: node scripts/browser-proxy.js <microvm-id>");
  process.exit(1);
}

function terraformOutput(name) {
  return execFileSync("terraform", ["output", "-raw", name], { encoding: "utf8" }).trim();
}

function awsJson(args) {
  return JSON.parse(execFileSync("aws", args, { encoding: "utf8" }));
}

function awsText(args) {
  return execFileSync("aws", args, { encoding: "utf8" }).trim();
}

const region = process.env.AWS_REGION || terraformOutput("aws_region");
const microvm = awsJson([
  "lambda-microvms",
  "get-microvm",
  "--region",
  region,
  "--microvm-identifier",
  microvmId,
]);

let token = "";
let tokenExpiresAt = 0;

function getToken() {
  const now = Date.now();
  if (token && now < tokenExpiresAt) {
    return token;
  }

  token = awsText([
    "lambda-microvms",
    "create-microvm-auth-token",
    "--region",
    region,
    "--microvm-identifier",
    microvmId,
    "--expiration-in-minutes",
    "30",
    "--allowed-ports",
    '[{"port":8080}]',
    "--query",
    "authToken",
    "--output",
    "text",
  ]);
  tokenExpiresAt = now + 25 * 60 * 1000;
  return token;
}

const server = http.createServer((clientReq, clientRes) => {
  const proxyReq = https.request(
    {
      hostname: microvm.endpoint,
      path: clientReq.url,
      method: clientReq.method,
      headers: {
        ...clientReq.headers,
        host: microvm.endpoint,
        "x-aws-proxy-auth": getToken(),
        "x-aws-proxy-port": "8080",
      },
    },
    (proxyRes) => {
      clientRes.writeHead(proxyRes.statusCode || 502, proxyRes.headers);
      proxyRes.pipe(clientRes);
    }
  );

  proxyReq.on("error", (err) => {
    clientRes.writeHead(502, { "content-type": "application/json" });
    clientRes.end(JSON.stringify({ error: err.message }));
  });

  clientReq.pipe(proxyReq);
});

server.listen(localPort, () => {
  console.log(`Proxying http://localhost:${localPort} to https://${microvm.endpoint}`);
});
