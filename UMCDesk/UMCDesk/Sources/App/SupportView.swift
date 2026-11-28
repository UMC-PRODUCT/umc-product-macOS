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
        case operations, faq
    }
    @State private var page = Page.answers
    @State private var composing = false
    @State private var createdTicket: UUID?

    @State private var searchRequest = 0
    @State private var toolsOpen = false
    @State private var reference: SupportArticle?

    private var heading: String {
        switch page {
        case .answers: AppLocalization.string("문의")
        case .inquiries: AppLocalization.string("내 문의")
        case .operations, .faq: "문의 관리"
        }
    }

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

    init(fixture: SupportFixture) {
        _fixture = State(initialValue: fixture)
    }

    init() {
        #if DEBUG
        let arguments = ProcessInfo.processInfo.arguments
        self.init(designPreview: arguments.contains("--support-preview"),
                  emptyInquiries: arguments.contains("--support-preview-empty"))
        #else
        self.init(designPreview: false, emptyInquiries: false)
        #endif
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value20) {
            HStack {
                Spacer()
                Button("문의 도구", systemImage: "slider.horizontal.3") { toolsOpen.toggle() }
                    .popover(isPresented: $toolsOpen) {
                        VStack(alignment: .leading, spacing: 14) {
                            let operating = page == .operations || page == .faq
                            HStack {
                                Text(operating ? "문의 관리 도구" : "문의 도구").umcTypography(.headlineBold)
                                Spacer()
                                Button("닫기") { toolsOpen = false }.keyboardShortcut(.cancelAction)
                            }
                            if operating, fixture != nil {
                                Text("UMC PRODUCT 구성원만 사용할 수 있는 관리 도구예요.")
                                Button("FAQ 작성 · 관리") { navigate(.faq) }
                                Button("문의 관리 목록") { navigate(.operations) }
                                Button("많이 묻는 질문 보기") { navigate(.answers) }
                            } else {
                                Text("답을 찾아보고 내 문의를 이어가세요.")
                                Button("도움말 검색") { navigate(.answers); searchRequest += 1 }
                                if fixture != nil {
                                    Button("새 문의 작성") {
                                        toolsOpen = false
                                        reference = nil
                                        composing = true
                                    }
                                }
                                Button("많이 묻는 질문") { navigate(.answers) }
                                Button("내 문의 현황") { navigate(.inquiries) }
                            }
                        }.padding(20).frame(width: 390, alignment: .leading)
                    }
            }
            if composing, let fixture {
                SupportComposePreview(articles: articles, cancel: { composing = false },
                                      submit: { subject, content, team, category, reference, attachment in
                    createdTicket = fixture.create(subject: subject, content: content, team: team, category: category,
                                                  reference: reference, attachmentName: attachment)
                    navigate(.inquiries)
                }, reference: reference)
            } else {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                    Text(heading).umcTypography(.largeTitle3Bold).accessibilityAddTraits(.isHeader)
                    if page == .answers {
                        Text("서비스 이용 중 궁금한 점은 답변을 찾거나 UMC PRODUCT에 문의해 주세요.")
                            .foregroundStyle(UMCColor.Semantic.textNeutralStrong800)
                    }
                }
                Spacer()
                if fixture != nil && page == .answers {
                    Button("문의하기") { reference = nil; composing = true }
                        .buttonStyle(SupportActionStyle(prominent: true))
                }
            }
            Picker(AppLocalization.string("고객센터"), selection: $page) {
                Text(AppLocalization.string("많이 묻는 질문")).tag(Page.answers)
                Text(AppLocalization.string("내 문의")).tag(Page.inquiries)
                if fixture != nil { Text("운영").tag(Page.operations) }
            }
            .pickerStyle(.segmented).controlSize(.large).modifier(SupportControlFill())
            .labelsHidden()
            .frame(maxWidth: 300)
            switch page {
            case .faq:
                if let fixture { SupportFAQPreview(fixture: fixture) { navigate(.operations) } }
            case .answers:
                SupportAnswersView(articles: articles, searchRequest: searchRequest, showInquiries: { page = .inquiries },
                                   compose: fixture == nil ? nil : { article in
                    reference = article
                    composing = true
                })
            case .inquiries:
                inquiries
            case .operations:
                if let fixture {
                    SupportInquiryPreview(fixture: fixture, isOperator: true) { page = .answers }
                }
            }
        }
        }.padding(.horizontal, 40).padding(.vertical, 24)
        .frame(minWidth: 560, maxWidth: .infinity, minHeight: 420, maxHeight: .infinity,
               alignment: .topLeading)
        .background(UMCColor.Custom.backgroundSurface)
        .buttonStyle(SupportActionStyle())
        .tint(UMCColor.Semantic.textBrandDefault)
        .safeAreaInset(edge: .bottom, alignment: .leading, spacing: 0) {
            if fixture != nil {
                Label("로컬 디자인 프리뷰", systemImage: "hammer")
                    .umcTypography(.captionRegular).foregroundStyle(.secondary)
                    .padding(.horizontal, UMCSpacing.value32).padding(.bottom, UMCSpacing.value8)
            }
        }
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
            SupportInquiryPreview(fixture: fixture, initialTicket: createdTicket) { page = .answers }
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
    let searchRequest: Int
    let showInquiries: () -> Void
    let compose: ((SupportArticle?) -> Void)?
    @State private var category: String?
    @State private var weekly = false
    @State private var refreshed = false
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
        search.isEmpty && category == nil && articles.contains { $0.dayReaders != nil }
    }

    private func readers(_ article: SupportArticle) -> Int? {
        if !weekly, refreshed, article.id == "login" { return 30 }
        return weekly ? article.weekReaders : article.dayReaders
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
            SupportAnswerDetail(article: detail, back: { self.detail = nil },
                                inquire: compose.map { action in { action(detail) } })
        } else {
            HStack(spacing: 12) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(AppLocalization.string("궁금한 내용을 검색하세요"), text: $search)
                .textFieldStyle(.plain)
                .accessibilityIdentifier("support.search")
                .focused($focus, equals: .search)
                .onSubmit { focusResults() }
                .onKeyPress(.downArrow) {
                    guard !matches.isEmpty else { return .ignored }
                    focusResults()
                    return .handled
                }
                .onChange(of: searchRequest, initial: true) { if searchRequest > 0 { focus = .search } }
                .onChange(of: search) { selectedID = nil }
            Button("검색") { focusResults() }
            }.padding(.horizontal, 16).frame(minHeight: 52)
                .background(UMCColor.Custom.backgroundSurfaceGreyWeak, in: .rect(cornerRadius: 12))
            if focus == .search && search.isEmpty {
                HStack {
                    Button("출석·과제") { search = "출석·과제" }
                        .buttonStyle(.plain).padding(8)
                        .foregroundStyle(UMCColor.Semantic.textNeutralDefault)
                        .background(UMCColor.Primitives.teal500, in: .rect(cornerRadius: 8))
                        .overlay { RoundedRectangle(cornerRadius: 8).strokeBorder(lineWidth: 2) }
                        .environment(\.colorScheme, .light)
                    Button("영수증") { search = "영수증" }
                        .buttonStyle(.plain).padding(8)
                        .foregroundStyle(UMCColor.Semantic.textInverse)
                        .background(Color(red: 96/255, green: 98/255, blue: 98/255),
                                    in: .rect(cornerRadius: 8))
                }
            }
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
                if let compose { Button("문의하기") { compose(nil) } }
            } else {
                HStack(alignment: .top, spacing: UMCSpacing.value16) {
                    results
                    helpPanel
                        .containerRelativeFrame(.horizontal) { width, _ in
                            min(360, width * 0.28)
                        }
                }
                if showsRanking && !refreshed {
                    HStack {
                        Text("새 순위가 있어요. 읽던 목록은 그대로 유지했어요.")
                        Spacer()
                        Button("새 순위 보기") { refreshed = true }
                    }.padding(12)
                }
            }
        }
    }

    private var helpPanel: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
            Text(AppLocalization.string("카테고리별 답변"))
                .umcTypography(.headlineBold).accessibilityAddTraits(.isHeader)
            if compose != nil { Text("UMC PRODUCT가 확인한 서비스 이용 답변을 보여요.") }
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                categoryButtons
            }
            Divider()
            Text(AppLocalization.string("아직 해결되지 않았나요?")).umcTypography(.headlineBold)
            if let compose { Button("문의하기") { compose(nil) } }
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
                    }.pickerStyle(.segmented).modifier(SupportControlFill()).labelsHidden().fixedSize()
                }
            }
            if showsRanking {
                HStack {
                    Text(weekly ? "최근 7일" : "최근 24시간")
                    Spacer()
                    Text(refreshed ? "마지막 갱신 14:33" : "마지막 갱신 14:32")
                }.umcTypography(.captionRegular)
            }
            List(selection: $selectedID) {
                ForEach(Array(matches.enumerated()), id: \.element.id) { index, article in
                    Button { open(article) } label: {
                        HStack(spacing: 20) {
                            if showsRanking {
                                Text(String(index + 1)).umcTypography(.headlineBold)
                                    .frame(width: 40, height: 40)
                                    .background(UMCColor.Custom.backgroundSurfaceGreyWeak,
                                                in: .rect(cornerRadius: 8))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(article.question).umcTypography(.headlineBold)
                                Text(article.category).umcTypography(.captionRegular)
                                if !search.isEmpty { Text(article.answer).lineLimit(2) }
                            }
                            Spacer()
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

/// The system draws a white label on selected segments and prominent buttons.
struct SupportControlFill: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content.tint(colorScheme == .dark
                  ? UMCColor.Semantic.fillPrimaryStrong200 : UMCColor.Semantic.textBrandDefault)
    }
}

struct SupportAnswerDetail: View {
    let article: SupportArticle
    let back: () -> Void
    let inquire: (() -> Void)?
    @State private var resolved = false

    var body: some View {
        Button("목록으로", action: back).keyboardShortcut(.cancelAction)
        ScrollView {
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 16) {
                    Text(article.question).umcTypography(.title2Bold)
                    Text(article.category)
                    Text(article.answer).umcTypography(.bodyRegular).textSelection(.enabled)
                    if let inquire {
                        HStack {
                            Button("해결됐어요") { resolved = true }.disabled(resolved)
                            Button("담당자에게 문의하기", action: inquire)
                        }
                        if resolved { Text("✓ 해결 응답을 기록했어요. 문의가 새로 등록되지는 않아요.") }
                    }
                }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
                VStack(alignment: .leading, spacing: 16) {
                    Text("답변 정보").umcTypography(.headlineBold)
                    Text(article.category)
                    Text(inquire == nil ? "앱 이용 안내" : "검증된 답변 · UMC PRODUCT")
                }.padding(24).frame(width: 356, alignment: .leading)
            }
        }
    }
}

struct SupportActionStyle: ButtonStyle {
    var prominent = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .umcTypography(.bodyRegular)
            .padding(.horizontal, 16)
            .frame(minHeight: prominent ? 40 : 36)
            .foregroundStyle(prominent ? UMCColor.Custom.backgroundTextWhite
                             : UMCColor.Semantic.textNeutralDefault)
            .background(prominent ? UMCColor.Semantic.fillPrimaryStrong200
                        : UMCColor.Custom.backgroundSurfaceGreyWeaker, in: .rect(cornerRadius: 8))
            .overlay { RoundedRectangle(cornerRadius: 8)
                .strokeBorder(UMCColor.Semantic.borderNeutralWeak200, lineWidth: prominent ? 0 : 1) }
            .opacity(configuration.isPressed ? 0.75 : 1)
    }
}
