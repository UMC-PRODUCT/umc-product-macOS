#  thread_management_fixture.py
#  UMCDesk
#
#  Created by euijjang97 on 11/23/26.

"""Synthetic thread management contract for the authenticated loopback session fixture."""

import re
import threading
from urllib.parse import parse_qs, urlsplit

_LOCK = threading.Lock()
_PEOPLE = {
    "101": ("첫 챌린저", "WEB"), "102": ("둘째 챌린저", "PLAN"),
    "201": ("테스트 디자인", "DESIGN"), "202": ("테스트 개발", "IOS"),
    "203": ("테스트 서버", "SPRINGBOOT"), "204": ("테스트 기획", "PLAN"),
}


def _person(identifier):
    name, part = _PEOPLE[identifier]
    return {"memberId": identifier, "name": name, "part": part, "generation": "10"}


def _store(server):
    if not hasattr(server, "thread_management_rooms"):
        server.thread_management_rooms = {}
    return server.thread_management_rooms


def register_thread(server, summary, owner_id, *, seeded=False):
    """Register a real fixture creation result so editing and listing see the same metadata."""
    with _LOCK:
        return _register(server, summary, owner_id, seeded)


def _register(server, summary, owner_id, seeded):
    roles = {owner_id: "OWNER"}
    if seeded:
        roles.update({"201": "ADMIN", "202": "MEMBER"})
    room = {"summary": dict(summary), "roles": roles, "departed": {}, "deleted": False}
    _store(server)[str(summary["threadId"])] = room
    return room


def _detail(room, actor):
    role = room["roles"].get(actor)
    return {**room["summary"], "myRole": role, "memberCount": str(len(room["roles"])),
            "maxMembers": "100", "isJoined": role is not None,
            "membershipState": "ACTIVE" if role else room["departed"].get(actor)}


def management_summary(server, summary, actor):
    """Return current list metadata, or None when the thread is no longer visible."""
    with _LOCK:
        room = _store(server).get(str(summary["threadId"]))
        if room is None:
            return summary
        if room["deleted"] or room["departed"].get(actor) == "KICKED_ACKNOWLEDGED":
            return None
        updated = _detail(room, actor)
        keys = ("title", "description", "category", "icon", "myRole", "memberCount",
                "maxMembers", "isJoined", "membershipState")
        return {**summary, **{key: updated[key] for key in keys}}


def _page(rows, query):
    term = query.get("q", [""])[0].casefold()
    rows = [row for row in rows if term in row["name"].casefold()]
    try:
        start = int(query.get("offset", ["0"])[0])
        limit = int(query.get("limit", ["20"])[0])
    except ValueError:
        return 400, None
    if start < 0 or not 1 <= limit <= 100:
        return 400, None
    end = start + limit
    return 200, {"items": rows[start:end], "total": str(len(rows)),
                 "nextOffset": str(end) if end < len(rows) else None}


def _route(room, actor, suffix, method, query, body):
    roles, departed = room["roles"], room["departed"]
    role = roles.get(actor)
    manager = role in ("OWNER", "ADMIN")
    if room["deleted"]:
        return 404, None
    if method == "POST" and suffix == "kick/acknowledge" and departed.get(actor) == "KICKED":
        departed[actor] = "KICKED_ACKNOWLEDGED"
        return 200, _mutation(room, actor)
    if departed.get(actor, "").startswith("KICKED"):
        return 403, None
    if method == "GET":
        if not suffix:
            return 200, _detail(room, actor)
        if suffix == "members":
            return _page([{**_person(i), "role": r, "state": "ACTIVE",
                           "joinedAt": "2026-10-01T00:00:00Z"} for i, r in roles.items()], query)
        if not manager:
            return 403, None
        return _page([{**_person(i), "challengerId": i} for i in _PEOPLE
                      if i not in roles and departed.get(i) in (None, "LEFT")], query)
    if suffix == "leave" and method == "POST":
        if role not in ("MEMBER", "ADMIN"):
            return 403, None
        roles.pop(actor)
        departed[actor] = "LEFT"
        return 200, _mutation(room, actor, role)
    if not manager:
        return 403, None
    if suffix == "invite" and method == "POST":
        ids = body.get("memberIds")
        if (not isinstance(ids, list) or not 1 <= len(ids) <= 99
                or any(type(i) is not int or str(i) not in _PEOPLE for i in ids)
                or len(ids) != len(set(ids))):
            return 400, None
        members = [str(i) for i in ids]
        if any(i in roles or departed.get(i) not in (None, "LEFT") for i in members):
            return 409, None
        for i in members:
            roles[i] = "MEMBER"
            departed.pop(i, None)
        return 200, {"invitedMembers": [{**_person(i), "role": "MEMBER", "state": "ACTIVE"}
                                        for i in members], "memberCount": str(len(roles))}
    if not suffix and method == "PATCH":
        fields = {"title", "description", "category", "icon"}
        if not body or not fields.issuperset(body) or not all(isinstance(v, str) for v in body.values()):
            return 400, None
        room["summary"].update(body)
        return 200, _detail(room, actor)
    if not suffix and method == "DELETE":
        room["deleted"] = True
        return 200, _detail(room, actor)
    target = re.fullmatch(r"members/(\d+)(/role)?", suffix)
    if target:
        i = target[1]
        if i not in roles or roles[i] == "OWNER" or i == actor:
            return 409, None
        if target[2] and method == "PATCH":
            requested = body.get("role")
            if role != "OWNER":
                return 403, None
            if requested not in ("OWNER", "ADMIN", "MEMBER") or requested == roles[i]:
                return 409, None
            if requested == "OWNER":
                roles[actor] = "ADMIN"
            roles[i] = requested
            return 200, _mutation(room, i)
        if not target[2] and method == "DELETE":
            previous = roles.pop(i)
            departed[i] = "KICKED"
            return 200, _mutation(room, i, previous)
    return 404, None


def _mutation(room, member_id, old_role=None):
    return {"threadId": room["summary"]["threadId"], "memberId": member_id,
            "role": room["roles"].get(member_id, old_role or "MEMBER"),
            "state": room["departed"].get(member_id, "ACTIVE"),
            "memberCount": str(len(room["roles"]))}


def handle_thread_management(handler, identifier, body=None):
    """Call after authentication. Return True if a response was written."""
    url = urlsplit(handler.path)
    profile = re.fullmatch(r"/api/v1/member/profile/(\d+)", url.path)
    if profile and handler.command == "GET":
        i = profile[1]
        if i not in _PEOPLE:
            handler.send_result(404)
        else:
            name, part = _PEOPLE[i]
            handler.send_result(200, {"id": i, "name": name, "nickname": name,
                "schoolName": "테스트 대학교", "challengerRecords": [{"gisu": "10", "part": part}],
                "profile": {"github": "https://example.test/test-profile"}})
        return True
    match = re.fullmatch(r"/api/v1/community/threads/(\d+)(?:/(members(?:/\d+(?:/role)?)?"
                         r"|invitable|invite|leave|kick/acknowledge))?", url.path)
    if not match:
        return False
    thread_id, suffix = match.groups()
    with _LOCK:
        room = _store(handler.server).get(thread_id)
        if room is None and thread_id in ("101", "102"):
            summary = {"threadId": thread_id, "title": "테스트 스레드 " + thread_id,
                       "description": "로컬 테스트", "icon": "💬", "category": "FREE",
                       "isPinned": False, "isMuted": False, "unreadCount": "0"}
            room = _register(handler.server, summary, thread_id, True)
        # A one-shot control exercises partial failure and retry in bulk member operations.
        member = re.fullmatch(r"members/(\d+)(?:/role)?", suffix or "")
        if member and handler.command in ("DELETE", "PATCH") and hasattr(handler.server, "control"):
            marker = handler.server.control / ("fail-thread-member-once-" + member[1])
            if marker.exists():
                marker.unlink()
                handler.send_result(503)
                return True
        status, result = ((404, None) if room is None else
                          _route(room, identifier, suffix or "", handler.command,
                                 parse_qs(url.query), body or {}))
    handler.send_result(status, result)
    return True
