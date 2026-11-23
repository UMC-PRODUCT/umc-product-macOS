#  auth_flow_fixture.py
#  UMCDesk
#
#  Created by euijjang97 on 11/23/26.

"""Loopback auth QA. Use a new @example.test address, OTP 123456, challenger UMC123.

Resending rotates the code to 654321. Touch/remove 'maintenance' in the printed control
directory to toggle full maintenance, or hold-login to pause a valid login.
SIGUSR2 expires access tokens; SIGUSR1 expires all sessions. All data is synthetic.
"""

import argparse
import json
import secrets
import signal
import tempfile
import threading
from http.server import ThreadingHTTPServer
from pathlib import Path

from session_fixture import MEMBERS, PASSWORD, SessionFixture


AUTH_POST_PATHS = {
    "/api/v1/auth/email-verification",
    "/api/v1/auth/email-verification/resend",
    "/api/v1/auth/email-verification/code",
    "/api/v1/member/register/email",
    "/api/v1/auth/login/email",
    "/api/v1/challenger-record/member",
}


class AuthFixture(SessionFixture):
    def profile(self, email):
        result = super().profile(email)
        result["nickname"] = self.server.nicknames.get(email, result["nickname"])
        return result

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
        return super().do_GET()

    def read_body(self):
        size = int(self.headers.get("Content-Length", "0"))
        if not 0 < size <= 8192:
            raise ValueError()
        body = json.loads(self.rfile.read(size))
        if not isinstance(body, dict):
            raise ValueError()
        return body

    def do_POST(self):
        # SessionFixture dispatches its PATCH, DELETE and PUT handlers through self.do_POST().
        if self.command != "POST" or self.path not in AUTH_POST_PATHS:
            return super().do_POST()
        try:
            body = self.read_body()
            if self.path == "/api/v1/auth/login/email":
                return self.login(body)
            with self.server.flow_lock:
                self.post(body)
        except (ValueError, TypeError, KeyError):
            self.send_result(400)

    def login(self, body):
        email = body["email"]
        password = body["password"]
        with self.server.flow_lock:
            if email not in MEMBERS or self.server.passwords[email] != password:
                return self.send_result(401)
            member_id = MEMBERS[email][0]
        self.wait_if_held("login")
        with self.server.flow_lock:
            if (email not in MEMBERS or MEMBERS[email][0] != member_id
                    or self.server.passwords[email] != password):
                return self.send_result(401)
            with self.server.session_lock:
                result = self.issue(email)
        return self.send_result(200, result)

    def post(self, body):
        if self.path == "/api/v1/auth/email-verification":
            email, purpose = body["email"], body["purpose"]
            if (not isinstance(email, str) or not email.endswith("@example.test")
                    or purpose not in ("REGISTER", "PASSWORD_RESET")):
                return self.send_result(400)
            if (email in MEMBERS) != (purpose == "PASSWORD_RESET"):
                return self.send_result(400)
            identifier = self.server.next_verification
            self.server.next_verification += 1
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
            return self.send_result(401, code="AUTHENTICATION-0004", message="인증번호를 확인해 주세요.")
        if self.path == "/api/v1/member/register/email":
            token = body["emailVerificationToken"]
            email, purpose = self.server.proofs[token]
            agreements = {row["termsId"]: row["isAgreed"] for row in body["termsAgreements"]}
            if purpose != "REGISTER" or email in MEMBERS or body["schoolId"] != 1:
                return self.send_result(400)
            if agreements != {1: True, 2: True} or not body["name"] or not body["nickname"]:
                return self.send_result(400)
            self.server.passwords[email] = body["rawPassword"]
            self.server.nicknames[email] = body["nickname"]
            MEMBERS[email] = (str(self.server.next_member), body["name"])
            self.server.next_member += 1
            self.server.unlinked.add(email)
            del self.server.proofs[token]
            with self.server.session_lock:
                return self.send_result(200, self.issue(email))
        if self.path == "/api/v1/challenger-record/member":
            email = self.current_email()
            if not email:
                return self.send_result(401)
            if body["code"] == "USED12" or email not in self.server.unlinked:
                return self.send_result(400, code="CHALLENGER-0012", message="이미 사용한 챌린저 코드예요.")
            if body["code"] != "UMC123":
                return self.send_result(400)
            self.server.unlinked.remove(email)
            return self.send_result(200)
        self.send_result(404)

    def do_PATCH(self):
        if self.path != "/api/v1/auth/password/reset":
            return super().do_PATCH()
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
            return super().do_DELETE()
        with self.server.flow_lock:
            email = self.current_email()
            if not email:
                return self.send_result(401)
            del self.server.passwords[email]
            self.server.unlinked.discard(email)
            self.server.nicknames.pop(email, None)
            self.server.verifications = {key: row for key, row in self.server.verifications.items()
                                         if row[0] != email}
            self.server.proofs = {key: proof for key, proof in self.server.proofs.items()
                                  if proof[0] != email}
            with self.server.session_lock:
                identifier, _ = MEMBERS.pop(email)
                getattr(self.server, "profile_links", {}).pop(identifier, None)
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
        server.next_member = max(int(identifier) for identifier, _ in MEMBERS.values()) + 1
        server.next_verification = 1
        server.nicknames = {}
        server.passwords = dict.fromkeys(MEMBERS, PASSWORD)
        server.flow_lock = threading.Lock()
        server.session_lock = threading.Lock()
        server.log_lock = threading.Lock()
        with tempfile.TemporaryDirectory(prefix="umc-auth-flow-") as directory:
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
