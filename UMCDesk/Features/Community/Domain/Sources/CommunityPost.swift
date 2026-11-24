//
//  CommunityPost.swift
//  CommunityDomain
//
//  Created by euijjang97 on 11/23/26.
//

import Foundation

public struct CommunityPostMeeting: Codable, Equatable, Sendable {
    public let meetAt: String
    public let location: String
    public let maxParticipants: String
    public let openChatUrl: String

    public init(
        meetAt: String,
        location: String,
        maxParticipants: String,
        openChatUrl: String
    ) {
        self.meetAt = meetAt
        self.location = location
        self.maxParticipants = maxParticipants
        self.openChatUrl = openChatUrl
    }
}

public struct CommunityPost: Identifiable, Equatable, Sendable {
    public let id: String
    public let title: String
    public let content: String
    public let category: String
    public let authorMemberID: String?
    public let author: String?
    public let date: String?
    public let commentCount: String
    public let likeCount: String
    public let liked: Bool
    public let scrapCount: String?
    public let scrapped: Bool
    public let meeting: CommunityPostMeeting?

    public init(
        id: String,
        title: String,
        content: String,
        category: String,
        authorMemberID: String?,
        author: String?,
        date: String?,
        commentCount: String,
        likeCount: String,
        liked: Bool,
        scrapCount: String?,
        scrapped: Bool,
        meeting: CommunityPostMeeting?
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.category = category
        self.authorMemberID = authorMemberID
        self.author = author
        self.date = date
        self.commentCount = commentCount
        self.likeCount = likeCount
        self.liked = liked
        self.scrapCount = scrapCount
        self.scrapped = scrapped
        self.meeting = meeting
    }
}

public struct CommunityPostComment: Identifiable, Equatable, Sendable {
    public let id: String
    public let author: String?
    public let content: String
    public let isAuthor: Bool
    public let date: String?

    public init(
        id: String,
        author: String?,
        content: String,
        isAuthor: Bool,
        date: String?
    ) {
        self.id = id
        self.author = author
        self.content = content
        self.isAuthor = isAuthor
        self.date = date
    }
}

public struct CommunityPostPage: Sendable {
    public let values: [CommunityPost]
    public let cursor: String?

    public init(values: [CommunityPost], cursor: String?) {
        self.values = values
        self.cursor = cursor
    }
}

public enum CommunityPostScope: String, CaseIterable, Sendable {
    case all, my, commented, scrapped
}

public enum CommunityPostCategory: String, Codable, CaseIterable, Sendable {
    case free = "FREE"
    case question = "QUESTION"
    case information = "INFORMATION"
    case habit = "HABIT"
    case lightning = "LIGHTNING"
}

public enum CommunityPostAction: Sendable {
    case like, scrap, delete
    case comment(String, parentID: String?)
    case deleteComment(String)
    case likeComment(String)
}

public struct CommunityPostIntent: Codable, Identifiable, Sendable {
    public enum Draft: Codable, Sendable {
        case post(title: String, content: String, category: CommunityPostCategory,
                  meeting: CommunityPostMeeting?)
        case comment(postID: String, parentID: String?, content: String)
    }

    public let id: UUID
    public let draft: Draft
    public let baseline: Int64

    public init(draft: Draft, baseline: Int64) {
        self.id = UUID()
        self.draft = draft
        self.baseline = baseline
    }

    public var postID: String? {
        if case .comment(let id, _, _) = draft { return id }
        return nil
    }
}

public protocol CommunityPostRepository: Sendable {
    func pendingWrite(postID: String?) throws -> CommunityPostIntent?
    func discard(_ intent: CommunityPostIntent) throws
    func check(_ intent: CommunityPostIntent) async throws -> String
    func posts(
        scope: CommunityPostScope, category: CommunityPostCategory?, keyword: String,
        page: String
    ) async throws -> CommunityPostPage
    func post(id: String) async throws -> CommunityPost
    func comments(id: String) async throws -> [CommunityPostComment]
    func save(
        id: String?, title: String, content: String, category: CommunityPostCategory,
        meeting: CommunityPostMeeting?
    ) async throws -> CommunityPost
    func perform(_ action: CommunityPostAction, id: String) async throws -> Bool?
}

public enum CommunityPostWriteFailure: LocalizedError, Sendable {
    case inProgress, unconfirmed, storageUnavailable

    public var errorDescription: String? {
        switch self {
        case .storageUnavailable: "작성 기록을 읽거나 저장할 수 없어요."
        case .inProgress: "같은 내용을 등록하고 있어요."
        case .unconfirmed: "등록 결과를 확인하지 못했어요. 같은 내용으로 다시 누르면 결과를 조회해요."
        }
    }
}
