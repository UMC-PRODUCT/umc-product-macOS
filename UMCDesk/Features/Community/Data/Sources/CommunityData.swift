//
//  CommunityData.swift
//  CommunityData
//
//  Created by euijjang97 on 10/6/26.
//

import CommunityDomain
import CoreNetwork
import Foundation
import Moya
import UMCFoundation

public struct LiveCommunityThreadRepository: CommunityThreadRepository {
    private let adapter: MoyaNetworkAdapter
    private let environment: NetworkEnvironment

    public init(adapter: MoyaNetworkAdapter, environment: NetworkEnvironment) {
        self.adapter = adapter
        self.environment = environment
    }

    public func thread(id: String) async throws -> CommunityThread {
        try ConversationIdentifier.validate(id)
        let detail: ThreadResponse = try await request("/" + id)
        return detail.model
    }

    public func threads(query: String, filter: String, offset: String?) async throws -> ThreadPage<CommunityThread> {
        let fields = ThreadListQuery(filter: filter, query: query, offset: offset)
        let page: ListResponse = try await request("", task: .requestParameters(
            parameters: fields.parameters, encoding: URLEncoding.queryString))
        var ids = Set<String>()
        let rows = (page.pinned + page.threads).filter { ids.insert($0.threadId).inserted }
        return ThreadPage(values: rows.map(\.model), cursor: page.nextOffset)
    }

    public func messages(id: String, before: String?) async throws -> ThreadPage<ThreadMessage> {
        let fields = HistoryQuery(before: before)
        let page: MessagePageResponse = try await request("/" + id + "/messages",
            task: .requestParameters(parameters: fields.parameters, encoding: URLEncoding.queryString))
        return ThreadPage(values: page.messages.map(\.model), cursor: page.hasMore ? page.nextBefore : nil)
    }

    public func update(_ preference: ThreadPreference, enabled: Bool, id: String) async throws -> CommunityThread {
        let item: ThreadResponse = try await request("/" + id + "/" + preference.rawValue,
            method: enabled ? .post : .delete)
        return item.model
    }

    public func create(title: String, description: String, category: String, icon: String) async throws -> CommunityThread {
        let body = CreateThread(title: title, description: description, category: category, icon: icon)
        let item: ThreadResponse = try await request("", method: .post, task: .requestJSONEncodable(body))
        return item.model
    }

    private func request<T: Codable>(_ suffix: String, method: Moya.Method = .get,
                                     task: Moya.Task = .requestPlain) async throws -> T {
        let response = try await adapter.request(ThreadTarget(environment: environment,
            path: "/api/v1/community/threads" + suffix, method: method, task: task))
        return try JSONDecoder().decode(APIResponse<T>.self, from: response.data).unwrap()
    }
}

private struct ThreadTarget: BaseTargetType {
    let environment: NetworkEnvironment
    let path: String
    let method: Moya.Method
    let task: Moya.Task
}

private struct ThreadListQuery {
    let filter: String
    let query: String
    let offset: String?
    var parameters: [String: String] {
        var fields = ["filter": filter, "offset": offset ?? "0"]
        if !query.isEmpty { fields["q"] = query }
        return fields
    }
}

private struct HistoryQuery {
    let before: String?
    var parameters: [String: String] { before.map { ["before": $0] } ?? [:] }
}

private struct CreateThread: Encodable {
    let title: String
    let description: String
    let category: String
    let icon: String
}

struct ThreadResponse: Codable {
    let threadId: String
    let title: String
    let description: String?
    let icon: String
    let isPinned: Bool
    let isMuted: Bool
    let isJoined: Bool
    let membershipState: String?
    let unreadCount: String
    let myRole: ThreadManagementRole?
    let memberCount: String?
    let shareUrl: String?
    enum CodingKeys: CodingKey {
        case threadId, title, description, icon, isPinned, isMuted, isJoined, membershipState
        case unreadCount, myRole, memberCount, shareUrl
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        threadId = try values.decodeFlexibleString(forKey: .threadId)
        title = try values.decode(String.self, forKey: .title)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        icon = try values.decode(String.self, forKey: .icon)
        isPinned = try values.decode(Bool.self, forKey: .isPinned)
        isMuted = try values.decode(Bool.self, forKey: .isMuted)
        isJoined = try values.decode(Bool.self, forKey: .isJoined)
        membershipState = try values.decodeIfPresent(String.self, forKey: .membershipState)
        myRole = try values.decodeIfPresent(ThreadManagementRole.self, forKey: .myRole)
        memberCount = try values.decodeFlexibleStringIfPresent(forKey: .memberCount)
        shareUrl = try? values.decode(String.self, forKey: .shareUrl)
        unreadCount = try values.decodeFlexibleString(forKey: .unreadCount)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(threadId, forKey: .threadId)
        try values.encode(title, forKey: .title)
        try values.encodeIfPresent(description, forKey: .description)
        try values.encode(icon, forKey: .icon)
        try values.encode(isPinned, forKey: .isPinned)
        try values.encode(isMuted, forKey: .isMuted)
        try values.encode(isJoined, forKey: .isJoined)
        try values.encodeIfPresent(membershipState, forKey: .membershipState)
        try values.encodeIfPresent(myRole, forKey: .myRole)
        try values.encodeIfPresent(memberCount, forKey: .memberCount)
        try values.encodeIfPresent(shareUrl, forKey: .shareUrl)
        try values.encode(unreadCount, forKey: .unreadCount)
    }

    var model: CommunityThread {
        CommunityThread(id: threadId, title: title, description: description, icon: icon,
            isPinned: isPinned, isMuted: isMuted, isJoined: isJoined, membershipState: membershipState,
            unread: unreadCount, myRole: myRole, memberCount: memberCount,
            shareURL: shareUrl.flatMap { URL(string: $0, encodingInvalidCharacters: false) })
    }
}

private struct ListResponse: Codable {
    let pinned: [ThreadResponse]
    let threads: [ThreadResponse]
    let nextOffset: String?
    enum CodingKeys: CodingKey {
        case pinned, threads, nextOffset
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        pinned = try values.decode([ThreadResponse].self, forKey: .pinned)
        threads = try values.decode([ThreadResponse].self, forKey: .threads)
        nextOffset = try values.decodeFlexibleStringIfPresent(forKey: .nextOffset)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(pinned, forKey: .pinned)
        try values.encode(threads, forKey: .threads)
        try values.encodeIfPresent(nextOffset, forKey: .nextOffset)
    }
}

private struct MessageResponse: Codable {
    let messageId: String
    let senderName: String?
    let content: String?
    let deletedAt: String?
    let isSenderBlocked: Bool
    enum CodingKeys: CodingKey {
        case messageId, senderName, content, deletedAt, isSenderBlocked
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        messageId = try values.decodeFlexibleString(forKey: .messageId)
        senderName = try values.decodeIfPresent(String.self, forKey: .senderName)
        content = try values.decodeIfPresent(String.self, forKey: .content)
        deletedAt = try values.decodeIfPresent(String.self, forKey: .deletedAt)
        isSenderBlocked = try values.decode(Bool.self, forKey: .isSenderBlocked)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(messageId, forKey: .messageId)
        try values.encodeIfPresent(senderName, forKey: .senderName)
        try values.encodeIfPresent(content, forKey: .content)
        try values.encodeIfPresent(deletedAt, forKey: .deletedAt)
        try values.encode(isSenderBlocked, forKey: .isSenderBlocked)
    }

    var model: ThreadMessage {
        if isSenderBlocked { return .init(id: messageId, author: "", text: "차단한 회원의 메시지") }
        if deletedAt != nil { return .init(id: messageId, author: "", text: "삭제된 메시지") }
        return .init(id: messageId, author: senderName ?? "", text: content ?? "첨부 메시지")
    }
}

private struct MessagePageResponse: Codable {
    let messages: [MessageResponse]
    let hasMore: Bool
    let nextBefore: String?
    enum CodingKeys: CodingKey {
        case messages, hasMore, nextBefore
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        messages = try values.decode([MessageResponse].self, forKey: .messages)
        hasMore = try values.decode(Bool.self, forKey: .hasMore)
        nextBefore = try values.decodeFlexibleStringIfPresent(forKey: .nextBefore)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(messages, forKey: .messages)
        try values.encode(hasMore, forKey: .hasMore)
        try values.encodeIfPresent(nextBefore, forKey: .nextBefore)
    }
}
