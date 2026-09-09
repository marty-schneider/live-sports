#!/usr/bin/env python3
"""Prove CachedFetch-style curl refuses an allowlisted origin's redirect."""

from __future__ import annotations

import os
import ssl
import subprocess
import tempfile
import threading
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


MARKER = "PWNED-PRIVATE-HOST"


def _handler(code: int, body: bytes, location: str | None):
    class Handler(BaseHTTPRequestHandler):
        def do_GET(self):
            self.send_response(code)
            if location:
                self.send_header("Location", location)
            self.send_header("Content-Type", "text/plain")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            self.wfile.write(body)

        def log_message(self, *_args):
            return

    return Handler


def _tls_server(handler, certfile: str, keyfile: str):
    httpd = ThreadingHTTPServer(("127.0.0.1", 0), handler)
    ctx = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ctx.load_cert_chain(certfile, keyfile)
    httpd.socket = ctx.wrap_socket(httpd.socket, server_side=True)
    thread = threading.Thread(target=httpd.serve_forever, daemon=True)
    thread.start()
    return httpd, thread


def _make_cert(dirpath: str) -> tuple[str, str]:
    cert = os.path.join(dirpath, "cert.pem")
    key = os.path.join(dirpath, "key.pem")
    subprocess.check_call(
        [
            "openssl",
            "req",
            "-x509",
            "-newkey",
            "rsa:2048",
            "-keyout",
            key,
            "-out",
            cert,
            "-days",
            "1",
            "-nodes",
            "-subj",
            "/CN=127.0.0.1",
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    return cert, key


def _curl(url: str, follow: bool) -> subprocess.CompletedProcess[bytes]:
    # Production CachedFetch uses `-L --max-redirs 0`. The control case uses 3.
    cmd = [
        "curl",
        "-fsS",
        "-L",
        "--max-redirs",
        "3" if follow else "0",
        "--proto",
        "=https",
        "--proto-redir",
        "=https",
        "--max-time",
        "5",
        "-k",
        url,
    ]
    return subprocess.run(cmd, capture_output=True, timeout=10)


def main() -> int:
    with tempfile.TemporaryDirectory() as tmp:
        cert, key = _make_cert(tmp)
        secret, _ = _tls_server(_handler(200, MARKER.encode(), None), cert, key)
        origin, _ = _tls_server(
            _handler(
                302,
                b"redirect",
                f"https://127.0.0.1:{secret.server_port}/secret",
            ),
            cert,
            key,
        )
        origin_url = f"https://127.0.0.1:{origin.server_port}/scoreboard"
        try:
            blocked = _curl(origin_url, follow=False)
            if blocked.returncode == 0 or MARKER.encode() in blocked.stdout:
                print("FAIL  production flags followed the redirect")
                print(blocked.stdout, blocked.stderr, blocked.returncode)
                return 1
            print("ok  refused redirect to a private HTTPS host")

            followed = _curl(origin_url, follow=True)
            if MARKER.encode() not in followed.stdout:
                print("FAIL  control curl -L did not reach the private host")
                print(followed.stdout, followed.stderr, followed.returncode)
                return 1
            print("ok  control curl -L would have leaked the redirect body")
            return 0
        finally:
            origin.shutdown()
            secret.shutdown()


if __name__ == "__main__":
    raise SystemExit(main())
