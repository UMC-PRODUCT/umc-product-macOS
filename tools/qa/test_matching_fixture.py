#  test_matching_fixture.py
#  UMCDesk
#
#  Created by euijjang97 on 11/23/26.

"""Run with python3 -m unittest discover -s tools/qa -p test_matching_fixture.py.

일반 앱 QA (새 session_fixture 프로세스, ops@example.test / fixture-only, 2지부).

1. 전체 일정에서 디자인 1차 이름을 바꿔 일괄 저장 → 재진입 → 삭제 → 재등록한다.
   개발 일정은 시작되어 잠겼다. 개발 1차(951) 자동 선발 후 실행 완료 표시를 확인한다.
2. 내 프로젝트 → 운영 검증 프로젝트(820)의 공고를 편집·저장하고 다시 연다.
   지원자 심사에서 1차는 마감 안내, 2차(971)는 불합격 → 합격 및 재진입 결과를 확인한다.
3. 팀 구성에서 1차 합류자 105를 확인한다. 108을 PLAN 보조 PM으로 추가하고 상태 변경한다.
   매칭 현황 → 조정에서 디자인 109는 기간 거절, 웹 프로덕트 엔지니어 107은 배정된다.
   공개 명단 재조회 → 조정에서 107 해제 → 공개 명단 재조회로 확인한다.
4. 820의 지원 폼에서 공통 질문 섹션을 삭제한다. PROJECT-0026 확인창을 취소하면 답변이
   남는다. 다시 삭제하고 동의하면 지원자 상세에서도 답변이 사라진다. 파트별 선택 문항을
   만들어 옵션과 노출 파트가 재진입 시 유지되는지 확인한다.
5. 운영 초안(821)은 검토 요청 시 공개된다. 운영 승인 대기(822)는 공개 후 완료한다.
   820은 마지막에 사유를 입력해 중단한 뒤 삭제하고 관리 목록에서 사라지는지 확인한다.
6. fixture 기동 시 출력된 control 디렉터리에 fail-matching-managed-once 파일을 만든 뒤
   내 프로젝트를 열면 503이 한 번 발생한다. 다시 시도를 누르면 기존 관리 목록이 열린다.

104는 PLAN 운영자다. 신규 합류와 해제는 팀·공개 명단에서 검증한다. 파일 선택·업로드,
실제 스케줄러와 예약 발표, 랜덤 배정 및 비공개 조정에서 최종 공개로 넘어가는 작업은
이 시나리오의 지원 범위 밖이다. 정원 편집은 이미 첫 매칭이 시작된 지부에서 제한된다.
"""

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


class OperatorHTTPTests(unittest.TestCase):
    """Normal login and wire routes on a fresh loopback port per test."""

    def setUp(self):
        import subprocess
        import sys
        from pathlib import Path

        script = Path(__file__).with_name("session_fixture.py")
        self.process = subprocess.Popen([sys.executable, str(script), "--port", "0"],
                                        stdout=subprocess.PIPE, text=True)
        self.addCleanup(self.stop_server)
        ready = self.process.stdout.readline()
        endpoint, directory = ready.strip().split("; control=")
        self.port = int(endpoint.rsplit(":", 1)[1])
        self.control = Path(directory)
        self.headers = {}
        self.login("ops")

    def stop_server(self):
        self.process.terminate()
        self.process.wait(timeout=5)
        self.process.stdout.close()

    def send(self, method, path, body=None, status=200):
        import json
        from http.client import HTTPConnection

        client = HTTPConnection("127.0.0.1", self.port, timeout=3)
        try:
            client.request(method, path, json.dumps(body) if body is not None else None,
                           {**self.headers, "Content-Type": "application/json"})
            response = client.getresponse()
            envelope = json.loads(response.read())
            self.assertEqual(response.status, status, (method, path, envelope))
            self.assertEqual(envelope["success"], status == 200)
            self.error_code = envelope.get("code")
            return envelope["result"]
        finally:
            client.close()

    def login(self, account):
        session = self.send("POST", "/api/v1/auth/login/email",
                            {"email": account + "@example.test", "password": "fixture-only"})
        self.headers = {"Authorization": "Bearer " + session["accessToken"]}

    def test_schedule_edits_deletion_recreation_and_lock(self):
        self.assertTrue(self.send("GET", "/api/v2/member/me")["isSuperAdmin"])
        endpoint = ROUNDS + "/chapters/2"
        get = ROUNDS + "?chapterId=2&type=PLAN_DESIGN"
        before = self.send("GET", get)
        self.assertEqual(len(before), 4)
        keys = ("phase", "startsAt", "endsAt", "decisionDeadline", "resultPublishAt", "name")
        rows = [{k: r[k] for k in keys} for r in before]
        rows[-1].pop("decisionDeadline")
        invalid = {"type": "PLAN_DESIGN", "rounds": rows[:3]}
        self.send("PUT", endpoint, invalid, 400)
        self.assertEqual(before, self.send("GET", get))
        rows[0]["name"] = "수정한 운영 일정"
        body = {"type": "PLAN_DESIGN", "rounds": rows}
        self.send("PUT", endpoint, body)
        self.assertEqual(self.send("GET", get)[0]["name"], rows[0]["name"])
        self.send("DELETE", endpoint + "?type=PLAN_DESIGN")
        self.assertEqual(self.send("GET", get), [])
        self.send("PUT", endpoint, body)
        self.assertEqual(len(self.send("GET", get)), 4)
        self.send("DELETE", endpoint + "?type=PLAN_DEVELOPER", status=400)
        self.login("design")
        self.send("PUT", endpoint, body, 403)

    def test_review_join_assignment_and_publication(self):
        project = ROOT + "/820"
        reviews = project + "/applications"
        rows = self.send("GET", reviews)
        self.assertEqual(len(rows), 2)
        self.send("PATCH", reviews + "/970/decision", {"status": "REJECTED"}, 400)
        for status in ("APPROVED", "REJECTED", "SUBMITTED"):
            self.send("PATCH", reviews + "/971/decision", {"status": status})
            self.assertEqual(self.send("GET", reviews + "/971")["status"], status)
        self.send("POST", ROUNDS + "/952/auto-decide", status=400)
        self.send("POST", ROUNDS + "/951/auto-decide")
        self.send("POST", ROUNDS + "/951/auto-decide")
        rounds = self.send("GET", ROUNDS + "?chapterId=2")
        self.assertEqual(next(r for r in rounds if r["id"] == "951")["autoDecisionExecutedMemberId"], "104")
        team = self.send("GET", project + "/members")
        self.assertEqual(team["partGroups"][0]["members"][0]["memberId"], "105")

        admin = ROOT + "/admin/820/members"
        part = "WEB_PRODUCT_ENGINEER"
        candidates = self.send("GET", admin + "/candidates?part=" + part)
        self.assertIn("107", [c["memberId"] for c in candidates["content"]])
        self.send("POST", admin, {"memberId": 109, "part": "DESIGN"}, 409)
        self.send("POST", admin, {"memberId": 107, "part": part})
        self.send("POST", admin, {"memberId": 107, "part": part}, 409)
        for view in ("ADJUSTMENT", "PUBLISHED"):
            rows = self.send("GET", ROOT + "/statistics/matching-overview?chapterId=2&view=" + view)
            p = next(p for p in rows["projects"] if p["projectId"] == "820")
            self.assertEqual(p["currentMemberCount"], "2")
        public = ROOT + "/members?projectIds=820"
        self.login("first")
        public_team = self.send("GET", public)["820"]
        self.assertEqual([p["memberId"] for p in public_team["partGroups"][0]["members"]], ["105", "107"])
        self.send("GET", ROOT + "/statistics/matching-overview?chapterId=2&view=ADJUSTMENT", status=403)
        self.send("DELETE", admin + "/107", status=403)
        self.login("ops")
        self.send("DELETE", admin + "/107")
        self.assertEqual(len(self.send("GET", public)["820"]["partGroups"][0]["members"]), 1)
        self.send("POST", project + "/members", {"memberId": 108, "part": "PLAN"})
        self.assertEqual(self.send("GET", project + "/members")["coProductOwners"][0]["memberId"], "108")
        self.send("PATCH", project + "/members/108/status", {"status": "WITHDRAWN", "reason": "검증"})
        self.assertEqual(self.send("GET", project + "/members")["coProductOwners"], [])

    def test_form_answer_conflict_and_state_transitions(self):
        project = ROOT + "/820"
        self.send("PATCH", project, {"name": "수정한 공고"})
        self.assertEqual(self.send("GET", project)["name"], "수정한 공고")
        form = project + "/application-form"
        original = self.send("GET", form)
        new_form = {"title": "파트별 폼", "sections": [
            {"type": "PART", "title": "개발", "allowedParts": ["WEB_PRODUCT_ENGINEER"], "orderNo": 0,
             "questions": [{"type": "RADIO", "title": "역할", "isRequired": True, "orderNo": 0,
                            "options": [{"content": "개발", "orderNo": 0, "isOther": False}]}]}]}
        self.send("PUT", form, new_form, 409)
        self.assertEqual(self.error_code, "PROJECT-0026")
        self.assertEqual(self.send("GET", form), original)
        self.send("PUT", form, dict(new_form, confirmDeleteAnsweredSections=True))
        self.assertTrue(self.send("GET", form)["sections"][0]["questions"][0]["options"][0]["optionId"])
        review = self.send("GET", project + "/applications/971")
        self.assertIsNone(review["formResponse"]["sections"][0]["questions"][0]["answer"])

        managed = ROOT + "/me/managed?gisuId=10"
        (self.control / "fail-matching-managed-once").touch()
        self.send("GET", managed, status=503)
        self.assertIn("820", [r["id"] for r in self.send("GET", managed)["content"]])
        self.send("POST", ROOT + "/complete", {"projectIds": [820, 822]}, 409)
        self.assertEqual(self.send("GET", project)["status"], "IN_PROGRESS")
        self.send("POST", ROOT + "/822/publish")
        self.send("POST", ROOT + "/821/submit")
        self.send("POST", ROOT + "/complete", {"projectIds": [821, 822]})
        self.assertEqual(self.send("GET", ROOT + "/821")["status"], "COMPLETED")
        self.send("POST", project + "/abort", {"reason": "검증 종료"})
        self.assertEqual(self.send("GET", project)["status"], "ABORTED")
        self.assertEqual(self.send("GET", project + "/applications/971")["status"], "CANCELLED")
        self.send("DELETE", project)
        self.send("GET", project, status=404)
        self.assertNotIn("820", [r["id"] for r in self.send("GET", managed)["content"]])


if __name__ == "__main__":
    unittest.main()
