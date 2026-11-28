//
//  SupportView.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/23/26.
//

import CoreDesignSystem
import CoreUIComponents
import SwiftUI
import UMCFoundation

struct SupportView: View {
    @Environment(\.umcWorkspaceModalHost) private var modalHost
    @Environment(\.tabToolsDismissalRequest) private var dismissTools
    private var scene = SupportScene.home
    @State private var operatorTicket: UUID?
    @State private var operatorEntry = UUID()
    private enum Page {
        case answers, inquiries
        case operations, faq
    }
    @State private var page = Page.answers
    @State private var composing = false
    @State private var recipient = SupportComposition()
    @State private var createdTicket: UUID?

    @State private var searchRequest = 0
    @State private var toolsOpen = false
    @State private var dirtyFAQ = false
    @State private var pendingLeave: (() -> Void)?
    @State private var receiptMessage = ""
    @State private var searchState = SupportSearchState()
    @Environment(\.umcBodyTextScale) private var scale
    @FocusState private var toolsFocused: Bool

    @State private var fixture: SupportFixture?

    init(
        designPreview: Bool,
        emptyInquiries: Bool
    ) {
        let preview = designPreview || emptyInquiries
        let initialFixture = preview ? SupportFixture(emptyInquiries: emptyInquiries) : nil
        _fixture = State(initialValue: initialFixture)
        _page = State(initialValue: emptyInquiries ? .inquiries : .answers)
    }

    init(fixture: SupportFixture, scene: SupportScene = .home) {
        self.scene = scene
        _fixture = State(initialValue: fixture)
        let operations: [SupportScene] = [
            .operations, .longOperations, .operatorDetail, .assignee, .labels, .operatorTools,
            .assigned,
            .labelsApplied, .labelsCancelled, .labelsChanged, .mine, .unassigned, .unclassified,
        ]
        if operations.contains(scene) { _page = State(initialValue: .operations) }
        if [
            .conversation, .longConversation, .waiting, .closed, .empty, .reopened,
            .conversationReference,
        ].contains(
            scene)
        {
            _page = State(initialValue: .inquiries)
            if scene != .empty {
                let ticket = fixture.myTickets.first { ticket in
                    switch scene {
                    case .closed: ticket.status == .closed
                    case .waiting: ticket.status == .received
                    default: ticket.status == .active
                    }
                }
                _createdTicket = State(initialValue: ticket?.id)
            }
        }
        if [.faqManagement, .faqDraft, .faqArchived, .faqEditing].contains(scene) {
            _page = State(initialValue: .faq)
        }
        let recipient = SupportComposition()
        recipient.isOpen = scene == .team || scene == .longTeam
        if scene == .longTeam {
            recipient.teamNames[.brand] =
                String(repeating: "운영 담당 ", count: 8).prefix(40).description
        }
        if [.compose, .team, .longTeam, .reference].contains(scene) {
            recipient.subject = "출석 기록 표시 오류"
            recipient.content = "앱에서 출석 기록이 실제와 다르게 표시돼요.\n새로고침해도 같아서 앱 버전과 오류 화면을 보내드립니다."
            recipient.attachment = "오류 화면.png"
            if scene == .reference { recipient.referenceID = fixture.publishedArticles.first?.id }
        }
        _recipient = State(initialValue: recipient)
        _composing = State(initialValue: [.compose, .team, .longTeam, .reference].contains(scene))
        _toolsOpen = State(initialValue: [.userTools, .operatorTools].contains(scene))
        if [
            .operatorDetail, .assignee, .labels, .assigned, .labelsChanged, .labelsApplied,
            .labelsCancelled,
        ].contains(scene) {
            _operatorTicket = State(initialValue: fixture.tickets.first?.id)
        }
    }

    init() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("--support-preview"),
            let flag = arguments.firstIndex(of: "--support-scene"),
            let value = arguments.dropFirst(flag + 1).first,
            let scene = SupportScene(rawValue: value)
        {
            self.init(fixture: SupportFixture(scene: scene), scene: scene)
            return
        }
        self.init(
            designPreview: arguments.contains("--support-preview"),
            emptyInquiries: arguments.contains("--support-preview-empty"))
        #else
        self.init(designPreview: false, emptyInquiries: false)
        #endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                if let fixture {
                    Menu("데이터 미리보기") {
                        Button("사용자 · 많이 묻는 질문") { navigate(.answers) }
                        Button("운영 · 문의 관리") { navigate(.operations) }.disabled(
                            fixture.transport.access != .granted)
                        Divider()
                        Picker(
                            "예시 운영 권한",
                            selection: Binding(
                                get: { fixture.transport.access },
                                set: { fixture.transport.access = $0 })
                        ) {
                            ForEach(SupportPreviewTransport.Access.allCases, id: \.self) {
                                Text($0.rawValue)
                            }
                        }
                        Picker(
                            "다음 쓰기 결과",
                            selection: Binding(
                                get: { fixture.transport.nextWrite },
                                set: { fixture.transport.nextWrite = $0 })
                        ) {
                            ForEach(SupportPreviewTransport.Outcome.allCases, id: \.self) {
                                Text($0.rawValue)
                            }
                        }
                        Button("새 조회 실패 재현") {
                            fixture.transport.prepareInitialRead()
                            fixture.transport.nextReadFails = true
                            Task { await fixture.transport.reload() }
                        }
                        Button("기존 목록 갱신 실패 재현") {
                            fixture.transport.nextReadFails = true
                            Task { await fixture.transport.reload() }
                        }
                    }.fixedSize()
                }
                Spacer()
                Button(
                    page == .operations || page == .faq ? "문의 관리 도구" : "문의 도구",
                    systemImage: "slider.horizontal.3"
                ) { toolsOpen.toggle() }.focused($toolsFocused)

            }.padding(.horizontal, 40).frame(height: 44)
            Divider()
            if let fixture {
                if !receiptMessage.isEmpty { Text(receiptMessage).inquiryFont(14) }
                if fixture.transport.access != .granted {
                    Text(
                        fixture.transport.access == .checking
                            ? "운영 권한을 확인하고 있어요." : "운영 권한이 없어 사용자 고객센터를 표시해요."
                    ).inquiryFont(13)
                }
                if fixture.transport.read != .ready {
                    HStack {
                        if fixture.transport.read == .failed {
                            Text("문의를 불러오지 못했어요.")
                            Button("다시 불러오기") { Task { await fixture.transport.reload() } }
                        } else {
                            ProgressView().controlSize(.small)
                            Text(fixture.transport.hasSnapshot ? "문의를 갱신하는 중" : "문의를 불러오는 중")
                        }
                    }.padding(8)
                }
            }
            SupportContentInsets {
                VStack(alignment: .leading, spacing: 16) {
                    if composing, let fixture {
                        SupportComposePreview(
                            articles: articles, draft: recipient,
                            cancel: { leaveComposition { composing = false } },
                            submit: { submitComposition(fixture) },
                            reload: { Task { await fixture.transport.reload() } })
                    } else if fixture?.transport.hasSnapshot == false {
                        Spacer()
                    } else {
                        switch page {
                        case .faq:
                            if let fixture, fixture.transport.access == .granted {
                                SupportFAQPreview(
                                    fixture: fixture, scene: scene, onDirty: { dirtyFAQ = $0 }
                                ) {
                                    navigate(.operations)
                                }
                            }
                        case .answers:
                            SupportAnswersView(
                                articles: articles, state: searchState, scene: scene,
                                searchRequest: searchRequest,
                                showInquiries: { page = .inquiries },
                                compose: fixture == nil
                                    ? nil
                                    : { article in
                                        beginCompose(article)
                                    }
                            )
                        case .inquiries:
                            inquiries
                        case .operations:
                            if let fixture, fixture.transport.access == .granted {
                                SupportInquiryPreview(
                                    fixture: fixture, isOperator: true,
                                    initialTicket: operatorTicket,
                                    scene: scene, selectTicket: { operatorTicket = $0 },
                                    onFAQDirty: { dirtyFAQ = $0 }
                                ) { page = .answers }
                                .id(operatorEntry)
                            }
                        }
                    }
                }.frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
        .frame(
            minWidth: 560, maxWidth: .infinity, minHeight: 420, maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(UMCColor.Custom.backgroundSurface)
        .inquiryFont(14)
        .buttonStyle(SupportActionStyle())
        .tint(UMCColor.Semantic.textBrandDefault)
        .overlay(alignment: .topTrailing) {
            if toolsOpen {
                ZStack(alignment: .topTrailing) {
                    Color.clear.contentShape(Rectangle()).onTapGesture { toolsOpen = false }
                        .accessibilityHidden(true)
                    ViewThatFits(in: .vertical) {
                        toolsPanel
                        ScrollView { toolsPanel }
                    }
                    .frame(maxWidth: SupportLayoutMetrics.toolWidth)
                    .background(
                        UMCColor.Custom.backgroundSurfaceWhite, in: .rect(cornerRadius: 16)
                    )
                    .shadow(color: .black.opacity(0.13), radius: 12, y: 8)
                    .padding(.horizontal, SupportLayoutMetrics.edge).padding(.top, 48).padding(
                        .bottom, 16)
                }
            }
        }
        .alert(
            dirtyFAQ ? "FAQ 편집을 취소할까요?" : "작성 중인 문의를 취소할까요?",
            isPresented: Binding(
                get: { pendingLeave != nil }, set: { if !$0 { pendingLeave = nil } })
        ) {
            Button("계속 작성", role: .cancel) { pendingLeave = nil }
            Button("작성 취소", role: .destructive) {
                let action = pendingLeave
                pendingLeave = nil
                action?()
            }
        }
        .onChange(of: fixture?.transport.access) {
            guard fixture?.transport.access != .granted else { return }
            operatorTicket = nil
            operatorEntry = UUID()
            toolsOpen = false
            dirtyFAQ = false
            pendingLeave = nil
            if page == .operations || page == .faq {
                page = .answers
                composing = false
            }
        }
        .onChange(of: toolsOpen) { if !toolsOpen { toolsFocused = true } }
        .onChange(of: dismissTools) { toolsOpen = false }
        .disabled(recipient.isOpen)
        .accessibilityHidden(recipient.isOpen)
        .overlay {
            if recipient.isOpen && modalHost == nil { SupportTeamOptions(recipient: recipient) }
        }
        .onChange(of: recipient.isOpen, initial: true) {
            guard let modalHost else { return }
            modalHost.content =
                recipient.isOpen ? AnyView(SupportTeamOptions(recipient: recipient)) : nil
        }
        .onDisappear { if recipient.isOpen { modalHost?.content = nil } }
    }

    private var toolsPanel: some View {
        let operating = page == .operations || page == .faq
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(operating ? "문의 관리 도구" : "문의 도구").inquiryFont(16, weight: .bold)
                Spacer()
                Button {
                    toolsOpen = false
                } label: {
                    Image(systemName: "xmark")
                }
                .buttonStyle(.plain).accessibilityLabel("닫기").keyboardShortcut(.cancelAction)
            }
            Text(operating ? "UMC PRODUCT 구성원만 사용할 수 있는 관리 도구예요." : "답을 찾아보고 내 문의를 이어가세요.")
                .inquiryFont(12)
            if operating, fixture != nil {
                Button {
                    navigate(.faq)
                } label: {
                    Text("FAQ 작성 · 관리").frame(maxWidth: .infinity)
                }
                .buttonStyle(SupportActionStyle(prominent: true))
                Text("UMC PRODUCT 전용").inquiryFont(12)
                Button("문의 관리 목록") {
                    operatorTicket = nil
                    operatorEntry = UUID()
                    navigate(.operations)
                }
                Button("선택한 문의 확인") {
                    operatorTicket = operatorTicket ?? fixture?.tickets.first?.id
                    operatorEntry = UUID()
                    navigate(.operations)
                }
                Button("많이 묻는 질문 보기") { navigate(.answers) }
            } else {
                Button {
                    leaveComposition {
                        composing = false
                        page = .answers
                        searchState = SupportSearchState()
                        searchRequest += 1
                        toolsOpen = false
                    }
                } label: {
                    HStack {
                        Text("도움말 검색")
                        Spacer()
                        Text("⌘F")
                    }
                }
                if fixture != nil {
                    Button {
                        toolsOpen = false
                        beginCompose(nil)
                    } label: {
                        Text("새 문의 작성").frame(maxWidth: .infinity)
                    }.buttonStyle(SupportActionStyle(prominent: true))
                }
                Text("도움말과 내 문의").inquiryFont(12)
                Button("많이 묻는 질문") { navigate(.answers) }
                Button("내 문의 현황") { navigate(.inquiries) }
            }
            Spacer(minLength: 0)
            HStack {
                Text("상단 도구 버튼으로 다시 열 수 있어요")
                Spacer()
                Text("Esc")
            }.inquiryFont(11)
        }.padding(20).fixedSize(horizontal: false, vertical: true).frame(
            maxWidth: .infinity, alignment: .topLeading)
    }

    private func beginCompose(_ article: SupportArticle?) {
        if composing {
            toolsOpen = false
            return
        }
        recipient = SupportComposition()
        recipient.referenceID = article?.id
        recipient.category = article?.category ?? "출석·과제"
        receiptMessage = ""
        composing = true
    }

    private func leaveComposition(_ action: @escaping () -> Void) {
        toolsOpen = false
        guard !recipient.submitting else { return }
        if (composing && recipient.edited) || dirtyFAQ { pendingLeave = action } else { action() }
    }

    private func navigate(_ next: Page) {
        leaveComposition {
            if (page == .operations || page == .faq) && next != .operations && next != .faq {
                operatorTicket = nil
                operatorEntry = UUID()
            }
            dirtyFAQ = false
            composing = false
            page = next
        }
    }

    private func submitComposition(_ fixture: SupportFixture) {
        let draft = recipient
        guard draft.valid, let team = draft.team, !draft.submitting else { return }
        draft.submitting = true
        Task { @MainActor in
            var id: UUID?
            let result = await fixture.transport.send(
                id: draft.id, hasAttachment: draft.attachment != nil
            ) { attach in
                id = fixture.create(
                    subject: draft.subject, content: draft.content, team: team,
                    category: draft.category,
                    reference: draft.referenceID.flatMap(fixture.publishedArticle(id:)),
                    attachmentName: attach ? draft.attachment : nil)
                return id != nil
            }
            draft.receipt = result
            draft.submitting = false
            guard result.acknowledged, recipient === draft, composing, let id else { return }
            createdTicket = id
            if result == .refreshFailed { receiptMessage = "접수했어요. 목록을 다시 불러와 주세요." }
            if result == .attachmentFailed { receiptMessage = "문의는 접수했어요. 예시 파일 첨부는 실패했어요." }
            composing = false
            page = .inquiries
        }
    }

    private var articles: [SupportArticle] {
        if let fixture { return fixture.publishedArticles }
        return SupportArticle.appGuide
    }

    @ViewBuilder private var inquiries: some View {
        if let fixture {
            SupportInquiryPreview(
                fixture: fixture, initialTicket: createdTicket, beginCompose: { beginCompose(nil) }
            ) { page = .answers }
            .onAppear { createdTicket = nil }
        } else {
            serviceStatus
        }
    }

    private var serviceStatus: some View {
        ContentUnavailableView {
            Label(AppLocalization.string("문의 접수 준비 중"), systemImage: "bubble.left")
        } description: {
            Text(AppLocalization.string("앱에서 문의를 보내거나 답변을 조회하는 기능을 준비하고 있어요."))
        } actions: {
            Button(AppLocalization.string("답변 찾아보기")) { page = .answers }
        }
    }
}

@Observable private final class SupportSearchState {
    var initialized = false
    var typingSearch = false
    var choosingSearch = false
    var category: String?
    var weekly = false
    var refreshed = false
    var search = ""
    var selectedID: String?
    var detailID: String?
}

private struct SupportAnswersView: View {
    private enum Focus { case search, table, back }
    let articles: [SupportArticle]
    @Bindable var state: SupportSearchState
    @Environment(\.umcBodyTextScale) var scale
    var scene = SupportScene.home
    let searchRequest: Int
    let showInquiries: () -> Void
    let compose: ((SupportArticle?) -> Void)?
    private var detail: SupportArticle? { articles.first { $0.id == state.detailID } }
    @FocusState private var focus: Focus?

    private var categories: [String] {
        articles.map(\.category).filter { !$0.isEmpty }.reduce(into: []) {
            if !$0.contains($1) { $0.append($1) }
        }
    }

    private var showsRanking: Bool {
        state.search.isEmpty && state.category == nil && articles.contains { $0.dayReaders != nil }
    }

    private func readers(_ article: SupportArticle) -> Int? {
        if state.refreshed, article.id == "login" { return state.weekly ? 138 : 34 }
        if state.refreshed, article.id == "attendance" { return state.weekly ? 128 : 30 }
        return state.weekly ? article.weekReaders : article.dayReaders
    }

    private var matches: [SupportArticle] {
        let filtered = articles.filter {
            $0.matches(state.search) && (state.category == nil || state.category == $0.category)
        }
        guard showsRanking else { return filtered }
        return filtered.filter { readers($0) != nil }.sorted {
            (readers($0) ?? 0) > (readers($1) ?? 0)
        }
    }

    var body: some View {
        Group {
            if let detail {
                SupportAnswerDetail(
                    article: detail, initiallyResolved: scene == .resolved,
                    back: { state.detailID = nil },
                    inquire: compose.map { action in { action(detail) } })
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if !state.choosingSearch && state.search.isEmpty {
                            HStack(alignment: .center) {
                                VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                                    Text("문의").inquiryFont(28, weight: .bold)
                                        .accessibilityAddTraits(
                                            .isHeader)
                                    Group {
                                        Text("서비스 이용 중 궁금한 점은 답변을 찾거나 UMC PRODUCT에 문의해 주세요.")
                                            .foregroundStyle(
                                                UMCColor.Semantic.textNeutralStrong800)
                                    }
                                }
                                Spacer()
                                if let compose {
                                    Button("문의하기") { compose(nil) }
                                        .buttonStyle(SupportActionStyle(prominent: true))
                                }
                            }
                            HStack(spacing: 8) {
                                Button {
                                    state.choosingSearch = false
                                    state.search = ""
                                } label: {
                                    Text("많이 묻는 질문").frame(minWidth: 128, minHeight: 48)
                                }.buttonStyle(SupportActionStyle(selected: true))
                                Button(action: showInquiries) {
                                    Text("내 문의").frame(minWidth: 72, minHeight: 48)
                                }
                            }
                        } else {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("FAQ 검색").inquiryFont(28, weight: .bold)
                                    Text(
                                        state.search.isEmpty
                                            ? "서비스 이용 중 궁금한 내용을 찾아보세요." : "검색어 · " + state.search
                                    )
                                    .inquiryFont(14)
                                }
                                Spacer()
                                Button("많이 묻는 질문") {
                                    state.search = ""
                                    state.choosingSearch = false
                                }
                            }
                        }
                        Group {
                            HStack(spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass").foregroundStyle(
                                        .secondary)
                                    SupportInputField(
                                        "FAQ 제목·분류·답변 검색", identifier: "support.search",
                                        text: $state.search,
                                        focusRequest: searchRequest,
                                        onFocus: {
                                            state.typingSearch = true
                                            state.choosingSearch = true
                                        },
                                        submit: {
                                            if state.search.isEmpty {
                                                state.choosingSearch = true
                                            } else {
                                                focusResults()
                                            }
                                        },
                                        moveDown: { focusResults() }
                                    )
                                    .focused($focus, equals: .search)
                                    .frame(minHeight: 28 * scale)
                                    .onChange(of: state.search) { state.selectedID = nil }
                                }.padding(.horizontal, 12).frame(height: 40)
                                    .background(
                                        UMCColor.Custom.backgroundSurfaceGreyWeak,
                                        in: .rect(cornerRadius: 12))
                                Button("검색") {
                                    if state.search.isEmpty {
                                        state.choosingSearch = true
                                        focus = .search
                                    } else {
                                        focusResults()
                                    }
                                }
                            }.padding(.horizontal, 16).frame(minHeight: 52)
                                .background(
                                    UMCColor.Custom.backgroundSurfaceWhite,
                                    in: .rect(cornerRadius: 12))
                        }
                        if state.choosingSearch && state.search.isEmpty {
                            Spacer()
                            Text("어떤 내용을 찾으시나요?").inquiryFont(28, weight: .bold)
                                .frame(maxWidth: .infinity)
                            Text("예시 검색어를 선택해 FAQ를 찾아보세요.").frame(maxWidth: .infinity)
                            HStack {
                                Button {
                                    state.typingSearch = false
                                    state.search = "출석·과제"
                                } label: {
                                    Text("출석·과제").inquiryFont(13, weight: .medium).padding(
                                        .horizontal, 8
                                    ).frame(minWidth: 144, minHeight: 48)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(UMCColor.Primitives.black)
                                .background(
                                    UMCColor.Primitives.teal500, in: .rect(cornerRadius: 8)
                                )
                                .overlay {
                                    RoundedRectangle(cornerRadius: 8).strokeBorder(
                                        UMCColor.Semantic.borderNeutralWeaker100, lineWidth: 2)
                                }
                                .environment(\.colorScheme, .light)
                                Button {
                                    state.typingSearch = false
                                    state.search = "영수증"
                                } label: {
                                    Text("영수증").inquiryFont(13, weight: .medium).padding(
                                        .horizontal, 8
                                    ).frame(minWidth: 144, minHeight: 48)
                                }
                                .buttonStyle(.plain)
                                .foregroundStyle(UMCColor.Custom.backgroundTextWhite)
                                .background(
                                    Color(
                                        red: 0.3762000203, green: 0.38379999995, blue: 0.3832932711
                                    ),
                                    in: .rect(cornerRadius: 8))
                            }.frame(maxWidth: .infinity)
                            Button("직접 입력") {
                                state.typingSearch = true
                                focus = .search
                            }
                            .frame(maxWidth: .infinity)
                            Spacer()
                        }
                        if let category = state.category {
                            Button {
                                state.category = nil
                            } label: {
                                Label(category, systemImage: "xmark.circle")
                            }
                            .accessibilityHint(AppLocalization.string("카테고리 필터 해제"))
                        }
                        if !state.search.isEmpty && !matches.isEmpty {
                            HStack {
                                Text("검색 결과 \(matches.count)건")
                                    .inquiryFont(16)
                                Spacer()
                                Button("다시 검색") {
                                    state.choosingSearch = true
                                    state.search = ""
                                    focus = .search
                                }
                            }
                        }
                        if state.choosingSearch && state.search.isEmpty {
                            EmptyView()
                        } else if matches.isEmpty {
                            VStack(spacing: 16) {
                                Text("‘" + state.search + "’에 대한 검색 결과가 없어요").inquiryFont(
                                    28, weight: .bold)
                                Text("다른 검색어로 찾아보거나 UMC PRODUCT에 문의해 주세요.").inquiryFont(15)
                                HStack(spacing: 12) {
                                    Button("다시 검색") {
                                        state.search = ""
                                        state.choosingSearch = true
                                    }
                                    if let compose {
                                        Button("문의하기") { compose(nil) }
                                            .buttonStyle(SupportActionStyle(prominent: true))
                                    }
                                }
                            }.frame(maxWidth: .infinity, maxHeight: .infinity).supportCard()
                        } else {
                            SupportPanelLayout(scale: scale) {
                                results
                                if state.search.isEmpty {
                                    helpPanel
                                }
                            }
                            if showsRanking { Text("같은 사람의 반복 접수는 한 번만 집계해요.").inquiryFont(13) }
                            if showsRanking && !state.refreshed {
                                HStack {
                                    Text("새 순위가 있어요. 읽던 목록은 그대로 유지했어요.")
                                    Spacer()
                                    Button("새 순위 보기") { state.refreshed = true }
                                }.padding(12)
                            }
                        }
                    }
                }
            }
        }.onChange(of: articles) {
            if state.detailID != nil && detail == nil {
                state.detailID = nil
                state.selectedID = nil
            }
        }.onChange(of: searchRequest) {
            if searchRequest > 0 {
                state.choosingSearch = true
                state.typingSearch = true
                focus = .search
            }
        }.onAppear {
            guard !state.initialized else { return }
            state.initialized = true
            if [.detail, .resolved, .longFAQ].contains(scene) {
                state.detailID = articles.first?.id
            }
            if scene == .results {
                state.choosingSearch = true
                state.search = "출석·과제"
            }
            if scene == .noResults {
                state.choosingSearch = true
                state.search = "영수증"
            }
            if [.refreshed, .weeklyRefreshed].contains(scene) { state.refreshed = true }
            if [.weekly, .weeklyRefreshed].contains(scene) { state.weekly = true }
            if scene == .search || searchRequest > 0 { state.choosingSearch = true }
        }
    }

    private var helpPanel: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
            Text(AppLocalization.string("카테고리별 답변"))
                .inquiryFont(18, weight: .bold).accessibilityAddTraits(.isHeader)
            if compose != nil { Text("UMC PRODUCT가 확인한 서비스 이용 답변을 보여요.") }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                categoryButtons
            }
            Divider()
            Text(AppLocalization.string("아직 해결되지 않았나요?")).inquiryFont(16, weight: .bold)
            if let compose {
                Text("해결되지 않는 문제는 UMC PRODUCT 담당자가 도와드려요.").inquiryFont(13)
                Button("문의하기") { compose(nil) }.buttonStyle(SupportActionStyle(prominent: true))
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            UMCColor.Custom.backgroundSurfaceGreyWeak,
            in: .rect(cornerRadius: UMCRadius.value16))
    }

    private var categoryButtons: some View {
        ForEach(categories, id: \.self) { name in
            Button(name) {
                if let article = articles.first(where: { $0.category == name }) { open(article) }
            }
        }
    }

    private var results: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value8) {
            if showsRanking {
                VStack(alignment: .leading, spacing: 8) {
                    Text("실시간 인기 문의").inquiryFont(22, weight: .bold)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    HStack(spacing: 8) {
                        ForEach([false, true], id: \.self) { week in
                            Button {
                                state.weekly = week
                            } label: {
                                Text(
                                    (week == state.weekly ? "✓ " : "")
                                        + (week ? "최근 7일" : "최근 24시간")
                                )
                                .frame(minHeight: 48)
                            }
                            .accessibilityAddTraits(week == state.weekly ? .isSelected : [])
                        }
                    }
                }
            }
            if showsRanking {
                HStack {
                    Text(state.weekly ? "최근 7일" : "최근 24시간")
                    Spacer()
                    Text(state.refreshed ? "마지막 갱신 14:33" : "마지막 갱신 14:32")
                }.inquiryFont(13)
            }
            List(selection: $state.selectedID) {
                ForEach(Array(matches.enumerated()), id: \.element.id) { index, article in
                    Button {
                        open(article)
                    } label: {
                        HStack(spacing: 20) {
                            if showsRanking {
                                Text(String(index + 1)).inquiryFont(18, weight: .bold)
                                    .frame(width: 40, height: 40)
                                    .background(
                                        index == 0
                                            ? UMCColor.Semantic.surfaceBrandWeak
                                            : UMCColor.Custom.backgroundSurfaceGreyWeak,
                                        in: .rect(cornerRadius: 8))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(article.question).inquiryFont(17, weight: .medium)
                                Text(article.category).inquiryFont(13)
                                if !state.search.isEmpty {
                                    Text(article.answer).inquiryFont(14).lineLimit(2)
                                }

                            }
                            Spacer()
                            if !state.search.isEmpty { Text("답변 보기") }
                            if showsRanking, let count = readers(article) { Text("\(count)명 문의") }
                        }.padding(.vertical, 12).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain).tag(article.id)
                }
            }
            .frame(height: CGFloat(max(1, matches.count)) * (showsRanking ? 80 : 110) * scale)
            .listStyle(.plain)
            .environment(\.defaultMinListRowHeight, showsRanking ? 76 : 56)
            .accessibilityIdentifier("support.faq.table")
            .focused($focus, equals: .table)
            .task {
                guard state.selectedID != nil else { return }
                // A returning table receives its AppKit responder after insertion.
                await Task.yield()
                guard !Task.isCancelled else { return }
                focus = .table
            }
            .contextMenu(forSelectionType: String.self) { _ in
            } primaryAction: { ids in
                if let article = matches.first(where: { ids.contains($0.id) }) { open(article) }
            }
            .onKeyPress(.return) {
                guard let article = matches.first(where: { $0.id == state.selectedID }) else {
                    return .ignored
                }
                open(article)
                return .handled
            }
        }
    }

    private func focusResults() {
        guard let first = matches.first else { return }
        state.selectedID = first.id
        focus = .table
    }

    private func open(_ article: SupportArticle) {
        state.selectedID = article.id
        state.detailID = article.id
    }
}

/// The system draws a white label on selected segments and prominent buttons.
struct SupportControlFill: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.tint(
            colorScheme == .dark
                ? UMCColor.Semantic.fillPrimaryStrong200 : UMCColor.Semantic.textBrandDefault)
    }
}

struct SupportAnswerDetail: View {
    let article: SupportArticle
    @Environment(\.umcBodyTextScale) var scale
    var initiallyResolved = false
    let back: () -> Void
    var fromComposition = false
    let inquire: (() -> Void)?
    @State private var resolved = false
    @FocusState private var backFocused: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("자주 묻는 질문").inquiryFont(28, weight: .bold).accessibilityAddTraits(.isHeader)
                Text("UMC PRODUCT가 확인한 서비스 이용 답변을 확인하세요.")
            }
            Spacer()
            Button("목록으로", action: back).keyboardShortcut(.cancelAction)
                .focused($backFocused)
        }
        ScrollView {
            SupportPanelLayout(scale: scale, fraction: 902 / 1258) {
                VStack(alignment: .leading, spacing: 16) {
                    if inquire != nil {
                        Text("검증된 답변").inquiryFont(13, weight: .medium)
                            .padding(6).background(
                                UMCColor.Semantic.surfaceBrandWeak, in: .capsule)
                    }
                    Text(article.question).inquiryFont(28, weight: .bold).accessibilityAddTraits(
                        .isHeader)
                    Text(article.category + (inquire == nil ? "" : " · UMC 서비스")).inquiryFont(13)
                    Divider()
                    SupportSelectableText(article.answer).inquiryFont(16)
                        .fixedSize(horizontal: false, vertical: true).frame(
                            maxWidth: 720 * scale, alignment: .leading)
                    if let inquire {
                        SupportActionRow {
                            Button("해결됐어요") {
                                resolved = true
                                AccessibilityNotification.Announcement("해결 응답을 기록했어요.").post()
                            }.disabled(resolved)
                            Button(fromComposition ? "참고 답변으로 추가" : "담당자에게 문의하기", action: inquire)
                                .buttonStyle(SupportActionStyle(prominent: true))
                        }
                        if resolved {
                            Text("✓ 해결 응답을 기록했어요. 문의가 새로 등록되지는 않아요.")
                                .inquiryFont(13).foregroundStyle(
                                    UMCColor.Semantic.textBrandDefault)
                        }
                    }
                }.supportCard()
                VStack(alignment: .leading, spacing: 24) {
                    Text("답변 정보").inquiryFont(18, weight: .bold)
                    Text("적용 대상\n" + article.audience)
                    if inquire != nil {
                        Text("검증한 조직\nUMC PRODUCT")
                        Text("수정일\n2026.09.30")
                    }
                    Divider()
                    Text(
                        "관련 안내\n" + (article.id == "attendance" ? "출석 화면 오류 안내" : article.category)
                    )
                    Spacer()
                    if article.id == "attendance" {
                        Text("UMC PRODUCT가 앱의 표시·동기화 오류를 확인해 드려요. 출석 인정이나 학사 판단은 이 문의에서 처리하지 않아요.")
                            .inquiryFont(13)
                    }
                }.frame(maxWidth: .infinity, alignment: .leading).supportCard()
            }
        }
        .onAppear {
            resolved = initiallyResolved
            backFocused = true
        }
    }
}

struct SupportActionStyle: ButtonStyle {
    var prominent = false
    var selected = false
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .inquiryFont(13, weight: .medium).tracking(0)
            .padding(.horizontal, 16)
            .frame(minWidth: prominent ? 144 : nil, minHeight: prominent ? 40 : 36)
            .foregroundStyle(
                prominent
                    ? UMCColor.Semantic.textInverse
                    : UMCColor.Semantic.textNeutralDefault
            )
            .background(
                prominent
                    ? UMCColor.Semantic.textBrandDefault
                    : (selected
                        ? UMCColor.Semantic.surfaceBrandWeak
                        : UMCColor.Custom.backgroundSurfaceGreyWeaker), in: .rect(cornerRadius: 8)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(
                        contrast == .increased
                            ? UMCColor.Semantic.textNeutralMedium600
                            : UMCColor.Semantic.borderNeutralWeak200,
                        lineWidth: contrast == .increased ? 2 : (prominent ? 0 : 1))
            }
            .opacity(enabled ? (configuration.isPressed ? 0.75 : 1) : 0.5)
    }
}
