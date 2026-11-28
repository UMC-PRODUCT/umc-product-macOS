//
//  SupportInquiryPreview.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/23/26.
//

import CoreDesignSystem
import SwiftUI

struct SupportInquiryPreview: View {
    @Bindable var fixture: SupportFixture
    var scene = SupportScene.home
    var selectTicket: (UUID?) -> Void = { _ in }
    var isOperator = false
    let showAnswers: () -> Void
    @State private var status: SupportInquiryStatus?
    private enum Assignment: String, CaseIterable {
        case all = "전체", mine = "내 담당", unassigned = "미배정"

        func includes(_ ticket: SupportTicket) -> Bool {
            switch self {
            case .all: true
            case .mine: ticket.assignee == "예시 담당자"
            case .unassigned: ticket.assignee == "미배정"
            }
        }
    }

    @State private var assignment = Assignment.all
    @State private var category: String?
    @State private var label: String?
    @State private var initialDraft: SupportDraft?

    init(fixture: SupportFixture, isOperator: Bool = false, initialTicket: UUID? = nil,
         scene: SupportScene = .home, selectTicket: @escaping (UUID?) -> Void = { _ in },
         showAnswers: @escaping () -> Void) {
        self.scene = scene
        self.selectTicket = selectTicket
        self.fixture = fixture
        self.isOperator = isOperator
        self.showAnswers = showAnswers
        _selectedID = State(initialValue: initialTicket)
    }

    private var tickets: [SupportTicket] {
        guard isOperator else { return fixture.myTickets }
        return fixture.tickets.filter { ticket in
            (status == nil || status == ticket.status)
                && assignment.includes(ticket)
                && (category == nil || category == ticket.category)
                && (label == nil || ticket.labels.contains(label ?? "") || label == ticket.label)
        }
    }
    @FocusState private var tableFocused: Bool
    @State private var highlightedID: UUID?
    @State private var selectedID: UUID?
    @State private var composing = false
    @State private var managingFAQ = false

    private var selectedTicket: Binding<SupportTicket>? {
        $fixture.tickets.first {
            $0.wrappedValue.id == selectedID
                && (isOperator || $0.wrappedValue.belongsToCurrentUser)
        }
    }

    var body: some View {
        if composing {
            SupportComposePreview(articles: fixture.publishedArticles, cancel: { composing = false }) {
                subject, content, team, category, reference, attachment in
                selectedID = fixture.create(subject: subject, content: content, team: team, category: category,
                                            reference: reference, attachmentName: attachment)
                composing = false
            }
        } else if isOperator && managingFAQ {
            SupportFAQPreview(fixture: fixture, initialDraft: initialDraft) {
                initialDraft = nil
                managingFAQ = false
            }
        } else if let ticket = selectedTicket {
            SupportTicketDetail(ticket: ticket, scene: scene, isOperator: isOperator, articles: fixture.publishedArticles) {
                highlightedID = selectedID
                selectedID = nil
            }
            .id(ticket.wrappedValue.id)
            .onAppear { selectTicket(ticket.wrappedValue.id) }
        } else {
            HStack {
                Text(isOperator ? "접수된 문의" : "내 문의 현황")
                    .umcTypography(.title2Bold).accessibilityAddTraits(.isHeader)
                Spacer()
                if isOperator {
                    Button("FAQ 관리") { managingFAQ = true }
                } else if !fixture.myTickets.isEmpty {
                    Button("새 문의 작성") { composing = true }.buttonStyle(.borderedProminent).modifier(SupportControlFill())
                }
            }
            Group {
                if !isOperator && fixture.myTickets.isEmpty {
                    ContentUnavailableView {
                        Text("아직 등록한 문의가 없어요").umcTypography(.title2Bold)
                    } description: {
                        Text("많이 묻는 질문에서 먼저 답을 찾거나 문의를 남겨주세요.")
                    } actions: {
                        HStack {
                            Button("답변 찾아보기", action: showAnswers)
                            Button("문의하기") { composing = true }.buttonStyle(.borderedProminent).modifier(SupportControlFill())
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay {
                        RoundedRectangle(cornerRadius: UMCRadius.value12)
                            .strokeBorder(UMCColor.Semantic.borderNeutralWeak200)
                            .allowsHitTesting(false)
                    }
                } else {
                    if isOperator {
                        operatorFilters
                    }

                    HStack(alignment: .top, spacing: 24) {
                    ticketTable
                        .overlay {
                            if isOperator && tickets.isEmpty {
                                ContentUnavailableView {
                                    Label("조건에 맞는 문의가 없습니다", systemImage: "line.3.horizontal.decrease")
                                } actions: {
                                    Button("필터 초기화") {
                                        assignment = .all
                                        status = nil
                                        category = nil
                                        label = nil
                                    }
                                }
                            }
                        }
                    if isOperator, let suggestion = tickets.first {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                                Text("답변 준비 필요").umcTypography(.headlineBold)
                                Text("알림이 오지 않아요").umcTypography(.bodyRegular)
                                Text("최근 24시간 · 6명 문의")
                            }
                            Spacer()
                            Button("FAQ 초안 작성") {
                                // Operators edit a public question before publication.
                                initialDraft = SupportDraft(article: SupportArticle(
                                    id: UUID().uuidString, question: "", answer: "",
                                    category: suggestion.category
                                ))
                                managingFAQ = true
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).supportCard().frame(width: 298)
                    }
                    }
                }
            }

        }
    }

    private func needsDraft(_ ticket: SupportTicket) -> Bool {
        ticket.status != .closed && !fixture.publishedArticles.contains {
            $0.question == ticket.subject
        }
    }

    private var operatorFilters: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value8) {
            Picker("담당 범위", selection: $assignment) {
                ForEach(Assignment.allCases, id: \.self) { scope in
                    let count = fixture.tickets.filter(scope.includes).count
                    Text("\(scope.rawValue) \(count)").tag(scope)
                }
            }.pickerStyle(.segmented).modifier(SupportControlFill()).labelsHidden().fixedSize()
            HStack {
                Picker("상태", selection: $status) {
                    Text("상태 전체").tag(SupportInquiryStatus?.none)
                    ForEach(SupportInquiryStatus.allCases, id: \.self) {
                        Text($0.rawValue).tag(Optional($0))
                    }
                }
                Picker("카테고리", selection: $category) {
                    Text("카테고리 전체").tag(String?.none)
                    ForEach(Set(fixture.tickets.map(\.category)).sorted(), id: \.self) {
                        Text($0).tag(Optional($0))
                    }
                }
                Picker("라벨", selection: $label) {
                    Text("라벨 전체").tag(String?.none)
                    ForEach(Set(fixture.tickets.flatMap { $0.labels.isEmpty ? ["미분류"] : $0.labels }).sorted(), id: \.self) {
                        Text($0).tag(Optional($0))
                    }
                }
                Spacer(minLength: 0)
                Text("\(tickets.count)건").monospacedDigit()
            }.labelsHidden()
        }
    }

    private var ticketTable: some View {
        Table(tickets, selection: $highlightedID) {
            TableColumn("문의") { ticket in
                Button {
                    selectedID = ticket.id
                } label: {
                    VStack(alignment: .leading) {
                        Text(ticket.subject).inquiryFont(16, weight: .medium)
                        if isOperator { Text(ticket.category + " · " + ticket.team.rawValue).inquiryFont(13) }
                    }
                }.buttonStyle(.plain)
            }
            TableColumn("상태") { Text($0.status.rawValue) }
            if isOperator {
                TableColumn("담당자") { Text($0.assignee) }
                TableColumn("라벨") { Text($0.label) }
            }
            TableColumn("접수일") {
                Text($0.createdAt, format: .dateTime.month().day()).monospacedDigit()
            }
        }
        .environment(\.defaultMinListRowHeight, 64)
        .alternatingRowBackgrounds(.disabled)
        .focused($tableFocused)
        .onAppear { tableFocused = true }
        .contextMenu(forSelectionType: UUID.self) { _ in } primaryAction: { ids in
            selectedID = ids.first
        }
        .onKeyPress(.return) {
            guard let highlightedID else { return .ignored }
            selectedID = highlightedID
            return .handled
        }
    }
}

struct SupportComposePreview: View {
    let articles: [SupportArticle]
    let cancel: () -> Void
    let submit: (String, String, SupportTeam, String, SupportArticle?, String?) -> Void
    @State private var content = ""
    @State private var team: SupportTeam?
    @State private var choosingTeam = false
    @State private var attachment: String?
    @State private var reading = false
    @State private var reference: SupportArticle?
    @State private var category = "출석·과제"

    private var suggestion: SupportArticle? {
        reference ?? articles.first { $0.category == category }
    }

    init(articles: [SupportArticle], scene: SupportScene = .home, cancel: @escaping () -> Void,
         submit: @escaping (String, String, SupportTeam, String, SupportArticle?, String?) -> Void, reference: SupportArticle? = nil) {
        self.articles = articles
        self.cancel = cancel
        self.submit = submit
        if [.compose, .reference, .team].contains(scene) {
            _content = State(initialValue: "앱에서 출석 기록이 실제와 다르게 표시돼요.\n새로고침해도 같아서 앱 버전과 오류 화면을 보내드립니다.")
            _attachment = State(initialValue: "오류 화면.png")
        }
        _choosingTeam = State(initialValue: scene == .team)
        _reference = State(initialValue: reference ?? (scene == .reference ? articles.first : nil))
        _category = State(initialValue: reference?.category ?? "출석·과제")
    }

    var body: some View {
        if reading, let suggestion {
            SupportAnswerDetail(article: suggestion, back: { reading = false }) {
                reference = suggestion
                reading = false
            }
        } else {
            VStack(alignment: .leading, spacing: 16) {
                Text("문의하기").umcTypography(.largeTitle3Bold)
                Text("서비스 이용 중 겪은 문제를 알려주시면 UMC PRODUCT가 확인해 드려요.")
                HStack(alignment: .top, spacing: 24) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 20) {
                        Picker("카테고리", selection: $category) {
                            ForEach(Array(Set(articles.map(\.category))).sorted(), id: \.self) {
                                Text($0).tag($0)
                            }
                        }
                        Text("받는 팀").umcTypography(.headlineBold)
                        Button(team?.rawValue ?? "받는 팀 선택") { choosingTeam = true }
                        }
                        Text("문의와 가까운 팀을 선택해 주세요. 잘 모르겠다면 UMC PRODUCT에서 확인해 드려요.")
                        Text("문의 내용").umcTypography(.headlineBold)
                        TextEditor(text: $content)
                            .accessibilityLabel("문의 내용").frame(height: 156)
                            .border(UMCColor.Semantic.borderNeutralWeak200)
                        Text("첨부").umcTypography(.headlineBold)
                        Button(attachment ?? "예시 오류 화면 첨부") {
                            attachment = attachment == nil ? "오류 화면.png" : nil
                        }
                        Text("이미지·문서, 최대 50MB").inquiryFont(13)
                        Spacer()
                        HStack {
                            Spacer()
                            Button("취소", action: cancel)
                            Button("문의 보내기") {
                                guard let team else { choosingTeam = true; return }
                                let line = content.split(whereSeparator: \.isNewline)
                                    .map { $0.trimmingCharacters(in: .whitespaces) }
                                    .first { !$0.isEmpty } ?? ""
                                submit(String(line.prefix(50)), content, team, category, reference, attachment)
                            }
                            .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading).supportCard()
                    if let suggestion {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("먼저 확인해 보세요").umcTypography(.headlineBold)
                            Text(suggestion.question)
                            Text("검증된 답변 · UMC PRODUCT")
                            Button("답변 확인하기") { reading = true }
                            Text("답변을 읽지 않아도 문의를 보낼 수 있어요. 작성하던 내용과 첨부는 유지돼요.")
                            if let reference {
                                Text("참고한 답변\n" + reference.question).padding(16)
                                    .background(UMCColor.Semantic.surfaceBrandWeak, in: .rect(cornerRadius: 12))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading).supportCard().frame(width: 360)
                    }
                }
            }
            .disabled(choosingTeam).accessibilityHidden(choosingTeam)
            .overlay {
                if choosingTeam {
                ZStack {
                UMCColor.Custom.backgroundDimmed
                    .onTapGesture { choosingTeam = false }
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("어느 팀에 문의할까요?").umcTypography(.title2Bold)
                        Spacer()
                        Button("취소") { choosingTeam = false }.keyboardShortcut(.cancelAction)
                    }
                    Text("문의와 가까운 팀을 하나 선택하면 문의 작성 화면에 반영돼요.")
                    ScrollView {
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                            ForEach(SupportTeam.allCases, id: \.self) { option in
                                Button {
                                    team = option
                                    choosingTeam = false
                                } label: {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(option.rawValue).umcTypography(.headlineBold)
                                        Text(option.summary)
                                        if team == option { Image(systemName: "checkmark") }
                                    }
                                    .padding(14).frame(maxWidth: .infinity, minHeight: 96, alignment: .leading)
                                    .background(UMCColor.Custom.backgroundSurfaceGreyWeaker,
                                                in: .rect(cornerRadius: 10))
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }.padding(25).frame(width: 816, height: 587)
                    .background(UMCColor.Custom.backgroundSurface, in: .rect(cornerRadius: 16))
                }
                }
            }
        }
    }
}
