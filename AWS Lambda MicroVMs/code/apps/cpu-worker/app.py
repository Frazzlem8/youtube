import hashlib
import json
import time
from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import parse_qs, urlparse


def run_work(iterations):
    value = b"lambda-microvm-demo"
    for _ in range(iterations):
        value = hashlib.sha256(value).digest()
    return value.hex()


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        query = parse_qs(urlparse(self.path).query)
        iterations = int(query.get("iterations", ["250000"])[0])
        iterations = max(1, min(iterations, 2_000_000))

        started = time.perf_counter()
        digest = run_work(iterations)
        elapsed_ms = round((time.perf_counter() - started) * 1000, 2)

        payload = {
            "demo": "cpu-worker",
            "iterations": iterations,
            "elapsedMs": elapsed_ms,
            "digestPrefix": digest[:24],
            "capability": "longer-running service process with CPU work behind an HTTPS MicroVM endpoint",
        }

        body = json.dumps(payload, indent=2).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
