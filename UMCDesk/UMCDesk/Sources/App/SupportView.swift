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
    @State private var recipient = SupportRecipient()
    @State private var createdTicket: UUID?

    @State private var searchRequest = 0
    @State private var toolsOpen = false
    @State private var reference: SupportArticle?

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
            .operations, .operatorDetail, .assignee, .labels, .operatorTools, .assigned,
            .labelsApplied, .labelsCancelled, .labelsChanged, .mine, .unassigned, .unclassified,
        ]
        if operations.contains(scene) { _page = State(initialValue: .operations) }
        if [.conversation, .waiting, .closed, .empty, .reopened, .conversationReference].contains(
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
        let recipient = SupportRecipient()
        recipient.isOpen = scene == .team
        _recipient = State(initialValue: recipient)
        _composing = State(initialValue: [.compose, .team, .reference].contains(scene))
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
                if fixture != nil {
                    Menu("데이터 미리보기") {
                        Button("사용자 · 많이 묻는 질문") { navigate(.answers) }
                        Button("운영 · 문의 관리") { navigate(.operations) }
                    }.fixedSize()
                }
                Spacer()
                Button(
                    page == .operations || page == .faq ? "문의 관리 도구" : "문의 도구",
                    systemImage: "slider.horizontal.3"
                ) { toolsOpen.toggle() }

            }.padding(.horizontal, 40).frame(height: 44)
            Divider()
            VStack(alignment: .leading, spacing: 16) {
                if composing, let fixture {
                    SupportComposePreview(
                        articles: articles, scene: scene, recipient: recipient,
                        cancel: { composing = false },
                        submit: { subject, content, team, category, reference, attachment in
                            createdTicket = fixture.create(
                                subject: subject, content: content, team: team, category: category,
                                reference: reference, attachmentName: attachment)
                            if createdTicket != nil { navigate(.inquiries) }
                        }, reference: reference)
                } else {
                    switch page {
                    case .faq:
                        if let fixture {
                            SupportFAQPreview(fixture: fixture, scene: scene) {
                                navigate(.operations)
                            }
                        }
                    case .answers:
                        SupportAnswersView(
                            articles: articles, scene: scene, searchRequest: searchRequest,
                            showInquiries: { page = .inquiries },
                            compose: fixture == nil
                                ? nil
                                : { article in
                                    beginCompose(article)
                                }
                        ).id(searchRequest)
                    case .inquiries:
                        inquiries
                    case .operations:
                        if let fixture {
                            SupportInquiryPreview(
                                fixture: fixture, isOperator: true, initialTicket: operatorTicket,
                                scene: scene, selectTicket: { operatorTicket = $0 }
                            ) { page = .answers }
                            .id(operatorEntry)
                        }
                    }
                }
            }.padding(.leading, 40).padding(.trailing, 54).padding(.vertical, 24)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .frame(
            minWidth: 560, maxWidth: .infinity, minHeight: 420, maxHeight: .infinity,
            alignment: .topLeading
        )
        .background(UMCColor.Custom.backgroundSurface)
        .buttonStyle(SupportActionStyle())
        .tint(UMCColor.Semantic.textBrandDefault)
        .overlay(alignment: .topTrailing) {
            if toolsOpen {
                ZStack(alignment: .topTrailing) {
                    Color.clear.contentShape(Rectangle()).onTapGesture { toolsOpen = false }
                        .accessibilityHidden(true)
                    toolsPanel
                        .background(
                            UMCColor.Custom.backgroundSurfaceWhite, in: .rect(cornerRadius: 16)
                        )
                        .shadow(color: .black.opacity(0.13), radius: 12, y: 8)
                        .padding(.trailing, 48).padding(.top, 63)
                }
            }
        }
        .onChange(of: dismissTools) { toolsOpen = false }
        .disabled(recipient.isOpen)
        .accessibilityHidden(recipient.isOpen)
        .overlay { if recipient.isOpen { SupportTeamOptions(recipient: recipient) } }
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
                    navigate(.answers)
                    searchRequest += 1
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
        }.padding(20).frame(width: 390, height: operating ? 359 : 371, alignment: .topLeading)
    }

    private func beginCompose(_ article: SupportArticle?) {
        recipient = SupportRecipient()
        reference = article
        composing = true
    }

    private func navigate(_ next: Page) {
        toolsOpen = false
        composing = false
        page = next
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

private struct SupportAnswersView: View {
    private enum Focus { case search, table, back }
    let articles: [SupportArticle]
    var scene = SupportScene.home
    let searchRequest: Int
    let showInquiries: () -> Void
    let compose: ((SupportArticle?) -> Void)?
    @State private var typingSearch = false
    @State private var choosingSearch = false
    @State private var category: String?
    @State private var weekly = false
    @State private var refreshed = false
    @State private var search = ""
    @State private var selectedID: String?
    @State private var detailID: String?
    private var detail: SupportArticle? { articles.first { $0.id == detailID } }
    @FocusState private var focus: Focus?

    private var categories: [String] {
        articles.map(\.category).filter { !$0.isEmpty }.reduce(into: []) {
            if !$0.contains($1) { $0.append($1) }
        }
    }

    private var showsRanking: Bool {
        search.isEmpty && category == nil && articles.contains { $0.dayReaders != nil }
    }

    private func readers(_ article: SupportArticle) -> Int? {
        if refreshed, article.id == "login" { return weekly ? 138 : 34 }
        if refreshed, article.id == "attendance" { return weekly ? 128 : 30 }
        return weekly ? article.weekReaders : article.dayReaders
    }

    private var matches: [SupportArticle] {
        let filtered = articles.filter {
            $0.matches(search) && (category == nil || category == $0.category)
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
                    back: { detailID = nil },
                    inquire: compose.map { action in { action(detail) } })
            } else {
                if !choosingSearch && search.isEmpty {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                            Text("문의").inquiryFont(28, weight: .bold).accessibilityAddTraits(
                                .isHeader)
                            Group {
                                Text("서비스 이용 중 궁금한 점은 답변을 찾거나 UMC PRODUCT에 문의해 주세요.")
                                    .foregroundStyle(UMCColor.Semantic.textNeutralStrong800)
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
                            choosingSearch = false
                            search = ""
                        } label: {
                            Text("많이 묻는 질문").frame(width: 128, height: 48)
                        }.buttonStyle(SupportActionStyle(selected: true))
                        Button(action: showInquiries) { Text("내 문의").frame(width: 72, height: 48) }
                    }
                } else {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("FAQ 검색").inquiryFont(28, weight: .bold)
                            Text(search.isEmpty ? "서비스 이용 중 궁금한 내용을 찾아보세요." : "검색어 · " + search)
                                .inquiryFont(14)
                        }
                        Spacer()
                        Button("많이 묻는 질문") {
                            search = ""
                            choosingSearch = false
                        }
                    }
                }
                if !choosingSearch || typingSearch {
                    HStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                            TextField(AppLocalization.string("궁금한 내용을 검색하세요"), text: $search)
                                .textFieldStyle(.plain)
                                .accessibilityIdentifier("support.search")
                                .focused($focus, equals: .search)
                                .onChange(of: focus) {
                                    if focus == .search && search.isEmpty && !typingSearch {
                                        typingSearch = true
                                        choosingSearch = true
                                    }
                                }
                                .onSubmit {
                                    if search.isEmpty {
                                        choosingSearch = true
                                    } else {
                                        focusResults()
                                    }
                                }
                                .onKeyPress(.downArrow) {
                                    guard !matches.isEmpty else { return .ignored }
                                    focusResults()
                                    return .handled
                                }
                                .onChange(of: searchRequest, initial: true) {
                                    if searchRequest > 0 { focus = .search }
                                }
                                .onChange(of: search) { selectedID = nil }
                        }.padding(.horizontal, 12).frame(height: 40)
                            .background(
                                UMCColor.Custom.backgroundSurfaceGreyWeak,
                                in: .rect(cornerRadius: 12))
                        Button("검색") {
                            if search.isEmpty {
                                choosingSearch = true
                                focus = .search
                            } else {
                                focusResults()
                            }
                        }
                    }.padding(.horizontal, 16).frame(minHeight: 52)
                        .background(
                            UMCColor.Custom.backgroundSurfaceWhite, in: .rect(cornerRadius: 12))
                }
                if choosingSearch && search.isEmpty {
                    Spacer()
                    Text("어떤 내용을 찾으시나요?").inquiryFont(28, weight: .bold)
                        .frame(maxWidth: .infinity)
                    Text("예시 검색어를 선택해 FAQ를 찾아보세요.").frame(maxWidth: .infinity)
                    HStack {
                        Button {
                            typingSearch = false
                            search = "출석·과제"
                        } label: {
                            Text("출석·과제").frame(width: 144, height: 48)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(UMCColor.Semantic.textNeutralDefault)
                        .background(UMCColor.Primitives.teal500, in: .rect(cornerRadius: 8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8).strokeBorder(
                                UMCColor.Semantic.borderNeutralWeaker100, lineWidth: 2)
                        }
                        .environment(\.colorScheme, .light)
                        Button {
                            typingSearch = false
                            search = "영수증"
                        } label: {
                            Text("영수증").frame(width: 144, height: 48)
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(UMCColor.Semantic.textInverse)
                        .background(
                            Color(red: 96 / 255, green: 98 / 255, blue: 98 / 255),
                            in: .rect(cornerRadius: 8))
                    }.frame(maxWidth: .infinity)
                    Button("직접 입력") {
                        typingSearch = true
                        focus = .search
                    }
                    .frame(maxWidth: .infinity)
                    Spacer()
                }
                if let category {
                    Button {
                        self.category = nil
                    } label: {
                        Label(category, systemImage: "xmark.circle")
                    }
                    .accessibilityHint(AppLocalization.string("카테고리 필터 해제"))
                }
                if !search.isEmpty && !matches.isEmpty {
                    HStack {
                        Text("검색 결과 \(matches.count)건")
                            .inquiryFont(16)
                        Spacer()
                        Button("다시 검색") {
                            choosingSearch = true
                            search = ""
                            focus = .search
                        }
                    }
                }
                if choosingSearch && search.isEmpty {
                    EmptyView()
                } else if matches.isEmpty {
                    VStack(spacing: 16) {
                        Text("‘" + search + "’에 대한 검색 결과가 없어요").inquiryFont(28, weight: .bold)
                        Text("다른 검색어로 찾아보거나 UMC PRODUCT에 문의해 주세요.").inquiryFont(15)
                        HStack(spacing: 12) {
                            Button("다시 검색") {
                                search = ""
                                choosingSearch = true
                            }
                            if let compose {
                                Button("문의하기") { compose(nil) }
                                    .buttonStyle(SupportActionStyle(prominent: true))
                            }
                        }
                    }.frame(maxWidth: .infinity, maxHeight: .infinity).supportCard()
                } else {
                    HStack(alignment: .top, spacing: UMCSpacing.value24) {
                        results
                        if search.isEmpty {
                            helpPanel
                                .containerRelativeFrame(.horizontal) { width, _ in
                                    min(360, width * 0.28)
                                }
                        }
                    }
                    if showsRanking { Text("같은 사람의 반복 접수는 한 번만 집계해요.").inquiryFont(13) }
                    if showsRanking && !refreshed {
                        HStack {
                            Text("새 순위가 있어요. 읽던 목록은 그대로 유지했어요.")
                            Spacer()
                            Button("새 순위 보기") { refreshed = true }
                        }.padding(12)
                    }
                }
            }
        }.onChange(of: articles) {
            if detailID != nil && detail == nil {
                detailID = nil
                selectedID = nil
            }
        }.onAppear {
            if [.detail, .resolved].contains(scene) { detailID = articles.first?.id }
            if scene == .results {
                choosingSearch = true
                search = "출석·과제"
            }
            if scene == .noResults {
                choosingSearch = true
                search = "영수증"
            }
            if [.refreshed, .weeklyRefreshed].contains(scene) { refreshed = true }
            if [.weekly, .weeklyRefreshed].contains(scene) { weekly = true }
            if scene == .search || searchRequest > 0 { choosingSearch = true }
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
                HStack {
                    Text("실시간 인기 문의").inquiryFont(22, weight: .bold)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    HStack(spacing: 8) {
                        ForEach([false, true], id: \.self) { week in
                            Button {
                                weekly = week
                            } label: {
                                Text((week == weekly ? "✓ " : "") + (week ? "최근 7일" : "최근 24시간"))
                                    .frame(minHeight: 48)
                            }
                            .accessibilityAddTraits(week == weekly ? .isSelected : [])
                        }
                    }
                }
            }
            if showsRanking {
                HStack {
                    Text(weekly ? "최근 7일" : "최근 24시간")
                    Spacer()
                    Text(refreshed ? "마지막 갱신 14:33" : "마지막 갱신 14:32")
                }.inquiryFont(13)
            }
            List(selection: $selectedID) {
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

                            }
                            Spacer()
                            if !search.isEmpty { Text("답변 보기") }
                            if showsRanking, let count = readers(article) { Text("\(count)명 문의") }
                        }.padding(.vertical, 12).contentShape(Rectangle())
                    }
                    .buttonStyle(.plain).tag(article.id)
                }
            }
            .listStyle(.plain)
            .environment(\.defaultMinListRowHeight, showsRanking ? 76 : 56)
            .accessibilityIdentifier("support.faq.table")
            .focused($focus, equals: .table)
            .task {
                guard selectedID != nil else { return }
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
                guard let article = matches.first(where: { $0.id == selectedID }) else {
                    return .ignored
                }
                open(article)
                return .handled
            }
        }
    }

    private func focusResults() {
        guard let first = matches.first else { return }
        selectedID = first.id
        focus = .table
    }

    private func open(_ article: SupportArticle) {
        selectedID = article.id
        detailID = article.id
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
    var initiallyResolved = false
    let back: () -> Void
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
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 16) {
                if inquire != nil {
                    Text("검증된 답변").inquiryFont(13, weight: .medium)
                        .padding(6).background(UMCColor.Semantic.surfaceBrandWeak, in: .capsule)
                }
                Text(article.question).inquiryFont(28, weight: .bold).accessibilityAddTraits(
                    .isHeader)
                Text(article.category + (inquire == nil ? "" : " · UMC 서비스")).inquiryFont(13)
                Divider()
                ScrollView {
                    Text(article.answer).inquiryFont(16).textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                if let inquire {
                    HStack(spacing: 12) {
                        Spacer()
                        Button("해결됐어요") { resolved = true }.disabled(resolved)
                        Button("담당자에게 문의하기", action: inquire)
                            .buttonStyle(SupportActionStyle(prominent: true))
                    }
                    if resolved {
                        Text("✓ 해결 응답을 기록했어요. 문의가 새로 등록되지는 않아요.")
                            .inquiryFont(13).foregroundStyle(UMCColor.Semantic.textBrandDefault)
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
                Text("관련 안내\n" + (article.id == "attendance" ? "출석 화면 오류 안내" : article.category))
                Spacer()
                if article.id == "attendance" {
                    Text("UMC PRODUCT가 앱의 표시·동기화 오류를 확인해 드려요. 출석 인정이나 학사 판단은 이 문의에서 처리하지 않아요.")
                        .inquiryFont(13)
                }
            }.frame(maxWidth: .infinity, alignment: .leading).supportCard().frame(width: 356)
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
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .inquiryFont(13, weight: .medium).tracking(prominent ? -0.13 : -0.26)
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
                        UMCColor.Semantic.borderNeutralWeak200, lineWidth: prominent ? 0 : 1)
            }
            .opacity(enabled ? (configuration.isPressed ? 0.75 : 1) : 0.5)
    }
}
