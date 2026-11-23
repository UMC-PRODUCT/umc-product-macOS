#  test_matching_fixture.py
#  UMCDesk
#
#  Created by euijjang97 on 11/23/26.

"""Run with python3 -m unittest discover -s tools/qa -p test_matching_fixture.py."""

from concurrent.futures import ThreadPoolExecutor
from types import SimpleNamespace
import unittest

from matching_fixture import ROOT, ROUNDS, handle


class MatchingFixtureTests(unittest.TestCase):
    def setUp(self):
        self.server = SimpleNamespace()

    def request(self, method, path, member="101", body=None, query=None, status=200):
        captured = []
        handler = SimpleNamespace(server=self.server,
                                  send_result=lambda *result: captured.append(result))
        handled = handle(handler, method, ROOT + path, query or {}, body, member)
        self.assertTrue(handled)
        self.assertEqual(len(captured), 1)
        self.assertEqual(captured[0][0], status, captured)
        return captured[0][1]

    def create(self, member, round_id, status=200):
        return self.request("POST", "/1/applications", member, {"matchingRoundId": round_id},
                            status=status)

    def cards(self, member, status=None):
        query = {"gisuId": ["10"]}
        if status:
            query["status"] = [status]
        return self.request("GET", "/me/applications", member, query=query)

    def test_eligible_rounds_and_other_chapters(self):
        for member, eligible in (("101", 501), ("103", 502)):
            for rejected in {501, 502, 503, 504} - {eligible}:
                self.create(member, rejected, 400)
            self.create(member, 999, 404)
            self.create(member, eligible)
            self.create(member, eligible, 409)
        for round_id in (501, 502, 503, 504):
            self.create("102", round_id, 403)

    def test_save_submit_edit_cancel_and_reapply(self):
        key = self.create("101", 501)["applicationId"]
        path = "/1/applications/" + key
        form = self.request("GET", "/1/application-form")
        question = form["sections"][0]["questions"][0]
        self.assertTrue(question["isRequired"])
        field = {"questionId": int(question["questionId"]), "textValue": "첫 답변",
                 "fileIds": [], "selectedOptionIds": []}

        self.assertEqual(self.cards("101", "DRAFT")[0]["applicationId"], key)
        self.assertIsNone(self.cards("101")[0]["applicationId"])
        self.request("PUT", path, body={"answers": []})
        self.request("POST", path + "/submit", status=400)
        self.request("PUT", path, body={"answers": [field]})
        self.request("PUT", path, body={"answers": [dict(field, questionId=42)]}, status=400)
        submitted = self.request("POST", path + "/submit")
        self.assertEqual(submitted["status"], "SUBMITTED")
        detail = self.request("GET", path)
        self.assertIsNone(detail["status"])
        question = detail["formResponse"]["sections"][0]["questions"][0]
        self.assertEqual(question["answer"]["textValue"], "첫 답변")
        self.assertEqual(self.cards("101", "DRAFT"), [])
        cards = self.cards("101")
        self.assertEqual([card["applicationId"] for card in cards], [key, None])
        self.assertIsNone(cards[0]["status"])
        self.request("PUT", path, body={"answers": []}, status=400)
        self.request("PUT", path, body={"answers": [dict(field, textValue="수정")]})
        self.assertEqual(self.request("GET", path)["submittedAt"], detail["submittedAt"])
        self.request("POST", path + "/submit", status=404)
        self.assertEqual(self.request("DELETE", path)["status"], "CANCELLED")
        cancelled = self.request("GET", path)
        self.assertEqual(cancelled["formResponse"]["sections"][0]["questions"][0]
                         ["answer"]["textValue"], "수정")
        self.assertEqual(self.cards("101")[0]["status"], "CANCELLED")
        self.request("PUT", path, body={"answers": [field]}, status=404)
        self.request("DELETE", path, status=400)
        self.assertNotEqual(self.create("101", 501)["applicationId"], key)

    def test_member_and_server_isolation(self):
        key = self.create("103", 502)["applicationId"]
        path = "/1/applications/" + key
        for method, suffix in (("GET", ""), ("PUT", ""), ("DELETE", ""), ("POST", "/submit")):
            self.request(method, path + suffix, status=403)
        self.assertEqual(self.cards("101", "DRAFT"), [])
        self.assertEqual(self.cards("103", "DRAFT")[0]["matchingRound"]["id"], "502")
        self.server = SimpleNamespace()
        self.request("GET", path, "103", status=404)
        self.assertEqual(self.cards("103", "DRAFT"), [])

    def test_concurrent_creation_creates_one_draft(self):
        def request(_):
            result = []
            handler = SimpleNamespace(server=self.server, send_result=lambda s, r: result.append(s))
            handle(handler, "POST", ROOT + "/1/applications", {}, {"matchingRoundId": 501}, "101")
            return result[0]

        with ThreadPoolExecutor(max_workers=8) as pool:
            statuses = list(pool.map(request, range(12)))
        self.assertCountEqual(statuses, [200] + [409] * 11)
        self.assertEqual(len(self.cards("101", "DRAFT")), 1)

    def test_plan_private_project_and_form(self):
        body = {"gisuId": 10}
        self.request("POST", "", body=body, status=403)
        self.request("POST", "", "102", dict(body, productOwnerMemberId=101), status=403)
        key = self.request("POST", "", "102", body)["projectId"]
        for endpoint in ("/me/drafts", "/me/managed"):
            query = {"gisuId": ["10"]}
            self.assertEqual(self.request("GET", endpoint, query=query)["content"], [])
            rows = self.request("GET", endpoint, "102", query=query)["content"]
            self.assertEqual([r["id"] for r in rows], [key])
        path = "/" + key
        self.request("GET", path, status=403)
        query = {"ids": [key]}
        perms = self.request("GET", "/permissions", "102", query=query)["projects"][0]
        self.assertTrue(perms["applicationForm"]["canCreate"]["allowed"])
        form = {"title": "운영 폼", "sections": [
            {"type": "COMMON", "title": "공통", "orderNo": 0, "questions": [
                {"type": "LONG_TEXT", "title": "소개", "orderNo": 0,
                 "isRequired": True, "options": []}]}]}
        path += "/application-form"
        self.request("PUT", path, body=form, status=403)
        saved = self.request("PUT", path, "102", form)
        self.assertEqual(self.request("GET", path, "102"), saved)
        unsupported = {"sections": [dict(form["sections"][0], type="PART")]}
        self.request("PUT", path, "102", unsupported, status=501)
        self.assertEqual(self.request("GET", path, "102"), saved)
        section = saved["sections"][0]
        question = section["questions"][0]
        form["sections"][0]["sectionId"] = int(section["sectionId"])
        form["sections"][0]["questions"][0].update(questionId=int(question["questionId"]),
                                                 title="변경")
        updated = self.request("PUT", path, "102", form)["sections"][0]["questions"][0]
        self.assertEqual(updated["title"], "변경")
        self.assertEqual(updated["questionId"], question["questionId"])

    def test_operations_reader_and_protected_paths(self):
        chapter = {"chapterId": ["1"]}
        for member, can_create in (("101", True), ("102", False), ("103", True)):
            row = self.request("GET", "/permissions", member, query={"ids": ["1"]})["projects"][0]
            self.assertEqual(row["application"]["canCreate"]["allowed"], can_create)
        overview = self.request("GET", "/statistics/matching-overview", query=chapter)
        self.assertEqual(overview["projects"][0]["projectId"], "1")
        stats = self.request("GET", "/statistics/matchings", query=chapter)
        self.assertEqual(stats["roundMatchingStatistics"][0]["phase"], "FIRST")
        self.request("GET", "/statistics/matching-overview",
                     query=dict(chapter, view=["ADJUSTMENT"]), status=403)
        self.assertEqual(self.request("GET", "/1/applications"), [])
        self.assertIn("partGroups", self.request("GET", "/1/members"))
        for method, path in (("GET", "/admin/pm-candidates"), ("GET", "/statistics/applications"),
                             ("PATCH", "/1/applications/701/decision"), ("POST", "/1/publish"),
                             ("POST", "/admin/1/members")):
            self.request(method, path, status=403)
        calls = []
        handler = SimpleNamespace(server=self.server, send_result=lambda s, r: calls.append(s))
        self.assertTrue(handle(handler, "PUT", ROUNDS + "/chapters/1", {}, {}, "102"))
        self.assertEqual(calls, [403])
        self.assertFalse(handle(handler, "GET", "/api/v1/member/me", {}, {}, "101"))


if __name__ == "__main__":
    unittest.main()
