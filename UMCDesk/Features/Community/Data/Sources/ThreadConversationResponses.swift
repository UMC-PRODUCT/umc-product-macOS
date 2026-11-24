//
//  ThreadConversationResponses.swift
//  CommunityData
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import Foundation
import UMCFoundation

struct ConversationHistoryDTO: Codable {
    let messages: [ConversationMessageDTO]
    let hasMore: Bool
    let nextBefore: String?

    private enum CodingKeys: CodingKey {
        case messages
        case hasMore
        case nextBefore
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        messages = try values.decode([ConversationMessageDTO].self, forKey: .messages)
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

struct ConversationMessageDTO: Codable {
    let messageId: String
    let senderId: String?
    let senderName: String?
    let content: String?
    let createdAt: String?
    let deletedAt: String?
    let status: String?
    let isSenderBlocked: Bool
    let replyTo: ConversationReplyDTO?
    let files: [ConversationFileDTO]?
    let reactions: [ConversationReactionDTO]?

    private enum CodingKeys: CodingKey {
        case messageId
        case senderId
        case senderName
        case content
        case createdAt
        case deletedAt
        case status
        case isSenderBlocked
        case replyTo
        case files
        case reactions
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        messageId = try values.decodeFlexibleString(forKey: .messageId)
        senderId = try values.decodeFlexibleStringIfPresent(forKey: .senderId)
        senderName = try values.decodeIfPresent(String.self, forKey: .senderName)
        content = try values.decodeIfPresent(String.self, forKey: .content)
        createdAt = try values.decodeIfPresent(String.self, forKey: .createdAt)
        deletedAt = try values.decodeIfPresent(String.self, forKey: .deletedAt)
        status = try values.decodeIfPresent(String.self, forKey: .status)
        isSenderBlocked = try values.decode(Bool.self, forKey: .isSenderBlocked)
        replyTo = try values.decodeIfPresent(ConversationReplyDTO.self, forKey: .replyTo)
        files = try values.decodeIfPresent([ConversationFileDTO].self, forKey: .files)
        reactions = try values.decodeIfPresent([ConversationReactionDTO].self, forKey: .reactions)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(messageId, forKey: .messageId)
        try values.encodeIfPresent(senderId, forKey: .senderId)
        try values.encodeIfPresent(senderName, forKey: .senderName)
        try values.encodeIfPresent(content, forKey: .content)
        try values.encodeIfPresent(createdAt, forKey: .createdAt)
        try values.encodeIfPresent(deletedAt, forKey: .deletedAt)
        try values.encodeIfPresent(status, forKey: .status)
        try values.encode(isSenderBlocked, forKey: .isSenderBlocked)
        try values.encodeIfPresent(replyTo, forKey: .replyTo)
        try values.encodeIfPresent(files, forKey: .files)
        try values.encodeIfPresent(reactions, forKey: .reactions)
    }
}

struct ConversationReplyDTO: Codable {
    let messageId: String

    private enum CodingKeys: CodingKey {
        case messageId
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        messageId = try values.decodeFlexibleString(forKey: .messageId)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(messageId, forKey: .messageId)
    }
}

struct ConversationFileDTO: Codable {
    let fileId: String
    let fileName: String
    let fileUrl: String?

    private enum CodingKeys: CodingKey {
        case fileId
        case fileName
        case fileUrl
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fileId = try values.decodeFlexibleString(forKey: .fileId)
        fileName = try values.decode(String.self, forKey: .fileName)
        fileUrl = try values.decodeIfPresent(String.self, forKey: .fileUrl)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(fileId, forKey: .fileId)
        try values.encode(fileName, forKey: .fileName)
        try values.encodeIfPresent(fileUrl, forKey: .fileUrl)
    }
}

struct ConversationReactionDTO: Codable {
    let emoji: String
    let count: String
    let reactedByMe: Bool

    private enum CodingKeys: CodingKey {
        case emoji
        case count
        case reactedByMe
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        emoji = try values.decode(String.self, forKey: .emoji)
        count = try values.decodeFlexibleString(forKey: .count)
        reactedByMe = try values.decode(Bool.self, forKey: .reactedByMe)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(emoji, forKey: .emoji)
        try values.encode(count, forKey: .count)
        try values.encode(reactedByMe, forKey: .reactedByMe)
    }
}

struct ConversationUploadDTO: Codable {
    let fileId: String
    let uploadUrl: URL
    let uploadMethod: String
    let headers: [String: String]

    private enum CodingKeys: CodingKey {
        case fileId
        case uploadUrl
        case uploadMethod
        case headers
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fileId = try values.decodeFlexibleString(forKey: .fileId)
        uploadUrl = try values.decode(URL.self, forKey: .uploadUrl)
        uploadMethod = try values.decode(String.self, forKey: .uploadMethod)
        headers = try values.decode([String: String].self, forKey: .headers)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(fileId, forKey: .fileId)
        try values.encode(uploadUrl, forKey: .uploadUrl)
        try values.encode(uploadMethod, forKey: .uploadMethod)
        try values.encode(headers, forKey: .headers)
    }
}

extension ConversationMessageDTO {
    var model: ThreadConversationMessage { model(localBase: nil) }

    func model(localBase: URL?) -> ThreadConversationMessage {
        let hidden = isSenderBlocked || deletedAt != nil || status == "DELETED"
        let placeholder = isSenderBlocked ? "차단한 회원의 메시지" : "삭제된 메시지"
        return ThreadConversationMessage(
            id: messageId, authorID: hidden ? nil : senderId,
            author: hidden ? "" : senderName ?? "", text: hidden ? placeholder : content ?? "",
            createdAt: createdAt, replyID: hidden ? nil : replyTo?.messageId,
            files: hidden
                ? []
                : (files ?? []).map {
                    let url = $0.fileUrl.flatMap(URL.init(string:))
                    return ThreadConversationFile(
                        id: $0.fileId, name: $0.fileName,
                        url: Self.imageURL(url, localBase: localBase))
                },
            reactions: hidden
                ? []
                : (reactions ?? []).map {
                    ThreadConversationReaction(
                        emoji: $0.emoji, count: $0.count,
                        reactedByMe: $0.reactedByMe)
                }, isHidden: hidden
        )
    }

    private static func imageURL(_ url: URL?, localBase: URL?) -> URL? {
        guard let url else { return nil }
        if url.scheme == "https" { return url }
        #if DEBUG
            if let localBase, localBase.scheme == "http", localBase.host == "127.0.0.1",
                url.scheme == localBase.scheme, url.host == localBase.host,
                url.port == localBase.port
            {
                return url
            }
        #endif
        return nil
    }
}
