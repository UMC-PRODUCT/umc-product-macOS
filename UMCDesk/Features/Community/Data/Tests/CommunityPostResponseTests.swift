//
//  CommunityPostResponseTests.swift
//  CommunityDataTests
//
//  Created by euijjang97 on 11/23/26.
//

import Foundation
import Testing

@testable import CommunityData

struct CommunityPostResponseTests {
    @Test func decodesMemberOwnershipIndependentlyOfChallengerID() throws {
        let data = Data(
            """
            {"postId":22,"title":"번개","content":"합성","category":"LIGHTNING","authorId":"777",
             "authorMemberId":101,"authorNickname":"별명","writeTime":"2026-11-23T10:00:00Z",
             "commentCount":"3","likeCount":4,"isLiked":true,"isScrapped":false,"scrapCount":0,
             "lightningInfo":{"meetAt":"2026-11-24T10:00:00Z","location":"학교",
             "maxParticipants":5,"openChatUrl":"https://example.test/meet"}}
            """.utf8)
        let row = try JSONDecoder().decode(CommunityPostDTO.self, from: data).model
        #expect(row.id == "22" && row.authorMemberID == "101")
        #expect(row.meeting?.maxParticipants == "5" && row.likeCount == "4")
        #expect(row.liked && !row.scrapped)
    }

    @Test func commentOwnershipIsTheServerFlag() throws {
        let data = Data(
            """
            {"commentId":"5","challengerId":"101","content":"댓글","isAuthor":false}
            """.utf8)
        let row = try JSONDecoder().decode(CommunityPostCommentDTO.self, from: data).model
        #expect(row.id == "5" && !row.isAuthor)
    }
}
