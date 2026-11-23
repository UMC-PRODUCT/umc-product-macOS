#  community_post_fixture.py
#  UMCDesk
#
#  Created by euijjang97 on 11/23/26.

"""Synthetic authenticated board routes. State belongs to one loopback server instance."""

import re
import threading
from datetime import datetime, timezone

_LOCK = threading.RLock()
_CATEGORIES = {"FREE", "QUESTION", "INFORMATION", "HABIT", "LIGHTNING"}
_ROOT = "/api/v1/posts"


def _now():
    return datetime.now(timezone.utc).isoformat().replace("+00:00", "Z")


def _record(identifier, member, title, content, category):
    return {"id": identifier, "member": member, "title": title, "content": content,
            "category": category, "date": _now(), "likes": set(), "scraps": set(),
            "comments": {}, "meeting": None}


def _store(server):
    if not hasattr(server, "community_post_state"):
        server.community_post_state = {
            "posts": {1: _record(1, "101", "스터디 질문", "다음 모임 시간을 공유해요.", "QUESTION"),
                      2: _record(2, "102", "프로젝트 회고", "프로젝트 경험을 나눠요.", "FREE")},
            "next_post": 3, "next_comment": 1}
    return server.community_post_state


def _dto(post, member, detail=False):
    value = dict(postId=str(post["id"]), title=post["title"], content=post["content"],
                 category=post["category"], authorMemberId=post["member"],
                 authorName="합성 회원 " + post["member"], authorNickname=None,
                 commentCount=str(len(post["comments"])), likeCount=str(len(post["likes"])),
                 isLiked=member in post["likes"], lightningInfo=post["meeting"])
    if detail:
        value.update(writeTime=post["date"], scrapCount=str(len(post["scraps"])),
                     isScrapped=member in post["scraps"])
    else:
        value["createdAt"] = post["date"]
    return value


def _comment(row, member):
    return dict(commentId=str(row["id"]), postId=str(row["post"]), challengerName="합성 댓글 작성자",
                challengerNickname=None, content=row["content"], isAuthor=row["member"] == member,
                createdAt=row["date"])


def _page(entries, scope, query, member):
    category = query.get("category", [None])[0]
    keyword = query.get("keyword", [""])[0].casefold()
    if scope == "search" and not keyword:
        return 400, None
    try:
        page = int(query.get("page", [0])[0])
        size = int(query.get("size", [20])[0])
        if page < 0 or size < 1:
            return 400, None
    except (ValueError, TypeError):
        return 400, None
    rows = sorted(entries, key=lambda row: row["id"], reverse=True)
    if scope == "search":
        rows = [row for row in rows if keyword in (row["title"] + " " + row["content"]).casefold()]
    elif scope == "my":
        rows = [row for row in rows if row["member"] == member]
    elif scope == "scrapped":
        rows = [row for row in rows if member in row["scraps"]]
    elif scope == "commented":
        rows = [row for row in rows if any(v["member"] == member for v in row["comments"].values())]
    elif category:
        rows = [row for row in rows if row["category"] == category]
    start = page * size
    return 200, dict(content=[_dto(row, member) for row in rows[start:start + size]],
                     page=str(page), size=str(size), totalElements=str(len(rows)),
                     totalPages=str((len(rows) + size - 1) // size), hasPrevious=page > 0,
                     hasNext=start + size < len(rows))


def _route(state, method, suffix, query, body, member):
    posts = state["posts"]
    if method == "GET" and suffix in ("", "my", "scrapped", "commented", "search"):
        return _page(posts.values(), suffix, query, member)
    if method == "POST" and suffix in ("", "lightning"):
        new = _record(state["next_post"], member, "", "", "FREE")
        result = _save(new, body, member, suffix == "lightning")
        if result[0] == 200:
            posts[new["id"]] = new
            state["next_post"] += 1
        return result
    match = re.fullmatch(r"([1-9]\d*)(?:/(lightning|like|scrap|comments)(?:/([1-9]\d*)(/like)?)?)?", suffix)
    if not match:
        return 404, None
    identifier, action, comment_id, comment_like = match.groups()
    post = posts.get(int(identifier))
    if not post:
        return 404, None
    if method == "GET" and not action:
        return 200, _dto(post, member, detail=True)
    if method == "PATCH" and action in (None, "lightning"):
        if post["member"] != member:
            return 403, None
        if (post["category"] == "LIGHTNING") != (action == "lightning"):
            return 400, None
        return _save(post, body, member, action == "lightning")
    if method == "DELETE" and not action:
        if post["member"] != member:
            return 403, None
        del posts[int(identifier)]
        return 200, None
    if method == "POST" and action in ("like", "scrap") and not comment_id:
        key = "likes" if action == "like" else "scraps"
        post[key].symmetric_difference_update({member})
        return 200, {("liked" if action == "like" else "scrapped"): member in post[key],
                     action + "Count": str(len(post[key]))}
    if action == "comments":
        rows = post["comments"]
        if method == "GET" and not comment_id:
            return 200, [_comment(row, member) for row in rows.values()]
        if method == "POST" and not comment_id:
            content, parent = body.get("content"), body.get("parentId")
            if not isinstance(content, str) or not content.strip() or (parent is not None and parent not in rows):
                return 400, None
            row = dict(id=state["next_comment"], post=post["id"], member=member, content=content,
                       likes=set(), date=_now())
            rows[row["id"]] = row
            state["next_comment"] += 1
            return 200, _comment(row, member)
        row = rows.get(int(comment_id or 0))
        if not row:
            return 404, None
        if method == "DELETE" and not comment_like:
            if row["member"] != member:
                return 403, None
            del rows[row["id"]]
            return 200, None
        if method == "POST" and comment_like:
            row["likes"].symmetric_difference_update({member})
            return 200, dict(liked=member in row["likes"], likeCount=str(len(row["likes"])))
    return 405, None


def _save(post, body, member, lightning):
    title, content = body.get("title"), body.get("content")
    category = "LIGHTNING" if lightning else body.get("category")
    if (not all(isinstance(value, str) and value.strip() for value in (title, content))
            or category not in _CATEGORIES or (category == "LIGHTNING") != lightning):
        return 400, None
    meeting = None
    if lightning:
        if (not isinstance(body.get("maxParticipants"), int) or body["maxParticipants"] < 1
                or not all(isinstance(body.get(k), str) and body[k].strip()
                           for k in ("meetAt", "location", "openChatUrl"))):
            return 400, None
        meeting = {k: body[k] for k in ("meetAt", "location", "openChatUrl", "maxParticipants")}
    post.update(title=title, content=content, category=category, meeting=meeting)
    return 200, _dto(post, member)


def handle(handler, method, path, query, body, member_id):
    if path != _ROOT and not path.startswith(_ROOT + "/"):
        return False
    if not member_id:
        handler.send_result(401)
        return True
    with _LOCK:
        status, result = _route(_store(handler.server), method, path[len(_ROOT):].strip("/"),
                                query, body or {}, str(member_id))
    handler.send_result(status, result)
    return True
