#  matching_fixture.py
#  UMCDesk
#
#  Created by euijjang97 on 11/23/26.

"""Synthetic matching routes for the authenticated loopback session fixture."""

import re
from copy import deepcopy
from datetime import datetime, timedelta, timezone
from threading import Lock

from project_workspace_fixture import application_cards, published_teams

ROOT = "/api/v1/projects"
ROUNDS = "/api/v1/project/matching-rounds"
PARTS = {"101": "WEB", "102": "PLAN", "103": "DESIGN"}
ELIGIBLE = {"101": 501, "103": 502}
ROUND_TYPES = {501: "PLAN_DEVELOPER", 502: "PLAN_DESIGN",
               503: "PLAN_DEVELOPER", 504: "PLAN_DESIGN"}
_INIT_LOCK = Lock()


class State:
    def __init__(self):
        self.lock = Lock()
        self.applications = {}
        self.next_id = 701
        self.next_project = 801
        self.next_form_item = 2001
        self.drafts = {}
        self.forms = {}
        self.operations = OperationsScenario(self)

    def allocate_project(self):
        while self.next_project in (820, 821, 822):
            self.next_project += 1
        identifier = str(self.next_project)
        self.next_project += 1
        return identifier


def _now():
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds").replace("+00:00", "Z")


def _sections(application=None):
    question = {"questionId": "611", "type": "SHORT_TEXT", "title": "지원 동기",
                "description": None, "isRequired": True, "orderNo": "0", "options": []}
    if application is not None:
        value = application["text"]
        question["answer"] = None if value is None else {
            "answerId": application["id"], "answeredAsType": "SHORT_TEXT", "textValue": value,
            "selectedOptions": [], "files": [], "times": []}
    return [{"sectionId": "610", "type": "COMMON", "allowedParts": [], "title": "공통 질문",
             "description": None, "orderNo": "0", "questions": [question]}]


def _round(application):
    return {"id": str(application["round"]), "type": ROUND_TYPES[application["round"]],
            "phase": "FIRST"}


def _visible_status(application):
    # The result publication date is still in the future for both seeded rounds.
    return None if application["status"] == "SUBMITTED" else application["status"]


def _detail(application):
    member = application["member"]
    return {"applicationId": application["id"], "matchingRound": _round(application),
            "applicant": {"memberId": member, "part": PARTS[member], "name": "검증 " + member,
                          "nickname": "챌린저 " + member, "schoolName": "테스트 대학교"},
            "status": _visible_status(application), "submittedAt": application["submitted"],
            "statusChangedAt": application["changed"],
            "formResponse": {"formId": "600", "formResponseId": application["id"],
                             "submittedAt": application["submitted"],
                             "status": "SUBMITTED" if application["submitted"] else "DRAFT",
                             "lastSavedAt": application["saved"], "sections": _sections(application)}}


def _status(application):
    return 200, {"applicationId": application["id"], "status": application["status"]}


def _create(state, member, body):
    if member not in ELIGIBLE:
        return 403, None
    round_id = body.get("matchingRoundId")
    if type(round_id) is not int:
        return 400, None
    if round_id not in ROUND_TYPES:
        return 404, None
    if round_id != ELIGIBLE[member]:
        return 400, None
    if any(app["member"] == member and app["status"] != "CANCELLED"
           for app in state.applications.values()):
        return 409, None
    key = str(state.next_id)
    state.next_id += 1
    app = {"id": key, "member": member, "round": round_id, "status": "DRAFT",
           "text": None, "submitted": None, "changed": _now(), "saved": None}
    state.applications[key] = app
    return _status(app)


def _save(application, body):
    answers = body.get("answers")
    if not isinstance(answers, list) or len(answers) > 1:
        return 400, None
    value = None
    if answers:
        answer = answers[0]
        if not isinstance(answer, dict) or answer.get("questionId") != 611:
            return 400, None
        value = answer.get("textValue")
        if value is not None and not isinstance(value, str):
            return 400, None
        if answer.get("selectedOptionIds") not in (None, []) or answer.get("fileIds") not in (None, []):
            return 400, None
    if application["status"] == "SUBMITTED" and not (value or "").strip():
        return 400, None
    application.update(text=value, saved=_now())
    return _status(application)


def _cards(state, member, query):
    if query.get("gisuId") != ["10"]:
        return []
    wanted = query.get("status", [None])[0]
    cards = []
    for app in reversed(state.applications.values()):
        if app["member"] != member:
            continue
        status = _visible_status(app)
        if (wanted and status != wanted) or (not wanted and status == "DRAFT"):
            continue
        cards.append({"applicationId": app["id"], "projectId": "1",
                      "project": {"name": "모아", "partQuotas": []},
                      "matchingRound": _round(app), "status": status})
    return cards + application_cards(member, query)


def _dispatch(state, method, path, query, body, member):
    result = state.operations.dispatch(method, path, query, body, member)
    if result is not None:
        return result
    if path == ROOT + "/me/applications" and method == "GET":
        return 200, _cards(state, member, query)
    if path == ROOT + "/1/application-form" and method == "GET":
        return 200, {"projectId": "1", "applicationFormId": "600", "title": "모아 지원서",
                     "description": "프로젝트 지원 동기를 작성해 주세요.", "sections": _sections()}
    match = re.fullmatch(ROOT + r"/(\d+)/applications(?:/(\d+)(/submit)?)?", path)
    if not match:
        return _operations(state, method, path, query, body, member)
    project, identifier, action = match.groups()
    if project != "1":
        if project in state.drafts and identifier is None:
            return _operations(state, method, path, query, body, member)
        return 404, None
    if identifier is None:
        if method == "POST":
            return _create(state, member, body)
        return _operations(state, method, path, query, body, member)
    app = state.applications.get(identifier)
    if app is None:
        return 404, None
    if app["member"] != member:
        return 403, None
    if method == "GET" and not action:
        return 200, _detail(app)
    if app["status"] == "CANCELLED":
        return (400, None) if method == "DELETE" else (404, None)
    if method == "PUT" and not action:
        return _save(app, body)
    if method == "POST" and action == "/submit":
        if app["status"] != "DRAFT":
            return 404, None
        if not (app["text"] or "").strip():
            return 400, None
        now = _now()
        app.update(status="SUBMITTED", submitted=now, changed=now)
        return _status(app)
    if method == "DELETE" and not action:
        app.update(status="CANCELLED", changed=_now())
        return _status(app)
    return 405, None


def _page(rows, query):
    try:
        page = int(query.get("page", ["0"])[0])
        size = int(query.get("size", ["20"])[0])
    except (ValueError, IndexError):
        return 400, None
    if page < 0 or size < 1:
        return 400, None
    start = page * size
    return 200, {"content": rows[start:start + size], "page": str(page), "size": str(size),
                 "totalElements": str(len(rows)), "totalPages": str((len(rows) + size - 1) // size),
                 "hasPrevious": page > 0, "hasNext": start + size < len(rows)}


def _permission(project, member, state):
    draft = state.drafts.get(project)
    public = project == "1"
    own = draft is not None and draft["productOwner"]["memberId"] == member

    def flag(allowed):
        return {"allowed": allowed}

    return {"projectId": project, "exists": public or own,
            "canEditInfo": flag(False), "canDelete": flag(False),
            "application": {"canCreate": flag(public and member in ELIGIBLE),
                            "canReadList": flag(own), "canDecide": flag(False)},
            "applicationForm": {"canRead": flag(public or (own and project in state.forms)),
                                "canCreate": flag(own and project not in state.forms),
                                "canEdit": flag(own and project in state.forms)},
            "member": {"canRead": flag(public or own)}}


def _save_form(state, draft, body, *, extended=False):
    # Keep the original PLAN fixture limited to common free text; operations QA covers the editor.
    form = deepcopy(body)
    sections = form.get("sections")
    if not isinstance(sections, list):
        return 400, None
    project = draft["id"]
    prior = state.forms.get(project, {}).get("sections", [])
    next_id = state.next_form_item
    used = set()

    def assign(row, key, old):
        nonlocal next_id
        identifier = row.get(key)
        if identifier is None:
            identifier = next_id
            next_id += 1
        elif type(identifier) is not int or str(identifier) not in old:
            return False
        if identifier in used:
            return False
        used.add(identifier)
        row[key] = str(identifier)
        return True

    def valid_item(row):
        return (isinstance(row, dict) and isinstance(row.get("title"), str)
                and bool(row["title"].strip()) and type(row.get("orderNo")) is int
                and row["orderNo"] >= 0)

    old_sections = {s["sectionId"]: s for s in prior}
    for section in sections:
        if not valid_item(section) or not isinstance(section.get("questions"), list):
            return 400, None
        if section.get("type") != "COMMON":
            if not extended:
                return 501, None
            parts = section.get("allowedParts")
            if section.get("type") != "PART" or not isinstance(parts, list) or not parts or any(
                part not in ("PLAN", "DESIGN", "WEB_PRODUCT_ENGINEER", "MOBILE_PRODUCT_ENGINEER")
                for part in parts
            ):
                return 400, None
        if not assign(section, "sectionId", old_sections):
            return 400, None
        old_section = old_sections.get(section["sectionId"], {})
        old_questions = {q["questionId"]: q for q in old_section.get("questions", [])}
        for question in section["questions"]:
            if not valid_item(question) or not isinstance(question.get("isRequired"), bool):
                return 400, None
            kind = question.get("type")
            if kind not in ("SHORT_TEXT", "LONG_TEXT"):
                if not extended:
                    return 501, None
                if kind not in ("RADIO", "DROPDOWN", "CHECKBOX", "PORTFOLIO", "FILE", "SCHEDULE"):
                    return 400, None
            options = question.get("options")
            if not isinstance(options, list) or bool(options) != (kind in ("RADIO", "DROPDOWN", "CHECKBOX")):
                return 400, None
            if not assign(question, "questionId", old_questions):
                return 400, None
            prior_question = old_questions.get(question["questionId"], {})
            prior_options = {o["optionId"] for o in prior_question.get("options", [])}
            for option in options:
                if (not isinstance(option, dict) or not isinstance(option.get("content"), str)
                        or not option["content"].strip() or type(option.get("orderNo")) is not int
                        or option["orderNo"] < 0 or type(option.get("isOther")) is not bool
                        or not assign(option, "optionId", prior_options)):
                    return 400, None
    title = form.get("title")
    description = form.get("description")
    if title is not None and (not isinstance(title, str) or len(title) > 200):
        return 400, None
    if description is not None and (not isinstance(description, str) or len(description) > 500):
        return 400, None
    state.next_form_item = next_id
    form_id = str(10000 + int(project))
    result = {"projectId": project, "applicationFormId": form_id, "description": description,
              "title": title or "프로젝트 지원서", "sections": sections}
    state.forms[project] = result
    draft["applicationFormId"] = form_id
    return 200, result


def _public_stats(path, query):
    chapter = query.get("chapterId", [None])[0]
    if chapter not in ("1", "2"):
        return 400, None
    if path.endswith("/matching-overview"):
        if query.get("view", ["PUBLISHED"]) != ["PUBLISHED"]:
            return 403, None
        public = published_teams({"projectIds": ["1"]})["1"]
        parts = [{"part": group["part"], "members": group["members"],
                  "currentMemberCount": str(len(group["members"])), "quota": "2",
                  "status": "RECRUITING"} for group in public["partGroups"]]
        parts.append({"part": "DESIGN", "members": [], "currentMemberCount": "0",
                      "quota": "1", "status": "RECRUITING"})
        row = {"projectId": "1", "projectName": "모아", "currentMemberCount": "1",
               "quota": "3", "partQuotaStatus": "RECRUITING", "parts": parts,
               "productOwner": public["productOwner"], "coProductOwners": []}
        return 200, {"projects": [row] if chapter == "1" else []}
    count = {"phase": "FIRST", "matchedMemberCount": "0"}
    project = {"projectId": "1", "projectName": "모아", "matchedMemberCount": "0",
               "quota": "2", "rounds": [count], "parts": [{"part": "WEB", "quota": "2",
                                                          "matchedMemberCount": "0"}]}
    return 200, {"chapterId": chapter, "schoolMatchingStatistics": [],
                 "roundMatchingStatistics": [dict(count, availableMemberCount="1")]
                 if chapter == "1" else [],
                 "projectMatchingStatistics": [project] if chapter == "1" else []}


def _operations(state, method, path, query, body, member):
    if path == ROOT + "/permissions" and method == "GET":
        ids = [key for value in query.get("ids", []) for key in value.split(",")]
        if not ids or any(not key.isdecimal() for key in ids):
            return 400, None
        return 200, {"projects": [_permission(key, member, state) for key in dict.fromkeys(ids)]}
    if path == ROOT and method == "POST":
        if member != "102" or body.get("productOwnerMemberId") not in (None, 102):
            return 403, None
        if body.get("gisuId") != 10:
            return 400, None
        project = state.allocate_project()
        state.drafts[project] = {"id": project, "status": "DRAFT", "name": None,
                                 "productOwner": {"memberId": member, "name": "둘째 챌린저"},
                                 "partQuotas": [], "applicationFormId": None}
        return 200, {"projectId": project, "status": "DRAFT"}
    if method == "GET" and path in (ROOT + "/me/drafts", ROOT + "/me/managed"):
        keyword = query.get("keyword", [""])[0]
        rows = [draft for draft in reversed(state.drafts.values())
                if draft["productOwner"]["memberId"] == member and query.get("gisuId") == ["10"]
                and query.get("chapterId", ["1"]) == ["1"] and keyword in (draft["name"] or "")]
        return _page(rows, query)
    if method == "GET" and path in (ROOT + "/statistics/matchings",
                                    ROOT + "/statistics/matching-overview"):
        return _public_stats(path, query)
    if path == ROOT + "/members" and method == "GET":
        return 200, published_teams(query)
    if path == ROOT + "/1/members" and method == "GET":
        return 200, published_teams({"projectIds": ["1"]})["1"]
    if path.startswith(ROOT + "/admin/") or path.startswith(ROUNDS + "/"):
        return 403, None
    if path in (ROOT + "/complete", ROOT + "/statistics/applications"):
        return 403, None
    route = re.fullmatch(ROOT + r"/(\d+)(/.*)?", path)
    if route is None:
        return None
    project, suffix = route.groups()
    draft = state.drafts.get(project)
    if draft:
        if draft["productOwner"]["memberId"] != member:
            return 403, None
        if method == "GET":
            if not suffix:
                return 200, dict(draft)
            if suffix == "/application-form":
                return 200, state.forms.get(project)
            if suffix == "/applications":
                return 200, []
            if suffix == "/members":
                return 200, {"projectId": project, "productOwner": draft["productOwner"],
                             "coProductOwners": [], "partGroups": []}
        if method == "PUT" and suffix == "/application-form":
            return _save_form(state, draft, body)
        if suffix in (None, "/submit", "/part-quotas"):
            return 403, None  # Active round, incomplete draft or restricted quotas.
        return 501, None
    if project == "1" and method == "GET" and suffix == "/applications":
        return (400, None) if query.get("status") == ["DRAFT"] else (200, [])
    if project == "1" and method != "GET":
        return 403, None
    return None


OPS_MEMBER = "104"
OPS_CHAPTER = "2"
PHASES = ("FIRST", "SECOND", "THIRD", "RANDOM_MATCHING")
KINDS = ("PLAN_DEVELOPER", "PLAN_DESIGN")
OPS_PEOPLE = {
    "104": ("운영 챌린저", "PLAN"), "105": ("이전 차수 합류자", "WEB_PRODUCT_ENGINEER"),
    "106": ("심사 대기자", "WEB_PRODUCT_ENGINEER"), "107": ("수동 배정 후보", "WEB_PRODUCT_ENGINEER"),
    "108": ("보조 PM 후보", "PLAN"), "109": ("디자인 후보", "DESIGN"),
}


def _person(identifier):
    name, part = OPS_PEOPLE[identifier]
    return {"memberId": identifier, "nickname": name, "name": name, "part": part,
            "challengerId": identifier, "schoolId": "2", "schoolName": "운영 검증 대학교"}


def _instant(value):
    if not isinstance(value, str):
        raise ValueError("timestamp required")
    date = datetime.fromisoformat(value.replace("Z", "+00:00"))
    if date.tzinfo is None:
        raise ValueError("offset required")
    return date


def _stamp(date):
    return date.astimezone(timezone.utc).isoformat().replace("+00:00", "Z")


def _seed_rounds(now):
    rows = {}
    for kind_index, kind in enumerate(KINDS):
        for index, phase in enumerate(PHASES):
            days = (index * 8 - 10) if kind_index == 0 else (index * 8 + 30)
            start = now + timedelta(days=days)
            end = start + timedelta(days=1)
            deadline = end if phase == "RANDOM_MATCHING" else end + timedelta(days=3)
            identifier = str(951 + kind_index * 4 + index)
            rows[identifier] = {
                "id": identifier, "type": kind, "phase": phase, "chapterId": OPS_CHAPTER,
                "name": ("개발 " if kind_index == 0 else "디자인 ") + ("랜덤" if index == 3 else str(index+1)+"차"),
                "description": "운영 검증 일정", "startsAt": _stamp(start), "endsAt": _stamp(end),
                "decisionDeadline": _stamp(deadline),
                # Legacy first round publishes immediately upon automatic selection.
                "resultPublishAt": None if identifier == "951" else _stamp(deadline + timedelta(hours=1)),
                "autoDecisionExecutedAt": None, "autoDecisionExecutedMemberId": None}
    return rows


class OperationsScenario:
    """Chapter 2 fixtures, separate from the existing applicant accounts and project 1."""

    def __init__(self, state):
        self.state = state
        self.rounds = _seed_rounds(datetime.now(timezone.utc))
        self.next_round = 960
        self.projects = {}
        self.members = {}
        self.reviews = {}
        for key, name, status in (("820", "운영 검증 프로젝트", "IN_PROGRESS"),
                                  ("821", "운영 초안", "DRAFT"), ("822", "운영 승인 대기", "PENDING_REVIEW")):
            project = self.add_project(key, name, status, OPS_MEMBER)
            project["quota"] = {"WEB_PRODUCT_ENGINEER": 3, "DESIGN": 1}
            form_id = str(10000 + int(key))
            project["applicationFormId"] = form_id
            state.forms[key] = {"projectId": key, "applicationFormId": form_id, "title": name+" 지원서",
                                "description": None, "sections": _sections()}
        self.reviews = {
            "970": {"member": "105", "round": "951", "status": "APPROVED"},
            "971": {"member": "106", "round": "952", "status": "SUBMITTED"}}
        for review in self.reviews.values():
            review.update(project="820", text="운영 검증 지원 동기", submitted=_now(), changed=_now())

    def add_project(self, key, name, status, owner):
        self.members[key] = {}
        self.projects[key] = row = {"id": key, "name": name, "description": "운영 검증 공고",
                                    "status": status, "productOwner": _person(owner),
                                    "quota": {}, "applicationFormId": None}
        return row

    def active_members(self, project):
        show = "COMPLETED" if self.projects[project]["status"] == "COMPLETED" else "ACTIVE"
        return {key: value for key, value in self.members[project].items() if value["status"] == show}

    def roster(self, key):
        groups = {}
        for member, entry in self.active_members(key).items():
            person = dict(_person(member), matchedRoundInfo=self.rounds.get(entry.get("round")))
            groups.setdefault(person["part"], []).append(person)
        return {"projectId": key, "productOwner": self.projects[key]["productOwner"],
                "coProductOwners": groups.pop("PLAN", []),
                "partGroups": [{"part": part, "members": members} for part, members in groups.items()]}

    def detail(self, row):
        key = row["id"]
        team = self.roster(key)
        counts = {g["part"]: len(g["members"]) for g in team["partGroups"]}
        quotas = [{"part": part, "quota": str(quota), "currentCount": str(counts.get(part, 0)),
                   "status": "RECRUITING" if counts.get(part, 0) < quota else "COMPLETED"}
                  for part, quota in row["quota"].items()]
        return {**{k: v for k, v in row.items() if k != "quota"}, "partQuotas": quotas,
                "coProductOwners": team["coProductOwners"],
                "partQuotaStatus": ("RECRUITING" if any(q["status"] == "RECRUITING" for q in quotas)
                                    else "COMPLETED" if quotas else None)}

    def open_round(self):
        now = datetime.now(timezone.utc)
        return any(r["phase"] != "RANDOM_MATCHING" and _instant(r["startsAt"]) <= now
                   <= _instant(r["endsAt"]) for r in self.rounds.values())

    def manual_round(self, part):
        kind = "PLAN_DESIGN" if part == "DESIGN" else "PLAN_DEVELOPER"
        rounds = sorted((r for r in self.rounds.values() if r["type"] == kind
                         and r["phase"] != "RANDOM_MATCHING"), key=lambda r: PHASES.index(r["phase"]))
        now = datetime.now(timezone.utc)
        previous = None
        for row in rounds:
            if previous is None:
                started = _instant(row["startsAt"]) <= now
            else:
                # Only the seeded legacy 1st round has a published result in this scenario.
                started = previous["resultPublishAt"] is None and _instant(previous["decisionDeadline"]) < now
            if started and now < _instant(row["decisionDeadline"]):
                return max((r for r in rounds if _instant(r["startsAt"]) <= now),
                           key=lambda r: _instant(r["startsAt"]), default=None)
            previous = row
        return None

    def permissions(self, row):
        status = row["status"]
        active = status == "IN_PROGRESS"
        editable = status in ("DRAFT", "PENDING_REVIEW", "IN_PROGRESS")
        form = bool(row["applicationFormId"])
        ready = bool(form and row["quota"] and row["name"])
        unlocked = not self.open_round()
        return {"projectId": row["id"], "exists": True,
                "canEditInfo": {"allowed": editable and unlocked},
                "canDelete": {"allowed": unlocked}, "canTransferOwnership": {"allowed": editable},
                "application": {"canCreate": {"allowed": False}, "canReadList": {"allowed": True},
                                "canDecide": {"allowed": active}},
                "applicationForm": {"canRead": {"allowed": form}, "canCreate": {
                    "allowed": editable and not form and (not active or unlocked)},
                    "canEdit": {"allowed": editable and form and (not active or unlocked)}},
                "partQuota": {"canEdit": {"allowed": False, "reason": "지부의 첫 매칭이 시작됐어요."}},
                "status": {"canRequestReview": {"allowed": status == "DRAFT" and ready},
                           "canPublish": {"allowed": status == "PENDING_REVIEW" and ready},
                           "canAbort": {"allowed": active}, "canComplete": {"allowed": active}},
                "member": {"canRead": {"allowed": True}, "canCreate": {"allowed": editable},
                           "canDelete": {"allowed": editable}, "canAssign": {"allowed": active and self.manual_round("WEB_PRODUCT_ENGINEER") is not None},
                           "canUnassign": {"allowed": editable and self.manual_round("WEB_PRODUCT_ENGINEER") is not None}}, "statistics": {"canRead": {"allowed": True}}}

    def schedule(self, method, path, query, body):
        if path == ROUNDS and method == "GET":
            rows = [r for r in self.rounds.values() if query.get("chapterId", [OPS_CHAPTER]) == [OPS_CHAPTER]
                    and query.get("type", [r["type"]]) == [r["type"]]]
            if "time" in query:
                try:
                    if "chapterId" not in query:
                        return 400, None
                    when = _instant(query["time"][0])
                except (IndexError, ValueError):
                    return 400, None
                rows = [r for r in rows if r["phase"] != "RANDOM_MATCHING"
                        and _instant(r["startsAt"]) <= when <= _instant(r["endsAt"])]
            return 200, sorted(rows, key=lambda r: _instant(r["startsAt"]))
        auto = re.fullmatch(ROUNDS + r"/(\d+)/auto-decide", path)
        if auto and method == "POST":
            key = auto[1]
            row = self.rounds.get(key)
            if not row:
                return 404, None
            if row["autoDecisionExecutedAt"]:
                return 200, None
            if _instant(row["decisionDeadline"]) >= datetime.now(timezone.utc):
                return 400, None, {"code": "PROJECT-0307", "message": "아직 자동 선발을 실행할 수 없어요."}
            if key != "951":
                return 501, None  # Only the seeded legacy round models immediate publication.
            for review in self.reviews.values():
                if review["round"] == key and review["status"] == "APPROVED":
                    self.members[review["project"]][review["member"]] = {"status": "ACTIVE", "round": key}
            row.update(autoDecisionExecutedAt=_now(), autoDecisionExecutedMemberId=OPS_MEMBER)
            return 200, None
        if path != ROUNDS + "/chapters/2" or method not in ("PUT", "DELETE"):
            return 403, None
        kind = body.get("type") if method == "PUT" else query.get("type", [None])[0]
        if kind not in KINDS:
            return 400, None
        existing = {r["phase"]: r for r in self.rounds.values() if r["type"] == kind}
        if existing and _instant(existing["FIRST"]["startsAt"]) <= datetime.now(timezone.utc):
            return 400, None, {"code": "PROJECT-0314", "message": "1차 매칭이 시작되어 일정을 바꿀 수 없어요."}
        if method == "DELETE":
            if not existing:
                return 404, None
            for row in existing.values():
                del self.rounds[row["id"]]
            return 200, None
        changes = body.get("rounds")
        if not isinstance(changes, list) or len(changes) != len(PHASES):
            return 400, None
        proposed = {}
        try:
            for entry in changes:
                phase = entry["phase"]
                if phase not in PHASES or phase in proposed:
                    return 400, None
                name = entry["name"]
                if not isinstance(name, str) or not name.strip() or len(name) > 255:
                    return 400, None
                start, end, publish = map(_instant, [entry["startsAt"], entry["endsAt"], entry["resultPublishAt"]])
                if phase == "RANDOM_MATCHING":
                    if entry.get("decisionDeadline") is not None:
                        return 400, None
                    deadline = end
                else:
                    deadline = _instant(entry["decisionDeadline"])
                    if deadline <= end:
                        return 400, None
                if end <= start or publish < deadline + timedelta(minutes=5):
                    return 400, None
                proposed[phase] = {"phase": phase, "type": kind, "name": name, "chapterId": OPS_CHAPTER,
                                   "description": entry.get("description"), "startsAt": _stamp(start),
                                   "endsAt": _stamp(end), "decisionDeadline": _stamp(deadline),
                                   "resultPublishAt": _stamp(publish), "autoDecisionExecutedAt": None,
                                   "autoDecisionExecutedMemberId": None}
            for first, second in zip(PHASES, PHASES[1:]):
                if _instant(proposed[first]["resultPublishAt"]) > _instant(proposed[second]["startsAt"]):
                    return 400, None
        except (KeyError, ValueError, TypeError, OverflowError):
            return 400, None
        for phase in PHASES:
            row = proposed[phase]
            if phase in existing:
                key = existing[phase]["id"]
            else:
                key = str(self.next_round)
                self.next_round += 1
            row["id"] = key
            self.rounds[key] = row
        return 200, [proposed[phase] for phase in PHASES]

    def review_rows(self, key):
        return [{"applicationId": identifier, "applicant": _person(r["member"]), "status": r["status"],
                 "matchingRound": self.rounds[r["round"]], "submittedAt": r["submitted"],
                 "statusChangedAt": r["changed"]} for identifier, r in self.reviews.items()
                if r["project"] == key and r["status"] != "CANCELLED"]

    def review(self, project, identifier, decision, method, body):
        r = self.reviews.get(identifier)
        if not r or r["project"] != project:
            return 404, None
        row = self.rounds[r["round"]]
        if not decision and method == "GET":
            sections = deepcopy(self.state.forms[project]["sections"])
            for section in sections:
                for q in section["questions"]:
                    q["answer"] = None
                    if q["questionId"] == "611" and r["text"] is not None:
                        q["answer"] = {"textValue": r["text"], "selectedOptions": [], "files": []}
            return 200, {"applicationId": identifier, "status": r["status"], "matchingRound": row,
                         "applicant": _person(r["member"]), "submittedAt": r["submitted"],
                         "statusChangedAt": r["changed"], "formResponse": {"sections": sections}}
        if decision and method == "PATCH":
            if (self.projects[project]["status"] != "IN_PROGRESS" or not
                    _instant(row["endsAt"]) < datetime.now(timezone.utc) <= _instant(row["decisionDeadline"])):
                return 400, None, {"code": "PROJECT-0306", "message": "심사 기간이 종료됐어요."}
            status = body.get("status")
            if status not in ("APPROVED", "REJECTED", "SUBMITTED"):
                return 400, None
            if status == "APPROVED" and r["status"] != status:
                if any(r["member"] in self.active_members(k) for k in self.projects):
                    return 409, None, {"code": "PROJECT-0219", "message": "이미 팀에 배정된 지원자예요."}
                if not self.has_room(project, r["member"]):
                    return 409, None
            r.update(status=status, changed=_now())
            return 200, {"applicationId": identifier, "status": status}
        return 405, None

    def has_room(self, key, member):
        part = OPS_PEOPLE[member][1]
        reserved = set(self.active_members(key)) | {r["member"] for r in self.reviews.values()
                                                   if r["project"] == key and r["status"] == "APPROVED"}
        reserved.discard(member)
        return sum(OPS_PEOPLE[m][1] == part for m in reserved) < self.projects[key]["quota"].get(part, 0)

    def member_request(self, key, identifier, action, method, body, admin):
        project = self.projects[key]
        active = self.active_members(key)
        if not identifier and method == "GET" and not admin:
            return 200, self.roster(key)
        if ((method == "POST" and identifier is not None)
                or (method in ("PATCH", "DELETE") and identifier is None)):
            return 405, None
        if project["status"] in ("COMPLETED", "ABORTED"):
            return 409, None
        if not identifier:
            identifier = str(body.get("memberId", ""))
        if identifier not in OPS_PEOPLE:
            return 404, None
        if identifier == project["productOwner"]["memberId"]:
            return 400, None
        part = OPS_PEOPLE[identifier][1]
        if action == "status" and method == "PATCH":
            target = body.get("status")
            if not isinstance(body.get("reason"), str) or not body["reason"].strip() or target not in (
                    "COMPLETED", "WITHDRAWN", "DISMISSED"):
                return 400, None
            prior = self.members[key].get(identifier)
            if not prior:
                return 404, None
            if prior["status"] == target:
                return 200, None
            if prior["status"] != "ACTIVE":
                return 409, None
            prior.update(status=target, reason=body["reason"])
        else:
            if admin and part == "PLAN":
                return 400, None
            if part != "PLAN":
                assignment_round = self.manual_round(part)
                if assignment_round is None:
                    return 409, None, {"code": "PROJECT-0103", "message": "이 파트의 배정 기간이 아니에요."}
            if method == "POST" and not action:
                if body.get("part") != part:
                    return 400, None
                if project["status"] != "IN_PROGRESS" and part != "PLAN":
                    return 409, None
                if any(identifier in self.active_members(k) or p["productOwner"]["memberId"] == identifier
                       for k, p in self.projects.items()) or (part != "PLAN" and not self.has_room(key, identifier)):
                    return 409, None
                if any(r["member"] == identifier and r["status"] == "APPROVED" for r in self.reviews.values()):
                    return 409, None
                self.members[key][identifier] = {
                    "status": "ACTIVE", "round": None if part == "PLAN" else assignment_round["id"]}
                return 200, str(int(key) * 1000 + int(identifier))
            if method != "DELETE" or action:
                return 405, None
            if identifier not in active:
                return 404, None
            del self.members[key][identifier]
        if method == "DELETE" or body.get("status") != "COMPLETED":
            for r in self.reviews.values():
                if r["project"] == key and r["member"] == identifier:
                    r.update(status="REJECTED", changed=_now())
        return 200, None

    def finish(self, key, status):
        row = self.projects[key]
        row["status"] = status
        for entry in self.members[key].values():
            if entry["status"] == "ACTIVE":
                entry["status"] = "COMPLETED" if status == "COMPLETED" else "WITHDRAWN"
        for r in self.reviews.values():
            if r["project"] == key and r["status"] == "SUBMITTED":
                r.update(status="CANCELLED", changed=_now())

    def project_request(self, key, suffix, method, body, query):
        row = self.projects[key]
        permissions = self.permissions(row)
        status = row["status"]
        if not suffix:
            if method == "GET":
                return 200, self.detail(row)
            if method == "PATCH":
                if not permissions["canEditInfo"]["allowed"]:
                    return 409, None
                if any(k not in ("name", "description", "externalLink") for k in body):
                    return 501, None
                if any(v is not None and (not isinstance(v, str) or len(v) > limit)
                       for k, limit in (("name", 100), ("description", 200), ("externalLink", 300))
                       for v in [body.get(k)]):
                    return 400, None
                row.update({k: v for k, v in body.items() if v is not None})
            elif method == "DELETE":
                if not permissions["canDelete"]["allowed"]:
                    return 409, None
                self.projects.pop(key)
                self.members.pop(key)
                self.state.forms.pop(key, None)
                self.reviews = {k: r for k, r in self.reviews.items() if r["project"] != key}
                return 200, None
            else:
                return 405, None
        elif suffix == "/application-form":
            if method == "GET":
                return 200, self.state.forms.get(key)
            if method != "PUT":
                return 405, None
            if not any(permissions["applicationForm"][k]["allowed"] for k in ("canCreate", "canEdit")):
                return 409, None
            sections = body.get("sections")
            if not isinstance(sections, list) or not all(isinstance(s, dict) for s in sections):
                return 400, None
            drops_answers = any(r["project"] == key and r["text"] for r in self.reviews.values()) and not any(
                str(s.get("sectionId")) == "610" for s in sections)
            if drops_answers and body.get("confirmDeleteAnsweredSections") is not True:
                return 409, None, {"code": "PROJECT-0026", "message": "공통 질문에 제출된 답변도 삭제됩니다."}
            result = _save_form(self.state, row, body, extended=True)
            if result[0] == 200 and not any(
                question["questionId"] == "611" for section in result[1]["sections"]
                for question in section["questions"]
            ):
                for r in self.reviews.values():
                    if r["project"] == key:
                        r["text"] = None
            return result
        elif suffix == "/part-quotas" and method == "PUT":
            return 409, None  # Chapter 2 has already started the first developer round.
        elif suffix == "/abort" and method == "POST":
            if status != "IN_PROGRESS" or not isinstance(body.get("reason"), str) or not body["reason"].strip():
                return 400, None
            self.finish(key, "ABORTED")
            return 200, None
        elif suffix in ("/submit", "/publish") and method == "POST":
            flag = "canPublish" if suffix == "/publish" else "canRequestReview"
            if not permissions["status"][flag]["allowed"]:
                return 409, None
            row["status"] = "IN_PROGRESS"
        elif suffix == "/transfer-ownership" and method == "POST":
            new_owner = str(body.get("newOwnerMemberId"))
            if not permissions["canTransferOwnership"]["allowed"] or new_owner not in self.active_members(key):
                return 409, None
            if OPS_PEOPLE[new_owner][1] != "PLAN":
                return 400, None
            self.members[key].pop(new_owner)
            self.members[key][row["productOwner"]["memberId"]] = {"status": "ACTIVE", "round": None}
            row["productOwner"] = _person(new_owner)
        elif suffix == "/applications" and method == "GET":
            if query.get("status", ["SUBMITTED"])[0] not in ("SUBMITTED", "APPROVED", "REJECTED"):
                return 400, None
            return 200, [r for r in self.review_rows(key)
                         if query.get("status", [r["status"]]) == [r["status"]]
                         and query.get("part", [r["applicant"]["part"]]) == [r["applicant"]["part"]]
                         and query.get("matchingRoundId", [r["matchingRound"]["id"]]) == [r["matchingRound"]["id"]]]
        else:
            review = re.fullmatch(r"/applications/(\d+)(/decision)?", suffix)
            if review:
                return self.review(key, review[1], review[2], method, body)
            team = re.fullmatch(r"/members(?:/(\d+)(?:/(status))?)?", suffix)
            if team:
                return self.member_request(key, team[1], team[2], method, body, False)
            return 501, None
        return 200, {"projectId": key, "status": row["status"]}

    def statistics(self, path, query):
        if path.endswith("/applications"):
            keys = query.get("projectIds", [""])[0].split(",")
            if any(key not in self.projects for key in keys):
                return 404, None
            projects = []
            for key in keys:
                counts = {phase: 0 for phase in PHASES[:3]}
                for row in self.review_rows(key):
                    counts[row["matchingRound"]["phase"]] += 1
                projects.append({"projectId": key, "projectName": self.projects[key]["name"],
                                 "rounds": [{"phase": p, "applicantCount": str(n)} for p,n in counts.items()]})
            return 200, {"chapterId": "2", "matchingRound": self.rounds["952"],
                         "summary": {"roundApplicationStatistics": [], "schoolApplicationStatistics": [],
                                     "projectRoundStatistics": projects}}
        overview = []
        stats = []
        for key, row in self.projects.items():
            if row["status"] not in ("IN_PROGRESS", "COMPLETED"):
                continue
            detail = self.detail(row)
            team = self.roster(key)
            groups = {g["part"]: g["members"] for g in team["partGroups"]}
            parts = [{"part": q["part"], "currentMemberCount": q["currentCount"], "quota": q["quota"],
                      "status": q["status"], "members": groups.get(q["part"], [])} for q in detail["partQuotas"]]
            overview.append({"projectId": key, "projectName": row["name"], "productOwner": row["productOwner"],
                             "coProductOwners": team["coProductOwners"], "parts": parts,
                             "quota": str(sum(row["quota"].values())), "partQuotaStatus": detail["partQuotaStatus"],
                             "currentMemberCount": str(sum(len(m) for m in groups.values()))})
            web = groups.get("WEB_PRODUCT_ENGINEER", [])
            counts = [{"phase": phase, "matchedMemberCount": str(sum(
                (m.get("matchedRoundInfo") or {}).get("phase") == phase for m in web))} for phase in PHASES]
            stats.append({"projectId": key, "projectName": row["name"], "quota": str(row["quota"].get("WEB_PRODUCT_ENGINEER",0)),
                          "matchedMemberCount": str(len(web)), "rounds": counts, "parts": [
                              {"part": "WEB_PRODUCT_ENGINEER", "matchedMemberCount": str(len(web)), "quota": str(row["quota"].get("WEB_PRODUCT_ENGINEER",0))}]})
        if path.endswith("/matching-overview"):
            return 200, {"projects": overview}
        phases = []
        remaining = 3
        for i, phase in enumerate(PHASES):
            n = sum(int(p["rounds"][i]["matchedMemberCount"]) for p in stats)
            phases.append({"phase": phase, "matchedMemberCount": str(n), "availableMemberCount": str(remaining)})
            remaining -= n
        return 200, {"chapterId": "2", "roundMatchingStatistics": phases,
                     "schoolMatchingStatistics": [], "projectMatchingStatistics": stats}

    def dispatch(self, method, path, query, body, member):
        operator = member == OPS_MEMBER
        if operator and (path == ROUNDS or path.startswith(ROUNDS + "/")):
            return self.schedule(method, path, query, body)
        if operator and path == ROOT + "/admin/pm-candidates" and method == "GET":
            rows = [_person(k) for k in OPS_PEOPLE if OPS_PEOPLE[k][1] == "PLAN"
                    and query.get("keyword", [""])[0] in OPS_PEOPLE[k][0]]
            return _page(rows, query)
        if operator and path == ROOT and method == "POST":
            owner = str(body.get("productOwnerMemberId", OPS_MEMBER))
            if owner not in OPS_PEOPLE or OPS_PEOPLE[owner][1] != "PLAN" or body.get("gisuId") != 10:
                return 400, None
            key = self.state.allocate_project()
            self.add_project(key, None, "DRAFT", owner)
            return 200, {"projectId": key, "status": "DRAFT"}
        if operator and path in (ROOT, ROOT + "/me/drafts", ROOT + "/me/managed") and method == "GET":
            rows = [self.detail(p) for p in reversed(self.projects.values())
                    if query.get("gisuId") == ["10"] and query.get("chapterId", ["2"]) == ["2"]
                    and query.get("keyword", [""])[0] in (p["name"] or "")]
            if path == ROOT:
                rows = [p for p in rows if p["status"] in ("IN_PROGRESS", "COMPLETED")]
            if path.endswith("/drafts"):
                rows = [p for p in rows if p["status"] == "DRAFT" and p["productOwner"]["memberId"] == member]
            if path.endswith("/managed"):
                priority = {"IN_PROGRESS": 0, "PENDING_REVIEW": 1, "DRAFT": 2}
                rows.sort(key=lambda p: priority.get(p["status"], 3))
            return _page(rows, query)
        if path == ROOT + "/permissions" and method == "GET" and operator:
            keys = [key for v in query.get("ids", []) for key in v.split(",")]
            return 200, {"projects": [self.permissions(self.projects[k]) if k in self.projects
                                      else _permission(k, member, self.state) for k in keys]}
        if path.startswith(ROOT + "/statistics/"):
            if operator and path.endswith("/applications"):
                return self.statistics(path, query)
            if query.get("chapterId") == ["2"] and path in (
                    ROOT + "/statistics/matchings", ROOT + "/statistics/matching-overview"):
                if query.get("view", ["PUBLISHED"]) not in (["ADJUSTMENT"], ["PUBLISHED"]):
                    return 400, None
                if not operator and query.get("view") == ["ADJUSTMENT"]:
                    return 403, None
                return self.statistics(path, query)
        if path == ROOT + "/members" and method == "GET":
            keys = [key for v in query.get("projectIds", []) for key in v.split(",")]
            if any(k in self.projects for k in keys):
                result = published_teams(query)
                result.update({k: self.roster(k) for k in keys if k in self.projects and
                               self.projects[k]["status"] in ("IN_PROGRESS", "COMPLETED")})
                return 200, result
        if operator and path == ROOT + "/complete" and method == "POST":
            keys = body.get("projectIds")
            if not isinstance(keys, list) or not keys or any(type(k) is not int for k in keys):
                return 400, None
            keys = list(dict.fromkeys(str(k) for k in keys))
            if any(k not in self.projects for k in keys):
                return 404, None
            if any(self.projects[k]["status"] != "IN_PROGRESS" for k in keys):
                return 409, None
            for k in keys:
                self.finish(k, "COMPLETED")
            return 200, None
        route = re.fullmatch(ROOT + r"/(admin/)?(\d+)(/.*)?", path)
        if not route or route[2] not in self.projects:
            return None
        key, suffix = route[2], route[3]
        if not operator:
            public = self.projects[key]["status"] in ("IN_PROGRESS", "COMPLETED")
            if public and not route[1] and method == "GET":
                if suffix is None:
                    return 200, self.detail(self.projects[key])
                if suffix == "/members":
                    return 200, self.roster(key)
                if suffix == "/applications":
                    return 200, []
            return 403, None
        if route[1]:
            if suffix == "/members/candidates" and method == "GET":
                part = query.get("part", [None])[0]
                rows = [_person(k) for k in OPS_PEOPLE if OPS_PEOPLE[k][1] == part
                    and not any(r["member"] == k and r["status"] == "APPROVED" for r in self.reviews.values())
                    and query.get("keyword", [""])[0] in OPS_PEOPLE[k][0] and not any(
                    k in self.active_members(p) or k == row["productOwner"]["memberId"]
                    for p,row in self.projects.items())]
                return _page(rows, query)
            team = re.fullmatch(r"/members(?:/(\d+))?", suffix or "")
            if not team:
                return 404, None
            return self.member_request(key, team[1], None, method, body, True)
        return self.project_request(key, suffix, method, body, query)


def handle(handler, method, path, query, body, member_id) -> bool:
    """Return False when a different fixture owns the route."""
    if not (path in (ROOT, ROUNDS) or path.startswith((ROOT + "/", ROUNDS + "/"))):
        return False
    with _INIT_LOCK:
        if not hasattr(handler.server, "matching_state"):
            handler.server.matching_state = State()
    state = handler.server.matching_state
    with state.lock:
        control = getattr(handler.server, "control", None)
        if (str(member_id) == OPS_MEMBER and path == ROOT + "/me/managed" and method == "GET"
                and control is not None and (control / "fail-matching-managed-once").is_file()):
            (control / "fail-matching-managed-once").unlink()
            result = 503, None, {"code": "FIXTURE-503", "message": "운영 QA 일시 오류입니다. 다시 시도해 주세요."}
        else:
            result = deepcopy(_dispatch(state, method, path, query, body or {}, str(member_id)))
    if result is None:
        return False
    if len(result) == 3:
        status, data, error = result
        handler.send_result(status, data, **error)
    else:
        handler.send_result(*result)
    return True
