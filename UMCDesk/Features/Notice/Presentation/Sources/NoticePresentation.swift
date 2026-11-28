//  NoticePresentation.swift
//  NoticePresentation
//
//  Created by euijjang97 on 11/23/26.

import CoreUIComponents
import CoreDesignSystem
import CoreRouting
import Network
import NoticeDomain
import SwiftUI
import UMCFoundation

@MainActor
@Observable
final class NoticeBoardModel {
    let repository: any NoticeRepository
    var entries: [NoticeEntry] = []
    var tab = "CHALLENGER"
    var keyword = ""
    var gisu = ""
    var canCompose = false
    var part: String?
    var nextPage: Int?
    var isLoading = false
    var error: (any Error)?
    private(set) var failedPage = 0
    private var loadedFilter: Filter?

    private struct Filter: Equatable {
        let tab: String
        let keyword: String
        let part: String?
    }
    var accessLossRevision = 0
    var readIDs: Set<String> = []
    private var requestID = UUID()

    init(repository: any NoticeRepository) {
        self.repository = repository
    }

    func hasFilters(pinnedOnly: Bool) -> Bool {
        !keyword.isEmpty || tab != "CHALLENGER" || part != nil || pinnedOnly
    }

    /// Uses the submitted keyword, never the text field's in-progress IME composition.
    func filterSummary(pinnedOnly: Bool) -> String {
        var labels = [noticeTabs.first { $0.value == tab }?.label ?? tab]
        if tab == "CHALLENGER" {
            labels.append(noticeParts.first { $0.value == part }?.label
                          ?? AppLocalization.string("전체 파트"))
        }
        labels.append(pinnedOnly ? AppLocalization.string("고정") : AppLocalization.string("전체"))
        if !keyword.isEmpty { labels.append(AppLocalization.string("검색: \(keyword)")) }
        return labels.joined(separator: " · ")
    }

    func revokeArticle(_ id: String) {
        requestID = UUID()
        isLoading = false
        entries.removeAll { $0.id == id }
        readIDs.remove(id)
        error = NoticeRequestFailure.accessDenied
    }

    func load(page: Int = 0) async {
        let token = UUID()
        requestID = token
        error = nil
        isLoading = true
        let filter = Filter(tab: tab, keyword: keyword, part: tab == "CHALLENGER" ? part : nil)
        if filter != loadedFilter {
            entries.removeAll()
            nextPage = nil
        }
        defer { if requestID == token { isLoading = false } }
        do {
            let generation = gisu.isEmpty ? try await repository.activeGisu() : gisu
            guard requestID == token, !Task.isCancelled else { return }
            gisu = generation
            let allowed = (try? await repository.canCompose(gisu: generation)) == true
            guard requestID == token, !Task.isCancelled else { return }
            canCompose = allowed
            let response = try await repository.notices(
                gisu: generation, tab: filter.tab,
                keyword: filter.keyword, part: filter.part, page: page)
            guard requestID == token, !Task.isCancelled else { return }
            loadedFilter = filter
            if page == 0 { entries.removeAll() }
            var known = Set(entries.map(\.id))
            entries += response.content.filter { known.insert($0.id).inserted }
            entries = entries.map { (entry: $0, date: $0.postedAt) }
                .sorted { $0.date > $1.date }.map(\.entry)
            nextPage = response.hasNext ? page + 1 : nil
        } catch {
            guard requestID == token, !Task.isCancelled else { return }
            if case NoticeRequestFailure.accessDenied = error {
                entries = []
                canCompose = false
                accessLossRevision += 1
                readIDs = []
                nextPage = nil
            }
            failedPage = page
            self.error = error
        }
    }
}

public struct NoticeBoardView: View {
    @State private var model: NoticeBoardModel
    @Environment(\.invalidateWindowDetail) private var invalidateDetail
    @WindowDetailSelection private var selection: String?
    @State private var search = ""
    @State private var composing = false
    @State private var checkingWriter = false
    @State private var pinnedExpanded = true
    @State private var readingLayout = NoticeReadingLayout()
    @State private var pinnedOnly = false
    @State private var period = NoticePeriod.all
    @State private var start = Date.now
    @State private var end = Date.now
    @State private var scope: String?
    @State private var generationName: String?
    @Environment(\.calendar) private var calendar

    public init(repository: any NoticeRepository) {
        _model = State(initialValue: NoticeBoardModel(repository: repository))
    }

    public var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            HStack(spacing: 0) {
                if let id = selection {
                    if !readingLayout.isFullReader {
                        noticeList
                            .frame(minWidth: 280, idealWidth: 300, maxWidth: 340)
                        Divider()
                    }
                    NoticeArticleView(
                        repository: model.repository, id: id,
                        confirmed: model.readIDs.contains(id),
                        onDelete: { discardArticle(id) },
                        onAccessLost: {
                            model.revokeArticle(id)
                            discardArticle(id)
                        },
                        onChanged: { Task { await model.load() } },
                        onRead: { model.readIDs.insert(id) }
                    )
                    .id(id)
                } else {
                    noticeList
                }
            }
        }
        .background(UMCColor.Custom.backgroundDefault)
        .umcTabTools(AppLocalization.string("공지 도구"), width: .wide, findShortcut: true) { dismiss in tools(dismiss: dismiss) }
        .task(id: model.gisu) {
            generationName = nil
            guard !model.gisu.isEmpty else { return }
            let organization = try? await model.repository.organization(gisu: model.gisu)
            if !Task.isCancelled { generationName = organization?.generation }
        }
        .task(id: model.tab) { await model.load() }
        .task {
            let monitor = NWPathMonitor()
            defer { monitor.cancel() }
            var wasDisconnected = false
            for await path in monitor {
                guard !Task.isCancelled else { return }
                if wasDisconnected, path.status == .satisfied,
                   let error = model.error, NoticeConnectionFailure.matches(error) {
                    await model.load(page: model.failedPage)
                }
                wasDisconnected = path.status != .satisfied
            }
        }
        .onChange(of: model.accessLossRevision) {
            if let selection { discardArticle(selection) }
        }
        .onChange(of: model.part) { _, _ in Task { await model.load() } }
        .onChange(of: model.canCompose) { _, allowed in
            if !allowed { composing = false }
        }
        .sheet(isPresented: $composing) {
            NoticeComposer(
                repository: model.repository, gisu: model.gisu, tab: model.tab,
                onAccessDenied: {
                    composing = false
                    model.canCompose = false
                    model.error = NoticeRequestFailure.accessDenied
                }
            ) { id in
                composing = false
                selection = id
                Task { await model.load() }
            }
        }
    }

    private func discardArticle(_ id: String) {
        if let invalidateDetail { invalidateDetail(WindowDetail(id)) }
        else if selection == id { selection = nil }
    }

    private var toolbar: some View {
        HStack {
            if selection == nil {
                Text("공지").umcTypography(.title1Bold).accessibilityAddTraits(.isHeader)
            } else {
                Button("공지 목록", systemImage: "list.bullet") {
                    readingLayout.beginSelection()
                    selection = nil
                }
                Button(
                    readingLayout.isFullReader ? "분할 보기" : "전체 읽기",
                    systemImage: readingLayout.isFullReader ? "sidebar.left" : "arrow.up.left.and.arrow.down.right"
                ) {
                    readingLayout.toggle()
                }
            }
            Spacer()
        }
        .padding(.horizontal, UMCSpacing.value20)
        .padding(.vertical, UMCSpacing.value12)
    }

    private var hasFilters: Bool {
        model.hasFilters(pinnedOnly: pinnedOnly) || period != .all || scope != nil
    }

    @ViewBuilder
    private func tools(dismiss: @escaping () -> Void) -> some View {
        Text(AppLocalization.string("목록 보기와 게시 대상 설정"))
            .font(.caption).foregroundStyle(.secondary)
        NoticeSearchField(search: $search, submit: searchNotices)
        UMCToolGroupHeading(AppLocalization.string("빠른 보기"))
        Picker(AppLocalization.string("빠른 보기"), selection: $pinnedOnly) {
            Text(AppLocalization.string("전체")).tag(false)
            Text(AppLocalization.string("고정")).tag(true)
        }
        .pickerStyle(.segmented)
        .labelsHidden()
        Divider()
        filterRow("게시 기간") {
            Picker(AppLocalization.string("게시 기간"), selection: $period) {
                ForEach(NoticePeriod.allCases, id: \.self) { Text(AppLocalization.string(.init($0.rawValue))).tag($0) }
            }
        }
        if period == .day || period == .range {
            DatePicker(AppLocalization.string("시작일"), selection: $start, displayedComponents: .date)
                .onChange(of: start) { if start > end { end = start } }
        }
        if period == .range {
            DatePicker(AppLocalization.string("종료일"), selection: $end, in: calendar.startOfDay(for: start)...,
                       displayedComponents: .date)
        }
        Divider()
        UMCToolGroupHeading(AppLocalization.string("공지 대상"))
        if let generationName {
            LabeledContent(AppLocalization.string("기수"), value: AppLocalization.string("\(generationName)기"))
        }
        filterRow("공지 구분") {
            Picker(AppLocalization.string("공지 구분"), selection: $model.tab) {
                ForEach(noticeTabs, id: \.value) { tab in Text(AppLocalization.string(.init(tab.label))).tag(tab.value) }
            }
        }
        filterRow("범위") {
            Picker(AppLocalization.string("범위"), selection: $scope) {
                Text(AppLocalization.string("전체 범위")).tag(String?.none)
                ForEach(["전체", "지부", "학교"], id: \.self) { Text(AppLocalization.string(.init($0))).tag(Optional($0)) }
            }
        }
        if model.tab == "CHALLENGER" {
            filterRow("파트") {
                Picker(AppLocalization.string("파트"), selection: $model.part) {
                    Text(AppLocalization.string("전체 파트")).tag(String?.none)
                    ForEach(noticeParts, id: \.value) { item in
                        Text(AppLocalization.string(.init(item.label))).tag(Optional(item.value))
                    }
                }
            }
        }
        Divider()
        Text(AppLocalization.string("최신순으로 표시")).font(.caption).foregroundStyle(.secondary)
        if model.nextPage != nil {
            Text(AppLocalization.string("현재 불러온 공지에 적용됩니다. 더 보기를 눌러 이전 공지도 확인하세요."))
                .font(.caption).foregroundStyle(.secondary)
        }
        if hasFilters || !search.isEmpty {
            Button(AppLocalization.string("필터 초기화"), systemImage: "arrow.counterclockwise", action: resetFilters)
        }
        if model.canCompose {
            Button(AppLocalization.string("공지 작성"), systemImage: "square.and.pencil") {
                dismiss()
                Task {
                    guard !checkingWriter else { return }
                    checkingWriter = true
                    defer { checkingWriter = false }
                    do {
                        model.canCompose = try await model.repository.canCompose(gisu: model.gisu)
                        composing = model.canCompose
                    } catch {
                        model.canCompose = false
                        model.error = error
                    }
                }
            }
            .buttonStyle(UMCToolPrimaryButtonStyle())
            .disabled(checkingWriter)
        }
        Button(AppLocalization.string("새로고침"), systemImage: "arrow.clockwise") { Task { await model.load() } }
            .disabled(model.isLoading)
    }

    private func filterRow<Content: View>(
        _ title: String.LocalizationValue, @ViewBuilder picker: () -> Content
    ) -> some View {
        HStack {
            Text(AppLocalization.string(title)).accessibilityHidden(true)
            Spacer(minLength: UMCSpacing.value8)
            picker()
                .labelsHidden()
                .accessibilityLabel(Text(AppLocalization.string(title)))
                .pickerStyle(.menu)
                .buttonStyle(.borderless)
                .tint(.primary)
                .fixedSize()
        }
        .umcTypography(.subheadlineRegular)
        .padding(.horizontal, UMCSpacing.value8)
        .frame(maxWidth: .infinity, minHeight: 28)
    }

    private var noticeList: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
            NoticeSearchField(search: $search, submit: searchNotices)
            let summary = [model.filterSummary(pinnedOnly: pinnedOnly),
                           period == .all ? nil : AppLocalization.string(.init(period.rawValue)),
                           scope.map { AppLocalization.string(.init($0)) }]
                .compactMap { $0 }.joined(separator: " · ")
            Text(summary)
                .umcTypography(.calloutRegular)
                .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
                .lineLimit(2)
                .help(summary)
                .accessibilityLabel(summary)
            if model.nextPage != nil, period != .all || scope != nil || pinnedOnly {
                Text(AppLocalization.string("현재 불러온 공지에 적용됩니다. 더 보기를 눌러 이전 공지도 확인하세요."))
                    .font(.caption).foregroundStyle(.secondary)
            }
            ScrollView {
                LazyVStack(alignment: .leading, spacing: UMCSpacing.value8) {
                    let entries = model.entries.filter { entry in
                        (scope == nil || entry.targetInfo != nil && entry.scopeLabel == scope)
                            && period.includes(entry.createdAt, start: start, end: end,
                                               calendar: calendar)
                    }
                    let pinned = entries.filter(\.mustRead)
                    if !pinned.isEmpty {
                        DisclosureGroup(isExpanded: $pinnedExpanded) {
                            VStack(spacing: UMCSpacing.value8) {
                                ForEach(pinned, content: card)
                            }
                        } label: {
                            Text(AppLocalization.string("고정 공지 · 불러온 \(pinned.count)개"))
                                .umcTypography(.calloutRegular)
                        }
                    }
                    if !pinnedOnly {
                        let recent = entries.filter { !$0.mustRead }
                        if !recent.isEmpty { Text("최근 공지").umcTypography(.headlineBold) }
                        ForEach(recent, content: card)
                    }
                    if model.isLoading {
                        if model.entries.isEmpty { NoticeListPlaceholder() }
                        else { ProgressView().controlSize(.small).frame(maxWidth: .infinity) }
                    }
                    if let error = model.error {
                        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                            if model.entries.isEmpty {
                                Text(AppLocalization.string("공지를 불러오지 못했습니다")).umcTypography(.title4Bold)
                            }
                            Text((error as? UMCFoundation.NetworkError)?.userMessage
                                 ?? error.localizedDescription)
                            let retry = AppLocalization.string("다시 시도")
                            UMCFocusableButton(retry, identifier: "notice.connection.retry") {
                                Task { await model.load(page: model.failedPage) }
                            } label: { hovered in
                                Text(retry)
                                    .foregroundStyle(UMCColor.Semantic.textBrandDefault)
                                    .padding(UMCSpacing.value8)
                                    .background(hovered ? UMCColor.Semantic.fillPrimaryStrong200
                                                : UMCColor.Semantic.surfaceBrandWeak,
                                                in: .rect(cornerRadius: UMCRadius.value6))
                            }
                            if model.entries.isEmpty, NoticeConnectionFailure.matches(error) {
                                NoticeLetterRunner()
                            }
                        }
                        .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
                        .padding(UMCSpacing.value24)
                        .frame(maxWidth: 680, alignment: .leading)
                        .frame(maxWidth: .infinity)
                    } else {
                        let empty = NoticeEmptyState(
                            entries: entries, loading: model.isLoading, hasError: false,
                            keyword: period != .all || scope != nil ? summary : model.keyword, pinnedOnly: pinnedOnly,
                            hasNext: model.nextPage != nil)
                        if empty != .none {
                            VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                                Text(empty.message).umcTypography(.headlineRegular)
                                if hasFilters { Button("필터 초기화", action: resetFilters) }
                            }
                            .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
                            .padding(UMCSpacing.value24)
                            .frame(maxWidth: 680, alignment: .leading)
                            .frame(maxWidth: .infinity)
                        }
                        if let next = model.nextPage, !model.isLoading {
                            Button("더 보기") { Task { await model.load(page: next) } }
                        }
                    }
                }
                .padding(2) // Leave the native keyboard focus ring room inside the scroll clip.
            }
        }
        .padding(UMCSpacing.value12)
        .frame(maxWidth: selection == nil ? 960 : .infinity)
        .frame(maxWidth: .infinity)
    }

    private func resetFilters() {
        search = ""
        model.tab = "CHALLENGER"
        model.part = nil
        pinnedOnly = false
        period = .all
        scope = nil
        searchNotices()
    }

    private func searchNotices() {
        model.keyword = search.trimmingCharacters(in: .whitespacesAndNewlines)
        Task { await model.load() }
    }

    private func card(_ entry: NoticeEntry) -> some View {
        NoticeListRow(
            entry: entry, selected: selection == entry.id,
            confirmed: model.readIDs.contains(entry.id), showsPreview: selection == nil
        ) {
            readingLayout.beginSelection()
            selection = entry.id
        }
    }

}

let noticeTabs = [
    (value: "CHALLENGER", label: "챌린저"),
    (value: "CENTRAL_MEMBER", label: "중앙 운영진"),
    (value: "SCHOOL_CORE", label: "교내 회장단"),
    (value: "SCHOOL_PART_LEADER", label: "교내 파트장"),
]

let noticeParts = [
    (value: "PLAN", label: "기획"), (value: "DESIGN", label: "디자인"),
    (value: "WEB_PRODUCT_ENGINEER", label: "웹 PE"),
    (value: "MOBILE_PRODUCT_ENGINEER", label: "모바일 PE"),
]

extension NoticeEntry {
    var postedAt: Date {
        (try? Date.ISO8601FormatStyle().parse(createdAt)) ?? .distantPast
    }

    var scopeLabel: String {
            targetInfo?.targetSchoolId != nil
            ? "학교" : (targetInfo?.targetChapterId != nil ? "지부" : "전체")
    }

    var audienceLabel: String {
        let tab = noticeTabs.first { $0.value == targetInfo?.targetNoticeTab }?.label
        return [scopeLabel, tab].compactMap { $0 }.joined(separator: " · ")
    }

    var metadata: String {
        [
            author?.organizationName, author?.nickname ?? author?.name,
            String(createdAt.prefix(10)), "조회 " + viewCount,
        ].compactMap { $0 }
            .filter { !$0.isEmpty }.joined(separator: " · ")
    }
}

func noticeWebURL(_ text: String) -> URL? {
    guard let url = URL(string: text), ["http", "https"].contains(url.scheme?.lowercased()),
        url.host != nil
    else { return nil }
    return url
}
