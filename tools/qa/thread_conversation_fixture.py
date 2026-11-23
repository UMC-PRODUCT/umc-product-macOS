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

_lock = threading.Lock()
_rooms = {}
_keys = {}
_subscribers = {}


def _message(identifier, author, content):
    return dict(messageId=str(identifier), senderId=author, senderName="합성 참여자",
                content=content, createdAt="2026-11-23T09:00:00Z", deletedAt=None,
                isSenderBlocked=False, files=[], reactions=[], replyTo=None)


def _room(thread):
    if thread not in _rooms:
        blocked = _message(2, "9001", "숨겨야 하는 차단 본문")
        blocked["isSenderBlocked"] = True
        deleted = _message(3, "9002", "숨겨야 하는 삭제 본문")
        deleted["deletedAt"] = "2026-11-23T09:01:00Z"
        _rooms[thread] = [_message(1, thread, "로컬 계정별 테스트 메시지"), blocked, deleted]
    return _rooms[thread]


def history(thread_id, before=None):
    with _lock:
        rows = [row for row in reversed(_room(thread_id))
                if before is None or int(row["messageId"]) < int(before)]
        return json.loads(json.dumps(dict(messages=rows[:30], hasMore=len(rows) > 30,
                                          nextBefore=rows[29]["messageId"] if len(rows) > 30 else None)))


def _apply(member, destination, body):
    match = re.fullmatch(r"/app/community/threads/([1-9][0-9]*)/(messages|read)(?:/(.+))?", destination)
    if not match or member != match[1]:
        raise ValueError("THREAD_ACCESS_DENIED")
    thread, command, suffix = match.groups()
    with _lock:
        rows = _room(thread)
        if command == "read":
            return None, False
        if suffix is None:
            key = member, thread, str(uuid.UUID(body["clientMessageId"]))
            if key in _keys:
                previous, identifier = _keys[key]
                if previous != body:
                    raise ValueError("IDEMPOTENCY_CONFLICT")
                return identifier, True
            if len(body["content"]) > 2000 or not (body["content"].strip() or body["fileMetadataIds"]):
                raise ValueError("INVALID_MESSAGE")
            identifier = str(int(rows[-1]["messageId"]) + 1)
            row = _message(identifier, member, body["content"])
            if body.get("replyToId"):
                row["replyTo"] = dict(messageId=str(body["replyToId"]))
            for file_id in body.get("fileMetadataIds", []):
                item = _uploads.get(file_id)
                if not item or item["owner"] != member or not item["confirmed"]:
                    raise ValueError("IMAGE_UNAVAILABLE")
                row["files"].append(dict(fileId=file_id, fileName=item["name"],
                                         fileSize=str(item["size"]), fileUrl=item["url"]))
            rows.append(row)
            _keys[key] = body, identifier
            return identifier, False
        message, action = suffix.split("/", 1)
        row = next((item for item in rows if item["messageId"] == message), None)
        if not row or row["isSenderBlocked"] or row["deletedAt"]:
            raise ValueError("MESSAGE_UNAVAILABLE")
        if action in ("reactions/add", "reactions/remove"):
            emoji = body["emoji"]
            row["reactions"] = [item for item in row["reactions"] if item["emoji"] != emoji]
            if action == "reactions/add":
                row["reactions"].append(dict(emoji=emoji, count="1", reactedByMe=True))
        elif action == "edit" and row["senderId"] == member:
            row["content"] = body["content"]
        elif action == "delete" and row["senderId"] == member:
            row["deletedAt"] = "2026-11-23T10:00:00Z"
        else:
            raise ValueError("COMMAND_DENIED")
        return message, False


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


def _broadcast(thread):
    event = dict(type="message.updated", threadId=thread, eventId=str(uuid.uuid4()))
    with _lock:
        subscribers = list(_subscribers.items())
    queue = "/user/queue/community/threads/events"
    for handler, (identify, token, subscription) in subscribers:
        if identify(token) != thread:
            continue
        try:
            _send(handler, f"MESSAGE\ndestination:{queue}\nsubscription:{subscription}\n\n"
                  + json.dumps(event) + "\0")
        except OSError:
            pass


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
            if command == "CONNECT":
                token = fields.get("Authorization", "").removeprefix("Bearer ")
                if not identify(token):
                    _send(handler, "ERROR\n\ninvalid fixture session\0")
                    return
                _send(handler, "CONNECTED\nversion:1.2\nheart-beat:0,0\n\n\0")
            elif command == "SUBSCRIBE":
                queues[fields["destination"]] = fields["id"]
                if fields["destination"] == "/user/queue/community/threads/events":
                    with _lock:
                        _subscribers[handler] = identify, token, fields["id"]
            elif command == "SEND":
                identifier = str(uuid.UUID(fields["x-command-id"]))
                try:
                    body = json.loads(content)
                    member = identify(token)
                    message, repeated = _apply(member, fields["destination"], body)
                    event = dict(type="command.acknowledged", threadId=member,
                                 payload=dict(commandId=identifier, messageId=message,
                                              deduplicated=repeated, clientMessageId=body.get("clientMessageId")))
                    queue = "/user/queue/community/threads/events"
                    if message is not None and not repeated:
                        _broadcast(member)
                except (KeyError, ValueError) as exc:
                    event = dict(commandId=identifier, message=str(exc), retryable=False)
                    queue = "/user/queue/errors"
                frame = f"MESSAGE\ndestination:{queue}\nsubscription:{queues[queue]}\n\n"
                _send(handler, frame + json.dumps(event) + "\0")
    except (OSError, ValueError, EOFError, KeyError):
        return
    finally:
        with _lock:
            _subscribers.pop(handler, None)

_uploads = {}


def prepare_photo(member, body, port):
    """Return a synthetic signed PUT URL to this loopback fixture."""
    if not member or body.get("category") != "POST_IMAGE":
        return 403, None
    size = body.get("fileSize")
    if not isinstance(size, int) or not 0 < size <= 10 * 1024 * 1024:
        return 400, None
    file_id = str(uuid.uuid4())
    url = f"http://127.0.0.1:{port}/fixture/thread-photo/{file_id}"
    with _lock:
        _uploads[file_id] = dict(url=url, mime=body["contentType"], owner=member, size=size, name=body["fileName"],
                                 received=False, confirmed=False, port=port)
    return 200, dict(fileId=file_id, uploadMethod="PUT", headers={"Content-Type": body["contentType"]},
                     uploadUrl=f"http://127.0.0.1:{port}/fixture/thread-photo/{file_id}",
                     expiresAt="2099-01-01T00:00:00")


def put_photo(file_id, data):
    with _lock:
        item = _uploads.get(file_id)
        if not item or len(data) != item["size"]:
            return 400
        item["data"] = data
        item["received"] = True
        return 200


def confirm_photo(member, file_id):
    with _lock:
        item = _uploads.get(file_id)
        if not item or item["owner"] != member or not item["received"]:
            return 403
        item["confirmed"] = True
        return 200


def photo(file_id):
    """Resolve the loopback-only signed image URL after confirmation."""
    with _lock:
        item = _uploads.get(file_id)
        return (item["mime"], item["data"]) if item and item["confirmed"] else None
