#  notice_design_fixture.py
#  UMCDesk
#
#  Created by euijjang97 on 11/27/26.

"""Opt-in loopback UI scenarios. Reuses session authentication; never changes the base fixture.

Start: python3 -B tools/qa/notice_design_fixture.py --port 0 --scenario reading
After window permission, launch the Debug app with --local-api-port PRINTED_PORT.
Sign in with first@example.test / fixture-only. The existing Debug fixture entry uses
memory tokens, not Keychain. This is NOT the View > Data Preview in-process dataset.

The printed control folder contains local PNGs and notice-requests.jsonl (no tokens).
Touch a marker in that folder to arm a scenario:
  late-pin                      nonpinned first page; pinned 21 on the last page
  fail-notice-page-once          next page returns 503 once
  fail-notice-list-once          existing first/any list failure
  deny-notice-list-once          existing list 403
  deny-notice-detail-once        next detail returns 403
  fail-notice-read-once          read confirmation returns 503 without changing reads
  fail-notice-vote-once          vote response returns 503 without changing ballots
  fail-notice-delete-once        delete returns 503 without removing the article
  fail-notice-images-once        image PATCH fails before saving
  fail-notice-links-once         link PATCH fails after any earlier image success
  drop-notice-create-once        create commits but returns 503 (uncertain publication)
  drop-notice-poll-once          poll commits, returns 503, blocks receipt read
Remove block-poll-receipt-read to let the poll recovery button confirm the saved poll.
All failures are synthetic, not claims about server ordering or permission contracts.
Restart this wrapper for a fresh dataset; it never touches another fixture/process.
"""

import argparse
import copy
import json
import struct
import tempfile
import threading
import zlib
from http.server import ThreadingHTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlsplit

import notice_fixture
from session_fixture import SessionFixture

ROOT = "/api/v1/notices"
OWNER = "first@example.test"


def sample_png(color):
    """Small deterministic RGB fixture image; no external image or service dependency."""
    def chunk(kind, payload):
        return (struct.pack(">I", len(payload)) + kind + payload
                + struct.pack(">I", zlib.crc32(kind + payload) & 0xffffffff))
    width, height = 320, 220
    pixels = b"".join(b"\0" + bytes(color) * width for _ in range(height))
    return (b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0))
            + chunk(b"IDAT", zlib.compress(pixels)) + chunk(b"IEND", b""))


def prepare(server, scenario="reading"):
    server.design_lock = threading.RLock()
    server.notice_state = notice_fixture._initial_state()
    state = server.notice_state
    base = f"http://127.0.0.1:{server.server_port}"
    main = state["entries"]["21"]
    main["title"] = "긴 한글 공지 제목과 줄바꿈을 확인하는 운영 안내입니다 " * 3
    main["author"]["nickname"] = "긴작성자이름을가진운영담당챌린저" * 3
    main["author"]["organizationName"] = "합성대학교 중앙운영팀 · 긴 소속명 검수"
    main["content"] = ("첫 문단을 선택하고 복사할 수 있습니다.\n\n"
                       "사진과 투표를 확인한 뒤 읽음 확인을 따로 진행하세요.\n" * 5)
    main["links"] = [{"id": "1", "url": base + "/qa/notice-design/link/" + "long-path-" * 35}]
    main["images"] = []
    for name, color in [("blue", (60, 120, 180)), ("green", (45, 145, 110))]:
        data = sample_png(color)
        key = "design-" + name
        (server.control / (name + ".png")).write_bytes(data)
        state["files"][key] = {"owner": OWNER, "size": len(data), "type": "image/png",
                               "data": data, "confirmed": True}
        main["images"].append({"id": key, "fileId": key, "url": base + "/qa/notice-upload/" + key})
    for identifier in range(23, 44):
        entry = copy.deepcopy(state["entries"]["22"])
        entry.update(id=str(identifier), title=f"페이지 검수 공지 {identifier}")
        state["entries"][str(identifier)] = entry
    if scenario == "late-pin":
        (server.control / "late-pin").touch()
    (server.control / "notice-requests.jsonl").touch()


def consume(server, marker):
    try:
        (server.control / marker).unlink()
        return True
    except FileNotFoundError:
        return False


class Capture:
    """Capture only JSON results; binary responses still use the original handler."""
    def __init__(self, handler):
        self.handler = handler
        self.result = None

    def __getattr__(self, name):
        return getattr(self.handler, name)

    def send_result(self, status, result=None, **kwargs):
        self.result = (status, result, kwargs)


def handle(handler, method, path, query, body, email):
    permission = path == "/api/v1/authorization/resource-permission"
    if not (path.startswith(ROOT) or permission or path.startswith("/api/v1/storage/")):
        return False
    server = handler.server
    with server.design_lock:
        with (server.control / "notice-requests.jsonl").open("a") as log:
            # Deliberately excludes credentials, request bodies, and upload bytes.
            print(json.dumps({"method": method, "path": path, "query": query},
                             ensure_ascii=False), file=log)
        is_list = method == "GET" and path in (ROOT, ROOT + "/search")
        is_detail = (method == "GET" and path.startswith(ROOT + "/")
                     and path.removeprefix(ROOT + "/").isdigit())
        failures = [
            (method == "DELETE" and path.removeprefix(ROOT + "/").isdigit(),
             "fail-notice-delete-once", 503),
            (is_list and query.get("page", ["0"]) != ["0"], "fail-notice-page-once", 503),
            (is_detail, "deny-notice-detail-once", 403),
            (method == "POST" and path.endswith("/read"), "fail-notice-read-once", 503),
            (method in ("POST", "PUT") and path.endswith("/votes/responses"),
             "fail-notice-vote-once", 503),
            (method == "PATCH" and path.endswith("/images"), "fail-notice-images-once", 503),
            (method == "PATCH" and path.endswith("/links"), "fail-notice-links-once", 503),
        ]
        for matches, marker, status in failures:
            if matches and consume(server, marker):
                handler.send_result(status)
                return True
        if is_detail and (server.control / "block-poll-receipt-read").exists():
            handler.send_result(503)
            return True
        late_pin = is_list and (server.control / "late-pin").exists()
        forwarded_query = {**query, "page": ["0"], "size": ["100"]} if late_pin else query
        capture = Capture(handler)
        handled = notice_fixture.handle(capture, method, path, forwarded_query, body, email)
        if not handled or capture.result is None:
            return handled
        status, result, kwargs = capture.result
        if status == 200 and late_pin:
            try:
                page = max(0, int(query.get("page", ["0"])[0]))
                size = max(1, min(100, int(query.get("size", ["20"])[0])))
            except ValueError:
                handler.send_result(400)
                return True
            rows = sorted(result["content"], key=lambda row: (row["mustRead"], int(row["id"])))
            result = {"content": rows[page*size:(page+1)*size],
                      "hasNext": (page+1)*size < len(rows)}
        if status == 200 and method == "POST":
            marker = ("drop-notice-create-once" if path == ROOT else
                      "drop-notice-poll-once" if path.endswith("/votes") else None)
            if marker and consume(server, marker):
                if marker == "drop-notice-poll-once":
                    (server.control / "block-poll-receipt-read").touch()
                status, result = 503, None
        handler.send_result(status, result, **kwargs)
        return True


class NoticeDesignFixture(SessionFixture):
    def feature_request(self, email, body):
        url = urlsplit(self.path)
        if handle(self, self.command, url.path, parse_qs(url.query), body, email):
            return True
        return super().feature_request(email, body)

    def do_GET(self):
        if urlsplit(self.path).path.startswith("/qa/notice-design/link/"):
            payload = "로컬 공지 링크를 열었습니다.".encode()
            self.send_response(200)
            self.send_header("Content-Type", "text/plain; charset=utf-8")
            self.send_header("Content-Length", str(len(payload)))
            self.end_headers()
            self.wfile.write(payload)
            return
        super().do_GET()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=0)
    parser.add_argument("--scenario", choices=["reading", "late-pin"], default="reading")
    args = parser.parse_args()
    with ThreadingHTTPServer(("127.0.0.1", args.port), NoticeDesignFixture) as server:
        server.sessions = {}
        server.session_lock = threading.Lock()
        server.log_lock = threading.Lock()
        with tempfile.TemporaryDirectory(prefix="umc-notice-design-") as directory:
            server.control = Path(directory)
            (server.control / "events").touch()
            prepare(server, args.scenario)
            print(f"Notice design ready: port={server.server_port} control={directory}", flush=True)
            server.serve_forever()


if __name__ == "__main__":
    main()
