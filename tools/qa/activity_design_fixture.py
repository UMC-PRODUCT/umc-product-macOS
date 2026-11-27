#  activity_design_fixture.py
#  UMCDesk
#
#  Created by euijjang97 on 11/27/26.

"""Isolated Activity design fixture. No production requests, GPS, or Keychain.

Run with --port 0, then use the printed loopback port with the existing DEBUG
--local-api-port argument. Login second@example.test (manager) or
first@example.test (participant) with password fixture-only.
Restart this process to reset. Markers in the printed control folder:
fail-read-once, fail-write-once, empty-search, fail-search, no-create,
no-track, no-review, no-decide, empty-schedules, hold-write (remove to release).
The first schedule is online; the multi-day onsite schedule has no coordinate,
so opening its location sheet cannot trigger GPS. Never request real GPS.
Point markers: drop-point-receipt-once, point-ledger-unavailable. Logs omit tokens/bodies.
"""

import argparse
import copy
import importlib.util
import json
from pathlib import Path
import tempfile
import threading
import time
from datetime import timedelta
from http.server import ThreadingHTTPServer
from urllib.parse import parse_qs, urlsplit

from session_fixture import SessionFixture, MEMBERS


def prepare(server):
    # A fresh module instance owns all mutable activity state for this server.
    spec = importlib.util.spec_from_file_location(
        "activity_design_private", Path(__file__).with_name("home_activity_fixture.py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    module._groups["301"]["name"] = "긴 스터디 그룹 이름 검수 " * 3 + "가나다라마바 사"
    module._groups["301"]["name"] = module._groups["301"]["name"].ljust(50, "가")[:50]
    module._names.update({"101": "이름이아주긴합성챌린저" * 3, "102": "운영담당합성멘토" * 3})
    module._status["101", "701"] = "EXCUSED_PENDING"
    server.activity_design = module
    server.activity_lock = threading.RLock()


def consume(server, marker):
    try:
        (server.control / marker).unlink()
        return True
    except FileNotFoundError:
        return False


def handle(handler, method, path, query, body, email):
    server = handler.server
    member = str(MEMBERS[email][0])
    activity = server.activity_design
    # Delegate only activity routes; retain the established session/auth harness.
    with server.activity_lock:
        supported = (path.startswith(("/api/v2/schedules", "/api/v2/curriculums",
                                     "/api/v1/study-groups", "/api/v1/challenger/"))
                     or path.startswith("/api/v1/member/profile/")
                     or path == "/api/v1/member/search" and query.get("size") == ["30"]
                     or path.startswith("/api/v1/authorization/resource-permission"))
        if not supported:
            return False
        # Batch permission POST is a read, never a simulated write failure.
        is_read = method == "GET" or path.endswith("/batch")
        marker = "fail-read-once" if is_read else "fail-write-once"
        if path.startswith("/api/v1/challenger/") and is_read and (server.control / "point-ledger-unavailable").exists():
            record(server, method, path, query, 503)
            handler.send_result(503, None)
            return True
        if not is_read:
            while (server.control / "hold-write").exists():
                time.sleep(0.1)
        if consume(server, marker):
            record(server, method, path, query, 503)
            handler.send_result(503, None)
            return True
        if path == "/api/v1/member/search" and (server.control / "fail-search").exists():
            record(server, method, path, query, 503)
            handler.send_result(503, None)
            return True
        response = activity.handle(method, path, query, body, member)
        if response is None:
            return False
        status, result = response
        if status == 200 and method == "POST" and path.endswith("/points") and consume(server, "drop-point-receipt-once"):
            (server.control / "point-ledger-unavailable").touch()
            record(server, method, path, query, 503)
            handler.send_result(503, None)
            return True
        result = copy.deepcopy(result)
        if status == 200:
            if path == "/api/v2/schedules/capabilities":
                if (server.control / "no-create").exists():
                    result["canCreateSchedule"] = False
                if (server.control / "no-track").exists():
                    result["canCreateAttendanceRequiredSchedule"] = False
            elif path == "/api/v2/schedules/me":
                for row in result:
                    row["name"] = ("긴 일정 제목과 날짜 및 장소를 확인하는 합성 일정 " * 5)[:100]
                    if row["scheduleId"] == "702":
                        row["startsAt"] = activity._iso(activity._anchor - timedelta(days=1))
                        row["endsAt"] = activity._iso(activity._anchor + timedelta(days=2))
                        row["attendancePolicy"] = {
                            "checkInStartAt": activity._iso(activity._anchor - timedelta(minutes=10)),
                            "onTimeEndAt": activity._iso(activity._anchor + timedelta(minutes=10)),
                            "lateEndAt": activity._iso(activity._anchor + timedelta(minutes=45))}
                        row["location"] = {"locationName": "매우 긴 장소 " * 12}
                if (server.control / "empty-schedules").exists():
                    result = []
            elif path == "/api/v2/schedules/attendance":
                for row in result:
                    row["name"] = "긴 검토 일정 " * 10
                    row["participants"][0]["name"] = activity._names["101"]
                    row["participants"][0]["excuseReason"] = ("긴 사유의 줄바꿈과 복사 및 개별 판정을 검수합니다. " * 15)[:300]
            elif path.startswith("/api/v1/study-groups/") and "mentors" in result:
                for role in ("mentors", "members"):
                    for row in result[role]:
                        row["schoolName"] = "긴 이름의 합성대학교 소프트웨어융합대학 " * 3
            elif path == "/api/v1/member/search":
                if (server.control / "empty-search").exists():
                    result["page"]["content"] = []
                for row in result["page"]["content"]:
                    row["name"] = activity._names[str(row["memberId"])]
                    row["schoolName"] = "긴 이름의 합성대학교 소프트웨어융합대학 " * 3
            elif path.endswith("resource-permission"):
                if query.get("resourceType") == ["ATTENDANCE"] and (server.control / "no-review").exists():
                    for permission in result["permissions"]:
                        permission["hasPermission"] = False
            elif path.endswith("/batch") and (server.control / "no-decide").exists():
                for row in result["results"]:
                    for permission in row["permissions"]:
                        permission["hasPermission"] = False
        record(server, method, path, query, status)
        handler.send_result(status, result)
        return True


def record(server, method, path, query, status):
    with (server.control / "activity-requests.jsonl").open("a") as log:
        log.write(json.dumps({"method": method, "path": path, "query": query,
                              "status": status}, ensure_ascii=False) + "\n")


class ActivityDesignFixture(SessionFixture):
    def feature_request(self, email, body):
        url = urlsplit(self.path)
        if handle(self, self.command, url.path, parse_qs(url.query), body, email):
            return True
        return super().feature_request(email, body)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--port", type=int, default=0)
    args = parser.parse_args()
    with ThreadingHTTPServer(("127.0.0.1", args.port), ActivityDesignFixture) as server:
        server.sessions = {}
        server.session_lock = threading.Lock()
        server.log_lock = threading.Lock()
        with tempfile.TemporaryDirectory(prefix="umc-activity-design-") as folder:
            server.control = Path(folder)
            (server.control / "events").touch()
            prepare(server)
            print(f"Activity design ready: port={server.server_port} control={folder}", flush=True)
            server.serve_forever()


if __name__ == "__main__":
    main()
