import json
import os
import resource
import subprocess
import sys
import tempfile
from http.server import BaseHTTPRequestHandler, HTTPServer


DEFAULT_CODE = """import math

numbers = [2, 3, 5, 8, 13, 21]
score = sum(math.sqrt(n) for n in numbers)

print('AI generated analysis complete')
print({'numbers': numbers, 'score': round(score, 4)})
"""


def limit_child_process():
    limits = [
        (resource.RLIMIT_CPU, (2, 2)),
        (resource.RLIMIT_FSIZE, (1_000_000, 1_000_000)),
        (resource.RLIMIT_AS, (256 * 1024 * 1024, 256 * 1024 * 1024)),
    ]

    for target, value in limits:
        try:
            resource.setrlimit(target, value)
        except (OSError, ValueError):
            pass


def execute_python(code):
    with tempfile.TemporaryDirectory(prefix="microvm-ai-sandbox-") as workdir:
        script_path = os.path.join(workdir, "generated_code.py")
        with open(script_path, "w", encoding="utf-8") as script:
            script.write(code)

        completed = subprocess.run(
            [sys.executable, "-I", "-S", script_path],
            cwd=workdir,
            env={"PYTHONUNBUFFERED": "1"},
            text=True,
            capture_output=True,
            timeout=5,
            preexec_fn=limit_child_process,
            check=False,
        )

    return {
        "exitCode": completed.returncode,
        "stdout": completed.stdout[-4000:],
        "stderr": completed.stderr[-4000:],
    }


class Handler(BaseHTTPRequestHandler):
    def send_json(self, status_code, payload):
        body = json.dumps(payload, indent=2).encode("utf-8")
        self.send_response(status_code)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path not in ["/", "/demo"]:
            self.send_json(404, {"error": "Use GET /demo or POST /run"})
            return

        try:
            result = execute_python(DEFAULT_CODE)
        except subprocess.SubprocessError as exc:
            self.send_json(500, {"error": f"Could not start generated code: {exc}"})
            return
        except subprocess.TimeoutExpired:
            self.send_json(408, {"error": "Generated code timed out"})
            return

        self.send_json(
            200,
            {
                "demo": "ai-code-sandbox",
                "useCase": "Run AI-generated code in an isolated Lambda MicroVM session",
                "whyMicroVM": [
                    "Each session can get its own VM-level boundary",
                    "The app can keep state while the MicroVM is running",
                    "The environment can be terminated when the agent or user session ends",
                ],
                "executedCode": DEFAULT_CODE,
                "result": result,
            },
        )

    def do_POST(self):
        if self.path != "/run":
            self.send_json(404, {"error": "Use POST /run"})
            return

        content_length = int(self.headers.get("Content-Length", "0"))
        if content_length > 32_000:
            self.send_json(413, {"error": "Payload too large"})
            return

        try:
            payload = json.loads(self.rfile.read(content_length) or b"{}")
            code = payload.get("code", "")
        except json.JSONDecodeError:
            self.send_json(400, {"error": "Request body must be JSON"})
            return

        if not isinstance(code, str) or not code.strip():
            self.send_json(400, {"error": "JSON body must include a non-empty string field named code"})
            return

        try:
            result = execute_python(code)
        except subprocess.SubprocessError as exc:
            self.send_json(500, {"error": f"Could not start generated code: {exc}"})
            return
        except subprocess.TimeoutExpired:
            self.send_json(408, {"error": "Generated code timed out"})
            return

        self.send_json(
            200,
            {
                "demo": "ai-code-sandbox",
                "useCase": "Run AI-generated code in an isolated Lambda MicroVM session",
                "result": result,
            },
        )


HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
