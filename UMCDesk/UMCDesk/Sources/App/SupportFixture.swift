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
    var team: SupportTeam { didSet { if oldValue != team { record("받는 팀 · " + team.rawValue) } } }
    var category = "기타"
    var assignee = "미배정" { didSet { if oldValue != assignee { record("담당자 · " + assignee) } } }
    var labels: [String] = [] { didSet { if oldValue != labels { record("라벨 · " + label) } } }
    var linkedQuestion: String? {
        didSet { if oldValue != linkedQuestion { record("대표 질문 연결 변경") } }
    }
    var attachmentName: String?
    var reference: SupportArticle?
    struct Event: Identifiable {
        let id = UUID()
        let time: Date
        let actor: String
        let message: String
    }
    var history: [Event] = []

    private mutating func record(_ message: String) {
        history.append(.init(time: .now, actor: "예시 담당자", message: message))
    }

    mutating func applyLabels(original: [String], selected: [String]) {
        let removed = Set(original).subtracting(selected)
        labels = labels.filter { !removed.contains($0) }
            + selected.filter { !original.contains($0) && !labels.contains($0) }
    }

    var label: String { labels.isEmpty ? "미분류" : labels.joined(separator: " · ") }
    var status = SupportInquiryStatus.received {
        didSet { if oldValue != status { record(status.rawValue) } }
    }
    var replies: [Reply] = []

    enum Author: String { case requester = "문의자", agent = "예시 담당자" }

    struct Reply: Identifiable {
        let id = UUID()
        let sentAt = Date()
        let author: Author
        let text: String
    }

    @discardableResult
    mutating func reply(_ input: String, from author: Author) -> Bool {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, status != .closed || author == .requester else { return false }
        guard author == .agent || belongsToCurrentUser else { return false }
        replies.append(Reply(author: author, text: text))
        if author == .agent || status == .closed { status = .active }
        return true
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
        SupportTicket(subject: "출석 기록이 실제와 다르게 보여요", content: "앱에서 출석 기록이 실제와 다르게 표시돼요.\n새로고침해도 같아서 앱 버전과 오류 화면을 보내드립니다.",
                      team: .learning, category: "출석·과제", assignee: "예시 담당자", labels: ["출석 오류", "정보 확인"], attachmentName: "오류 화면.png", status: .active,
                      replies: [.init(author: .agent, text: "확인해 볼게요. 사용 중인 앱 버전과 오류가 나타난 화면을 보내주실 수 있나요?")]),
        SupportTicket(subject: "앱에 로그인이 안 돼요", content: "앱 언어 설정을 확인했어요.",
                      team: .operations, category: "앱 설정", status: .closed,
                      replies: [.init(author: .agent, text: "언어 설정 확인이 끝나 문의를 종료했어요.")]),
        SupportTicket(belongsToCurrentUser: false, subject: "과제 파일이 업로드되지 않아요",
                      content: "과제 제출을 확인하고 싶어요.", team: .learning, category: "출석·과제"),
        SupportTicket(subject: "프로젝트 지원이 저장되지 않아요", content: "지원서를 확인해 주세요.",
                      team: .learning, category: "프로젝트·매칭", labels: ["기능 요청"]),
        SupportTicket(belongsToCurrentUser: false, subject: "활동 증명서가 열리지 않아요",
                      content: "증명서를 확인하고 싶어요.", team: .learning, category: "활동 증명")
    ]
    var drafts: [SupportDraft]

    init(emptyInquiries: Bool = false) {
        let examples = [
            SupportArticle(id: "attendance", question: "출석 기록이 실제와 다르게 보여요",
                           answer: """
                           활동 메뉴의 기록이 실제와 다르다면 새로고침 후 다시 확인해 주세요. 문제가 계속되면 UMC PRODUCT에 알려주세요.

                           1. 활동 메뉴를 새로고침하고 해당 일정의 출석 상태를 확인해 주세요.

                           2. 문제가 계속되면 앱 버전, 발생 시각과 화면을 준비해 주세요.

                           3. 아래 문의하기에서 UMC PRODUCT에 표시 오류를 알려주세요.

                           UMC PRODUCT가 앱의 표시·동기화 오류를 확인해 드려요. 출석 인정이나 학사 판단은 이 문의에서 처리하지 않아요.
                           """,
                           category: "출석·과제", dayReaders: 28, weekReaders: 126),
            SupportArticle(id: "login", question: "앱에 로그인이 안 돼요",
                           answer: "가입할 때 사용한 로그인 방식을 선택해 주세요.",
                           category: "계정·로그인", dayReaders: 21, weekReaders: 93),
            SupportArticle(id: "assignment", question: "과제 파일이 업로드되지 않아요",
                           answer: "스터디의 해당 주차와 제출 기한을 확인해 주세요.",
                           category: "출석·과제", dayReaders: 16, weekReaders: 74),
            SupportArticle(id: "application", question: "프로젝트 지원이 저장되지 않아요",
                           answer: "매칭에서 내 지원과 임시 저장한 지원서를 확인해 주세요.",
                           category: "프로젝트·매칭", dayReaders: 11, weekReaders: 42),
            SupportArticle(id: "activity", question: "활동 증명서가 열리지 않아요",
                           answer: "활동 기수와 등록 정보를 확인한 뒤 문의를 남겨 주세요.",
                           category: "활동 증명", dayReaders: 7, weekReaders: 29)
        ]
        drafts = examples.map { SupportDraft(article: $0, published: $0) }
        if emptyInquiries { tickets.removeAll() }
    }

    enum FAQAction { case save, publish, archive }

    @discardableResult
    func apply(_ action: FAQAction, draft: SupportDraft) -> SupportDraft {
        let index = drafts.firstIndex { $0.id == draft.id }
        var latest = index.map { drafts[$0] } ?? SupportDraft(article: draft.article)
        switch action {
        case .save: latest.article = draft.article
        case .publish:
            latest.article = draft.article
            latest.publish()
        case .archive: latest.archive()
        }
        if let index { drafts[index] = latest } else { drafts.append(latest) }
        return latest
    }

    var myTickets: [SupportTicket] { tickets.filter(\.belongsToCurrentUser) }

    var publishedArticles: [SupportArticle] { drafts.compactMap(\.published) }

    @discardableResult
    func create(subject: String, content: String, team: SupportTeam, category: String = "기타",
                reference: SupportArticle? = nil, attachmentName: String? = nil) -> UUID? {
        let title = subject.trimmingCharacters(in: .whitespacesAndNewlines)
        let body = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty, !body.isEmpty else { return nil }
        let ticket = SupportTicket(subject: title, content: body, team: team, category: category,
                                   attachmentName: attachmentName, reference: reference)
        tickets.insert(ticket, at: 0)
        return ticket.id
    }
}
