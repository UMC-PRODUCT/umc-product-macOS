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
from urllib.parse import parse_qs, urlsplit

MEMBERS = {
    "first@example.test": ("101", "첫 챌린저"),
    "design@example.test": ("103", "디자인 챌린저"),
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
                self.wait_if_held("login")
                with self.server.session_lock:
                    result = self.issue(email)
                return self.send_result(200, result)
            return self.send_result(401)

        if self.path in ("/api/v1/auth/logout", "/api/v1/auth/token/renew"):
            if self.path.endswith("/logout"):
                self.wait_if_held("revoke")
            refresh = body.get("refreshToken")
            with self.server.session_lock:
                prior = self.server.sessions.pop(refresh, None) if isinstance(refresh, str) else None
                if self.path.endswith("/renew") and not prior:
                    return self.send_result(401)
                result = self.issue(prior[1]) if self.path.endswith("/renew") else None
            return self.send_result(200, result)
        self.send_result(404)

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

    def do_GET(self):
        email = self.current_email()
        if not email:
            return self.send_result(401)
        url = urlsplit(self.path)
        query = parse_qs(url.query)
        identifier, name = MEMBERS[email]
        if url.path == "/api/v1/member/me":
            part = {"101": "WEB", "102": "PLAN", "103": "DESIGN"}[identifier]
            return self.send_result(200, {
                "id": identifier, "name": name, "nickname": name, "email": email,
                "schoolName": "테스트 대학교", "roles": [], "challengerRecords": [
                    {"challengerId": identifier, "gisuId": "10", "gisu": "10", "part": part, "roles": []},
                    {"challengerId": "999", "gisuId": "9", "gisu": "9", "part": "DESIGN", "roles": []}],
            })
        if url.path == "/api/v2/member/me":
            return self.send_result(200, {"isSuperAdmin": False})
        if url.path == "/api/v1/gisu/active":
            return self.send_result(200, {"gisuId": "10"})
        if url.path == "/api/v2/gisu":
            return self.send_result(200, {"gisus": [{"gisuId": "10", "schools": [],
                "chapters": [{"chapterId": "1", "chapterName": "테스트 지부"}]}]})
        if url.path == "/api/v1/projects/matching-affiliation/me":
            return self.send_result(200, {"gisuId": "10", "matchingChapter": {"id": "1"}})
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
        if url.path == "/api/v1/community/threads":
            rows = [self.thread(identifier)]
            if query.get("filter", ["all"])[0] not in ("all", "FREE"):
                rows = []
            rows = [row for row in rows if query.get("q", [""])[0] in row["title"]]
            return self.send_result(200, {"pinned": [], "threads": rows, "nextOffset": None,
                                          "total": str(len(rows))})
        if url.path == f"/api/v1/community/threads/{identifier}/messages":
            return self.send_result(200, {"messages": [
                {"messageId": "1", "senderName": name, "content": "로컬 계정별 테스트 메시지",
                 "isSenderBlocked": False}], "hasMore": False, "nextBefore": None})
        self.send_result(404)

    @staticmethod
    def thread(identifier):
        return {"threadId": identifier, "title": "테스트 스레드 " + identifier, "description": "로컬 테스트",
                "icon": "💬", "category": "FREE", "isPinned": False, "isMuted": False,
                "isJoined": True, "membershipState": "ACTIVE", "unreadCount": "0"}


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
