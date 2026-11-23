#  matching_fixture.py
#  UMCDesk
#
#  Created by euijjang97 on 11/23/26.

"""Synthetic matching routes for the authenticated loopback session fixture."""

import re
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
        return 409, None
    if method == "PUT" and not action:
        return _save(app, body)
    if method == "POST" and action == "/submit":
        if app["status"] != "DRAFT":
            return 409, None
        if not (app["text"] or "").strip():
            return 400, None
        now = _now()
        app.update(status="SUBMITTED", submitted=now, changed=now)
        return _status(app)
    if method == "DELETE" and not action:
        app.update(status="CANCELLED", changed=_now())
        return _status(app)
    return 405, None


def _operations(state, method, path, query, body, member):
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
        result = _dispatch(state, method, path, query, body or {}, str(member_id))
    if result is None:
        return False
    handler.send_result(*result)
    return True
