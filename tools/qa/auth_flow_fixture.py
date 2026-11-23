#  auth_flow_fixture.py
#  UMCDesk
#
#  Created by euijjang97 on 11/23/26.

"""Loopback auth QA. Use a new @example.test address, OTP 123456, challenger UMC123.

Resending rotates the code to 654321. Touch/remove 'maintenance' in the printed control
directory to toggle full maintenance. Accounts and verification tokens live in memory.
"""

import argparse
import json
import secrets
import tempfile
import threading
from http.server import ThreadingHTTPServer
from pathlib import Path

from session_fixture import MEMBERS, PASSWORD, SessionFixture


class AuthFixture(SessionFixture):
    def do_GET(self):
        if self.path == "/api/v1/system/status":
            active = (self.server.control / "maintenance").exists()
            return self.send_result(200, {"inMaintenance": active,
                                          "current": {"scope": "FULL"} if active else None,
                                          "upcoming": None})
        if self.path == "/api/v1/schools/all":
            return self.send_result(200, {"schools": [{"schoolId": "1", "schoolName": "테스트대학교"}]})
        if self.path == "/api/v1/terms":
            return self.send_result(200, {"terms": [
                {"id": str(index), "typeDescription": title, "isMandatory": True,
                 "link": "https://example.test/terms/" + str(index)}
                for index, title in enumerate(("서비스 이용약관", "개인정보 처리방침"), 1)
            ]})
        email = self.current_email()
        if self.path == "/api/v1/member/me" and email in self.server.unlinked:
            return self.send_result(200, {
                "id": MEMBERS[email][0], "name": MEMBERS[email][1], "nickname": MEMBERS[email][1],
                "email": email, "schoolName": "테스트대학교", "roles": [], "challengerRecords": [],
            })
        super().do_GET()

    def reject_code(self, status, code, message):
        payload = json.dumps({"success": False, "code": code, "message": message,
                              "result": None}).encode()
        with self.server.log_lock:
            with (self.server.control / "events").open("a") as events:
                print(self.command, self.path, status, file=events)
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        self.wfile.write(payload)

    def read_body(self):
        size = int(self.headers.get("Content-Length", "0"))
        if not 0 < size <= 8192:
            raise ValueError()
        body = json.loads(self.rfile.read(size))
        if not isinstance(body, dict):
            raise ValueError()
        return body

    def do_POST(self):
        if self.path in ("/api/v1/auth/logout", "/api/v1/auth/token/renew"):
            return super().do_POST()
        try:
            body = self.read_body()
            with self.server.flow_lock:
                self.post(body)
        except (ValueError, TypeError, KeyError):
            self.send_result(400)

    def post(self, body):
        if self.path == "/api/v1/auth/email-verification":
            email, purpose = body["email"], body["purpose"]
            if not email.endswith("@example.test") or purpose not in ("REGISTER", "PASSWORD_RESET"):
                return self.send_result(400)
            if (email in MEMBERS) != (purpose == "PASSWORD_RESET"):
                return self.send_result(400)
            identifier = len(self.server.verifications) + 1
            self.server.verifications[identifier] = [email, purpose, "123456"]
            return self.send_result(200, {"emailVerificationId": str(identifier)})
        if self.path.startswith("/api/v1/auth/email-verification/"):
            session = self.server.verifications[body["emailVerificationId"]]
            if not session[2]:
                return self.send_result(400)
            if self.path.endswith("/resend"):
                session[2] = "654321" if session[2] == "123456" else "123456"
                return self.send_result(200)
            if self.path.endswith("/code") and body["verificationCode"] == session[2]:
                token = secrets.token_urlsafe()
                self.server.proofs[token] = session[:2]
                session[2] = None
                return self.send_result(200, {"emailVerificationToken": token})
            return self.reject_code(401, "AUTHENTICATION-0004", "인증번호를 확인해 주세요.")
        if self.path == "/api/v1/member/register/email":
            token = body["emailVerificationToken"]
            email, purpose = self.server.proofs[token]
            agreements = {row["termsId"]: row["isAgreed"] for row in body["termsAgreements"]}
            if purpose != "REGISTER" or email in MEMBERS or body["schoolId"] != 1:
                return self.send_result(400)
            if agreements != {1: True, 2: True} or not body["name"] or not body["nickname"]:
                return self.send_result(400)
            self.server.passwords[email] = body["rawPassword"]
            MEMBERS[email] = (str(self.server.next_member), body["name"])
            self.server.next_member += 1
            self.server.unlinked.add(email)
            del self.server.proofs[token]
            with self.server.session_lock:
                return self.send_result(200, self.issue(email))
        if self.path == "/api/v1/auth/login/email":
            email = body["email"]
            if email not in MEMBERS or self.server.passwords[email] != body["password"]:
                return self.send_result(401)
            with self.server.session_lock:
                return self.send_result(200, self.issue(email))
        if self.path == "/api/v1/challenger-record/member":
            email = self.current_email()
            if not email:
                return self.send_result(401)
            if body["code"] == "USED12" or email not in self.server.unlinked:
                return self.reject_code(400, "CHALLENGER-0012", "이미 사용한 챌린저 코드예요.")
            if body["code"] != "UMC123":
                return self.send_result(400)
            self.server.unlinked.remove(email)
            return self.send_result(200)
        self.send_result(404)

    def do_PATCH(self):
        if self.path != "/api/v1/auth/password/reset":
            return self.send_result(404)
        try:
            body = self.read_body()
            with self.server.flow_lock:
                email, purpose = self.server.proofs[body["emailVerificationToken"]]
                if purpose != "PASSWORD_RESET":
                    return self.send_result(400)
                self.server.passwords[email] = body["newPassword"]
                del self.server.proofs[body["emailVerificationToken"]]
            self.send_result(200)
        except (ValueError, TypeError, KeyError):
            self.send_result(400)

    def do_DELETE(self):
        if self.path != "/api/v1/member":
            return self.send_result(404)
        with self.server.flow_lock:
            email = self.current_email()
            if not email:
                return self.send_result(401)
            del MEMBERS[email]
            del self.server.passwords[email]
            self.server.unlinked.discard(email)
            with self.server.session_lock:
                self.server.sessions = {key: pair for key, pair in self.server.sessions.items()
                                        if pair[1] != email}
            self.send_result(200, {"email": email})


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=18762)
    args = parser.parse_args()
    with ThreadingHTTPServer(("127.0.0.1", args.port), AuthFixture) as server:
        server.sessions = {}
        server.verifications = {}
        server.proofs = {}
        server.unlinked = set()
        server.next_member = 103
        server.passwords = dict.fromkeys(MEMBERS, PASSWORD)
        server.flow_lock = threading.Lock()
        server.session_lock = threading.Lock()
        server.log_lock = threading.Lock()
        with tempfile.TemporaryDirectory(prefix="umc-auth-flow-") as directory:
            server.control = Path(directory)
            (server.control / "events").touch()
            print(f"Fixture ready on 127.0.0.1:{server.server_port}; control={directory}", flush=True)
            server.serve_forever()
