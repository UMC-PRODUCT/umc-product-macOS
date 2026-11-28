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
         showAnswers: @escaping () -> Void) {
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
                && (label == nil || label == ticket.label)
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
                subject, content, team in
                selectedID = fixture.create(subject: subject, content: content, team: team)
                composing = false
            }
        } else if isOperator && managingFAQ {
            SupportFAQPreview(fixture: fixture, initialDraft: initialDraft) {
                initialDraft = nil
                managingFAQ = false
            }
        } else if let ticket = selectedTicket {
            SupportTicketDetail(ticket: ticket, isOperator: isOperator) {
                highlightedID = selectedID
                selectedID = nil
            }
            .id(ticket.wrappedValue.id)
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
                    if isOperator, let suggestion = tickets.first(where: needsDraft) {
                        HStack {
                            VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                                Text("답변 준비 필요").umcTypography(.headlineBold)
                                Text(suggestion.subject).umcTypography(.bodyRegular)
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
                        .padding(UMCSpacing.value12)
                        .background(UMCColor.Custom.backgroundSurfaceGreyWeaker,
                                    in: .rect(cornerRadius: UMCRadius.value12))
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
                    ForEach(Set(fixture.tickets.map(\.label)).sorted(), id: \.self) {
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
                Button(ticket.subject) { selectedID = ticket.id }
                    .buttonStyle(.link)
            }
            if isOperator {
                TableColumn("담당자") { Text($0.assignee) }
                TableColumn("라벨") { Text($0.label) }
                TableColumn("받는 팀") { Text($0.team.rawValue) }
            }
            TableColumn("상태") { Text($0.status.rawValue) }
            TableColumn("접수일") {
                Text($0.createdAt, format: .dateTime.month().day()).monospacedDigit()
            }
        }
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
    let submit: (String, String, SupportTeam) -> Void
    @State private var content = ""
    @State private var team: SupportTeam?
    @State private var choosingTeam = false
    @State private var reading = false
    @State private var reference: SupportArticle?
    @State private var category = "출석·과제"

    private var suggestion: SupportArticle? {
        articles.first { $0.category == category }
    }

    init(articles: [SupportArticle], cancel: @escaping () -> Void,
         submit: @escaping (String, String, SupportTeam) -> Void, reference: SupportArticle? = nil) {
        self.articles = articles
        self.cancel = cancel
        self.submit = submit
        _reference = State(initialValue: reference)
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
                        Picker("카테고리", selection: $category) {
                            ForEach(Array(Set(articles.map(\.category))).sorted(), id: \.self) {
                                Text($0).tag($0)
                            }
                        }
                        Text("받는 팀").umcTypography(.headlineBold)
                        Button(team?.rawValue ?? "받는 팀 선택") { choosingTeam = true }
                        Text("문의 내용").umcTypography(.headlineBold)
                        TextEditor(text: $content)
                            .accessibilityLabel("문의 내용").frame(minHeight: 120)
                            .border(UMCColor.Semantic.borderNeutralWeak200)
                        if let reference {
                            Text("참고한 답변 · " + reference.question)
                        }
                        HStack {
                            Button("취소", action: cancel)
                            Button("문의 보내기") {
                                guard let team else { choosingTeam = true; return }
                                let line = content.split(whereSeparator: \.isNewline)
                                    .map { $0.trimmingCharacters(in: .whitespaces) }
                                    .first { !$0.isEmpty } ?? ""
                                submit(String(line.prefix(50)), content, team)
                            }
                            .disabled(content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding(24)
                    if let suggestion {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("먼저 확인해 보세요").umcTypography(.headlineBold)
                            Text(suggestion.question)
                            Text("검증된 답변 · UMC PRODUCT")
                            Button("답변 확인하기") { reading = true }
                        }
                        .padding(24).frame(width: 360, alignment: .leading)
                        .background(UMCColor.Custom.backgroundSurfaceGreyWeak, in: .rect(cornerRadius: 16))
                    }
                }
            }
            .sheet(isPresented: $choosingTeam) {
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
            }
        }
    }
}
