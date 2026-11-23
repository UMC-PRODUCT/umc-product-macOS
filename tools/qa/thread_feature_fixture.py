#  thread_feature_fixture.py
#  UMCDesk
#
#  Created by euijjang97 on 11/23/26.

"""Synthetic thread routes for session_fixture.

Touch fail-thread-command-once in the fixture control directory for a retryable
pre-commit command failure, or drop-thread-ack-once for a post-commit disconnect.
Retrying a message with its original clientMessageId returns the stored acknowledgement.
"""

import re

import thread_conversation_fixture as conversation
import thread_management_fixture as management

_THREADS = "/api/v1/community/threads"


def handle(handler, method, path, query, body, member_id):
    """Write a response for a recognized route. Signed PUT receives raw bytes."""
    server = handler.server

    def send(status, result=None):
        handler.send_result(status, result)
        return True

    signed = re.fullmatch(r"/fixture/thread-photo/([a-f0-9-]+)", path)
    if signed:
        if method == "PUT":
            return send(conversation.put_photo(server, signed[1], body,
                                               handler.headers.get("Content-Type")))
        if method == "GET":
            item = conversation.photo(server, signed[1])
            if not item:
                return send(404)
            mime, data = item
            handler.send_response(200)
            handler.send_header("Content-Type", mime)
            handler.send_header("Content-Length", str(len(data)))
            handler.end_headers()
            handler.wfile.write(data)
            return True
        return send(405)

    prepare = path == "/api/v1/storage/prepare-upload" and body.get("category") == "POST_IMAGE"
    confirm = re.fullmatch(r"/api/v1/storage/([a-f0-9-]{36})/confirm", path)
    if not (path == _THREADS or path.startswith(_THREADS + "/")
            or re.fullmatch(r"/api/v1/member/profile/\d+", path) or prepare or confirm):
        return False
    if not member_id:
        return send(401)
    if prepare:
        if method != "POST":
            return send(405)
        return send(*conversation.prepare_photo(server, member_id, body))
    if confirm:
        if method != "POST":
            return send(405)
        status = conversation.confirm_photo(server, member_id, confirm[1])
        return False if status is None else send(status)
    if path == _THREADS:
        if method == "GET":
            return send(*management.list_rooms(server, query, member_id))
        if method == "POST":
            return send(*management.create_room(server, body, member_id))
        return send(405)
    history = re.fullmatch(_THREADS + r"/(\d+)/messages", path)
    if history:
        if method != "GET":
            return send(405)
        status, _ = management.room_access(server, history[1], member_id)
        if status != 200:
            return send(status)
        before = query.get("before", [None])[0]
        try:
            limit = int(query.get("limit", ["30"])[0])
            if not 1 <= limit <= 100 or (before is not None and int(before) <= 0):
                return send(400)
        except ValueError:
            return send(400)
        return send(200, conversation.history(server, history[1], member_id, before, limit))
    return management.handle_thread_management(handler, member_id, body)


def socket(handler, identify):
    """Delegate upgrades; resolve the synthetic session again for each command and delivery."""
    return conversation.serve_socket(handler, identify)
