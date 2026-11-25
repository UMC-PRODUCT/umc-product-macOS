//
//  SupportView.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/23/26.
//

import CoreDesignSystem
import SwiftUI
import UMCFoundation

struct SupportView: View {
    private enum Page {
        case answers, inquiries
        #if DEBUG
        case operations
        #endif
    }
    @State private var page = Page.answers
    @State private var composing = false
    @State private var createdTicket: UUID?

    private var heading: String {
        switch page {
        case .answers: AppLocalization.string("문의")
        case .inquiries: AppLocalization.string("내 문의")
        #if DEBUG
        case .operations: "문의 관리"
        #endif
        }
    }

    #if DEBUG
    @State private var fixture: SupportFixture?

    init(
        designPreview: Bool = ProcessInfo.processInfo.arguments.contains("--support-preview"),
        emptyInquiries: Bool = ProcessInfo.processInfo.arguments
            .contains("--support-preview-empty")
    ) {
        let preview = designPreview || emptyInquiries
        let initialFixture = preview ? SupportFixture(emptyInquiries: emptyInquiries) : nil
        _fixture = State(initialValue: initialFixture)
        _page = State(initialValue: emptyInquiries ? .inquiries : .answers)
    }
    #else
    init() {}
    #endif

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value20) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                    Text(heading).umcTypography(.largeTitle3Bold).accessibilityAddTraits(.isHeader)
                }
                Spacer()
                #if DEBUG
                if fixture != nil && page == .answers {
                    Button("문의하기") { composing = true }
                        .buttonStyle(.borderedProminent)
                }
                #endif
            }
            Picker(AppLocalization.string("고객센터"), selection: $page) {
                Text(AppLocalization.string("많이 묻는 질문")).tag(Page.answers)
                Text(AppLocalization.string("내 문의")).tag(Page.inquiries)
                #if DEBUG
                if fixture != nil { Text("운영").tag(Page.operations) }
                #endif
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(maxWidth: 300)
            switch page {
            case .answers:
                SupportAnswersView(articles: articles, showInquiries: { page = .inquiries })
            case .inquiries:
                inquiries
            #if DEBUG
            case .operations:
                if let fixture {
                    SupportInquiryPreview(fixture: fixture, isOperator: true) { page = .answers }
                }
            #endif
            }
        }
        .padding(UMCSpacing.value32)
        .frame(minWidth: 560, maxWidth: .infinity, minHeight: 420, maxHeight: .infinity,
               alignment: .topLeading)
        .background(UMCColor.Custom.backgroundDefault)
        .tint(UMCColor.Semantic.textBrandDefault)
        #if DEBUG
        .safeAreaInset(edge: .bottom, alignment: .leading, spacing: 0) {
            if fixture != nil {
                Label("로컬 디자인 프리뷰", systemImage: "hammer")
                    .umcTypography(.captionRegular).foregroundStyle(.secondary)
                    .padding(.horizontal, UMCSpacing.value32).padding(.bottom, UMCSpacing.value8)
            }
        }
        .sheet(isPresented: $composing) {
            SupportComposePreview { subject, content, team in
                createdTicket = fixture?.create(subject: subject, content: content, team: team)
                page = .inquiries
                composing = false
            }
        }
        #endif
    }

    private var articles: [SupportArticle] {
        #if DEBUG
        if let fixture { return fixture.publishedArticles + SupportArticle.appGuide }
        #endif
        return SupportArticle.appGuide
    }

    @ViewBuilder private var inquiries: some View {
        #if DEBUG
        if let fixture {
            SupportInquiryPreview(fixture: fixture, initialTicket: createdTicket) { page = .answers }
                .onAppear { createdTicket = nil }
        } else {
            serviceStatus
        }
        #else
        serviceStatus
        #endif
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
    let showInquiries: () -> Void
    @State private var category: String?
    @State private var weekly = false
    @State private var search = ""
    @State private var selectedID: String?
    @State private var detail: SupportArticle?
    @FocusState private var focus: Focus?

    private var categories: [String] {
        articles.map(\.category).filter { !$0.isEmpty }.reduce(into: []) {
            if !$0.contains($1) { $0.append($1) }
        }
    }

    private var showsRanking: Bool {
        #if DEBUG
        search.isEmpty && category == nil && articles.contains { $0.dayReaders != nil }
        #else
        false
        #endif
    }

    private func readers(_ article: SupportArticle) -> Int? {
        #if DEBUG
        weekly ? article.weekReaders : article.dayReaders
        #else
        nil
        #endif
    }

    private var matches: [SupportArticle] {
        let filtered = articles.filter { $0.matches(search) && (category == nil || category == $0.category) }
        guard showsRanking else { return filtered }
        return filtered.filter { readers($0) != nil }.sorted {
            (readers($0) ?? 0) > (readers($1) ?? 0)
        }
    }

    var body: some View {
        if let detail {
            Button { self.detail = nil } label: {
                Label(AppLocalization.string("목록으로"), systemImage: "chevron.left")
            }
            .focused($focus, equals: .back)
            .keyboardShortcut(.cancelAction)
            .onAppear { focus = .back }
            ScrollView {
                VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                    Text(detail.question).umcTypography(.title2Bold)
                        .accessibilityAddTraits(.isHeader)
                    Text(detail.answer).umcTypography(.bodyRegular).textSelection(.enabled)
                }
                .padding(UMCSpacing.value24)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    UMCColor.Custom.backgroundSurface, in: .rect(cornerRadius: UMCRadius.value12)
                )
            }
        } else {
            TextField(AppLocalization.string("궁금한 내용을 검색하세요"), text: $search)
                .textFieldStyle(.roundedBorder)
                .accessibilityIdentifier("support.search")
                .focused($focus, equals: .search)
                .onSubmit { focusResults() }
                .onKeyPress(.downArrow) {
                    guard !matches.isEmpty else { return .ignored }
                    focusResults()
                    return .handled
                }
                .onAppear { if selectedID == nil { focus = .search } }
                .onChange(of: search) { selectedID = nil }
            if let category {
                Button { self.category = nil } label: {
                    Label(category, systemImage: "xmark.circle")
                }
                .accessibilityHint(AppLocalization.string("카테고리 필터 해제"))
            }
            if !search.isEmpty {
                HStack {
                    Text("\(AppLocalization.string("많이 묻는 질문")) (\(matches.count))")
                        .umcTypography(.headlineRegular)
                    Spacer()
                    Button(AppLocalization.string("검색어 지우기")) {
                        search = ""
                        focus = .search
                    }
                }
            }
            if matches.isEmpty {
                ContentUnavailableView.search(text: search)
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: UMCSpacing.value16) {
                        results.frame(minWidth: 420)
                        helpPanel.frame(width: 230)
                    }
                    VStack(alignment: .leading) {
                        Menu(AppLocalization.string("카테고리별 답변")) { categoryButtons }
                        results
                    }
                }

            }
        }
    }

    private var helpPanel: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
            Text(AppLocalization.string("카테고리별 답변"))
                .umcTypography(.headlineBold).accessibilityAddTraits(.isHeader)
            categoryButtons
            Divider()
            Text(AppLocalization.string("아직 해결되지 않았나요?")).umcTypography(.headlineBold)
            Button(action: showInquiries) {
                Label(AppLocalization.string("내 문의"), systemImage: "bubble.left.and.bubble.right")
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(UMCSpacing.value20)
        .background(UMCColor.Custom.backgroundSurfaceGreyWeaker,
                    in: .rect(cornerRadius: UMCRadius.value12))
    }

    private var categoryButtons: some View {
        ForEach(categories, id: \.self) { name in
            Button(name) {
                category = name
                selectedID = nil
                focus = .search
            }
        }
    }

    private var results: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value8) {
            if showsRanking {
                HStack {
                    Text("실시간 인기 문의").umcTypography(.title3Bold)
                        .accessibilityAddTraits(.isHeader)
                    Spacer()
                    Picker("집계 기간", selection: $weekly) {
                        Text("최근 24시간").tag(false)
                        Text("최근 7일").tag(true)
                    }.pickerStyle(.segmented).labelsHidden().fixedSize()
                }
            }
            Table(matches, selection: $selectedID) {
                TableColumn(AppLocalization.string("많이 묻는 질문")) { article in
                    Button { open(article) } label: {
                        VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                            Text(article.question).umcTypography(.headlineBold)
                            Text(article.category).umcTypography(.captionRegular)
                        }
                        .multilineTextAlignment(.leading)
                        .padding(.vertical, UMCSpacing.value4)
                    }
                    .buttonStyle(.plain)
                }
                if showsRanking {
                    TableColumn("문의 인원") { article in
                        if let count = readers(article) { Text("\(count)명").monospacedDigit() }
                    }.width(65)
                }
            }
            .accessibilityIdentifier("support.faq.table")
            .focused($focus, equals: .table)
            .onAppear { if selectedID != nil { focus = .table } }
            .contextMenu(forSelectionType: String.self) { _ in } primaryAction: { ids in
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
        detail = article
    }
}
