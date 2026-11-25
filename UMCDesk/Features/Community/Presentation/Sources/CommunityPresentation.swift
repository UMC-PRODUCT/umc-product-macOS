//
//  CommunityPresentation.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 10/6/26.
//

import AppKit
import CommunityDomain
import CoreDesignSystem
import SwiftUI

public struct CommunityThreadsView: View {
    private let accountID: String
    private let repository: any CommunityThreadRepository
    private let conversations: any ThreadConversationRepository
    private let management: any ThreadManagementRepository
    private let defaults: UserDefaults

    public init(
        accountID: String, repository: any CommunityThreadRepository,
        conversations: any ThreadConversationRepository, management: any ThreadManagementRepository,
        defaults: UserDefaults = .standard
    ) {
        self.accountID = accountID
        self.repository = repository
        self.conversations = conversations
        self.management = management
        self.defaults = defaults
    }

    public var body: some View {
        ThreadBrowser(accountID: accountID, repository: repository,
                      conversations: conversations, management: management, defaults: defaults)
            .id(accountID)
    }
}

private struct ThreadBrowser: View {
    let accountID: String
    let repository: any CommunityThreadRepository
    let conversations: any ThreadConversationRepository
    let management: any ThreadManagementRepository
    let defaults: UserDefaults

    @FocusState private var resultsFocused: Bool
    @State private var query = ""
    @State private var filter = ThreadListFilter.all
    @State private var participation = ThreadParticipationFilter.all
    @State private var focusRequest = 0
    @State private var threads: [CommunityThread] = []
    @State private var next: String?
    @State private var selection: String?
    @State private var reload = 0
    @State private var loading = false
    @State private var failure: String?
    @State private var creating = false
    @State private var loadedSearch: [String]?
    @State private var pendingSelection: [String]?

    private var search: [String] { [query, filter.rawValue, participation.rawValue] }

    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                HStack {
                    Text("스레드").umcTypography(.title1Bold)
                    Spacer()
                    ThreadBrowserTools(filter: $filter, participation: $participation,
                                       focusSearch: { focusRequest += 1 },
                                       create: { creating = true }, showAll: showAll)
                        .menuStyle(.borderlessButton)
                        .menuIndicator(.visible)
                        .foregroundStyle(.primary)
                        .fixedSize()
                        .accessibilityLabel("스레드 도구")
                        .help("스레드 도구")
                }
                ThreadSearchField(query: $query, focusRequest: focusRequest, selectResult: selectFirst)
                    .frame(height: 28)
                if filter != .all || participation != .all {
                    Text([filter == .all ? nil : filter.title,
                          participation == .all ? nil : participation.rawValue]
                        .compactMap { $0 }.joined(separator: " · "))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let failure {
                    Text(failure).foregroundStyle(.secondary)
                    Button("다시 시도") { reload += 1 }
                }
                if loading { ProgressView().controlSize(.small) }
                List(selection: $selection) {
                    if query.isEmpty && threads.contains(where: \.isPinned) {
                        Section("고정") { rows(threads.filter(\.isPinned)) }
                        Section("전체") { rows(threads.filter { !$0.isPinned }) }
                    } else {
                        rows(threads)
                    }
                }
                .listStyle(.plain)
                .contentMargins(.horizontal, 0, for: .scrollContent)
                .contentMargins(.vertical, 0, for: .scrollContent)
                .scrollContentBackground(.hidden)
                // The macOS plain list retains an eight-point gutter around its rows.
                .padding(.horizontal, -8)
                .frame(minHeight: 0, maxHeight: .infinity)
                .focused($resultsFocused)
                .accessibilityLabel("스레드 검색 결과")
                if let next {
                    Button("더 보기") { Task { await load(offset: next) } }.disabled(loading)
                }
            }
            .padding(UMCSpacing.value16)
            .frame(minWidth: 220, idealWidth: 344, maxWidth: 344,
                   minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            if let item = threads.first(where: { $0.id == selection }) {
                ThreadDestination(accountID: accountID, thread: item, detached: false,
                                  repository: repository, conversations: conversations,
                                  management: management, defaults: defaults)
                    .id(item.id)
            } else {
                ContentUnavailableView(threads.isEmpty && !loading && failure == nil
                    ? "표시할 스레드가 없어요" : "스레드를 선택하세요",
                    systemImage: "bubble.left.and.bubble.right")
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            }
        }
        .communitySplitContent()
        .task(id: search + [String(reload)]) {
            if loadedSearch != search {
                threads = []
                selection = nil
                next = nil
            }
            await load(offset: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: .threadBrowserChanged)) { notice in
            guard let key = notice.object as? ThreadWindowKey, key.accountID == accountID else { return }
            if notice.userInfo?["exit"] as? Bool == true && selection == key.threadID {
                selection = nil
            }
            reload += 1
        }
        .sheet(isPresented: $creating) {
            ThreadComposer(repository: repository) { item in
                filter = .all
                participation = .all
                query = ""
                threads.removeAll { $0.id == item.id }
                threads.insert(item, at: 0)
                loadedSearch = search
                selection = item.id
                creating = false
                reload += 1
            }
        }
    }

    private func rows(_ items: [CommunityThread]) -> some View {
        ForEach(items) { item in
            let selected = selection == item.id
            let title = selected ? UMCColor.Semantic.textInverse : UMCColor.Semantic.textNeutralDefault
            let detail = selected ? UMCColor.Semantic.textInverse : UMCColor.Semantic.textNeutralMedium600
            let kicked = item.membershipState == "KICKED"
            let status = kicked ? "내보내짐" : (item.isMuted ? "알림 꺼짐" : (item.isJoined ? "참여 중" : "미참여"))
            let category = item.category.map { ThreadListFilter(rawValue: $0)?.title ?? $0 }
            let preview = [category, kicked ? "확인 필요" : item.description]
                .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
            HStack(alignment: .top, spacing: 8) {
                Text(item.icon).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 5) {
                        Text(item.title)
                            .umcTypography(item.unread == "0" ? .headlineRegular : .headlineBold)
                            .lineLimit(2).foregroundStyle(title)
                            .layoutPriority(1)
                        if item.isPinned {
                            Image(systemName: "pin.fill").font(.caption2).accessibilityLabel("고정됨")
                        }
                        Spacer(minLength: 2)
                        if item.unread != "0" {
                            Text(item.unread).font(.caption2.bold())
                                .foregroundStyle(UMCColor.Semantic.textBrandStrong)
                                .padding(.horizontal, 5).padding(.vertical, 1)
                                .background(UMCColor.Semantic.surfaceBrandMedium, in: Capsule())
                                .accessibilityLabel("안 읽은 메시지 " + item.unread)
                        }
                    }
                    Text([status, preview].filter { !$0.isEmpty }.joined(separator: " · "))
                        .umcTypography(.captionRegular).lineLimit(1)
                }
            }
            .foregroundStyle(detail)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                if selected {
                    RoundedRectangle(cornerRadius: 8).fill(UMCColor.Semantic.fillPrimaryInverseStronger600)
                }
            }
            .contentShape(Rectangle())
            .listRowInsets(EdgeInsets())
            .listRowBackground(UMCColor.Custom.backgroundDefault)
            .tag(item.id)
        }
    }

    private func showAll() {
        query = ""
        filter = .all
        participation = .all
        selection = nil
        pendingSelection = nil
    }

    private func selectFirst() {
        guard loadedSearch == search && !loading else { pendingSelection = search; return }
        guard let id = threads.first?.id else { return }
        selection = id
        resultsFocused = true
    }

    @MainActor private func load(offset: String?) async {
        let expected = search
        let generation = reload
        loading = true
        failure = nil
        defer {
            if !Task.isCancelled, expected == search, generation == reload { loading = false }
        }
        do {
            if !query.isEmpty, offset == nil { try await Task.sleep(for: .milliseconds(200)) }
            let previous = offset == nil ? [] : threads
            var ids = Set(previous.map(\.id))
            var cursor = offset
            var visited = Set<String>()
            var matches: [CommunityThread] = []
            repeat {
                if let cursor { visited.insert(cursor) }
                let page = try await repository.threads(query: String(query.unicodeScalars.prefix(80)),
                                                        filter: filter.rawValue, offset: cursor)
                try Task.checkCancellation()
                guard expected == search, generation == reload else { return }
                matches = page.values.filter { participation.includes($0) && ids.insert($0.id).inserted }
                cursor = page.cursor.flatMap { visited.contains($0) ? nil : $0 }
            } while matches.isEmpty && cursor != nil
            threads = previous + matches
            next = cursor
            loadedSearch = expected
            if pendingSelection == expected, let first = threads.first {
                selection = first.id
                resultsFocused = true
            }
            pendingSelection = nil
        } catch {
            if !Task.isCancelled, expected == search, generation == reload {
                failure = error.localizedDescription
            }
        }
    }
}

struct ThreadBrowserTools: View {
    @Binding var filter: ThreadListFilter
    @Binding var participation: ThreadParticipationFilter
    let focusSearch: () -> Void
    let create: () -> Void
    let showAll: () -> Void

    var body: some View {
        Menu("도구") {
            Button("제목·소개 검색", systemImage: "magnifyingglass") {
                focusSearch()
            }.keyboardShortcut("f")
            Button("스레드 만들기", systemImage: "plus") { create() }
            Divider()
            Menu("분류 · 참여 상태 필터") {
                Picker("분류", selection: $filter) {
                    ForEach(ThreadListFilter.allCases, id: \.self) { value in
                        Text(value.title).tag(value)
                    }
                }.pickerStyle(.inline)
                Divider()
                Picker("참여 상태", selection: $participation) {
                    ForEach(ThreadParticipationFilter.allCases, id: \.self) { value in
                        Text(value.rawValue).tag(value)
                    }
                }.pickerStyle(.inline)
            }
            .toggleStyle(.automatic)
            Button("전체 스레드") {
                showAll()
            }
        }
    }
}

enum ThreadListFilter: String, CaseIterable {
    case all, unread
    case study = "STUDY"
    case question = "QNA"
    case project = "PROJECT"
    case free = "FREE"

    var title: String {
        switch self {
        case .all: "모든 분류"
        case .unread: "읽지 않음"
        case .study: "스터디"
        case .question: "질문"
        case .project: "프로젝트"
        case .free: "자유"
        }
    }
}

enum ThreadParticipationFilter: String, CaseIterable {
    case all = "모든 참여 상태"
    case joined = "참여 중"
    case unjoined = "미참여"

    func includes(_ thread: CommunityThread) -> Bool {
        switch self {
        case .all: true
        case .joined: thread.isJoined
        case .unjoined: !thread.isJoined
        }
    }
}

private struct ThreadComposer: View {
    let repository: any CommunityThreadRepository
    let created: (CommunityThread) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var icon = "💬"
    @State private var category = "FREE"
    @State private var failure: String?
    @State private var saving = false

    var body: some View {
        Form {
            Text("새 스레드").umcTypography(.title1Bold)
            TextField("이름", text: $title)
            TextField("설명", text: $description, axis: .vertical)
            TextField("아이콘", text: $icon)
            Picker("카테고리", selection: $category) {
                Text("자유").tag("FREE")
                Text("스터디").tag("STUDY")
                Text("질문").tag("QNA")
                Text("프로젝트").tag("PROJECT")
            }
            if let failure { Text(failure).foregroundStyle(.secondary) }
            HStack {
                Spacer()
                Button("취소") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("만들기") { create() }.keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                              || title.unicodeScalars.count > 80 || description.unicodeScalars.count > 500
                              || icon.count != 1 || icon.unicodeScalars.count > 32)
            }
        }.padding(UMCSpacing.value24).frame(width: 420).disabled(saving)
         .interactiveDismissDisabled(saving)
    }

    private func create() {
        guard !saving else { return }
        saving = true
        Task { @MainActor in
            defer { saving = false }
            do {
                let value = try await repository.create(title: title, description: description,
                                                        category: category, icon: icon)
                created(value)
            } catch { failure = error.localizedDescription }
        }
    }
}

extension View {
    /// A native split pane next to the app rail can extend beneath the unified window toolbar.
    func communitySplitContent() -> some View {
        frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity,
              alignment: .topLeading)
            .padding(.top, UMCSpacing.value16)
    }
}

struct ThreadShareMenu: View {
    let thread: CommunityThread

    var body: some View {
        Menu("공유", systemImage: "square.and.arrow.up") {
            if let url = thread.shareURL {
                Button("링크 복사", systemImage: "document.on.document") {
                    Self.copy(url, to: .general)
                }
                ShareLink(item: url) {
                    Label("다른 앱으로 공유…", systemImage: "square.and.arrow.up")
                }
            } else {
                Text("공유 링크가 제공되지 않았어요")
                ShareLink(item: summary) {
                    Label("스레드 소개 공유…", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    var summary: String {
        [thread.title, thread.description ?? ""]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }.joined(separator: "\n")
    }

    static func copy(_ url: URL, to pasteboard: NSPasteboard) {
        let item = NSPasteboardItem()
        item.setString(url.absoluteString, forType: .URL)
        item.setString(url.absoluteString, forType: .string)
        pasteboard.clearContents()
        pasteboard.writeObjects([item])
    }
}
