#  test_activity_design_fixture.py
#  UMCDesk
#
#  Created by euijjang97 on 11/27/26.

"""No HTTP listener, app launch, network, Keychain, or GPS."""
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from datetime import timedelta

import activity_design_fixture as design
import home_activity_fixture as base


class ActivityDesignFixtureTests(unittest.TestCase):
    def setUp(self):
        folder = tempfile.TemporaryDirectory()
        self.addCleanup(folder.cleanup)
        self.server = SimpleNamespace(control=Path(folder.name))
        design.prepare(self.server)

    def request(self, path, query=None, method="GET", body=None, status=200):
        responses = []
        handler = SimpleNamespace(server=self.server,
                                  send_result=lambda *args: responses.append(args))
        self.assertTrue(design.handle(handler, method, path, query or {}, body or {},
                                      "second@example.test"))
        self.assertEqual(responses[0][0], status)
        return responses[0][1]

    def schedules(self):
        anchor = self.server.activity_design._anchor
        return self.request("/api/v2/schedules/me", {
            "from": [(anchor - timedelta(days=30)).isoformat()],
            "to": [(anchor + timedelta(days=30)).isoformat()],
            "isAttendanceRequired": ["true"]})

    def arm(self, marker):
        (self.server.control / marker).touch()

    def test_long_content_multiday_and_no_gps_coordinate(self):
        rows = self.schedules()
        self.assertEqual(len(rows[0]["name"]), 100)
        onsite = next(row for row in rows if row["scheduleId"] == "702")
        self.assertNotIn("latitude", onsite["location"])
        self.assertGreater(onsite["endsAt"][:10], onsite["startsAt"][:10])
        groups = self.request("/api/v1/study-groups/names")
        self.assertEqual(len(groups["studyGroups"][0]["name"]), 50)
        roster = self.request("/api/v2/schedules/attendance")
        self.assertEqual(len(roster[0]["participants"][0]["excuseReason"]), 300)
        self.assertEqual(roster[0]["participants"][0]["attendanceStatus"], "EXCUSED_PENDING")

    def test_permissions_and_search_empty_error_are_independent(self):
        self.arm("no-create")
        self.arm("no-track")
        caps = self.request("/api/v2/schedules/capabilities")
        self.assertFalse(caps["canCreateSchedule"])
        self.assertFalse(caps["canCreateAttendanceRequiredSchedule"])
        self.arm("empty-search")
        self.assertEqual(self.request("/api/v1/member/search", {"size": ["30"]})["page"]["content"], [])
        self.arm("fail-search")
        self.request("/api/v1/member/search", {"size": ["30"]}, status=503)

    def test_failed_write_never_commits_or_retries_on_read(self):
        self.arm("fail-write-once")
        self.request("/api/v2/schedules/701/attendances/decide", method="POST",
                     body=[{"participantMemberId": 101, "isApproved": True}], status=503)
        rows = self.request("/api/v2/schedules/attendance")
        self.assertEqual(rows[0]["participants"][0]["attendanceStatus"], "EXCUSED_PENDING")

    def test_private_state_does_not_change_base_or_second_server(self):
        self.server.activity_design._status["101", "701"] = "PRESENT"
        self.assertNotEqual(base._status.get(("101", "701")), "PRESENT")
        other = SimpleNamespace(control=self.server.control)
        design.prepare(other)
        self.assertEqual(other.activity_design._status["101", "701"], "EXCUSED_PENDING")

    def test_batch_permissions_are_reads_and_points_receipt_loss_is_not_repayment(self):
        self.arm("fail-write-once")
        self.arm("no-decide")
        result = self.request("/api/v1/authorization/resource-permissions/batch", method="POST",
                              body={"queries": [{"resourceType": "ATTENDANCE", "resourceIds": ["701"]}]})
        self.assertFalse(result["results"][0]["permissions"][0]["hasPermission"])
        self.assertTrue((self.server.control / "fail-write-once").exists())
        (self.server.control / "fail-write-once").unlink()
        self.arm("drop-point-receipt-once")
        self.request("/api/v1/challenger/101/points", method="POST", status=503,
                     body={"pointType": "CUSTOM", "pointValue": 1, "description": "합성 사유"})
        self.request("/api/v1/challenger/101", status=503)
        (self.server.control / "point-ledger-unavailable").unlink()
        ledger = self.request("/api/v1/challenger/101")
        self.assertEqual(len(ledger["points"]), 1)

    def test_logs_omit_identity_tokens_and_body(self):
        self.schedules()
        log = (self.server.control / "activity-requests.jsonl").read_text()
        self.assertNotIn("token", log)
        self.assertNotIn("second@example", log)
        self.assertNotIn("excuseReason", log)


if __name__ == "__main__":
    unittest.main()
