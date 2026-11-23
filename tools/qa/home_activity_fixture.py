#  home_activity_fixture.py
#  UMCDesk
#
#  Created by euijjang97 on 11/23/26.

"""Authenticated synthetic Home and Activity routes for the local session fixture."""

from datetime import datetime, timedelta, timezone
import re
import threading

_lock = threading.RLock()
_status = {}
_created = {}
_groups = {"301": {"name": "테스트 스터디", "mentors": ["102"], "members": ["101"]}}
_names = {"101": "첫 챌린저", "102": "둘째 챌린저"}
_points = {}
_study_schedules = set()
_anchor = datetime.now(timezone.utc).replace(microsecond=0)


def _iso(moment):
    return moment.isoformat().replace("+00:00", "Z")


def _schedules(member):
    rows = []
    for identifier, title, offset, online in [
        ("701", "합성 온라인 스터디", 0, True),
        ("702", "합성 프로젝트 발표", 1, False),
        ("703", "합성 회고", -3, True),
    ]:
        start = _anchor + timedelta(days=offset, minutes=-5)
        rows.append({
            "scheduleId": identifier, "name": title, "startsAt": _iso(start),
            "endsAt": _iso(start + timedelta(hours=1)), "isOnline": online,
            "isParticipant": True, "isAttendanceChecked": True,
            "location": None if online else {"locationName": "테스트 강의실",
                                                  "latitude": 37.5, "longitude": 127.0},
            "attendanceStatus": _status.get((member, identifier),
                                            "PRESENT" if identifier == "703" else None),
            "attendancePolicy": {"checkInStartAt": _iso(start - timedelta(minutes=10)),
                                 "onTimeEndAt": _iso(start + timedelta(minutes=20)),
                                 "lateEndAt": _iso(start + timedelta(minutes=45))}
        })
    return rows + _created.get(member, [])


def handle(method, path, query, body, member_id):
    """Return (HTTP status, result) for a matched route, otherwise None."""
    member = str(member_id)
    if member not in {"101", "102"}:
        return None
    with _lock:
        return _handle(method, path, query, body or {}, member)


def _study_route(method, path, query, body, member):
    if path == "/api/v1/authorization/resource-permission" and method == "GET":
        resource = query.get("resourceType", [""])[0]
        if resource not in {"STUDY_GROUP", "CHALLENGER_POINT", "ATTENDANCE"}:
            return None
        permission = query.get("permissionType", [""])[0]
        return 200, {"permissions": [{"permissionType": permission,
                    "hasPermission": member == "102" and permission in {"WRITE", "EDIT", "READ"}}]}
    if path == "/api/v1/authorization/resource-permissions/batch" and method == "POST":
        queries = body.get("queries", [])
        if not queries or any(q.get("resourceType") != "ATTENDANCE" for q in queries):
            return None
        return 200, {"results": [{"resourceId": target, "permissions": [
                     {"permissionType": "APPROVE", "hasPermission": member == "102"}]}
                     for query in queries for target in query.get("resourceIds", [])]}
    profile = re.fullmatch(r"/api/v1/member/profile/(101|102)", path)
    if profile and method == "GET":
        key = profile.group(1)
        return 200, {"id": key, "name": _names[key], "schoolName": "테스트 대학교",
                     "challengerRecords": [{"challengerId": key, "gisu": "10", "part": "WEB"}]}
    point = re.fullmatch(r"/api/v1/challenger/(101|102)/points", path)
    if point and method == "POST":
        if member != "102":
            return 403, None
        if body.get("pointType") != "CUSTOM" or not body.get("description"):
            return 400, None
        key = point.group(1)
        _points[key] = _points.get(key, 0) + body["pointValue"]
        return 200, {"challengerId": key}
    prefix = "/api/v1/study-groups"
    if not path.startswith(prefix):
        return None
    suffix = path.removeprefix(prefix)
    if method == "GET" and suffix == "/names":
        return 200, {"studyGroups": [{"groupId": key, "name": row["name"]}
                     for key, row in _groups.items()]}
    if method == "POST" and not suffix:
        if member != "102":
            return 403, None
        if not body.get("name") or not body.get("mentorIds") or not body.get("memberIds"):
            return 400, None
        mentors = list(map(str, body["mentorIds"]))
        members = list(map(str, body["memberIds"]))
        if not all(person in _names for person in mentors + members):
            return 400, None
        _groups[str(301 + len(_groups))] = {"name": body["name"], "mentors": mentors, "members": members}
        return 200, None
    if method == "POST" and suffix == "/schedules":
        group = _groups.get(str(body.get("studyGroupId")))
        if not group or member not in group["mentors"]:
            return 403, None
        link = (body["studyGroupId"], body["scheduleId"], body["weeklyCurriculumId"])
        if link in _study_schedules:
            return 400, None
        _study_schedules.add(link)
        return 200, str(len(_study_schedules))
    parts = suffix.strip("/").split("/")
    group = _groups.get(parts[0])
    if not group:
        return 404, None
    if method == "GET" and len(parts) == 1:
        return 200, {role: [{"memberId": user, "memberName": _names[user],
                     "schoolName": "테스트 대학교"} for user in group[role]] for role in ("mentors", "members")}
    if method == "PATCH":
        if member != "102":
            return 403, None
        if len(parts) == 1 and body.get("name"):
            group["name"] = body["name"]
            return 200, None
        if len(parts) == 3 and parts[1] in ("mentors", "members") and parts[2] in _names:
            if parts[2] not in group[parts[1]]:
                group[parts[1]].append(parts[2])
            return 200, None
    return 400, None


def _handle(method, path, query, body, member):
    study = _study_route(method, path, query, body, member)
    if study is not None:
        return study
    if method == "GET":
        if path == "/api/v2/schedules/me":
            try:
                since = datetime.fromisoformat(query["from"][0].replace("Z", "+00:00"))
                until = datetime.fromisoformat(query["to"][0].replace("Z", "+00:00"))
                tracked = {"true": True, "false": False}[query["isAttendanceRequired"][0]]
            except (ValueError, IndexError, KeyError):
                return 400, None
            return 200, [row for row in _schedules(member)
                         if row["isAttendanceChecked"] == tracked
                         and datetime.fromisoformat(row["endsAt"].replace("Z", "+00:00")) >= since
                         and datetime.fromisoformat(row["startsAt"].replace("Z", "+00:00")) <= until]
        if path == "/api/v2/schedules/capabilities":
            return 200, {"canCreateSchedule": True, "canCreateAttendanceRequiredSchedule": member == "102",
                         "maxParticipantCount": "3"}
        if path == "/api/v2/schedules/attendance":
            if member != "102":
                return 403, None
            return 200, [{"scheduleId": row["scheduleId"], "name": row["name"],
                          "participants": [{"memberId": "101", "name": "첫 챌린저",
                                            "attendanceStatus": row["attendanceStatus"],
                                            "excuseReason": None}]} for row in _schedules("101")]
        if path == "/api/v2/curriculums/progress/me":
            if query.get("gisuId") != ["10"]:
                return 400, None
            return 200, {"weeks": [{"weeklyCurriculumId": "501", "weekNo": 1,
                                    "title": "합성 커리큘럼", "originalWorkbooks": [
                                        {"title": "합성 워크북"}]}]}
        if path == "/api/v1/member/search" and query.get("size") == ["30"]:
            members = [{"memberId": "101", "name": "첫 챌린저", "schoolName": "테스트 대학교",
                        "gisu": "10", "part": "WEB"},
                       {"memberId": "102", "name": "둘째 챌린저", "schoolName": "테스트 대학교",
                        "gisu": "10", "part": "PLAN"}]
            return 200, {"page": {"hasNext": False, "content": [row for row in members
                          if query.get("keyword", [""])[0] in row["name"]
                          and (not query.get("part") or row["part"] in query["part"])]}}
        # Other modules own the general notice and project list fixture responses.
        if path == "/api/v1/projects/me/managed" and query.get("size") == ["1"]:
            return 200, {"content": [{"id": "401", "name": "합성 프로젝트"}]}
    if method == "POST":
        if path == "/api/v2/schedules":
            members = body.get("participantMemberIds", [])
            policy = body.get("attendancePolicy")
            if not body.get("name") or any(m not in (101, 102) for m in members):
                return 400, None
            if policy and member != "102":
                return 403, None
            if policy and not members:
                return 400, None
            identifier = str(800 + sum(len(rows) for rows in _created.values()))
            for participant in members:
                _created.setdefault(str(participant), []).append({
                    "scheduleId": identifier, "name": body["name"], "startsAt": body["startsAt"],
                    "endsAt": body["endsAt"], "isOnline": body.get("location") is None,
                    "isParticipant": True, "isAttendanceChecked": bool(policy),
                    "attendanceStatus": None, "location": body.get("location"),
                    "attendancePolicy": policy})
            return 200, identifier
        match = re.fullmatch(r"/api/v2/schedules/(70[123])/attendances/(request|excuse|decide)", path)
        if match:
            identifier, action = match.groups()
            if action == "decide":
                if member != "102":
                    return 403, None
                if not isinstance(body, list) or len(body) != 1:
                    return 400, None
                target = str(body[0].get("participantMemberId"))
                previous = _status.get((target, identifier), "")
                if not previous.endswith("_PENDING"):
                    return 400, None
                result = previous.removesuffix("_PENDING") if body[0]["isApproved"] else "ABSENT"
                _status[target, identifier] = result
                return 200, [{"status": result}]
            previous = _status.get((member, identifier))
            if action == "request":
                if previous or identifier != "701" or body.get("locationVerified") is not False:
                    return 400, None
                result = "PRESENT_PENDING"
            else:
                if previous not in (None, "ABSENT", "LATE") or not body.get("excuseReason", "").strip():
                    return 400, None
                result = "EXCUSED_PENDING"
            _status[member, identifier] = result
            return 200, {"status": result}
    return None
