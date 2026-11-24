#  test_thread_safety_fixture.py
#  UMCDesk
#
#  Created by euijjang97 on 11/23/26.

"""Authenticated loopback contract for thread message reports and profile moderation."""

from http.server import ThreadingHTTPServer
import json
from pathlib import Path
import tempfile
import threading
import unittest
from urllib.error import HTTPError
from urllib.request import Request, urlopen

from session_fixture import SessionFixture


class ThreadSafetyFixtureTests(unittest.TestCase):
    def setUp(self):
        self.server = ThreadingHTTPServer(("127.0.0.1", 0), SessionFixture)
        self.server.sessions = {}
        self.server.session_lock = threading.Lock()
        self.server.log_lock = threading.Lock()
        temp = tempfile.TemporaryDirectory()
        self.addCleanup(temp.cleanup)
        self.server.control = Path(temp.name)
        self.addCleanup(self.server.server_close)
        thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        thread.start()
        self.addCleanup(self.server.shutdown)
        self.first = self.login("first")
        self.second = self.login("second")

    def call(self, method, path, token=None, body=None, expected=200):
        request = Request(f"http://127.0.0.1:{self.server.server_port}/api/v1/" + path,
                          method=method, data=None if body is None else json.dumps(body).encode(),
                          headers={"Authorization": "Bearer " + (token or ""),
                                   "Content-Type": "application/json"})
        try:
            response = urlopen(request, timeout=4)
        except HTTPError as error:
            response = error
        with response:
            self.assertEqual(response.status, expected, path)
            return json.load(response)["result"]

    def login(self, name):
        return self.call("POST", "auth/login/email", body={"email": name + "@example.test",
                         "password": "fixture-only"})["accessToken"]

    def test_report_retry_and_block_readback_are_account_scoped(self):
        message = "community/messages/1/report"
        reasons = {"reasons": ["SPAM", "ABUSE"]}
        self.call("POST", message, self.first, reasons, 403)
        self.call("POST", message, self.second, reasons, 403)
        self.call("POST", "community/threads/101/invite", self.first, {"memberIds": [102]})
        (self.server.control / "fail-thread-safety-once").touch()
        self.call("POST", message, self.second, reasons, 503)
        receipt = self.call("POST", message, self.second, reasons, 201)
        self.assertEqual(receipt["messageId"], "1")
        self.assertEqual(receipt["reasons"], reasons["reasons"])
        self.call("POST", message, self.second, reasons, 409)
        report = "reports/members/101"
        self.call("POST", report, self.second, {"reasons": ["ABUSE"], "detail": "내용"}, 400)
        self.call("POST", report, self.second, {"reasons": ["HARASSMENT"], "detail": " "}, 400)
        member = self.call("POST", report, self.second,
                           {"reasons": ["HARASSMENT"], "detail": "반복되는 연락"}, 201)
        self.assertNotEqual(member["reportId"], receipt["reportId"])
        self.assertEqual(member["memberId"], "101")
        route = "member/blocks"
        self.call("POST", route + "/101", self.first, expected=400)
        (self.server.control / "fail-thread-safety-once").touch()
        self.call("POST", route + "/101", self.second, expected=503)
        self.assertEqual(self.call("GET", route, self.second)["members"], [])
        self.assertTrue(self.call("POST", route + "/101", self.second)["isBlocked"])
        self.assertEqual(self.call("GET", route, self.second)["members"][0]["memberId"], "101")
        self.assertEqual(self.call("GET", route, self.first)["members"], [])
        history = "community/threads/101/messages"
        def hidden():
            rows = self.call("GET", history, self.second)["messages"]
            return next(row for row in rows if row["messageId"] == "1")["isSenderBlocked"]
        self.assertTrue(hidden())
        self.assertFalse(self.call("DELETE", route + "/101", self.second)["isBlocked"])
        self.assertFalse(hidden())
        self.assertEqual(self.call("GET", route, self.second)["members"], [])


if __name__ == "__main__":
    unittest.main()
