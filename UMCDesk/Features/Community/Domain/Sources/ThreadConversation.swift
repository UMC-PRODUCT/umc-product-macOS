//
//  ThreadConversation.swift
//  CommunityDomain
//
//  Created by euijjang97 on 11/23/26.
//

import Foundation

public struct ThreadConversationReaction: Equatable, Sendable {
    public let emoji: String
    public let count: String
    public let reactedByMe: Bool

    public init(
        emoji: String,
        count: String,
        reactedByMe: Bool
    ) {
        self.emoji = emoji
        self.count = count
        self.reactedByMe = reactedByMe
    }
}

public struct ThreadConversationFile: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String
    public let url: URL?

    public init(
        id: String,
        name: String,
        url: URL?
    ) {
        self.id = id
        self.name = name
        self.url = url
    }
}

public struct ThreadConversationMessage: Identifiable, Equatable, Sendable {
    public let id: String
    public let authorID: String?
    public let author: String
    public let text: String
    public let createdAt: String?
    public let replyID: String?
    public let files: [ThreadConversationFile]
    public let reactions: [ThreadConversationReaction]
    public let isHidden: Bool

    public init(
        id: String,
        authorID: String?,
        author: String,
        text: String,
        createdAt: String?,
        replyID: String?,
        files: [ThreadConversationFile],
        reactions: [ThreadConversationReaction],
        isHidden: Bool
    ) {
        self.id = id
        self.authorID = authorID
        self.author = author
        self.text = text
        self.createdAt = createdAt
        self.replyID = replyID
        self.files = files
        self.reactions = reactions
        self.isHidden = isHidden
    }
}

public enum ThreadConversationCommand: Sendable {
    case create(
        key: String, content: String, files: [String], reply: String?, mentions: [String] = [])
    case react(message: String, emoji: String, adding: Bool)
    case edit(message: String, content: String)
    case delete(message: String)
    case read(message: String)
}

public protocol ThreadConversationRepository: Sendable {
    func history(thread: String, before: String?) async throws -> ThreadPage<
        ThreadConversationMessage
    >
    func members(thread: String, query: String) async throws -> [ThreadManagementPerson]
    func perform(_ command: ThreadConversationCommand, thread: String) async throws
    func observeChanges(
        thread: String, changed: @escaping @Sendable () async -> Void
    ) async throws
    func upload(name: String, contentType: String, data: Data) async throws -> String
}

public enum ThreadConversationRejection: LocalizedError {
    case rateLimited
    case denied(String)

    public var errorDescription: String? {
        switch self {
        case .rateLimited: "전송 요청이 많아요. 잠시 후 다시 시도해 주세요."
        case .denied(let reason): reason
        }
    }
}
