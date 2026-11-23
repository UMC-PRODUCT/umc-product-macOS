//  NoticeContractTests.swift
//  NoticeDomainTests
//
//  Created by euijjang97 on 11/23/26.

import Foundation
import NoticeDomain
import Testing

@Suite("공지 서버 응답 계약")
struct NoticeContractTests {
    @Test("목록은 첨부 플래그와 숫자 또는 문자열 식별자를 읽는다")
    func summary() throws {
        let json = """
            {"content":[{"id":"9007199254740993","title":"합성 공지","content":"본문",
            "mustRead":false,"createdAt":"2026-11-23T00:00:00Z","viewCount":0,
            "hasVote":true,"hasLinks":false,"hasImages":false}],"hasNext":true}
            """
        let page = try JSONDecoder().decode(NoticePage.self, from: Data(json.utf8))
        #expect(page.hasNext)
        let row = try #require(page.content.first)
        #expect(row.id == "9007199254740993")
        #expect(row.viewCount == "0")
        #expect(row.hasVote == true && row.vote == nil)
    }

    @Test("상세 투표의 응답과 첨부 순서를 보존한다")
    func article() throws {
        let json = """
            {"id":77,"title":"합성 투표","content":"본문","createdAt":"2026-11-23T00:00:00Z",
            "mustRead":true,"viewCount":"8","links":[{"id":9,"url":"https://example.test"}],
            "vote":{"title":"선택","status":"OPEN","isAnonymous":true,"allowMultipleChoice":true,
            "endsAtExclusive":"2026-11-30T00:00:00Z","totalParticipants":1,"options":[
            {"optionId":"82","content":"첫째","voteCount":1}],"mySelectedOptionIds":[82]}}
            """
        let entry = try JSONDecoder().decode(NoticeEntry.self, from: Data(json.utf8))
        #expect(entry.links?.first?.id == "9")
        #expect(entry.vote?.mySelectedOptionIds == ["82"])
        let encoded = try JSONEncoder().encode(entry)
        let decoded = try JSONDecoder().decode(NoticeEntry.self, from: encoded)
        #expect(decoded.vote?.options.first?.voteCount == "1")
    }

    @Test("읽음 현황의 다음 페이지 커서는 문자열로 보존한다")
    func readers() throws {
        let json =
            #"{"content":[{"challengerId":"25","name":"합성 회원"}],"nextCursor":42,"hasNext":true}"#
        let page = try JSONDecoder().decode(NoticeReaders.self, from: Data(json.utf8))
        #expect(page.hasNext && page.nextCursor == "42")
    }
}
