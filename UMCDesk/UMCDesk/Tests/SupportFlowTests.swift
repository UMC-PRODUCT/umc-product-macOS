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
        fixture.tickets[index].reply("확인 중", from: .agent)
        #expect(fixture.tickets[index].status == .active)
        fixture.tickets[index].status = .closed
        fixture.tickets[index].reply("종료 뒤 운영자 입력", from: .agent)
        #expect(fixture.tickets[index].replies.map(\.text) == ["확인 중"])
    }

    @Test func emptyPreviewAcceptsFirstInquiryWithoutOtherUsersData() throws {
        let fixture = SupportFixture(emptyInquiries: true)
        #expect(fixture.tickets.isEmpty)
        #expect(!fixture.publishedArticles.isEmpty)
        let id = try #require(fixture.create(subject: "첫 문의", content: "내용", team: .product))
        #expect(fixture.myTickets.map(\.id) == [id])
        #expect(fixture.myTickets[0].status == .received)
    }

    @Test func requesterMessageReopensOriginalTicketOnlyAfterSending() throws {
        let fixture = SupportFixture()
        let closed = try #require(fixture.myTickets.first { $0.status == .closed })
        let index = try #require(fixture.tickets.firstIndex { $0.id == closed.id })
        let count = fixture.tickets.count
        for blank in ["", "  \n "] {
            fixture.tickets[index].reply(blank, from: .requester)
            #expect(fixture.tickets[index].status == .closed)
            #expect(fixture.tickets[index].replies.count == closed.replies.count)
        }
        fixture.tickets[index].reply(" 다시 확인해 주세요 ", from: .requester)
        let reopened = try #require(fixture.myTickets.first { $0.id == closed.id })
        #expect(fixture.tickets.count == count)
        #expect(reopened.status == .active)
        #expect(reopened.replies.dropLast().map(\.id) == closed.replies.map(\.id))
        #expect(reopened.replies.last?.author == .requester)
        #expect(reopened.replies.last?.text == "다시 확인해 주세요")
    }

    @Test func myInquiriesExcludeOtherUsersAndKeepReplyAuthors() throws {
        let fixture = SupportFixture()
        let other = try #require(fixture.tickets.first { !$0.belongsToCurrentUser })
        #expect(!fixture.myTickets.contains { $0.id == other.id })
        let id = try #require(fixture.create(subject: "질문", content: "예시 본문", team: .product))
        let index = try #require(fixture.tickets.firstIndex { $0.id == id })
        fixture.tickets[index].reply("추가 설명", from: .requester)
        #expect(fixture.tickets[index].status == .received)
        fixture.tickets[index].reply("확인했어요", from: .agent)
        let mine = try #require(fixture.myTickets.first { $0.id == id })
        #expect(mine.replies.map(\.author) == [.requester, .agent])
        #expect(mine.status == .active)
        var inaccessible = other
        inaccessible.reply("다른 사용자의 문의에 입력", from: .requester)
        #expect(inaccessible.replies.isEmpty)
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
