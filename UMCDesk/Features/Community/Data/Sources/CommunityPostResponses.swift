//
//  CommunityPostResponses.swift
//  CommunityData
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import Foundation
import UMCFoundation

struct CommunityPostPageDTO: Codable {
    let content: [CommunityPostDTO]
    let page: String
    let hasNext: Bool

    enum CodingKeys: CodingKey {
        case content
        case page
        case hasNext
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        content = try values.decode([CommunityPostDTO].self, forKey: .content)
        page = try values.decodeFlexibleString(forKey: .page)
        hasNext = try values.decode(Bool.self, forKey: .hasNext)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(content, forKey: .content)
        try values.encode(page, forKey: .page)
        try values.encode(hasNext, forKey: .hasNext)
    }
}

struct CommunityPostDTO: Codable {
    let postId: String
    let title: String
    let content: String
    let category: String
    let authorMemberId: String?
    let authorName: String?
    let authorNickname: String?
    let createdAt: String?
    let writeTime: String?
    let commentCount: String
    let likeCount: String
    let isLiked: Bool
    let scrapCount: String?
    let isScrapped: Bool?
    let lightningInfo: CommunityPostMeetingDTO?

    enum CodingKeys: CodingKey {
        case postId
        case title
        case content
        case category
        case authorMemberId
        case authorName
        case authorNickname
        case createdAt
        case writeTime
        case commentCount
        case likeCount
        case isLiked
        case scrapCount
        case isScrapped
        case lightningInfo
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        postId = try values.decodeFlexibleString(forKey: .postId)
        title = try values.decode(String.self, forKey: .title)
        content = try values.decode(String.self, forKey: .content)
        category = try values.decode(String.self, forKey: .category)
        authorMemberId = try values.decodeFlexibleStringIfPresent(forKey: .authorMemberId)
        authorName = try values.decodeIfPresent(String.self, forKey: .authorName)
        authorNickname = try values.decodeIfPresent(String.self, forKey: .authorNickname)
        createdAt = try values.decodeIfPresent(String.self, forKey: .createdAt)
        writeTime = try values.decodeIfPresent(String.self, forKey: .writeTime)
        commentCount = try values.decodeFlexibleString(forKey: .commentCount)
        likeCount = try values.decodeFlexibleString(forKey: .likeCount)
        isLiked = try values.decode(Bool.self, forKey: .isLiked)
        scrapCount = try values.decodeFlexibleStringIfPresent(forKey: .scrapCount)
        isScrapped = try values.decodeIfPresent(Bool.self, forKey: .isScrapped)
        lightningInfo = try values.decodeIfPresent(
            CommunityPostMeetingDTO.self, forKey: .lightningInfo)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(postId, forKey: .postId)
        try values.encode(title, forKey: .title)
        try values.encode(content, forKey: .content)
        try values.encode(category, forKey: .category)
        try values.encodeIfPresent(authorMemberId, forKey: .authorMemberId)
        try values.encodeIfPresent(authorName, forKey: .authorName)
        try values.encodeIfPresent(authorNickname, forKey: .authorNickname)
        try values.encodeIfPresent(createdAt, forKey: .createdAt)
        try values.encodeIfPresent(writeTime, forKey: .writeTime)
        try values.encode(commentCount, forKey: .commentCount)
        try values.encode(likeCount, forKey: .likeCount)
        try values.encode(isLiked, forKey: .isLiked)
        try values.encodeIfPresent(scrapCount, forKey: .scrapCount)
        try values.encodeIfPresent(isScrapped, forKey: .isScrapped)
        try values.encodeIfPresent(lightningInfo, forKey: .lightningInfo)
    }
}

struct CommunityPostCommentDTO: Codable {
    let commentId: String
    let challengerName: String?
    let challengerNickname: String?
    let content: String
    let createdAt: String?
    let isAuthor: Bool

    enum CodingKeys: CodingKey {
        case commentId
        case challengerName
        case challengerNickname
        case content
        case createdAt
        case isAuthor
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        commentId = try values.decodeFlexibleString(forKey: .commentId)
        challengerName = try values.decodeIfPresent(String.self, forKey: .challengerName)
        challengerNickname = try values.decodeIfPresent(String.self, forKey: .challengerNickname)
        content = try values.decode(String.self, forKey: .content)
        createdAt = try values.decodeIfPresent(String.self, forKey: .createdAt)
        isAuthor = try values.decode(Bool.self, forKey: .isAuthor)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(commentId, forKey: .commentId)
        try values.encodeIfPresent(challengerName, forKey: .challengerName)
        try values.encodeIfPresent(challengerNickname, forKey: .challengerNickname)
        try values.encode(content, forKey: .content)
        try values.encodeIfPresent(createdAt, forKey: .createdAt)
        try values.encode(isAuthor, forKey: .isAuthor)
    }
}

struct CommunityPostMeetingDTO: Codable {
    let meetAt: String
    let location: String
    let maxParticipants: String
    let openChatUrl: String

    enum CodingKeys: CodingKey {
        case meetAt
        case location
        case maxParticipants
        case openChatUrl
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        meetAt = try values.decode(String.self, forKey: .meetAt)
        location = try values.decode(String.self, forKey: .location)
        maxParticipants = try values.decodeFlexibleString(forKey: .maxParticipants)
        openChatUrl = try values.decode(String.self, forKey: .openChatUrl)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(meetAt, forKey: .meetAt)
        try values.encode(location, forKey: .location)
        try values.encode(maxParticipants, forKey: .maxParticipants)
        try values.encode(openChatUrl, forKey: .openChatUrl)
    }
}

extension CommunityPostDTO {
    var model: CommunityPost {
        .init(
            id: postId, title: title, content: content, category: category,
            authorMemberID: authorMemberId, author: authorNickname ?? authorName,
            date: writeTime ?? createdAt, commentCount: commentCount, likeCount: likeCount,
            liked: isLiked, scrapCount: scrapCount, scrapped: isScrapped ?? false,
            meeting: lightningInfo.map {
                .init(
                    meetAt: $0.meetAt, location: $0.location, maxParticipants: $0.maxParticipants,
                    openChatUrl: $0.openChatUrl)
            })
    }
}

extension CommunityPostCommentDTO {
    var model: CommunityPostComment {
        .init(
            id: commentId, author: challengerNickname ?? challengerName,
            content: content, isAuthor: isAuthor, date: createdAt)
    }
}
