//
//  CommunityPostRepository.swift
//  CommunityData
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import CoreNetwork
import Foundation
import Moya
import Synchronization
import UMCFoundation

public struct LiveCommunityPostRepository: CommunityPostRepository {
    private let adapter: MoyaNetworkAdapter
    private let environment: NetworkEnvironment

    private let writes: CommunityPostWrites

    public init(adapter: MoyaNetworkAdapter, environment: NetworkEnvironment,
                accountID: String, defaults: UserDefaults = .standard) {
        writes = .init(defaults: defaults, scope: environment.baseURL.absoluteString + "|" + accountID)
        self.adapter = adapter
        self.environment = environment
    }

    public func posts(
        scope: CommunityPostScope, category: CommunityPostCategory?, keyword: String,
        page: String
    ) async throws -> CommunityPostPage {
        let path = keyword.isEmpty ? (scope == .all ? "" : "/" + scope.rawValue) : "/search"
        let query = PostQuery(
            page: page, category: scope == .all && keyword.isEmpty ? category : nil,
            keyword: keyword)
        let result: CommunityPostPageDTO = try await request(
            path,
            task: .requestParameters(
                parameters: query.parameters, encoding: URLEncoding.queryString))
        let next =
            result.hasNext ? Int(result.page).flatMap { $0 < Int.max ? String($0 + 1) : nil } : nil
        return .init(values: result.content.map(\.model), cursor: next)
    }

    public func post(id: String) async throws -> CommunityPost {
        try ConversationIdentifier.validate(id)
        let value: CommunityPostDTO = try await request("/" + id)
        return value.model
    }

    public func comments(id: String) async throws -> [CommunityPostComment] {
        try ConversationIdentifier.validate(id)
        let rows: [CommunityPostCommentDTO] = try await request("/\(id)/comments")
        return rows.map(\.model)
    }

    public func save(
        id: String?, title: String, content: String, category: CommunityPostCategory,
        meeting: CommunityPostMeeting?
    ) async throws -> CommunityPost {
        if let id { try ConversationIdentifier.validate(id) }
        var path = id.map { "/" + $0 } ?? ""
        let task: Moya.Task
        if category == .lightning {
            guard let meeting, let count = Int32(meeting.maxParticipants), count > 0 else {
                throw PostInputFailure.invalidMeeting
            }
            path += "/lightning"
            task = .requestJSONEncodable(
                MeetingBody(
                    title: title, content: content,
                    meetAt: meeting.meetAt, location: meeting.location, maxParticipants: count,
                    openChatUrl: meeting.openChatUrl))
        } else {
            task = .requestJSONEncodable(
                PostBody(
                    title: title, content: content,
                    category: category.rawValue))
        }
        if id != nil {
            let row: CommunityPostDTO = try await request(path, method: .patch, task: task)
            return row.model
        }
        guard try pendingWrite(postID: nil) == nil else { throw CommunityPostWriteFailure.unconfirmed }
        let rows = try await posts(scope: .my, category: nil, keyword: "", page: "0").values
        let intent = try intent(
            .post(title: title, content: content, category: category, meeting: meeting),
            ids: rows.map(\.id))
        return try await submit(intent) {
            let row: CommunityPostDTO = try await request(path, method: .post, task: task)
            return row.model
        }
    }

    public func pendingWrite(postID: String?) throws -> CommunityPostIntent? {
        try writes.pending(postID)
    }

    public func discard(_ intent: CommunityPostIntent) throws { try writes.discard(intent) }

    public func check(_ intent: CommunityPostIntent) async throws -> String {
        guard let stored = try writes.pending(intent.postID), stored.id == intent.id else {
            throw CommunityPostWriteFailure.unconfirmed
        }
        switch stored.draft {
        case let .post(title, content, category, meeting):
            let rows = try await posts(scope: .my, category: nil, keyword: "", page: "0").values
            let candidates = rows.filter {
                (Int64($0.id) ?? 0) > stored.baseline && $0.title == title && $0.content == content
                    && $0.category == category.rawValue && Self.sameMeeting($0.meeting, meeting)
            }
            if candidates.isEmpty { return "최근 내 게시글에서 일치하는 글을 찾지 못했어요." }
            let ids = candidates.map(\.id).joined(separator: ", ")
            return "내용이 같은 내 게시글 번호: " + ids + ". 이 작업으로 등록됐는지는 확인할 수 없어요."
        case let .comment(postID, parentID, content):
            let rows = try await comments(id: postID)
            let matches = rows.filter {
                (Int64($0.id) ?? 0) > stored.baseline && $0.isAuthor && $0.content == content
            }
            if matches.isEmpty { return "일치하는 내 댓글을 찾지 못했어요." }
            if let parentID {
                return "같은 내용의 내 댓글이 있지만 원댓글 번호 " + parentID + "에 달린 답글인지는 확인할 수 없어요."
            }
            return "같은 내용의 내 댓글이 있지만 이 작업으로 등록됐는지는 확인할 수 없어요."
        }
    }

    private func intent(_ draft: CommunityPostIntent.Draft, ids: [String]) throws -> CommunityPostIntent {
        let numbers = ids.compactMap(Int64.init)
        guard ids.count == numbers.count else { throw NetworkError.invalidResponse }
        return CommunityPostIntent(draft: draft, baseline: numbers.max() ?? 0)
    }

    private func submit<T>(_ intent: CommunityPostIntent, create: () async throws -> T) async throws -> T {
        try _Concurrency.Task.checkCancellation()
        try writes.begin(intent)
        defer { writes.finish(intent) }
        do {
            let result = try await create()
            try writes.remove(intent)
            return result
        } catch {
            if case NetworkError.requestFailed(let status, _) = error, (400..<500).contains(status) {
                try writes.remove(intent)
                throw error
            }
            throw CommunityPostWriteFailure.unconfirmed
        }
    }

    private static func sameMeeting(_ lhs: CommunityPostMeeting?, _ rhs: CommunityPostMeeting?) -> Bool {
        guard let lhs, let rhs else { return lhs == nil && rhs == nil }
        func instant(_ raw: String) -> Date? {
            (try? Date(raw, strategy: .iso8601))
                ?? (try? Date(raw, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)))
        }
        return lhs.location == rhs.location && lhs.openChatUrl == rhs.openChatUrl
            && Int32(lhs.maxParticipants) == Int32(rhs.maxParticipants)
            && (lhs.meetAt == rhs.meetAt || instant(lhs.meetAt).map { $0 == instant(rhs.meetAt) } == true)
    }

    public func perform(_ action: CommunityPostAction, id: String) async throws -> Bool? {
        try ConversationIdentifier.validate(id)
        let root = "/" + id
        switch action {
        case .like:
            let value: CommunityPostToggleDTO = try await request(root + "/like", method: .post)
            return value.liked
        case .scrap:
            let value: CommunityPostToggleDTO = try await request(root + "/scrap", method: .post)
            return value.scrapped
        case .delete:
            let _: EmptyResult = try await request(root, method: .delete)
        case .comment(let content, let parentID):
            if let parentID { try ConversationIdentifier.validate(parentID) }
            let body = CommentBody(content: content, parentId: parentID.flatMap(Int64.init))
            guard try pendingWrite(postID: id) == nil else { throw CommunityPostWriteFailure.unconfirmed }
            let rows = try await comments(id: id)
            let intent = try intent(.comment(postID: id, parentID: parentID, content: content),
                                    ids: rows.map(\.id))
            _ = try await submit(intent) {
                let row: CommunityPostCommentDTO = try await request(
                    root + "/comments", method: .post, task: .requestJSONEncodable(body))
                return row.model
            }
        case .deleteComment(let comment):
            try ConversationIdentifier.validate(comment)
            let _: EmptyResult = try await request(root + "/comments/" + comment, method: .delete)
        case .likeComment(let comment):
            try ConversationIdentifier.validate(comment)
            let value: CommunityPostToggleDTO = try await request(
                root + "/comments/\(comment)/like",
                method: .post)
            return value.liked
        }
        return nil
    }

    private func request<T: Codable>(
        _ suffix: String, method: Moya.Method = .get,
        task: Moya.Task = .requestPlain
    ) async throws -> T {
        let response = try await adapter.request(
            PostTarget(
                environment: environment,
                path: "/api/v1/posts" + suffix, method: method, task: task))
        if response.data.isEmpty, let empty = EmptyResult() as? T { return empty }
        return try JSONDecoder().decode(APIResponse<T>.self, from: response.data).unwrap()
    }
}

private struct PostTarget: BaseTargetType {
    let environment: NetworkEnvironment
    let path: String
    let method: Moya.Method
    let task: Moya.Task
}

private struct PostQuery {
    let page: String
    let category: CommunityPostCategory?
    let keyword: String
    var parameters: [String: String] {
        var fields = ["page": page, "size": "20"]
        if let category { fields["category"] = category.rawValue }
        if !keyword.isEmpty { fields["keyword"] = keyword }
        return fields
    }
}

private struct PostBody: Encodable {
    let title: String
    let content: String
    let category: String
}

private struct MeetingBody: Encodable {
    let title: String
    let content: String
    let meetAt: String
    let location: String
    let maxParticipants: Int32
    let openChatUrl: String
}

private struct CommentBody: Encodable {
    let content: String
    let parentId: Int64?
}

private enum PostInputFailure: LocalizedError {
    case invalidMeeting
    var errorDescription: String? { "모임의 최대 참여 인원을 확인해 주세요." }
}

private struct CommunityPostToggleDTO: Codable {
    let liked: Bool?
    let scrapped: Bool?
    private enum CodingKeys: CodingKey { case liked, scrapped }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        liked = try values.decodeIfPresent(Bool.self, forKey: .liked)
        scrapped = try values.decodeIfPresent(Bool.self, forKey: .scrapped)
    }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(liked, forKey: .liked)
        try values.encodeIfPresent(scrapped, forKey: .scrapped)
    }
}

// Serialize compare-and-set across repository instances using the same defaults suite.
private final class CommunityPostWrites: @unchecked Sendable {
    private static let running = Mutex<Set<UUID>>([])
    private let defaults: UserDefaults
    private let scope: String

    init(defaults: UserDefaults, scope: String) {
        self.defaults = defaults
        self.scope = scope
    }

    private func key(_ id: String?) -> String {
        "community.pending.v1|" + scope + "|" + (id ?? "post")
    }

    private func load(_ id: String?) throws -> CommunityPostIntent? {
        guard let data = defaults.data(forKey: key(id)) else { return nil }
        return try JSONDecoder().decode(CommunityPostIntent.self, from: data)
    }

    func pending(_ id: String?) throws -> CommunityPostIntent? {
        try Self.running.withLock { _ in try load(id) }
    }

    func begin(_ intent: CommunityPostIntent) throws {
        try Self.running.withLock { running in
            guard try load(intent.postID) == nil else { throw CommunityPostWriteFailure.unconfirmed }
            defaults.set(try JSONEncoder().encode(intent), forKey: key(intent.postID))
            guard defaults.synchronize() else { throw CommunityPostWriteFailure.storageUnavailable }
            running.insert(intent.id)
        }
    }

    func finish(_ intent: CommunityPostIntent) {
        _ = Self.running.withLock { $0.remove(intent.id) }
    }

    func remove(_ intent: CommunityPostIntent) throws {
        try Self.running.withLock { _ in try clear(intent) }
    }

    func discard(_ intent: CommunityPostIntent) throws {
        try Self.running.withLock { running in
            guard !running.contains(intent.id) else { throw CommunityPostWriteFailure.inProgress }
            try clear(intent)
        }
    }

    private func clear(_ intent: CommunityPostIntent) throws {
        guard try load(intent.postID)?.id == intent.id else { throw CommunityPostWriteFailure.unconfirmed }
        defaults.removeObject(forKey: key(intent.postID))
        guard defaults.synchronize() else { throw CommunityPostWriteFailure.storageUnavailable }
    }
}
