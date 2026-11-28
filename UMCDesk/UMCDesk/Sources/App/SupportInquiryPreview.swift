//
//  SupportInquiryPreview.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/23/26.
//

import CoreDesignSystem
import SwiftUI

struct SupportInquiryPreview: View {
    @Environment(\.umcBodyTextScale) private var scale
    @Bindable var fixture: SupportFixture
    var scene = SupportScene.home
    var selectTicket: (UUID?) -> Void = { _ in }
    var isOperator = false
    var onFAQDirty: (Bool) -> Void = { _ in }
    let showAnswers: () -> Void
    let beginCompose: () -> Void
    @State private var status: SupportInquiryStatus?
    @State private var assignment = SupportQueue.all
    @State private var category: String?
    @State private var label: String?
    @State private var initialDraft: SupportDraft?

    init(
        fixture: SupportFixture, isOperator: Bool = false, initialTicket: UUID? = nil,
        scene: SupportScene = .home, selectTicket: @escaping (UUID?) -> Void = { _ in },
        onFAQDirty: @escaping (Bool) -> Void = { _ in }, beginCompose: @escaping () -> Void = {},
        showAnswers: @escaping () -> Void
    ) {
        self.scene = scene
        self.onFAQDirty = onFAQDirty
        self.selectTicket = selectTicket
        self.fixture = fixture
        self.isOperator = isOperator
        self.beginCompose = beginCompose
        self.showAnswers = showAnswers
        _selectedID = State(initialValue: initialTicket)
        _assignment = State(
            initialValue: scene == .mine
                ? .mine
                : scene == .unassigned
                    ? .unassigned : scene == .unclassified ? .unclassified : .all
        )
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
    @FocusState private var focusedTicket: UUID?
    @State private var highlightedID: UUID?
    @State private var selectedID: UUID?
    @State private var managingFAQ = false

    private var selectedTicket: Binding<SupportTicket>? {
        $fixture.tickets.first {
            $0.wrappedValue.id == selectedID
                && (isOperator || $0.wrappedValue.belongsToCurrentUser)
        }
    }

    var body: some View {
        if isOperator && managingFAQ {
            SupportFAQPreview(fixture: fixture, initialDraft: initialDraft, onDirty: onFAQDirty) {
                initialDraft = nil
                managingFAQ = false
            }
        } else if let ticket = selectedTicket {
            SupportTicketDetail(
                ticket: ticket, fixture: fixture, scene: scene, isOperator: isOperator,
                articles: isOperator
                    ? fixture.operatorPublishedArticles : fixture.publishedArticles
            ) {
                highlightedID = selectedID
                selectedID = nil
            }
            .id(ticket.wrappedValue.id)
            .onAppear { selectTicket(ticket.wrappedValue.id) }
        } else {
            ScrollViewReader { reader in
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(isOperator ? "문의 관리" : "내 문의").inquiryFont(28, weight: .bold)
                                    .accessibilityAddTraits(.isHeader)
                                Text(
                                    isOperator
                                        ? "UMC PRODUCT 전용 · 서비스에 접수된 문의를 관리하세요."
                                        : "내가 남긴 문의의 처리 상태와 답변을 확인하세요."
                                ).inquiryFont(14)
                            }
                            Spacer()
                            if isOperator {
                                Button("FAQ 관리") { managingFAQ = true }
                            } else if !fixture.myTickets.isEmpty {
                                Button("문의하기", action: beginCompose).buttonStyle(
                                    SupportActionStyle(prominent: true))
                            }
                        }
                        if !isOperator {
                            HStack(spacing: 8) {
                                Button("많이 묻는 질문", action: showAnswers)
                                Text("내 문의").padding(12).background(
                                    UMCColor.Semantic.surfaceBrandWeak, in: .rect(cornerRadius: 8))
                            }
                        }
                        if isOperator { operatorFilters }
                        if isOperator || !fixture.myTickets.isEmpty {
                            Text(isOperator ? "접수된 문의" : "내 문의 현황")
                                .inquiryFont(20, weight: .bold).accessibilityAddTraits(.isHeader)
                        }
                        Group {
                            if !isOperator && fixture.myTickets.isEmpty {
                                ContentUnavailableView {
                                    Text("아직 등록한 문의가 없어요").inquiryFont(28, weight: .bold)
                                } description: {
                                    Text("많이 묻는 질문에서 먼저 답을 찾거나 문의를 남겨주세요.")
                                } actions: {
                                    HStack {
                                        Button("답변 찾아보기", action: showAnswers)
                                        Button("문의하기", action: beginCompose).buttonStyle(
                                            SupportActionStyle(prominent: true))
                                    }
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .overlay {
                                    RoundedRectangle(cornerRadius: UMCRadius.value12)
                                        .strokeBorder(UMCColor.Semantic.borderNeutralWeak200)
                                        .allowsHitTesting(false)
                                }
                            } else {

                                SupportPanelLayout(
                                    scale: scale, firstMinimum: 680, secondMinimum: 240,
                                    fraction: 960 / 1258
                                ) {
                                    ticketTable
                                        .overlay {
                                            if isOperator && tickets.isEmpty {
                                                ContentUnavailableView {
                                                    Label(
                                                        "조건에 맞는 문의가 없습니다",
                                                        systemImage: "line.3.horizontal.decrease")
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
                                    if isOperator, let suggestion = fixture.suggestedDraft {
                                        VStack(alignment: .leading, spacing: 16) {
                                            VStack(alignment: .leading, spacing: UMCSpacing.value4)
                                            {
                                                Text("답변 준비 필요").inquiryFont(18, weight: .bold)
                                                Text("문의는 늘고 있지만 아직 발행 답변이 없는 질문이에요.").inquiryFont(
                                                    13)
                                                Text(suggestion.article.question).inquiryFont(16)
                                                Text("최근 24시간 · 6명 문의")
                                                Text("PRODUCT 내부 집계\n공개 인기 순위에는 표시하지 않아요.")
                                                    .inquiryFont(13)
                                            }
                                            Spacer()
                                            Button("FAQ 초안 작성") {
                                                initialDraft = suggestion
                                                managingFAQ = true
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .supportCard()
                                    }
                                }
                            }
                        }

                    }
                }.onAppear {
                    if isOperator { selectTicket(nil) }
                    if let highlightedID {
                        reader.scrollTo(highlightedID)
                        focusedTicket = highlightedID
                    }
                }
            }
        }
    }

    private var operatorFilters: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value8) {
            Picker("담당 범위", selection: $assignment) {
                ForEach(
                    [SupportQueue.all, .mine, .unassigned]
                        + (assignment == .unclassified ? [.unclassified] : []), id: \.self
                ) { scope in
                    let count = fixture.tickets.filter(scope.includes).count
                    Text("\(scope.rawValue) \(count)").tag(scope)
                }
            }.pickerStyle(.segmented).modifier(SupportControlFill()).labelsHidden().fixedSize()
            SupportActionRow {
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
                    ForEach(
                        Set(fixture.tickets.flatMap { $0.labels.isEmpty ? ["미분류"] : $0.labels })
                            .sorted(), id: \.self
                    ) {
                        Text($0).tag(Optional($0))
                    }
                }
                Button("미분류 문의") {
                    assignment = .unclassified
                    label = nil
                    category = nil
                    status = nil
                }
                Spacer(minLength: 0)
                Text("\(tickets.count)건").monospacedDigit()
            }.labelsHidden()
        }
    }

    private enum Columns { case compact, medium, full }

    @ViewBuilder private var ticketTable: some View {
        if isOperator {
            ViewThatFits(in: .horizontal) {
                SupportTableWidth(minimum: SupportLayoutMetrics.fullTable(scale)) { rows(.full) }
                SupportTableWidth(minimum: SupportLayoutMetrics.mediumTable(scale)) {
                    rows(.medium)
                }
                rows(.compact)
            }
        } else {
            rows(.compact)
        }
    }

    private func rows(_ columns: Columns) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if isOperator {
                HStack {
                    Text("문의")
                    Spacer()
                    if columns == .full { Text("상태 · 담당자 · 라벨 · 접수일") }
                    if columns == .medium { Text("상태 · 담당자") }
                }.inquiryFont(13, weight: .medium).foregroundStyle(
                    UMCColor.Semantic.textNeutralStrong800)
            }
            ForEach(tickets) { ticket in
                Button {
                    highlightedID = ticket.id
                    selectedID = ticket.id
                } label: {
                    Group {
                        if columns == .full {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(ticket.subject).inquiryFont(16, weight: .medium)
                                    Text(ticket.visibleTeam).inquiryFont(13)
                                }.frame(maxWidth: .infinity, alignment: .leading)
                                Text(ticket.status.rawValue).frame(width: 74 * scale)
                                Text(ticket.assignee).frame(width: 74 * scale)
                                Text(ticket.label).frame(width: 120 * scale)
                                Text(ticket.createdAt, format: .dateTime.month().day()).frame(
                                    width: 85 * scale)
                            }
                        } else if columns == .medium {
                            HStack(alignment: .top, spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(ticket.subject).inquiryFont(16, weight: .medium)
                                    metadata(ticket)
                                }.frame(maxWidth: .infinity, alignment: .leading)
                                Text(ticket.status.rawValue)
                                Text(ticket.assignee)
                            }
                        } else {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ticket.subject).inquiryFont(16, weight: .medium)
                                Text(
                                    isOperator
                                        ? ticket.status.rawValue + " · " + ticket.assignee
                                        : ticket.status.rawValue)
                                if isOperator {
                                    metadata(ticket)
                                } else {
                                    Text(ticket.createdAt, format: .dateTime.year().month().day())
                                        .inquiryFont(13)
                                }
                            }
                        }
                    }.fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 8)
                        .contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityAddTraits(
                    highlightedID == ticket.id ? .isSelected : []
                )
                .focused($focusedTicket, equals: ticket.id)
                .id(ticket.id).onKeyPress(.return) {
                    highlightedID = ticket.id
                    selectedID = ticket.id
                    return .handled
                }
                Divider()
            }
        }.frame(
            maxWidth: .infinity, minHeight: tickets.isEmpty ? 180 * scale : 0,
            alignment: .topLeading)
    }
    private func metadata(_ ticket: SupportTicket) -> some View {
        Text(
            ticket.visibleTeam + " · " + ticket.label + " · "
                + ticket.createdAt.formatted(date: .abbreviated, time: .omitted)
        ).inquiryFont(13)
    }
}

@Observable final class SupportComposition {
    let id = UUID()
    var teamNames: [SupportTeam: String] = [:]
    var team: SupportTeam?
    var isOpen = false
    var subject = ""
    var content = ""
    var category = "출석·과제"
    var attachment: String?
    var referenceID: String?
    var readingID: String?
    var submitting = false
    var resultTicket: UUID?
    var submitKey: SupportPreviewTransport.Key {
        SupportPreviewTransport.createKey
    }
    var receipt: SupportPreviewTransport.Receipt?
    var edited: Bool {
        !subject.isEmpty || !content.isEmpty || team != nil || attachment != nil
            || category != "출석·과제"
    }
    var valid: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct SupportComposePreview: View {
    let articles: [SupportArticle]
    @Bindable var draft: SupportComposition
    var priorCreationPending = false
    let cancel: () -> Void
    let submit: () -> Void
    let reload: () -> Void
    @Environment(\.umcBodyTextScale) private var scale
    @FocusState private var teamFocused: Bool
    private var reference: SupportArticle? { articles.first { $0.id == draft.referenceID } }
    private var recommendation: SupportArticle? {
        reference ?? articles.first { $0.category == draft.category }
    }

    var body: some View {
        Group {
            if let reading = articles.first(where: { $0.id == draft.readingID }) {
                SupportAnswerDetail(
                    article: reading, back: { draft.readingID = nil }, fromComposition: true
                ) {
                    draft.referenceID = reading.id
                    draft.readingID = nil
                }
            } else {
                SupportReadingArea {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("문의하기").inquiryFont(28, weight: .bold).accessibilityAddTraits(
                            .isHeader)
                        Text("서비스 이용 중 겪은 문제를 알려주시면 UMC PRODUCT가 확인해 드려요.")
                        SupportPanelLayout(scale: scale) {
                            fields.disabled(draft.submitting).supportCard()
                            if let recommendation { recommended(recommendation).supportCard() }
                        }
                    }
                } actions: {
                    VStack(alignment: .leading, spacing: 8) {
                        if draft.receipt == .failed {
                            Text("문의를 보내지 못했어요. 작성한 내용을 확인하고 다시 보내 주세요.")
                        }
                        if draft.receipt == .uncertain {
                            Text("접수 결과를 확인할 수 없어요. 내 문의에서 새로 고침해 주세요.")
                            Button("다시 불러오기", action: reload)
                        }
                        SupportActionRow {
                            Button("취소", action: cancel)
                            Button(
                                draft.submitting
                                    ? "보내는 중…" : (draft.receipt == .failed ? "다시 보내기" : "문의 보내기")
                            ) {
                                guard draft.team != nil else {
                                    draft.isOpen = true
                                    return
                                }
                                submit()
                            }.buttonStyle(SupportActionStyle(prominent: true))
                                .disabled(
                                    !draft.valid || priorCreationPending || draft.submitting
                                        || draft.receipt == .uncertain
                                )
                        }
                    }
                }
            }
        }
        .onChange(of: articles) {
            if !articles.contains(where: { $0.id == draft.readingID }) { draft.readingID = nil }
            if !articles.contains(where: { $0.id == draft.referenceID }) {
                draft.referenceID = nil
            }
        }
        .onChange(of: draft.isOpen) { if !draft.isOpen { teamFocused = true } }
    }

    private var fields: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("받는 팀").inquiryFont(14, weight: .medium)
            Button {
                draft.isOpen = true
            } label: {
                HStack {
                    Text(draft.team.map { draft.teamNames[$0] ?? $0.rawValue } ?? "받는 팀 선택")
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer()
                    Image(systemName: "chevron.down").accessibilityHidden(true)
                }
            }.focused($teamFocused).accessibilityLabel("받는 팀 선택")
                .accessibilityValue(draft.team?.rawValue ?? "미선택")
            Picker("카테고리", selection: $draft.category) {
                ForEach(Set(articles.map(\.category) + [draft.category]).sorted(), id: \.self) {
                    Text($0)
                }
            }
            Text("제목").inquiryFont(14, weight: .medium)
            TextField("문의 제목", text: $draft.subject, axis: .vertical)
                .accessibilityIdentifier("support.compose.title").accessibilityLabel("문의 제목")
                .textFieldStyle(.roundedBorder)
            Text("문의 내용").inquiryFont(14, weight: .medium)
            TextEditor(text: $draft.content)
                .accessibilityIdentifier("support.compose.body").accessibilityLabel("문의 내용")
                .scrollContentBackground(.hidden)
                .inquiryFont(16).padding(12).frame(minHeight: 160 * scale)
                .background(UMCColor.Custom.backgroundSurfaceGreyWeak, in: .rect(cornerRadius: 12))
            Button {
                draft.attachment = draft.attachment == nil ? "오류 화면.png" : nil
            } label: {
                Label(
                    draft.attachment.map { $0 + " · 첨부 제거" } ?? "예시 파일 첨부",
                    systemImage: "paperclip")
            }.accessibilityValue(draft.attachment ?? "없음")
            Text("이미지·문서, 최대 50MB").inquiryFont(13)
        }
    }

    private func recommended(_ article: SupportArticle) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("먼저 확인해 보세요").inquiryFont(20, weight: .bold)
            Text(article.question).fixedSize(horizontal: false, vertical: true)
            Text("검증된 답변 · UMC PRODUCT").inquiryFont(13)
            Button("답변 확인하기") { draft.readingID = article.id }
            if let reference {
                VStack(alignment: .leading, spacing: 8) {
                    Text("참고한 답변").inquiryFont(13, weight: .medium)
                    Text(reference.question).inquiryFont(14)
                }.fixedSize(horizontal: false, vertical: true).padding(16)
                    .background(UMCColor.Semantic.surfaceBrandWeak, in: .rect(cornerRadius: 12))
            }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct SupportTeamOptions: View {
    @Environment(\.umcBodyTextScale) private var scale
    @FocusState private var focused: SupportTeam?
    @Bindable var recipient: SupportComposition

    var body: some View {
        ZStack {
            UMCColor.Custom.backgroundDimmed
                .onTapGesture { recipient.isOpen = false }
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("어느 팀에 문의할까요?").inquiryFont(20, weight: .bold)
                    Spacer()
                    Button("취소") { recipient.isOpen = false }.keyboardShortcut(.cancelAction)
                }
                Text("문의와 가까운 팀을 하나 선택하면 문의 작성 화면에 반영돼요.")
                ScrollView {
                    ViewThatFits(in: .horizontal) {
                        teamGrid(columns: 2).frame(
                            minWidth: SupportLayoutMetrics.teamGridMinimum(scale))
                        teamGrid(columns: 1)
                    }
                }
            }.padding(SupportLayoutMetrics.teamInset).frame(
                maxWidth: SupportLayoutMetrics.teamWidth, maxHeight: min(800, 587 * scale)
            )
            .background(UMCColor.Custom.backgroundSurface, in: .rect(cornerRadius: 16)).padding(16)
        }.onAppear { focused = recipient.team ?? .brand }
    }

    private func teamGrid(columns: Int) -> some View {
        let options = SupportTeam.allCases
        return VStack(spacing: 12) {
            ForEach(Array(stride(from: 0, to: options.count, by: columns)), id: \.self) { index in
                HStack(alignment: .top, spacing: 12) {
                    ForEach(options[index..<min(index + columns, options.count)], id: \.self) {
                        option in
                        teamButton(option)
                    }
                }
            }
        }
    }

    private func teamButton(_ option: SupportTeam) -> some View {
        Button {
            recipient.team = option
            recipient.isOpen = false
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                Text(recipient.teamNames[option] ?? option.rawValue).fixedSize(
                    horizontal: false, vertical: true
                ).inquiryFont(14, weight: .medium)
                Text(option.summary).inquiryFont(13)
                if recipient.team == option { Image(systemName: "checkmark") }
            }
            .padding(14).frame(
                maxWidth: .infinity, minHeight: 96, alignment: .leading
            )
            .background(
                UMCColor.Custom.backgroundSurfaceGreyWeaker,
                in: .rect(cornerRadius: 10)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(UMCColor.Semantic.borderNeutralMedium300)
            }
        }.buttonStyle(.plain).focused($focused, equals: option)
            .accessibilityAddTraits(recipient.team == option ? .isSelected : [])
    }
}
