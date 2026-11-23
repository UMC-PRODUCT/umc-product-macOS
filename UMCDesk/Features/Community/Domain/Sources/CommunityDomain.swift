//
//  CommunityDomain.swift
//  CommunityDomain
//
//  Created by euijjang97 on 10/6/26.
//

import Foundation

public enum ThreadDetailError: LocalizedError {
    case accessDenied
    case deleted

    public var errorDescription: String? {
        switch self {
        case .accessDenied: "대화에 접근할 수 없어요."
        case .deleted: "삭제된 스레드예요"
        }
    }
}

public struct CommunityThread: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let description: String?
    public let category: String?
    public let icon: String
    public let isPinned: Bool
    public let isMuted: Bool
    public let isJoined: Bool
    public let membershipState: String?
    public let myRole: ThreadManagementRole?
    public let memberCount: String?
    public let unread: String
    public let shareURL: URL?

    public init(id: String, title: String, description: String?, icon: String,
                isPinned: Bool, isMuted: Bool, isJoined: Bool, membershipState: String?, unread: String,
                category: String? = nil, myRole: ThreadManagementRole? = nil, memberCount: String? = nil, shareURL: URL? = nil) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.icon = icon
        self.isPinned = isPinned
        self.isMuted = isMuted
        self.isJoined = isJoined
        self.membershipState = membershipState
        self.myRole = myRole
        self.memberCount = memberCount
        self.unread = unread
        if let shareURL, let parts = URLComponents(url: shareURL, resolvingAgainstBaseURL: false),
           parts.scheme?.lowercased() == "https", let host = parts.host, !host.isEmpty,
           parts.user == nil, parts.password == nil, parts.query == nil, parts.fragment == nil,
           let numericID = Int64(id), numericID > 0, String(numericID) == id,
           parts.percentEncodedPath == "/community/threads/" + id {
            self.shareURL = shareURL
        } else {
            self.shareURL = nil
        }
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
    func thread(id: String) async throws -> CommunityThread
    func threads(query: String, filter: String, offset: String?) async throws -> ThreadPage<CommunityThread>
    func messages(id: String, before: String?) async throws -> ThreadPage<ThreadMessage>
    func update(_ preference: ThreadPreference, enabled: Bool, id: String) async throws -> CommunityThread
    func create(title: String, description: String, category: String, icon: String) async throws -> CommunityThread
}
