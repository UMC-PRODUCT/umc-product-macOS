//
//  SupportFixture.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/23/26.
//

import Foundation
import Observation

enum SupportTeam: String, CaseIterable {
    case brand = "Brand & Growth"
    case learning = "Learning & Activity"
    case community = "Community & Connection"
    case operations = "Operations Enablement"
    case platform = "Platform"
    case design = "Design Platform"
    case infrastructure = "Infrastructure"
    case product = "어느 팀인지 모르겠어요"

    var summary: String {
        switch self {
        case .brand: "모집·선발, 공식 홈페이지, 테크 블로그"
        case .learning: "워크북·미션, 활동 참여, 출석·수료, UPMS"
        case .community: "커뮤니티·Connect, 프로필·전자명함, 채팅 이용"
        case .operations: "기수·조직·역할 관리, 공지, 출석·운영 승인"
        case .platform: "로그인·인증, 알림·채팅 전달 오류, 공통 폼"
        case .design: "디자인 시스템, Figma 라이브러리·토큰"
        case .infrastructure: "배포·실행 환경, 장애·모니터링"
        case .product: "UMC PRODUCT에서 담당 팀을 확인해 드려요."
        }
    }
}

enum SupportInquiryStatus: String, CaseIterable {
    case received = "접수"
    case active = "진행 중"
    case closed = "종료"
}

struct SupportTicket: Identifiable {
    let id = UUID()
    let createdAt = Date()
    var belongsToCurrentUser = true
    var subject: String
    var content: String
    var team: SupportTeam
    var category = "기타"
    var assignee = "미배정"
    var label = "미분류"
    var status = SupportInquiryStatus.received
    var replies: [Reply] = []

    enum Author: String { case requester = "문의자", agent = "예시 담당자" }

    struct Reply: Identifiable {
        let id = UUID()
        let sentAt = Date()
        let author: Author
        let text: String
    }

    mutating func reply(_ input: String, from author: Author) {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, status != .closed || author == .requester else { return }
        guard author == .agent || belongsToCurrentUser else { return }
        replies.append(Reply(author: author, text: text))
        if author == .agent || status == .closed { status = .active }
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
                      team: .learning, category: "출석·과제", assignee: "예시 담당자", label: "화면 오류", status: .active,
                      replies: [.init(author: .agent, text: "확인해 볼게요. 사용 중인 앱 버전을 알려 주세요.")]),
        SupportTicket(subject: "종료된 예시 문의", content: "앱 언어 설정을 확인했어요.",
                      team: .operations, category: "앱 설정", status: .closed,
                      replies: [.init(author: .agent, text: "언어 설정 확인이 끝나 문의를 종료했어요.")]),
        SupportTicket(belongsToCurrentUser: false, subject: "다른 사용자의 예시 문의",
                      content: "알림 설정을 확인하고 싶어요.", team: .operations, category: "앱 설정")
    ]
    var drafts: [SupportDraft]

    init(emptyInquiries: Bool = false) {
        let examples = [
            SupportArticle(id: "attendance", question: "출석 기록이 실제와 다르게 보여요",
                           answer: "활동에서 일정을 선택하고 내 출석 상태를 확인해 주세요.",
                           category: "출석·과제", dayReaders: 28, weekReaders: 42),
            SupportArticle(id: "login", question: "앱에 로그인이 안 돼요",
                           answer: "가입할 때 사용한 로그인 방식을 선택해 주세요.",
                           category: "계정·로그인", dayReaders: 21, weekReaders: 56),
            SupportArticle(id: "assignment", question: "과제 파일이 업로드되지 않아요",
                           answer: "스터디의 해당 주차와 제출 기한을 확인해 주세요.",
                           category: "출석·과제", dayReaders: 16, weekReaders: 23),
            SupportArticle(id: "application", question: "프로젝트 지원이 저장되지 않아요",
                           answer: "매칭에서 내 지원과 임시 저장한 지원서를 확인해 주세요.",
                           category: "프로젝트·매칭", dayReaders: 11, weekReaders: 32),
            SupportArticle(id: "activity", question: "활동 증명서가 열리지 않아요",
                           answer: "활동 기수와 등록 정보를 확인한 뒤 문의를 남겨 주세요.",
                           category: "활동 증명", dayReaders: 7, weekReaders: 13)
        ]
        drafts = examples.map { SupportDraft(article: $0, published: $0) }
        if emptyInquiries { tickets.removeAll() }
    }

    var myTickets: [SupportTicket] { tickets.filter(\.belongsToCurrentUser) }

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
