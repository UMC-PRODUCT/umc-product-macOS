#  session_fixture.py
#  UMCDesk
#
#  Created by euijjang97 on 11/23/26.

"""Run a loopback-only login fixture. SIGUSR1 expires current test sessions."""

import community_post_fixture
import home_activity_fixture
import matching_fixture
import notice_fixture
import thread_feature_fixture
import argparse
import json
import secrets
import signal
import tempfile
import threading
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

MEMBERS = {
    "first@example.test": ("101", "첫 챌린저"),
    "ops@example.test": ("104", "운영 검증 회원"),
    "design@example.test": ("103", "디자인 챌린저"),
    "second@example.test": ("102", "둘째 챌린저"),
}
PASSWORD = "fixture-only"


class SessionFixture(BaseHTTPRequestHandler):
    def send_result(self, status, result=None, *, code=None, message=None):
        envelope = {"success": 200 <= status < 300, "result": result}
        if code is not None:
            envelope["code"] = code
        if message is not None:
            envelope["message"] = message
        body = json.dumps(envelope).encode()
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
            path = urlsplit(self.path).path
            is_upload = self.command == "PUT" and path.startswith(("/qa/notice-upload/", "/fixture/thread-photo/"))
            limit = 10 * 1024 * 1024 if is_upload else 1048576
            if not 0 <= length <= limit:
                return self.send_result(400)
            data = self.rfile.read(length)
            if is_upload:
                return self.signed_request(path, data)
            body = json.loads(data) if data else {}
            if not isinstance(body, dict) and not (isinstance(body, list) and self.path.endswith("/attendances/decide")):
                return self.send_result(400)
        except (ValueError, UnicodeDecodeError):
            return self.send_result(400)

        if self.command == "POST" and self.path == "/api/v1/auth/login/email":
            email = body.get("email")
            if isinstance(email, str) and email in MEMBERS and body.get("password") == PASSWORD:
                self.wait_if_held("login")
                with self.server.session_lock:
                    result = self.issue(email)
                return self.send_result(200, result)
            return self.send_result(401)

        if self.command == "POST" and self.path in ("/api/v1/auth/logout", "/api/v1/auth/token/renew"):
            if self.path.endswith("/logout"):
                self.wait_if_held("revoke")
            refresh = body.get("refreshToken")
            with self.server.session_lock:
                prior = self.server.sessions.pop(refresh, None) if isinstance(refresh, str) else None
                if self.path.endswith("/renew") and not prior:
                    return self.send_result(401)
                result = self.issue(prior[1]) if self.path.endswith("/renew") else None
            return self.send_result(200, result)
        email = self.current_email()
        if not email:
            return self.send_result(401)
        if self.feature_request(email, body):
            return
        self.send_result(404)

    def feature_request(self, email, body):
        url = urlsplit(self.path)
        path, query = url.path, parse_qs(url.query)
        member = MEMBERS[email][0]
        if self.command == "PATCH" and path == "/api/v1/member/profile/links":
            fields = {"GITHUB": "github", "LINKEDIN": "linkedIn", "INSTAGRAM": "instagram",
                      "BLOG": "blog", "PERSONAL": "personal"}
            links = {}
            try:
                entries = body["links"]
                if not isinstance(entries, list):
                    raise ValueError()
                for item in entries:
                    key, address = fields[item["type"]], item["link"]
                    url = urlsplit(address)
                    if key in links or url.scheme not in ("http", "https") or not url.hostname:
                        raise ValueError()
                    links[key] = address
            except (KeyError, TypeError, ValueError):
                self.send_result(400, message="프로필 링크 형식을 확인해 주세요.")
                return True
            with self.server.session_lock:
                if not hasattr(self.server, "profile_links"):
                    self.server.profile_links = {}
                self.server.profile_links[member] = links
            self.send_result(200, self.profile(email))
            return True
        if community_post_fixture.handle(self, self.command, path, query, body, member):
            return True
        if thread_feature_fixture.handle(self, self.command, path, query, body, member):
            return True
        if notice_fixture.handle(self, self.command, path, query, body, email):
            return True
        result = home_activity_fixture.handle(self.command, path, query, body, member)
        if result is not None:
            self.send_result(*result)
            return True
        return matching_fixture.handle(self, self.command, path, query, body, member)

    def signed_request(self, path, data):
        if path.startswith("/fixture/thread-photo/"):
            if thread_feature_fixture.handle(self, self.command, path, {}, data, None):
                return
        elif notice_fixture.handle(self, self.command, path, {}, data, None):
            return
        self.send_result(404)

    def do_PATCH(self):
        self.do_POST()

    def do_DELETE(self):
        self.do_POST()

    def do_PUT(self):
        self.do_POST()

    def wait_if_held(self, name):
        hold = self.server.control / ("hold-" + name)
        if hold.exists():
            marker = self.server.control / ("waiting-" + name)
            marker.touch()
            try:
                while hold.exists():
                    time.sleep(0.05)
            finally:
                marker.unlink(missing_ok=True)

    def current_email(self):
        with self.server.session_lock:
            for access, email in self.server.sessions.values():
                if self.headers.get("Authorization") == "Bearer " + access:
                    return email
        return None

    def profile(self, email):
        identifier, name = MEMBERS[email]
        part = {"101": "WEB", "102": "PLAN", "103": "DESIGN", "104": "PLAN"}.get(identifier, "WEB")
        activities = [{"challengerId": identifier, "gisuId": "10", "gisu": "10", "part": part, "roles": []}]
        if identifier in ("101", "102", "103", "104"):
            activities.append({"challengerId": "999", "gisuId": "9", "gisu": "9", "part": "DESIGN", "roles": []})
        if email in getattr(self.server, "unlinked", set()):
            activities = []
        with self.server.session_lock:
            links = getattr(self.server, "profile_links", {}).get(identifier, {}).copy()
        return {"id": identifier, "name": name, "nickname": name, "email": email,
                "profile": links, "schoolName": "테스트 대학교", "roles": [], "challengerRecords": activities}

    def do_GET(self):
        path = urlsplit(self.path).path
        if path == "/ws/websocket":
            def identify(token):
                with self.server.session_lock:
                    return next((MEMBERS[email][0] for access, email in self.server.sessions.values()
                                 if access == token), None)
            return thread_feature_fixture.socket(self, identify)
        if path.startswith(("/qa/notice-upload/", "/fixture/thread-photo/")):
            return self.signed_request(path, b"")
        if self.path == "/api/v1/system/status":
            return self.send_result(200, {"inMaintenance": False, "current": None, "upcoming": None})
        email = self.current_email()
        if not email:
            return self.send_result(401)
        url = urlsplit(self.path)
        query = parse_qs(url.query)
        identifier, name = MEMBERS[email]
        if self.feature_request(email, {}):
            return
        if url.path == "/api/v1/member/me":
            self.wait_if_held("profile-" + identifier)
            reject = self.server.control / ("fail-profile-once-" + identifier)
            if reject.exists():
                reject.unlink(missing_ok=True)
                return self.send_result(401)
            return self.send_result(200, self.profile(email))
        if url.path == "/api/v2/member/me":
            notice_operator = identifier == "101"
            return self.send_result(200, {
                "isSuperAdmin": identifier == "104",
                "currentGisuMemberInfo": {
                    "gisuId": "10",
                    "isAdmin": notice_operator,
                    "roleTypes": ["CENTRAL_OPERATING_TEAM_MEMBER"] if notice_operator else [],
                },
            })
        if url.path == "/api/v1/gisu/active":
            return self.send_result(200, {"gisuId": "10"})
        if url.path == "/api/v2/gisu":
            return self.send_result(200, {"gisus": [{"gisuId": "10", "schools": [],
                "chapters": [{"chapterId": "2" if identifier == "104" else "1",
                              "chapterName": "운영 검증 지부" if identifier == "104" else "테스트 지부"}]}]})
        if url.path == "/api/v1/projects/matching-affiliation/me":
            return self.send_result(200, {"gisuId": "10", "matchingChapter": {
                "id": "2" if identifier == "104" else "1"}})
        if url.path == "/api/v1/project/matching-rounds":
            rounds = []
            for round_id, chapter, kind in [
                ("501", "1", "PLAN_DEVELOPER"), ("502", "1", "PLAN_DESIGN"),
                ("503", "2", "PLAN_DEVELOPER"), ("504", "2", "PLAN_DESIGN")
            ]:
                rounds.append({"id": round_id, "name": "검증 차수 " + round_id,
                               "type": kind, "phase": "FIRST", "chapterId": chapter,
                               "startsAt": "2025-01-01T00:00:00Z", "endsAt": "2030-01-01T00:00:00Z"})
            return self.send_result(200, rounds)
        if url.path == "/api/v1/projects/permissions":
            return self.send_result(200, {"projects": [{"projectId": "1", "exists": True,
                "member": {"canRead": {"allowed": True}},
                "application": {"canCreate": {"allowed": identifier != "102"}}}]})
        if url.path == "/api/v1/projects/1":
            return self.send_result(200, {"id": "1", "name": "모아", "description": "로컬 검증 공고",
                                          "partQuotas": [], "partQuotaStatus": "RECRUITING"})
        if url.path == "/api/v1/projects/me/applications":
            return self.send_result(200, [])
        if url.path == "/api/v1/projects/admin/pm-candidates":
            return self.send_result(403)
        if url.path == "/api/v1/projects":
            projects = [{"id": "1", "name": "모아", "description": "로컬 검증 공고",
                         "partQuotas": [], "partQuotaStatus": "RECRUITING"}]
            projects = [row for row in projects if query.get("keyword", [""])[0] in row["name"]]
            return self.send_result(200, {"content": projects, "totalElements": str(len(projects)),
                                          "hasNext": False})
        self.send_result(404)


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
