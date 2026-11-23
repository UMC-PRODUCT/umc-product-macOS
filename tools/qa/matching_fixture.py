#  matching_fixture.py
#  UMCDesk
#
#  Created by euijjang97 on 11/23/26.

"""Synthetic matching routes for the authenticated loopback session fixture."""

import re
from copy import deepcopy
from datetime import datetime, timezone
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


def _save_form(state, draft, body):
    # QA supports common free-text sections. Surface additional editor features as unsupported.
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
            return 501, None
        if not assign(section, "sectionId", old_sections):
            return 400, None
        old_section = old_sections.get(section["sectionId"], {})
        old_questions = {q["questionId"] for q in old_section.get("questions", [])}
        for question in section["questions"]:
            if not valid_item(question) or not isinstance(question.get("isRequired"), bool):
                return 400, None
            if question.get("type") not in ("SHORT_TEXT", "LONG_TEXT"):
                return 501, None
            if question.get("options") != [] or not assign(question, "questionId", old_questions):
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
        project = str(state.next_project)
        state.next_project += 1
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


def handle(handler, method, path, query, body, member_id) -> bool:
    """Return False when a different fixture owns the route."""
    if not (path == ROOT or path.startswith((ROOT + "/", ROUNDS + "/"))):
        return False
    with _INIT_LOCK:
        if not hasattr(handler.server, "matching_state"):
            handler.server.matching_state = State()
    state = handler.server.matching_state
    with state.lock:
        result = deepcopy(_dispatch(state, method, path, query, body or {}, str(member_id)))
    if result is None:
        return False
    handler.send_result(*result)
    return True
