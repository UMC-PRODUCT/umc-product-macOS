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
            Text(AppLocalization.string("고객센터"))
                .umcTypography(.largeTitle3Bold)
                .accessibilityAddTraits(.isHeader)
            #if DEBUG
            if fixture != nil {
                Label("로컬 디자인 프리뷰 · 모든 변경은 이 창에서만 볼 수 있어요.", systemImage: "hammer")
                    .foregroundStyle(.secondary)
            }
            #endif
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
                SupportAnswersView(articles: articles)
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
            SupportInquiryPreview(fixture: fixture) { page = .answers }
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
    @State private var search = ""
    @State private var selectedID: String?
    @State private var detail: SupportArticle?
    @FocusState private var focus: Focus?

    private var matches: [SupportArticle] { articles.filter { $0.matches(search) } }

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
                Table(matches, selection: $selectedID) {
                    TableColumn(AppLocalization.string("많이 묻는 질문")) { article in
                        Text(article.question)
                    }
                    TableColumn("") { article in
                        Button(AppLocalization.string("답변 찾아보기")) { open(article) }
                            .buttonStyle(.link)
                            .accessibilityLabel(article.question)
                            .accessibilityHint(AppLocalization.string("답변 찾아보기"))
                    }
                    .width(100)
                }
                .accessibilityIdentifier("support.faq.table")
                .focused($focus, equals: .table)
                .onAppear { if selectedID != nil { focus = .table } }
                .contextMenu(forSelectionType: String.self) { _ in } primaryAction: { ids in
                    if let article = matches.first(where: { ids.contains($0.id) }) {
                        open(article)
                    }
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
