//
//  SupportFlowTests.swift
//  UMCDeskTests
//
//  Created by euijjang97 on 11/23/26.
//

import Testing
@testable import UMCDesk

struct SupportFlowTests {
    @Test func searchIncludesAnswersAndIgnoresOuterWhitespace() {
        let guide = SupportArticle(id: "guide", question: "앱 언어", answer: "Open Settings")
        #expect(guide.matches("  언어"))
        #expect(guide.matches(" settings "))
        #expect(guide.matches(" "))
        #expect(!guide.matches("네트워크"))
    }

    #if DEBUG
    @Test func localInquiryLifecycle() throws {
        let fixture = SupportFixture()
        let otherWindow = SupportFixture()
        let initialCount = fixture.tickets.count
        #expect(fixture.create(subject: "  ", content: "예시", team: .operations) == nil)
        let id = try #require(fixture.create(subject: " 예시 ", content: " 문의 ", team: .operations))
        let index = try #require(fixture.tickets.firstIndex { $0.id == id })
        #expect(fixture.tickets.count == initialCount + 1)
        #expect(otherWindow.tickets.count == initialCount)
        #expect(fixture.tickets[index].team == .operations)
        #expect(fixture.tickets[index].subject == "예시")
        fixture.tickets[index].assignee = "예시 담당자"
        #expect(fixture.tickets[index].status == .received)
        fixture.tickets[index].reply("확인 중")
        #expect(fixture.tickets[index].status == .active)
        fixture.tickets[index].status = .closed
        fixture.tickets[index].reply("종료 뒤 입력")
        #expect(fixture.tickets[index].replies.map(\.text) == ["확인 중"])
    }

    @Test func draftEditsAreVisibleOnlyAfterPublication() throws {
        let fixture = SupportFixture()
        let original = try #require(fixture.publishedArticles.first)
        fixture.drafts[0].article.answer = "새 예시 답변"
        #expect(fixture.drafts[0].status == "수정 중")
        #expect(fixture.publishedArticles.first == original)
        fixture.drafts[0].publish()
        #expect(fixture.publishedArticles.first?.answer == "새 예시 답변")
        fixture.drafts[0].archive()
        #expect(fixture.publishedArticles.isEmpty)
    }
    #endif
}
