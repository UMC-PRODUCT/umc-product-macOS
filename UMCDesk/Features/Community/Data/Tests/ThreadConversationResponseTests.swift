//
//  ThreadConversationResponseTests.swift
//  CommunityDataTests
//
//  Created by euijjang97 on 11/23/26.
//

import Foundation
import Testing

@testable import CommunityData

struct ThreadConversationResponseTests {
    @Test func redactsNestedContentBeforePassingItToPresentation() throws {
        let source = """
            {"messages":[{"messageId":12,"senderId":"2","senderName":"숨김","content":"비공개",
            "isSenderBlocked":true,"replyTo":{"messageId":1},"files":[{"fileId":"photo",
            "fileName":"숨김.png","fileUrl":"https://example.test/image"}],"reactions":[{"emoji":"🔥",
            "count":2,"reactedByMe":true}]},{"messageId":"11","senderName":"삭제","content":"삭제 원문",
            "deletedAt":"2026-11-23T10:01:00Z","isSenderBlocked":false}],
            "hasMore":true,"nextBefore":11}
            """
        let page = try JSONDecoder().decode(ConversationHistoryDTO.self, from: Data(source.utf8))
        #expect(page.nextBefore == "11")
        let rows = page.messages.map(\.model)
        #expect(rows.map(\.text) == ["차단한 회원의 메시지", "삭제된 메시지"])
        #expect(
            rows.allSatisfy {
                $0.author.isEmpty && $0.authorID == nil && $0.replyID == nil
                    && $0.isHidden && $0.files.isEmpty && $0.reactions.isEmpty
            })
    }
}
