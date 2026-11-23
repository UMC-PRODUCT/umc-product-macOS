//
//  ThreadConversationSocket.swift
//  CommunityData
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import Foundation

struct ConversationSocket {
    let baseURL: URL

    func perform(
        _ command: ThreadConversationCommand, thread: String, token: String,
        validateAccount: () async throws -> Void
    ) async throws {
        let outgoing = try ConversationOutgoing(command, thread: thread)
        try await connected(token: token, timeoutInterval: .seconds(15)) { socket, reader in
            var frames = reader
            let id = UUID().uuidString.lowercased()
            try await validateAccount()
            try Task.checkCancellation()
            let header = "SEND\ndestination:\(outgoing.path)\nx-command-id:\(id)"
            try await socket.send(
                .string(
                    header + "\ncontent-type:application/json\n\n"
                        + outgoing.body + "\0"))
            while true {
                try Task.checkCancellation()
                let frame = try await frames.next()
                guard frame.command != "ERROR" else {
                    throw ConversationFailure("대화 연결이 종료됐어요. 다시 시도해 주세요.")
                }
                guard frame.command == "MESSAGE",
                    let json = try JSONSerialization.jsonObject(with: frame.body)
                        as? [String: Any]
                else { continue }
                let payload = json["payload"] as? [String: Any] ?? json
                guard payload["commandId"] as? String == id else { continue }
                if json["type"] as? String == "command.acknowledged",
                    json["threadId"] as? String == thread
                {
                    return
                }
                throw Self.commandError(payload)
            }
        }
    }

    static func commandError(_ payload: [String: Any]) -> any Error {
        let reason = payload["message"] as? String ?? "요청을 처리하지 못했어요."
        // These thread/message command codes refer to the thread or the calling member.
        switch payload["code"] as? String {
        case "COMMUNITY-0033", "COMMUNITY-0034", "COMMUNITY-0035", "COMMUNITY-0037":
            return ThreadConversationRejection.denied(reason)
        case nil where reason == "THREAD_ACCESS_DENIED":
            // The local fixture emits the symbolic code in the message field.
            return ThreadConversationRejection.denied(reason)
        default:
            break
        }
        if payload["status"] as? Int == 429 { return ThreadConversationRejection.rateLimited }
        if payload["retryable"] as? Bool == false {
            return ThreadConversationRejection.commandDenied(reason)
        }
        return ConversationFailure(reason)
    }

    func observe(
        thread: String, token: String, changed: @escaping @Sendable () async -> Void
    ) async throws {
        // Renew the subscription periodically with the account's current credential.
        try await connected(token: token, timeoutInterval: .seconds(120)) { _, reader in
            var frames = reader
            var seen = Set<String>()
            while true {
                try Task.checkCancellation()
                let frame = try await frames.next()
                guard frame.command != "ERROR" else { throw URLError(.networkConnectionLost) }
                guard frame.command == "MESSAGE",
                    let event = try JSONSerialization.jsonObject(with: frame.body)
                        as? [String: Any],
                    event["threadId"] as? String == thread,
                    let type = event["type"] as? String,
                    type != "command.acknowledged", type != "read.updated",
                    let id = event["eventId"] as? String, seen.insert(id).inserted
                else { continue }
                await changed()
            }
        }
    }

    private func connected(
        token: String, timeoutInterval: Duration,
        work: (URLSessionWebSocketTask, ConversationFrameReader) async throws -> Void
    ) async throws {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true),
            !token.isEmpty, !token.contains(where: { $0.isNewline || $0 == "\0" })
        else {
            throw ConversationFailure("연결 정보를 확인할 수 없어요.")
        }
        components.path = "/ws/websocket"
        components.query = nil
        components.fragment = nil
        components.scheme = components.scheme == "https" ? "wss" : "ws"
        guard let url = components.url, let host = components.host else {
            throw ConversationFailure("대화 서버 주소를 확인할 수 없어요.")
        }
        let session = URLSession(configuration: .ephemeral)
        let socket = session.webSocketTask(with: url, protocols: ["v12.stomp"])
        socket.maximumMessageSize = 2_097_152
        defer {
            socket.cancel(with: .normalClosure, reason: nil)
            session.invalidateAndCancel()
        }
        socket.resume()
        try await withTaskCancellationHandler {
            let timeout = Task {
                try await Task.sleep(for: timeoutInterval)
                socket.cancel(with: .goingAway, reason: nil)
            }
            defer { timeout.cancel() }
            let connect = "CONNECT\naccept-version:1.2\nhost:\(host)\nheart-beat:0,0"
            try await socket.send(.string(connect + "\nAuthorization:Bearer \(token)\n\n\0"))
            var frames = ConversationFrameReader(socket: socket)
            guard try await frames.next().command == "CONNECTED" else {
                throw ConversationFailure("대화 서버에 연결하지 못했어요.")
            }
            for (index, queue) in ["community/threads/events", "errors"].enumerated() {
                let subscribe = "SUBSCRIBE\nid:sub-\(index)\ndestination:/user/queue/\(queue)"
                try await socket.send(.string(subscribe + "\nack:auto\n\n\0"))
            }
            try await work(socket, frames)
        } onCancel: {
            socket.cancel(with: .goingAway, reason: nil)
        }
    }
}

private struct ConversationOutgoing {
    let path: String
    let body: String

    init(_ command: ThreadConversationCommand, thread: String) throws {
        let root = "/app/community/threads/\(thread)"
        var fields: [String: Any] = [:]
        switch command {
        case .create(let key, let content, let files, let reply, let mentions):
            path = root + "/messages"
            try mentions.forEach(ConversationIdentifier.validate)
            fields = [
                "clientMessageId": key, "type": files.isEmpty ? "TEXT" : "IMAGE",
                "content": content, "fileMetadataIds": files,
                "mentionedMemberIds": mentions.compactMap(Int64.init),
            ]
            if let reply {
                try ConversationIdentifier.validate(reply)
                fields["replyToId"] = Int64(reply)
            }
        case .react(let message, let emoji, let adding):
            try ConversationIdentifier.validate(message)
            path = root + "/messages/\(message)/reactions/" + (adding ? "add" : "remove")
            fields["emoji"] = emoji
        case .edit(let message, let content):
            try ConversationIdentifier.validate(message)
            path = root + "/messages/\(message)/edit"
            fields["content"] = content
        case .delete(let message):
            try ConversationIdentifier.validate(message)
            path = root + "/messages/\(message)/delete"
        case .read(let message):
            try ConversationIdentifier.validate(message)
            path = root + "/read"
            fields["lastReadMessageId"] = Int64(message)
        }
        body = String(decoding: try JSONSerialization.data(withJSONObject: fields), as: UTF8.self)
    }
}

private struct ConversationFrameReader {
    let socket: URLSessionWebSocketTask
    private var buffer = Data()

    init(socket: URLSessionWebSocketTask) { self.socket = socket }

    mutating func next() async throws -> (command: String, body: Data) {
        while true {
            if let end = buffer.firstIndex(of: 0) {
                let frame = String(decoding: buffer[..<end], as: UTF8.self)
                    .replacingOccurrences(of: "\r\n", with: "\n")
                    .drop(while: { $0 == "\n" })
                buffer.removeSubrange(...end)
                guard let separator = frame.range(of: "\n\n"),
                    let command = frame[..<separator.lowerBound].split(separator: "\n").first
                else { throw ConversationFailure("대화 응답을 읽을 수 없어요.") }
                return (String(command), Data(frame[separator.upperBound...].utf8))
            }
            switch try await socket.receive() {
            case .string(let string): buffer.append(contentsOf: string.utf8)
            case .data(let data): buffer.append(data)
            @unknown default: throw ConversationFailure("지원하지 않는 대화 응답이에요.")
            }
            guard buffer.count < 2_097_152 else { throw ConversationFailure("응답이 너무 커요.") }
        }
    }
}
