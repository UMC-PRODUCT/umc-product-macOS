//  NoticePresentation.swift
//  NoticePresentation
//
//  Created by euijjang97 on 11/23/26.

import CoreDesignSystem
import CoreRouting
import NoticeDomain
import SwiftUI

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
    var error: String?
    var accessLossRevision = 0
    var readIDs: Set<String> = []
    private var requestID = UUID()

    init(repository: any NoticeRepository) {
        self.repository = repository
    }

    func revokeArticle(_ id: String) {
        requestID = UUID()
        isLoading = false
        entries.removeAll { $0.id == id }
        readIDs.remove(id)
        error = NoticeRequestFailure.accessDenied.localizedDescription
    }

    func load(page: Int = 0) async {
        let token = UUID()
        requestID = token
        error = nil
        isLoading = true
        if page == 0 {
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
                gisu: generation, tab: tab,
                keyword: keyword, part: tab == "CHALLENGER" ? part : nil, page: page)
            guard requestID == token, !Task.isCancelled else { return }
            var known = Set(entries.map(\.id))
            entries += response.content.filter { known.insert($0.id).inserted }
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
            self.error = error.localizedDescription
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
    @State private var showTools = false
    @State private var fullReader = false
    @State private var pinnedOnly = false

    public init(repository: any NoticeRepository) {
        _model = State(initialValue: NoticeBoardModel(repository: repository))
    }

    public var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            HStack(spacing: 0) {
                if let id = selection {
                    if !fullReader {
                        noticeList
                            .frame(minWidth: 168, idealWidth: 280, maxWidth: 340)
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
        .task(id: model.tab) { await model.load() }
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
                    model.error = NoticeRequestFailure.accessDenied.localizedDescription
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
                Button("공지 목록", systemImage: "list.bullet") { selection = nil }
                Button(
                    fullReader ? "분할 보기" : "전체 읽기",
                    systemImage: fullReader ? "sidebar.left" : "arrow.up.left.and.arrow.down.right"
                ) {
                    fullReader.toggle()
                }
            }
            Spacer()
            if model.canCompose {
                Button("공지 작성", systemImage: "square.and.pencil") {
                    Task {
                        guard !checkingWriter else { return }
                        checkingWriter = true
                        defer { checkingWriter = false }
                        do {
                            model.canCompose = try await model.repository.canCompose(
                                gisu: model.gisu)
                            composing = model.canCompose
                        } catch {
                            model.canCompose = false
                            model.error = error.localizedDescription
                        }
                    }
                }.disabled(checkingWriter)
            }
            Button("공지 도구", systemImage: "slider.horizontal.3") { showTools.toggle() }
                .keyboardShortcut("f")
                .popover(isPresented: $showTools) { tools }
        }
        .padding(.horizontal, UMCSpacing.value20)
        .padding(.vertical, UMCSpacing.value12)
    }

    private var tools: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            HStack {
                Text("공지 도구").umcTypography(.headlineBold)
                Spacer()
                Button("초기화") {
                    search = ""
                    model.tab = "CHALLENGER"
                    model.part = nil
                    pinnedOnly = false
                    searchNotices()
                }
            }
            HStack {
                TextField("제목, 내용 검색", text: $search).onSubmit(searchNotices)
                Button("검색", action: searchNotices)
            }
            Picker("빠른 보기", selection: $pinnedOnly) {
                Text("전체").tag(false)
                Text("고정").tag(true)
            }.pickerStyle(.segmented)
            Picker("공지 대상", selection: $model.tab) {
                ForEach(noticeTabs, id: \.value) { tab in Text(tab.label).tag(tab.value) }
            }
            if model.tab == "CHALLENGER" {
                Picker("파트", selection: $model.part) {
                    Text("전체 파트").tag(String?.none)
                    ForEach(noticeParts, id: \.value) { item in
                        Text(item.label).tag(Optional(item.value))
                    }
                }
            }
            Button("새로고침", systemImage: "arrow.clockwise") { Task { await model.load() } }
        }.padding(UMCSpacing.value20).frame(width: 320)
    }

    private var noticeList: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: UMCSpacing.value12) {
                let pinned = model.entries.filter(\.mustRead)
                if !pinned.isEmpty {
                    DisclosureGroup("고정 공지 (\(pinned.count))", isExpanded: $pinnedExpanded) {
                        ForEach(pinned, content: card)
                    }
                }
                if !pinnedOnly {
                    let recent = model.entries.filter { !$0.mustRead }
                    if !recent.isEmpty { Text("최근 공지").umcTypography(.headlineBold) }
                    ForEach(recent, content: card)
                } else if pinned.isEmpty && !model.isLoading {
                    Text("고정된 공지가 없습니다.").foregroundStyle(.secondary)
                }
                if model.isLoading { ProgressView().frame(maxWidth: .infinity) }
                if let error = model.error {
                    Text(error).foregroundStyle(.secondary)
                    Button("다시 시도") { Task { await model.load(page: model.nextPage ?? 0) } }
                } else if let next = model.nextPage, !model.isLoading {
                    Button("더 보기") { Task { await model.load(page: next) } }
                } else if model.entries.isEmpty, !model.isLoading {
                    ContentUnavailableView("공지가 없습니다", systemImage: "megaphone")
                }
            }
        }
        .padding(selection == nil ? UMCSpacing.value24 : UMCSpacing.value12)
    }

    private func searchNotices() {
        model.keyword = search.trimmingCharacters(in: .whitespacesAndNewlines)
        Task { await model.load() }
    }

    private func card(_ entry: NoticeEntry) -> some View {
        Button {
            selection = entry.id
        } label: {
            VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                Text(entry.title)
                    .umcTypography(model.readIDs.contains(entry.id) ? .headlineRegular : .title3Bold)
                HStack {
                    Text(entry.audienceLabel).umcTypography(.footnoteRegular)
                    if entry.mustRead { Label("고정", systemImage: "pin.fill") }
                }
                .foregroundStyle(UMCColor.Semantic.textBrandDefault)
                if let deadline = entry.vote?.endsAtExclusive, !deadline.isEmpty {
                    Label("투표 마감 " + String(deadline.prefix(10)), systemImage: "calendar.badge.clock")
                        .umcTypography(.calloutRegular)
                }
                if selection == nil {
                    Text(entry.content).lineLimit(2).foregroundStyle(.secondary)
                }
                HStack {
                    Text(entry.metadata).umcTypography(.captionRegular)
                    Spacer()
                    if entry.hasLinks == true {
                        Image(systemName: "link").accessibilityLabel("링크")
                    }
                    if entry.hasImages == true {
                        Image(systemName: "photo").accessibilityLabel("사진")
                    }
                    if entry.hasVote == true {
                        Image(systemName: "chart.bar").accessibilityLabel("투표")
                    }
                    if model.readIDs.contains(entry.id) { Label("읽음", systemImage: "checkmark") }
                }
                .foregroundStyle(.secondary)
            }
            .padding(.vertical, UMCSpacing.value16)
            .padding(.horizontal, UMCSpacing.value20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                selection == entry.id
                    ? UMCColor.Semantic.fillPrimaryStrong200
                    : (entry.mustRead
                        ? UMCColor.Semantic.surfaceBrandWeak
                        : UMCColor.Custom.backgroundSurface)
            )
            .overlay(alignment: .leading) {
                if entry.mustRead {
                    Rectangle().fill(UMCColor.Semantic.textBrandDefault).frame(width: 3)
                }
            }
            .clipShape(.rect(cornerRadius: UMCRadius.value16))
            .overlay {
                RoundedRectangle(cornerRadius: UMCRadius.value16)
                    .strokeBorder(UMCColor.Semantic.borderNeutralWeak200)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("notice.row." + entry.id)
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
    var audienceLabel: String {
        let scope =
            targetInfo?.targetSchoolId != nil
            ? "학교" : (targetInfo?.targetChapterId != nil ? "지부" : "전체")
        let tab = noticeTabs.first { $0.value == targetInfo?.targetNoticeTab }?.label
        return [scope, tab].compactMap { $0 }.joined(separator: " · ")
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
