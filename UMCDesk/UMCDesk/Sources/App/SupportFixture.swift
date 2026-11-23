//
//  SupportFixture.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/23/26.
//

#if DEBUG
import Foundation
import Observation

enum SupportTeam: String, CaseIterable {
    case product = "UMC PRODUCT"
    case operations = "운영팀"
}

enum SupportInquiryStatus: String {
    case received = "접수"
    case active = "진행 중"
    case closed = "종료"
}

struct SupportTicket: Identifiable {
    let id = UUID()
    var subject: String
    var content: String
    var team: SupportTeam
    var assignee = "미배정"
    var label = "미분류"
    var status = SupportInquiryStatus.received
    var replies: [Reply] = []

    struct Reply: Identifiable {
        let id = UUID()
        let text: String
    }

    mutating func reply(_ input: String) {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard status != .closed, !text.isEmpty else { return }
        replies.append(Reply(text: text))
        status = .active
    }
}

struct SupportDraft: Identifiable {
    var article: SupportArticle
    var published: SupportArticle?
    var archived = false

    var id: String { article.id }

    var isValid: Bool {
        !article.question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !article.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var status: String {
        if archived { return "보관" }
        guard let published else { return "초안" }
        return published == article ? "발행" : "수정 중"
    }

    mutating func publish() {
        guard isValid else { return }
        published = article
        archived = false
    }

    mutating func archive() {
        published = nil
        archived = true
    }
}

@Observable
final class SupportFixture {
    var tickets = [
        SupportTicket(subject: "출석 화면 오류 문의", content: "예시 일정의 출석 기록을 확인해 주세요.",
                      team: .product, label: "화면 오류", status: .active),
        SupportTicket(subject: "종료된 예시 문의", content: "앱 언어 설정을 확인했어요.",
                      team: .operations, status: .closed)
    ]
    var drafts: [SupportDraft]

    init() {
        let example = SupportArticle(id: "fixture-attendance", question: "출석 기록이 실제와 다르게 보여요",
                                     answer: "활동 메뉴를 새로고침하고 해당 일정의 출석 상태를 확인해 주세요.")
        drafts = [SupportDraft(article: example, published: example)]
    }

    var publishedArticles: [SupportArticle] { drafts.compactMap(\.published) }

    @discardableResult
    func create(subject: String, content: String, team: SupportTeam) -> UUID? {
        let title = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !body.isEmpty else { return nil }
        let ticket = SupportTicket(subject: title, content: body, team: team)
        tickets.insert(ticket, at: 0)
        return ticket.id
    }
}
#endif
