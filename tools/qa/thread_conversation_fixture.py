#  thread_conversation_fixture.py
#  UMCDesk
#
#  Created by euijjang97 on 11/23/26.

"""Synthetic loopback Community history and STOMP fixture for session_fixture."""

import base64
import hashlib
import json
import re
import struct
import threading
import uuid
from types import SimpleNamespace

from thread_management_fixture import active_membership, room_access, blocked_ids

_lock = threading.Lock()


def _state(server):
    # Call under _lock. Separate fixture servers may reuse thread and member identifiers.
    if not hasattr(server, "thread_conversations"):
        server.thread_conversations = SimpleNamespace(rooms={}, keys={}, subscribers={},
                                                      uploads={}, reactions={})
    return server.thread_conversations


def _message(identifier, author, content):
    return dict(messageId=str(identifier), senderId=author, senderName="합성 참여자",
                content=content, createdAt="2026-11-23T09:00:00Z", deletedAt=None,
                isSenderBlocked=False, files=[], reactions=[], replyTo=None)


def _room(state, thread):
    if thread not in state.rooms and thread not in ("101", "102"):
        state.rooms[thread] = []
    if thread not in state.rooms:
        base = 0 if thread == "101" else 100
        blocked = _message(base + 2, "9001", "숨겨야 하는 차단 본문")
        blocked["isSenderBlocked"] = True
        deleted = _message(base + 3, "9002", "숨겨야 하는 삭제 본문")
        deleted["deletedAt"] = "2026-11-23T09:01:00Z"
        state.rooms[thread] = [_message(base + 1, thread, "로컬 계정별 테스트 메시지"), blocked, deleted]
    return state.rooms[thread]


def history(server, thread_id, member, before=None, limit=30):
    with _lock:
        state = _state(server)
        rows = [row for row in reversed(_room(state, thread_id))
                if before is None or int(row["messageId"]) < int(before)]
        messages = json.loads(json.dumps(rows[:limit]))
        blocked = blocked_ids(server, member)
        for row in messages:
            row["isSenderBlocked"] |= row["senderId"] in blocked
            reactions = state.reactions.get((thread_id, row["messageId"]), {})
            row["reactions"] = [dict(emoji=emoji, count=str(len(people)), reactedByMe=member in people)
                                for emoji, people in reactions.items()]
        return dict(messages=messages, hasMore=len(rows) > limit,
                    nextBefore=messages[-1]["messageId"] if len(rows) > limit else None)


def _apply(server, member, destination, body):
    match = re.fullmatch(r"/app/community/threads/([1-9][0-9]*)/(messages|read)(?:/(.+))?", destination)
    if not match or not member:
        raise ValueError("THREAD_ACCESS_DENIED")
    thread, command, suffix = match.groups()
    with _lock, active_membership(server, thread, member) as room:
        role = room["roles"][member]
        state = _state(server)
        rows = _room(state, thread)
        if command == "read":
            last_read = int(body["lastReadMessageId"])
            if not any(int(row["messageId"]) == last_read for row in rows):
                raise ValueError("MESSAGE_UNAVAILABLE")
            room["unread"][member] = {i for i in room["unread"].get(member, ()) if i > last_read}
            return None, False
        if suffix is None:
            key = member, thread, str(uuid.UUID(body["clientMessageId"]))
            if key in state.keys:
                previous, identifier = state.keys[key]
                if previous != body:
                    raise ValueError("IDEMPOTENCY_CONFLICT")
                return identifier, True
            if len(body["content"]) > 2000 or not (body["content"].strip() or body["fileMetadataIds"]):
                raise ValueError("INVALID_MESSAGE")
            identifier = str(getattr(server, "thread_message_sequence", 1000) + 1)
            server.thread_message_sequence = int(identifier)
            row = _message(identifier, member, body["content"])
            if body.get("replyToId"):
                row["replyTo"] = dict(messageId=str(body["replyToId"]))
            for file_id in body.get("fileMetadataIds", []):
                item = state.uploads.get(file_id)
                if not item or item["owner"] != member or not item["confirmed"]:
                    raise ValueError("IMAGE_UNAVAILABLE")
                row["files"].append(dict(fileId=file_id, fileName=item["name"],
                                         fileSize=str(item["size"]), fileUrl=item["url"]))
            rows.append(row)
            for recipient in room["roles"]:
                if recipient != member:
                    room["unread"].setdefault(recipient, set()).add(int(identifier))
            state.keys[key] = body, identifier
            return identifier, False
        message, action = suffix.split("/", 1)
        row = next((item for item in rows if item["messageId"] == message), None)
        if not row or row["isSenderBlocked"] or row["deletedAt"]:
            raise ValueError("MESSAGE_UNAVAILABLE")
        if action in ("reactions/add", "reactions/remove"):
            emoji = body["emoji"]
            reactions = state.reactions.setdefault((thread, message), {})
            people = reactions.setdefault(emoji, set())
            if action == "reactions/add":
                people.add(member)
            else:
                people.discard(member)
            if not people:
                del reactions[emoji]
        elif action == "edit" and row["senderId"] == member:
            row["content"] = body["content"]
        elif action == "delete" and (row["senderId"] == member or role in ("OWNER", "ADMIN")):
            row["deletedAt"] = "2026-11-23T10:00:00Z"
        else:
            raise ValueError("COMMAND_DENIED")
        return message, False


def report_message(server, member, message_id, body):
    from thread_management_fixture import save_report
    with _lock:
        state = _state(server)
        for thread in ("101", "102"):
            _room(state, thread)
        for thread, rows in state.rooms.items():
            row = next((r for r in rows if r["messageId"] == message_id), None)
            if row is None:
                continue
            try:
                with active_membership(server, thread, member):
                    if row["senderId"] == member or row["deletedAt"] or row["isSenderBlocked"]:
                        return 403, None
                    return save_report(server, member, "messageId", message_id, body)
            except ValueError:
                return 403, None
    return 404, None


def _receive(handler):
    header = handler.rfile.read(2)
    if len(header) != 2 or header[0] & 15 == 8:
        raise EOFError()
    size = header[1] & 127
    if size in (126, 127):
        size = int.from_bytes(handler.rfile.read(2 if size == 126 else 8), "big")
    if size > 65536 or not header[1] & 128:
        raise ValueError("invalid fixture frame")
    mask = handler.rfile.read(4)
    data = handler.rfile.read(size)
    return bytes(value ^ mask[i % 4] for i, value in enumerate(data)).decode()


def _send(handler, text):
    payload = text.encode()
    size = len(payload)
    length = bytes([size]) if size < 126 else b'\x7e' + struct.pack(">H", size)
    with handler.thread_socket_lock:
        handler.wfile.write(b'\x81' + length + payload)
        handler.wfile.flush()


def _broadcast(server, thread):
    event = dict(type="message.updated", threadId=thread, eventId=str(uuid.uuid4()))
    with _lock:
        subscribers = list(_state(server).subscribers.items())
    queue = "/user/queue/community/threads/events"
    for handler, (identify, token, subscription) in subscribers:
        member = identify(token)
        if not member or not room_access(server, thread, member)[1]:
            continue
        try:
            _send(handler, f"MESSAGE\ndestination:{queue}\nsubscription:{subscription}\n\n"
                  + json.dumps(event) + "\0")
        except OSError:
            pass


def _consume_control(server, name):
    if not hasattr(server, "control"):
        return False
    try:
        (server.control / name).unlink()
        return True
    except FileNotFoundError:
        return False


def serve_socket(handler, identify):
    """Handle the local upgrade. identify(token) returns the current synthetic member ID."""
    if handler.client_address[0] not in ("127.0.0.1", "::1"):
        handler.send_error(403)
        return
    key = handler.headers.get("Sec-WebSocket-Key")
    if not key:
        handler.send_error(400)
        return
    accept = hashlib.sha1((key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11").encode()).digest()
    handler.protocol_version = "HTTP/1.1"
    handler.send_response(101)
    handler.send_header("Connection", "Upgrade")
    handler.send_header("Upgrade", "websocket")
    handler.send_header("Sec-WebSocket-Accept", base64.b64encode(accept).decode())
    handler.send_header("Sec-WebSocket-Protocol", "v12.stomp")
    handler.end_headers()
    handler.close_connection = True
    handler.thread_socket_lock = threading.Lock()
    token = None
    queues = {}
    try:
        while True:
            text = _receive(handler)
            head, _, content = text.rstrip("\0").partition("\n\n")
            command, *headers = head.split("\n")
            fields = dict(line.split(":", 1) for line in headers)
            if command == "DISCONNECT":
                return
            if command == "CONNECT":
                if token is not None:
                    return
                token = fields.get("Authorization", "").removeprefix("Bearer ")
                if not identify(token):
                    _send(handler, "ERROR\n\ninvalid fixture session\0")
                    return
                _send(handler, "CONNECTED\nversion:1.2\nheart-beat:0,0\n\n\0")
            elif not token or not identify(token):
                _send(handler, "ERROR\n\ninvalid fixture session\0")
                return
            elif command == "SUBSCRIBE":
                if fields["destination"] not in ("/user/queue/community/threads/events", "/user/queue/errors"):
                    _send(handler, "ERROR\n\ninvalid queue\0")
                    return
                queues[fields["destination"]] = fields["id"]
                if fields["destination"] == "/user/queue/community/threads/events":
                    with _lock:
                        _state(handler.server).subscribers[handler] = identify, token, fields["id"]
            elif command == "UNSUBSCRIBE":
                for queue, subscription in list(queues.items()):
                    if subscription == fields.get("id"):
                        del queues[queue]
                        if queue.endswith("/events"):
                            with _lock:
                                _state(handler.server).subscribers.pop(handler, None)
            elif command == "SEND":
                identifier = str(uuid.UUID(fields["x-command-id"]))
                try:
                    body = json.loads(content)
                    member = identify(token)
                    destination = fields["destination"]
                    if _consume_control(handler.server, "fail-thread-command-once"):
                        raise TimeoutError("TEMPORARILY_UNAVAILABLE")
                    message, repeated = _apply(handler.server, member, destination, body)
                    thread = destination.split("/")[4]
                    event = dict(type="command.acknowledged", threadId=thread,
                                 payload=dict(commandId=identifier, messageId=message,
                                              deduplicated=repeated, clientMessageId=body.get("clientMessageId")))
                    queue = "/user/queue/community/threads/events"
                    if message is not None and not repeated:
                        _broadcast(handler.server, thread)
                    if _consume_control(handler.server, "drop-thread-ack-once"):
                        return
                except TimeoutError as exc:
                    event = dict(commandId=identifier, message=str(exc), retryable=True)
                    queue = "/user/queue/errors"
                except (KeyError, ValueError, TypeError, AttributeError) as exc:
                    event = dict(commandId=identifier, message=str(exc), retryable=False)
                    queue = "/user/queue/errors"
                frame = f"MESSAGE\ndestination:{queue}\nsubscription:{queues[queue]}\n\n"
                _send(handler, frame + json.dumps(event) + "\0")
    except (OSError, ValueError, EOFError, KeyError):
        return
    finally:
        with _lock:
            _state(handler.server).subscribers.pop(handler, None)


def prepare_photo(server, member, body):
    """Return a synthetic signed PUT URL to this loopback fixture."""
    if not member or body.get("category") != "POST_IMAGE":
        return 403, None
    size = body.get("fileSize")
    mime, name = body.get("contentType"), body.get("fileName")
    if not isinstance(name, str) or not name.strip() or mime not in (
            "image/jpeg", "image/png", "image/heic", "image/heif", "image/webp", "image/gif"):
        return 400, None
    if type(size) is not int or not 0 < size <= 10 * 1024 * 1024:
        return 400, None
    port = server.server_port
    file_id = str(uuid.uuid4())
    url = f"http://127.0.0.1:{port}/fixture/thread-photo/{file_id}"
    with _lock:
        _state(server).uploads[file_id] = dict(url=url, mime=mime, owner=member, size=size,
                                              name=name, received=False, confirmed=False)
    return 200, dict(fileId=file_id, uploadMethod="PUT", headers={"Content-Type": mime},
                     uploadUrl=url,
                     expiresAt="2099-01-01T00:00:00")


def put_photo(server, file_id, data, content_type):
    with _lock:
        item = _state(server).uploads.get(file_id)
        if not item:
            return 404
        if item["confirmed"]:
            return 403
        if not isinstance(data, bytes) or len(data) != item["size"] or content_type != item["mime"]:
            return 400
        item["data"] = data
        item["received"] = True
        return 200


def confirm_photo(server, member, file_id):
    with _lock:
        item = _state(server).uploads.get(file_id)
        if not item:
            return None  # Another storage fixture may own this identifier.
        if item["owner"] != member or not item["received"]:
            return 403
        item["confirmed"] = True
        return 200


def photo(server, file_id):
    """Resolve the loopback-only signed image URL after confirmation."""
    with _lock:
        item = _state(server).uploads.get(file_id)
        return (item["mime"], item["data"]) if item and item["confirmed"] else None
