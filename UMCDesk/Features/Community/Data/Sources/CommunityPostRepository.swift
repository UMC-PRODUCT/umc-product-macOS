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

public struct LiveCommunityPostRepository: CommunityPostRepository {
    private let adapter: MoyaNetworkAdapter
    private let environment: NetworkEnvironment

    public init(adapter: MoyaNetworkAdapter, environment: NetworkEnvironment) {
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
        let row: CommunityPostDTO = try await request(
            path, method: id == nil ? .post : .patch,
            task: task)
        return row.model
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
            let _: CommunityPostCommentDTO = try await request(
                root + "/comments", method: .post,
                task: .requestJSONEncodable(body))
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
