const http = require("http");

const startedAt = new Date().toISOString();

const server = http.createServer((req, res) => {
  const body = {
    demo: "http-api",
    status: "ok",
    path: req.url,
    startedAt,
    runtime: process.version,
    message: "Hello from an AWS Lambda MicroVM",
  };

  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify(body, null, 2));
});

server.listen(8080, () => {
  console.log("HTTP API listening on port 8080");
});
