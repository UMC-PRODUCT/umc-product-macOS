#  session_fixture.py
#  UMCDesk
#
#  Created by euijjang97 on 11/23/26.

"""Run a loopback-only login fixture. SIGUSR1 expires current test sessions."""

import argparse
import json
import secrets
import signal
import tempfile
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlsplit

MEMBERS = {
    "first@example.test": ("101", "첫 챌린저"),
    "second@example.test": ("102", "둘째 챌린저"),
}
PASSWORD = "fixture-only"


class SessionFixture(BaseHTTPRequestHandler):
    def send_result(self, status, result=None):
        body = json.dumps({"success": status == 200, "result": result}).encode()
        with self.server.log_lock:
            with (self.server.control / "events").open("a") as log:
                print(self.command, urlsplit(self.path).path, status, file=log)
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, *args):
        pass

    def issue(self, email):
        access, refresh = secrets.token_urlsafe(), secrets.token_urlsafe()
        self.server.sessions[refresh] = (access, email)
        return {"memberId": MEMBERS[email][0], "accessToken": access, "refreshToken": refresh}

    def do_POST(self):
        try:
            length = int(self.headers.get("Content-Length", "0"))
            if not 0 < length <= 8192:
                return self.send_result(400)
            body = json.loads(self.rfile.read(length))
            if not isinstance(body, dict):
                return self.send_result(400)
        except (ValueError, UnicodeDecodeError):
            return self.send_result(400)

        if self.path == "/api/v1/auth/login/email":
            email = body.get("email")
            if isinstance(email, str) and email in MEMBERS and body.get("password") == PASSWORD:
                control = self.server.control
                if (control / "hold-login").exists():
                    marker = control / "waiting-login"
                    marker.touch()
                    try:
                        while (control / "hold-login").exists():
                            time.sleep(0.05)
                    finally:
                        marker.unlink(missing_ok=True)
                with self.server.session_lock:
                    result = self.issue(email)
                return self.send_result(200, result)
            return self.send_result(401)

        if self.path in ("/api/v1/auth/logout", "/api/v1/auth/token/renew"):
            refresh = body.get("refreshToken")
            with self.server.session_lock:
                prior = self.server.sessions.pop(refresh, None) if isinstance(refresh, str) else None
                if self.path.endswith("/renew") and not prior:
                    return self.send_result(401)
                result = self.issue(prior[1]) if self.path.endswith("/renew") else None
            return self.send_result(200, result)
        self.send_result(404)

    def do_GET(self):
        if urlsplit(self.path).path != "/api/v1/member/me":
            return self.send_result(404)
        with self.server.session_lock:
            sessions = tuple(self.server.sessions.values())
        for access, email in sessions:
            if self.headers.get("Authorization") == "Bearer " + access:
                identifier, name = MEMBERS[email]
                return self.send_result(200, {
                    "id": identifier, "name": name, "nickname": name, "email": email,
                    "schoolName": "테스트 대학교", "roles": [], "challengerRecords": [],
                })
        self.send_result(401)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=18761)
    args = parser.parse_args()
    with ThreadingHTTPServer(("127.0.0.1", args.port), SessionFixture) as server:
        server.sessions = {}
        server.session_lock = threading.Lock()
        server.log_lock = threading.Lock()
        with tempfile.TemporaryDirectory(prefix=f"umc-session-{server.server_port}-") as directory:
            server.control = Path(directory)
            (server.control / "events").touch()

            def expire_sessions(*_):
                with server.session_lock:
                    server.sessions.clear()

            def expire_access(*_):
                with server.session_lock:
                    for refresh, (_, email) in server.sessions.copy().items():
                        server.sessions[refresh] = (secrets.token_urlsafe(), email)

            signal.signal(signal.SIGUSR1, expire_sessions)
            signal.signal(signal.SIGUSR2, expire_access)
            print(f"Fixture ready on 127.0.0.1:{server.server_port}; control={directory}", flush=True)
            server.serve_forever()
