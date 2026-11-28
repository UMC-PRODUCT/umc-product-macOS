//
//  CommunityPresentation.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 10/6/26.
//

import AppKit
import CommunityDomain
import CoreUIComponents
import CoreDesignSystem
import CoreRouting
import SwiftUI
import UMCFoundation

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

/// Restoring a paginated thread fetches its detail independently of the current list.
@MainActor @Observable
final class ThreadRestoration {
    private(set) var state: Loadable<CommunityThread> = .idle

    func load(id: String, repository: any CommunityThreadRepository) async {
        state = .loading
        do {
            let thread = try await repository.thread(id: id)
            if !Task.isCancelled { state = .loaded(thread) }
        } catch {
            if !Task.isCancelled { state = .failed(error) }
        }
    }
}

struct RestoredThreadPane<Content: View>: View {
    let id: String
    let listed: CommunityThread?
    let repository: any CommunityThreadRepository
    let content: (CommunityThread) -> Content
    @State private var restoration = ThreadRestoration()
    @State private var attempt = 0

    private var thread: CommunityThread? {
        if let listed { return listed }
        if case .loaded(let restored) = restoration.state { return restored }
        return nil
    }

    var body: some View {
        Group {
            // Keep the editor at the same SwiftUI identity when pagination supplies this row.
            if let thread { content(thread) }
            else if case .failed(let error) = restoration.state {
                ContentUnavailableView {
                    Label("스레드를 열지 못했어요", systemImage: "bubble.left")
                } description: {
                    Text(error.localizedDescription)
                } actions: {
                    Button("다시 시도") { attempt += 1 }
                }
            } else {
                ProgressView("스레드를 불러오는 중")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task(id: listed == nil ? attempt : nil) {
            if thread == nil { await restoration.load(id: id, repository: repository) }
        }
    }
}

private struct ThreadBrowser: View {
    let accountID: String
    let repository: any CommunityThreadRepository
    let conversations: any ThreadConversationRepository
    let management: any ThreadManagementRepository
    let defaults: UserDefaults

    @Environment(\.threadNotificationCenter) private var notifications
    @FocusState private var resultsFocused: Bool
    @State private var query = ""
    @State private var filter = ThreadListFilter.all
    @State private var participation = ThreadParticipationFilter.all
    @State private var focusRequest = 0
    @State private var toolsOpen = false
    @State private var threads: [CommunityThread] = []
    @State private var next: String?
    @WindowDetailSelection private var selection: String?
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
                Text("스레드").umcTypography(.title1Bold)
                ThreadSearchField(query: $query, focusRequest: focusRequest, selectResult: selectFirst)
                    .disabled(toolsOpen)
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
            if let selection {
                RestoredThreadPane(id: selection, listed: threads.first { $0.id == selection },
                                   repository: repository, content: destination)
                    .id(selection)
            } else {
                ContentUnavailableView(threads.isEmpty && !loading && failure == nil
                    ? "표시할 스레드가 없어요" : "스레드를 선택하세요",
                    systemImage: "bubble.left.and.bubble.right")
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            }
        }
        .communitySplitContent()
        .background {
            if !toolsOpen, !creating {
                Button("제목·소개 검색") { focusRequest += 1 }
                    .keyboardShortcut("f")
                    .hidden()
                    .accessibilityHidden(true)
            }
        }
        .umcTabTools(AppLocalization.string("스레드 도구"), width: .wide, isPresented: $toolsOpen) { dismiss in
            Text(AppLocalization.string("대화를 찾고 새로운 공간을 만드세요."))
                .font(.caption).foregroundStyle(.secondary)
            ThreadSearchField(query: $query, focusRequest: 1, placeholder: "제목, 소개 검색") {
                dismiss()
                selectFirst()
            }
            ThreadBrowserTools(filter: $filter, participation: $participation,
                               create: { dismiss(); creating = true },
                               showAll: { dismiss(); showAll() })
        }
        .task(id: search + [String(reload)]) {
            if loadedSearch != search {
                threads = []
                if loadedSearch != nil { selection = nil }
                next = nil
            }
            await load(offset: nil)
        }
        .onReceive(notifications.publisher(for: .threadBrowserChanged)) { notice in
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

    private func destination(for item: CommunityThread) -> some View {
        ThreadDestination(accountID: accountID, thread: item, detached: false,
                          repository: repository, conversations: conversations,
                          management: management, defaults: defaults)
            .id(item.id)
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
    let create: () -> Void
    let showAll: () -> Void

    var body: some View {
        Button(AppLocalization.string("스레드 만들기"), systemImage: "plus.bubble", action: create)
            .buttonStyle(UMCToolPrimaryButtonStyle())
        Divider()
        UMCToolGroupHeading(AppLocalization.string("목록 보기"))
        Menu {
            Picker(AppLocalization.string("분류"), selection: $filter) {
                ForEach(ThreadListFilter.allCases, id: \.self) { Text($0.title).tag($0) }
            }.pickerStyle(.inline)
            Divider()
            Picker(AppLocalization.string("참여 상태"), selection: $participation) {
                ForEach(ThreadParticipationFilter.allCases, id: \.self) { Text(AppLocalization.string(.init($0.rawValue))).tag($0) }
            }.pickerStyle(.inline)
        } label: {
            Label(AppLocalization.string("분류 · 참여 상태 필터"), systemImage: "line.3.horizontal.decrease")
        }
        .toggleStyle(.automatic)
        Button(AppLocalization.string("전체 스레드"), systemImage: "list.bullet", action: showAll)
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
        case .all: AppLocalization.string("모든 분류")
        case .unread: AppLocalization.string("읽지 않음")
        case .study: AppLocalization.string("스터디")
        case .question: AppLocalization.string("질문")
        case .project: AppLocalization.string("프로젝트")
        case .free: AppLocalization.string("자유")
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
                .umcInputField()
            TextField("설명", text: $description, axis: .vertical)
            TextField("아이콘", text: $icon)
                .umcInputField()
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
