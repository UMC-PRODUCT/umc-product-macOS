#  test_notice_design_fixture.py
#  UMCDesk
#
#  Created by euijjang97 on 11/27/26.

"""Offline handler tests: no listener, app, Keychain, or external requests."""

import copy
import json
import tempfile
import unittest
from pathlib import Path
from types import SimpleNamespace
from urllib.parse import urlsplit

import notice_fixture
import notice_design_fixture as design


class NoticeDesignFixtureTests(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.TemporaryDirectory(prefix="notice-design-test-")
        self.addCleanup(self.folder.cleanup)
        self.server = SimpleNamespace(server_port=19799, control=Path(self.folder.name))
        design.prepare(self.server)

    def request(self, method="GET", suffix="", query=None, body=None, status=200):
        results = []
        handler = SimpleNamespace(server=self.server,
                                  send_result=lambda *args, **kwargs: results.append(args))
        handled = design.handle(handler, method, design.ROOT + suffix, query or {},
                                body, design.OWNER)
        self.assertTrue(handled)
        self.assertEqual(len(results), 1)
        self.assertEqual(results[0][0], status)
        return results[0][1] if len(results[0]) > 1 else None

    def listing(self, page=0, keyword="", status=200):
        return self.request(query={"gisuId": ["10"], "noticeTab": ["CHALLENGER"],
                                   "page": [str(page)], "keyword": [keyword]}, status=status)

    def arm(self, marker):
        (self.server.control / marker).touch()

    def test_rich_content_is_local_and_base_fixture_is_unchanged(self):
        entry = self.request(suffix="/21")
        self.assertGreaterEqual(len(entry["title"]), 60)
        self.assertGreater(len(entry["author"]["nickname"]), 30)
        self.assertEqual(len(entry["images"]), 2)
        for value in entry["images"] + entry["links"]:
            self.assertEqual(urlsplit(value["url"]).hostname, "127.0.0.1")
        self.assertTrue(entry["vote"])
        empty = self.request(suffix="/22")
        self.assertEqual(empty["images"], [])
        self.assertIsNone(empty["vote"])
        self.assertEqual(set(notice_fixture._initial_state()["entries"]), {"21", "22"})
        self.assertTrue((self.server.control / "blue.png").read_bytes().startswith(b"\x89PNG"))

    def test_late_pin_and_same_page_retry(self):
        self.arm("late-pin")
        first = self.listing()
        self.assertTrue(first["hasNext"])
        self.assertFalse(any(row["mustRead"] for row in first["content"]))
        self.arm("fail-notice-page-once")
        self.listing(page=1, status=503)
        second = self.listing(page=1)
        self.assertEqual([row["id"] for row in second["content"] if row["mustRead"]], ["21"])
        self.assertFalse(second["hasNext"])

    def test_request_log_observes_search_without_detail_requests_or_tokens(self):
        self.listing(keyword="한글 조합 제출")
        log = (self.server.control / "notice-requests.jsonl").read_text()
        records = [json.loads(line) for line in log.splitlines()]
        self.assertEqual(len(records), 1)
        self.assertEqual(records[0]["query"]["keyword"], ["한글 조합 제출"])
        self.assertEqual(records[0]["path"], design.ROOT)
        self.assertNotIn("token", log.lower())
        self.assertNotIn(design.OWNER, log)

    def test_individual_detail_and_read_failures_do_not_mutate_other_state(self):
        self.arm("deny-notice-detail-once")
        self.request(suffix="/21", status=403)
        self.assertEqual(self.request(suffix="/22")["id"], "22")
        self.arm("fail-notice-read-once")
        self.request("POST", "/21/read", status=503)
        self.assertNotIn(design.OWNER, self.server.notice_state["reads"].get("21", set()))
        self.request("POST", "/21/read")
        self.assertIn(design.OWNER, self.server.notice_state["reads"]["21"])

    def test_create_receipt_lost_but_publication_is_saved_once(self):
        before = len(self.server.notice_state["entries"])
        self.arm("drop-notice-create-once")
        body = {"title": "결과 확인 검수", "content": "본문",
                "targetInfo": {"targetGisuId": 10, "targetNoticeTab": "CHALLENGER"}}
        self.request("POST", body=body, status=503)
        self.assertEqual(len(self.server.notice_state["entries"]), before + 1)
        self.assertEqual(len(self.listing(keyword=body["title"])["content"]), 1)

    def test_images_saved_before_links_failure_then_replace_retry(self):
        self.request("PATCH", "/22/images", body={"imageIds": ["design-blue"]})
        self.arm("fail-notice-links-once")
        body = {"links": ["http://127.0.0.1:19799/qa/notice-design/link/retry"]}
        self.request("PATCH", "/22/links", body=body, status=503)
        entry = self.request(suffix="/22")
        self.assertEqual(len(entry["images"]), 1)
        self.assertEqual(entry["links"], [])
        self.request("PATCH", "/22/links", body=body)
        self.assertEqual(len(self.request(suffix="/22")["links"]), 1)

    def test_poll_receipt_check_is_blocked_until_explicit_release(self):
        self.arm("drop-notice-poll-once")
        poll = copy.deepcopy(self.server.notice_state["entries"]["21"]["vote"])
        poll["options"] = ["첫째", "둘째"]
        self.request("POST", "/22/votes", body=poll, status=503)
        self.request(suffix="/22", status=503)
        (self.server.control / "block-poll-receipt-read").unlink()
        self.assertIsNotNone(self.request(suffix="/22")["vote"])

    def test_vote_failure_is_separate_from_read_confirmation(self):
        self.arm("fail-notice-vote-once")
        self.request("POST", "/21/votes/responses", body={"optionIds": ["1"]}, status=503)
        self.assertEqual(self.server.notice_state["ballots"], {})
        self.request("POST", "/21/votes/responses", body={"optionIds": ["1"]})
        self.assertEqual(self.server.notice_state["reads"]["21"], set())

    def test_delete_failure_preserves_article_until_explicit_retry(self):
        self.arm("fail-notice-delete-once")
        self.request("DELETE", "/21", status=503)
        self.assertEqual(self.request(suffix="/21")["id"], "21")
        self.request("DELETE", "/21")
        self.assertNotIn("21", self.server.notice_state["entries"])
        self.assertIn("22", self.server.notice_state["entries"])


if __name__ == "__main__":
    unittest.main()
