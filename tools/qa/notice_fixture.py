#  notice_fixture.py
#  UMCDesk
#
#  Created by euijjang97 on 11/23/26.

"""Synthetic notice routes shared by the loopback session fixture."""

from datetime import datetime, timedelta, timezone
from threading import RLock
from uuid import uuid4

_LOCK = RLock()
_MEMBERS = {"first@example.test": ("101", "첫 챌린저"),
            "second@example.test": ("102", "둘째 챌린저"),
            "design@example.test": ("103", "디자인 챌린저"),
            "ops@example.test": ("104", "운영 검증 회원")}
_WRITERS = {"first@example.test", "ops@example.test"}


def _now():
    return datetime.now(timezone.utc)


def _timestamp(moment):
    return moment.isoformat().replace("+00:00", "Z")


def _article(identifier, title, content, email, audience, pinned=False):
    return {"id": str(identifier), "title": title, "content": content,
            "createdAt": _timestamp(_now()), "mustRead": pinned, "viewCount": "0",
            "targetInfo": audience, "author": {"nickname": _MEMBERS[email][1],
            "organizationName": "합성 운영팀"}, "images": [], "links": [], "vote": None}


def _poll(title, options, ends_at, anonymous=True, multiple=False):
    return {"title": title, "status": "OPEN", "isAnonymous": anonymous,
            "allowMultipleChoice": multiple, "endsAtExclusive": ends_at,
            "totalParticipants": "0", "mySelectedOptionIds": [],
            "options": [{"optionId": str(i), "content": name, "voteCount": "0"}
                        for i, name in enumerate(options, start=1)]}


def _initial_state():
    audience = {"targetGisuId": 10, "targetNoticeTab": "CHALLENGER", "targetParts": []}
    owner = "first@example.test"
    main = _article(21, "합성 해커톤 참가 신청 안내", "참여할 프로그램을 선택해 주세요.",
                    owner, audience, True)
    main["vote"] = _poll("프로그램 선택", ["기획", "개발"], _timestamp(_now() + timedelta(days=3)))
    main["links"] = [{"id": "1", "url": "https://example.test/program"}]
    second = _article(22, "합성 중간 발표 제출 안내", "발표 자료를 확인해 주세요.", owner, audience)
    return {"entries": {"21": main, "22": second}, "reads": {}, "ballots": {}, "files": {}}


def handle(handler, method, path, query, body, email):
    """Return True if this route wrote a response. query uses urllib.parse.parse_qs."""
    permission = (path == "/api/v1/authorization/resource-permission"
                  and query.get("resourceType") == ["NOTICE"])
    if not (permission or path.startswith("/api/v1/notices") or path.startswith("/api/v1/storage/")
            or path.startswith("/qa/notice-upload/")):
        return False

    def send(status, result=None):
        handler.send_result(status, result)
        return True

    with _LOCK:
        server = handler.server
        if not hasattr(server, "notice_state"):
            server.notice_state = _initial_state()
        state = server.notice_state
        files = state["files"]
        if path.startswith("/qa/notice-upload/"):
            file = files.get(path.rsplit("/", 1)[-1])
            if not file:
                return send(404)
            if method == "PUT" and isinstance(body, bytes) and len(body) == file["size"]:
                file["data"] = body
                return send(200)
            if method == "GET" and file.get("confirmed"):
                handler.send_response(200)
                handler.send_header("Content-Type", file["type"])
                handler.send_header("Content-Length", str(len(file["data"])))
                handler.end_headers()
                handler.wfile.write(file["data"])
                return True
            return send(400)
        if email not in _MEMBERS:
            return send(401)
        if permission:
            key = query.get("resourceId", [""])[0]
            if key not in state["entries"]:
                return send(404)
            return send(200, {"resourceType": "NOTICE", "resourceId": key, "permissions": [
                {"permissionType": kind, "hasPermission": kind == "READ" or email in _WRITERS}
                for kind in ("READ", "CHECK", "EDIT", "DELETE")]})
        body = body or {}
        base = f"http://127.0.0.1:{server.server_port}/qa/notice-upload/"
        if path == "/api/v1/storage/prepare-upload" and method == "POST":
            if body.get("category") != "NOTICE_ATTACHMENT":
                return False
            size = body.get("fileSize")
            if not isinstance(size, int) or not 0 < size <= 10 * 1024 * 1024:
                return send(400)
            key = uuid4().hex
            files[key] = {"owner": email, "size": size, "type": body["contentType"]}
            return send(200, {"fileId": key, "uploadMethod": "PUT", "uploadUrl": base + key,
                              "headers": {"Content-Type": body["contentType"]}})
        if path.startswith("/api/v1/storage/"):
            key = path.split("/")[-2]
            if key not in files:
                return False
            if method == "POST" and path.endswith("/confirm") and files[key]["owner"] == email:
                if "data" not in files[key]:
                    return send(400)
                files[key]["confirmed"] = True
                return send(200)
            return send(404)
        entries = state["entries"]
        suffix = path.removeprefix("/api/v1/notices").strip("/")
        if suffix in ("", "search") and method == "GET":
            if "gisuId" not in query or "noticeTab" not in query:
                return send(400)
            term = query.get("keyword", [""])[0].casefold()
            try:
                page = max(0, int(query.get("page", ["0"])[0]))
                size = max(1, min(100, int(query.get("size", ["20"])[0])))
            except ValueError:
                return send(400)
            visible = [r for r in entries.values()
                       if str(r["targetInfo"].get("targetGisuId")) == query["gisuId"][0]
                       and r["targetInfo"]["targetNoticeTab"] == query["noticeTab"][0]
                       and (not query.get("part") or not r["targetInfo"].get("targetParts")
                            or query["part"][0] in r["targetInfo"]["targetParts"])
                       and term in (r["title"] + r["content"]).casefold()]
            visible.sort(key=lambda r: (r["mustRead"], r["createdAt"]), reverse=True)
            rows = [{**r, "hasImages": bool(r["images"]), "hasLinks": bool(r["links"]),
                     "hasVote": bool(r["vote"])} for r in visible[page*size:(page+1)*size]]
            for row in rows:
                for key in ("images", "links", "vote"):
                    del row[key]
            return send(200, {"content": rows, "hasNext": (page+1)*size < len(visible)})
        if not suffix and method == "POST":
            if email not in _WRITERS:
                return send(403)
            if not all(body.get(k) for k in ("title", "content", "targetInfo")):
                return send(400)
            key = str(max(map(int, entries)) + 1)
            entries[key] = _article(key, body["title"], body["content"], email, body["targetInfo"],
                                    body.get("mustRead", False))
            return send(200, {"noticeId": key})
        key, _, action = suffix.partition("/")
        entry = entries.get(key)
        if not entry:
            return send(404)
        ballots = state["ballots"].setdefault(key, {})
        readers = state["reads"].setdefault(key, set())
        vote = entry["vote"]
        if not action and method == "GET":
            entry["viewCount"] = str(int(entry["viewCount"]) + 1)
            result = dict(entry)
            if vote:
                result["vote"] = {**vote, "mySelectedOptionIds": ballots.get(email, []),
                                  "totalParticipants": str(len(ballots)), "options": [
                                      {**opt, "voteCount": str(sum(opt["optionId"] in ids
                                                                   for ids in ballots.values()))}
                                      for opt in vote["options"]]}
            return send(200, result)
        if action == "read" and method == "POST":
            readers.add(email)
            return send(200)
        if action == "votes/responses" and method in ("POST", "PUT"):
            if not vote or vote["status"] != "OPEN":
                return send(400)
            options = [str(i) for i in body.get("optionIds", [])]
            if (email in ballots) != (method == "PUT"):
                return send(409)
            if (method == "POST" and not options or not vote["allowMultipleChoice"] and len(options) > 1
                    or not set(options) <= {opt["optionId"] for opt in vote["options"]}):
                return send(400)
            if options:
                ballots[email] = options
            else:
                ballots.pop(email, None)
            return send(200)
        if email not in _WRITERS:
            return send(403)
        if not action and method == "PATCH":
            for field in ("title", "content", "mustRead"):
                entry[field] = body[field]
            return send(200)
        if not action and method == "DELETE":
            del entries[key]
            return send(200)
        if action == "reminders" and method == "POST":
            return send(200 if body.get("targetIds") else 400)
        if action == "vote" and method == "DELETE":
            entry["vote"] = None
            ballots.clear()
            return send(200)
        if action == "links" and method in ("POST", "PATCH"):
            if method == "PATCH":
                entry["links"] = []
            entry["links"] += [{"id": str(i), "url": url}
                               for i, url in enumerate(body["links"], start=len(entry["links"])+1)]
            return send(200, {"linkIds": [x["id"] for x in entry["links"]]})
        if action == "images" and method in ("POST", "PATCH"):
            ids = body.get("imageIds", [])
            if not ids and method == "POST" or not all(files.get(i, {}).get("confirmed") and files[i]["owner"] == email
                                  for i in ids):
                return send(400)
            if method == "PATCH":
                entry["images"] = []
            entry["images"] += [{"id": str(i), "fileId": file, "url": base + file}
                                for i, file in enumerate(ids, start=len(entry["images"])+1)]
            return send(200, {"imageIds": [x["id"] for x in entry["images"]]})
        if action == "votes" and method == "POST" and not vote:
            entry["vote"] = _poll(body["title"], body["options"], body["endsAtExclusive"],
                                  body["isAnonymous"], body["allowMultipleChoice"])
            return send(200, {"noticeVoteId": key, "voteId": key})
        if action == "read-statics" and method == "GET":
            return send(200, {"readCount": len(readers), "totalCount": len(_MEMBERS),
                              "unreadCount": len(_MEMBERS) - len(readers)})
        if action == "read-status" and method == "GET":
            read = query.get("status") == ["READ"]
            rows = [{"challengerId": member_id, "name": name, "schoolName": "합성 대학"}
                    for addr, (member_id, name) in _MEMBERS.items() if (addr in readers) == read]
            return send(200, {"content": rows, "nextCursor": None, "hasNext": False})
        return send(404)


def _serve_contract_test():
    """Serve one disposable NoticeData contract test on an OS-selected loopback port."""
    import json
    import os
    import time
    from pathlib import Path
    from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
    from urllib.parse import parse_qs, urlsplit

    directory = os.environ.get("NOTICE_CONTRACT_CONTROL")
    controls = Path(directory) if directory else None

    class ContractHandler(BaseHTTPRequestHandler):
        def send_result(self, status, result=None):
            payload = json.dumps({"success": status == 200, "result": result}).encode()
            if controls and status == 200 and self.command == "POST":
                kind = ("notice" if self.path == "/api/v1/notices" else
                        "poll" if self.path.endswith("/votes") else "")
                if kind:
                    with (controls / ("posts-" + kind)).open("a") as log:
                        log.write("1\n")
                    drop = controls / ("lose-" + kind)
                    if drop.exists():
                        drop.unlink()
                        payload = b"{"
            self.send_response(status)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)

        def log_message(self, *args):
            pass

        def dispatch(self):
            url = urlsplit(self.path)
            query = parse_qs(url.query)
            identities = {"Bearer notice-contract-fixture": "first@example.test",
                          "Bearer notice-reader-fixture": "second@example.test"}
            email = identities.get(self.headers.get("Authorization"))
            if url.path == "/api/v2/member/me" and email:
                return self.send_result(200, {"isSuperAdmin": email == "ops@example.test",
                    "currentGisuMemberInfo": {"gisuId": "10", "isAdmin": email in _WRITERS}})
            if url.path == "/api/v1/gisu/active" and email:
                return self.send_result(200, {"gisuId": "10"})
            if url.path == "/api/v2/gisu" and email:
                return self.send_result(200, {"gisus": [{"gisuId": 10, "generation": 10,
                    "schools": [], "chapters": [{"chapterId": 1, "chapterName": "합성 지부"}]}]})
            if controls:
                if (controls / "deny").exists() and (url.path.startswith("/api/v1/notices/")
                                                      or url.path.endswith("/resource-permission")):
                    return self.send_result(403)
                if self.command == "PUT":
                    (controls / "put-started").touch()
                    if url.path == "/qa/redirect-target":
                        (controls / "redirect-followed").touch()
                        return self.send_result(200)
                    if (controls / "redirect").exists():
                        self.send_response(307)
                        self.send_header("Location", "/qa/redirect-target")
                        self.end_headers()
                        return
                    if (controls / "hold-put").exists():
                        deadline = time.monotonic() + 5
                        while (controls / "hold-put").exists() and time.monotonic() < deadline:
                            time.sleep(0.02)
                if url.path.endswith("/confirm"):
                    (controls / "confirmed").touch()
            size = int(self.headers.get("Content-Length", "0"))
            if not 0 <= size <= 10 * 1024 * 1024:
                return self.send_result(400)
            data = self.rfile.read(size)
            if url.path.startswith("/qa/notice-upload/"):
                body = data
            else:
                try:
                    body = json.loads(data) if data else {}
                except ValueError:
                    return self.send_result(400)
            if not handle(self, self.command, url.path, query, body, email):
                self.send_result(404)

        do_GET = do_POST = do_PATCH = do_DELETE = do_PUT = dispatch

    with ThreadingHTTPServer(("127.0.0.1", 0), ContractHandler) as server:
        print(server.server_port, flush=True)
        server.serve_forever()


if __name__ == "__main__":
    _serve_contract_test()
