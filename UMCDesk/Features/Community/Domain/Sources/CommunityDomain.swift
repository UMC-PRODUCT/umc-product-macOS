//
//  CommunityDomain.swift
//  CommunityDomain
//
//  Created by euijjang97 on 10/6/26.
//

import Foundation

public struct CommunityThread: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let description: String?
    public let icon: String
    public let isPinned: Bool
    public let isMuted: Bool
    public let isJoined: Bool
    public let membershipState: String?
    public let unread: String

    public init(id: String, title: String, description: String?, icon: String,
                isPinned: Bool, isMuted: Bool, isJoined: Bool, membershipState: String?, unread: String) {
        self.id = id
        self.title = title
        self.description = description
        self.icon = icon
        self.isPinned = isPinned
        self.isMuted = isMuted
        self.isJoined = isJoined
        self.membershipState = membershipState
        self.unread = unread
    }
}

public struct ThreadMessage: Identifiable, Sendable {
    public let id: String
    public let author: String
    public let text: String

    public init(id: String, author: String, text: String) {
        self.id = id
        self.author = author
        self.text = text
    }
}

public struct ThreadPage<Value: Sendable>: Sendable {
    public let values: [Value]
    public let cursor: String?
    public init(values: [Value], cursor: String?) {
        self.values = values
        self.cursor = cursor
    }
}

public enum ThreadPreference: String, Sendable { case pin, mute }

public protocol CommunityThreadRepository: Sendable {
    func threads(query: String, filter: String, offset: String?) async throws -> ThreadPage<CommunityThread>
    func messages(id: String, before: String?) async throws -> ThreadPage<ThreadMessage>
    func update(_ preference: ThreadPreference, enabled: Bool, id: String) async throws -> CommunityThread
    func create(title: String, description: String, category: String, icon: String) async throws -> CommunityThread
}
