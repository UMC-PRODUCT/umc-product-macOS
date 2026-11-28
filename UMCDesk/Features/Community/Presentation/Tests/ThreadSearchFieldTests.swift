//
//  ThreadSearchFieldTests.swift
//  CommunityPresentationTests
//
//  Created by euijjang97 on 11/23/26.
//

import AppKit
import CommunityDomain
import CoreUIComponents
@testable import CommunityPresentation
import SwiftUI
import Testing

@MainActor
struct ThreadSearchFieldTests {
    @Test(arguments: [1040, 1440], [ColorScheme.light, .dark])
    func pressingReturnWhileSearchingSelectsTheFetchedRow(width: Int, scheme: ColorScheme) async throws {
        let fixture = ThreadSearchRepository()
        let view = CommunityThreadsView(accountID: "101", repository: fixture,
                                        conversations: fixture, management: fixture)
        let host = NSHostingView(rootView: view.environment(\.colorScheme, scheme))
        let window = NSWindow(contentRect: .init(x: 0, y: 0, width: width, height: 720),
                              styleMask: [.titled, .resizable], backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        let field = try #require(find(NSSearchField.self, in: host))
        let findKey = try #require(NSEvent.keyEvent(with: .keyDown, location: .zero,
            modifierFlags: .command, timestamp: 0, windowNumber: window.windowNumber,
            context: nil, characters: "f", charactersIgnoringModifiers: "f",
            isARepeat: false, keyCode: 3))
        #expect(window.performKeyEquivalent(with: findKey))
        let focusDeadline = ContinuousClock.now + .seconds(2)
        while field.currentEditor() == nil, ContinuousClock.now < focusDeadline {
            try await Task.sleep(for: .milliseconds(10))
            host.layoutSubtreeIfNeeded()
        }
        let editor = try #require(field.currentEditor() as? NSTextView)
        editor.insertText("한글", replacementRange: .init(location: NSNotFound, length: 0))
        editor.doCommand(by: #selector(NSResponder.insertNewline(_:)))
        let deadline = ContinuousClock.now + .seconds(3)
        while await fixture.selected.isEmpty, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(20))
            host.layoutSubtreeIfNeeded()
        }
        #expect(await fixture.selected == "42")
        #expect(window.firstResponder !== editor)
        #expect(find(NSTableView.self, in: host)?.selectedRow == 0)
        window.contentView = nil
    }

    @Test func disabledBrowserSearchYieldsCommandFToTheToolsPanel() throws {
        let host = NSHostingView(rootView: ThreadSearchField(query: .constant(""),
                                                             selectResult: {}).disabled(true))
        let window = NSWindow(contentRect: .init(x: 0, y: 0, width: 320, height: 60),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = host
        defer { window.contentView = nil }
        host.layoutSubtreeIfNeeded()
        let field = try #require(find(NSSearchField.self, in: host))
        let event = try #require(NSEvent.keyEvent(with: .keyDown, location: .zero,
            modifierFlags: .command, timestamp: 0, windowNumber: window.windowNumber,
            context: nil, characters: "f", charactersIgnoringModifiers: "f",
            isARepeat: false, keyCode: 3))
        #expect(!field.isEnabled)
        #expect(!field.performKeyEquivalent(with: event))
    }

    @Test func retryRestoresTheSelectedThreadAfterAnIndependentFetchFailure() async {
        let fixture = ThreadSearchRepository()
        await fixture.failNextDetailFetch()
        let restoration = ThreadRestoration()
        await restoration.load(id: "42", repository: fixture)
        guard case .failed = restoration.state else {
            Issue.record("상세 조회 실패가 복원 패널에 표시되어야 합니다.")
            return
        }
        await restoration.load(id: "42", repository: fixture)
        guard case .loaded(let thread) = restoration.state else {
            Issue.record("다시 시도하면 같은 스레드가 복원되어야 합니다.")
            return
        }
        #expect(thread.id == "42")
        #expect(await fixture.detailRequests == ["42", "42"])
    }

    @Test func paginationPreservesUnsavedEditsInTheRestoredThread() async throws {
        let fixture = ThreadSearchRepository()
        let state = DraftProbeState()
        let view = DraftProbeHost(repository: fixture, state: state)
        let controller = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: controller)
        defer { window.contentView = nil }
        func waitFor(_ condition: () -> Bool) async throws {
            let deadline = ContinuousClock.now + .seconds(3)
            while !condition(), ContinuousClock.now < deadline {
                controller.view.layoutSubtreeIfNeeded()
                try await Task.sleep(for: .milliseconds(20))
            }
            try #require(condition())
        }
        try await waitFor { state.edit != nil }
        state.edit?("아직 보내지 않은 수정")
        try await waitFor { state.rendered == "한글 결과:아직 보내지 않은 수정" }
        state.listed = CommunityThread(id: "42", title: "추가 페이지 결과", description: nil,
            icon: "💬", isPinned: false, isMuted: false, isJoined: false,
            membershipState: nil, unread: "0")
        try await waitFor { state.rendered.hasPrefix("추가 페이지 결과:") }
        #expect(state.rendered == "추가 페이지 결과:아직 보내지 않은 수정")
        #expect(await fixture.detailRequests == ["42"])
    }

    @Test func filterMenuShowsOneNativeMarkPerGroupAfterReopening() throws {
        var category = ThreadListFilter.all
        var participation = ThreadParticipationFilter.all

        func openFilters() throws -> NSMenu {
            let tools = ThreadBrowserTools(
                filter: .init(get: { category }, set: { category = $0 }),
                participation: .init(get: { participation }, set: { participation = $0 }),
                create: {}, showAll: {}
            )
            let menu = NSHostingMenu(rootView: tools.toggleStyle(UMCCheckboxStyle()))
            return try #require(menu.item(withTitle: "분류 · 참여 상태 필터")?.submenu)
        }

        func verifyRows(in menu: NSMenu) throws {
            let titles = ThreadListFilter.allCases.map(\.title)
                + ThreadParticipationFilter.allCases.map(\.rawValue)
            for title in titles {
                let item = try #require(menu.item(withTitle: title))
                let selected = title == category.title || title == participation.rawValue
                #expect(item.state == (selected ? .on : .off))
                #expect(item.image == nil)
                #expect(item.view == nil)
            }
        }

        let initial = try openFilters()
        try verifyRows(in: initial)
        let project = try #require(initial.item(withTitle: "프로젝트"))
        initial.performActionForItem(at: initial.index(of: project))
        #expect(category == .project && participation == .all)
        let afterCategory = try openFilters()
        try verifyRows(in: afterCategory)
        let unjoined = try #require(afterCategory.item(withTitle: "미참여"))
        afterCategory.performActionForItem(at: afterCategory.index(of: unjoined))
        #expect(category == .project && participation == .unjoined)
        try verifyRows(in: openFilters())
    }

    @Test func emptyThreadToolsKeepBothFiltersAndAllThreads() throws {
        var actions: [String] = []
        let tools = ThreadBrowserTools(filter: .constant(.all), participation: .constant(.all),
            create: { actions.append("create") }, showAll: { actions.append("all") })
        let menu = NSHostingMenu(rootView: tools)
        for title in ["스레드 만들기", "전체 스레드"] {
            let item = try #require(menu.item(withTitle: title))
            menu.performActionForItem(at: menu.index(of: item))
        }
        #expect(actions == ["create", "all"])
        #expect(menu.items.compactMap(\.submenu).contains {
            $0.item(withTitle: ThreadListFilter.project.title) != nil
        })
        #expect(menu.items.compactMap(\.submenu).contains {
            $0.item(withTitle: ThreadParticipationFilter.unjoined.rawValue) != nil
        })
    }

    @Test func sharingUsesNativeMenuActionsAndServerPayload() throws {
        func share(_ url: URL?) -> ThreadShareMenu {
            .init(thread: .init(id: "42", title: "스터디", description: "이번 주 소개", icon: "💬",
                                isPinned: false, isMuted: false, isJoined: true,
                                membershipState: "ACTIVE", unread: "0", shareURL: url))
        }
        let url = try #require(URL(string: "https://threads.example.org/community/threads/42"))
        let linked = NSHostingMenu(rootView: share(url))
        let sharing = try #require(linked.item(withTitle: "공유")?.submenu)
        #expect(sharing.item(withTitle: "링크 복사") != nil)
        #expect(sharing.item(withTitle: "다른 앱으로 공유…") != nil)
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        ThreadShareMenu.copy(url, to: pasteboard)
        #expect(pasteboard.string(forType: .URL) == url.absoluteString)
        #expect(pasteboard.string(forType: .string) == url.absoluteString)
        let fallback = share(nil)
        #expect(fallback.summary == "스터디\n이번 주 소개")
        let unlinked = NSHostingMenu(rootView: fallback)
        let textSharing = try #require(unlinked.item(withTitle: "공유")?.submenu)
        #expect(textSharing.item(withTitle: "링크 복사") == nil)
        #expect(textSharing.item(withTitle: "스레드 소개 공유…") != nil)
        #expect(textSharing.item(withTitle: "공유 링크가 제공되지 않았어요") != nil)
    }

    private func find<T: NSView>(_ type: T.Type, in root: NSView) -> T? {
        if let view = root as? T { return view }
        return root.subviews.lazy.compactMap { find(type, in: $0) }.first
    }

    @Test func preservesMarkedKoreanAndMovesToResultsOnlyAfterCommit() throws {
        var query = ""
        var selectedQueries: [String] = []
        let control = ThreadSearchField(query: .init(get: { query }, set: { query = $0 })) {
            selectedQueries.append(query)
        }
        let host = NSHostingView(rootView: control)
        let window = NSWindow(contentRect: .init(x: 0, y: 0, width: 320, height: 120),
                              styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = host
        defer { window.contentView = nil }
        host.layoutSubtreeIfNeeded()
        let field = try #require(find(NSSearchField.self, in: host))
        let delegate = try #require(field.delegate)
        #expect(field.focusRingType == .none)
        #expect(!field.isBordered)
        #expect(window.makeFirstResponder(field))
        let editor = try #require(field.currentEditor() as? NSTextView)
        let cursor = NSRange(location: 1, length: 0)
        let insertion = NSRange(location: NSNotFound, length: 0)
        editor.setMarkedText("ㅎ", selectedRange: cursor, replacementRange: insertion)
        editor.setMarkedText("한", selectedRange: cursor, replacementRange: insertion)
        #expect(editor.hasMarkedText())
        #expect(query.isEmpty)
        #expect(delegate.control?(field, textView: editor,
                                  doCommandBy: #selector(NSResponder.insertNewline(_:))) == false)
        #expect(selectedQueries.isEmpty)
        editor.insertText("한", replacementRange: insertion)
        #expect(query == "한")
        #expect(!editor.hasMarkedText())
        editor.doCommand(by: #selector(NSResponder.moveDown(_:)))
        editor.doCommand(by: #selector(NSResponder.insertNewline(_:)))
        #expect(selectedQueries == ["한", "한"])
    }
}

@MainActor @Observable
private final class DraftProbeState {
    var listed: CommunityThread?
    var edit: ((String) -> Void)?
    var rendered = ""
}

private struct DraftProbeHost: View {
    let repository: any CommunityThreadRepository
    let state: DraftProbeState

    var body: some View {
        RestoredThreadPane(id: "42", listed: state.listed, repository: repository) { thread in
            DraftProbe(title: thread.title, state: state)
        }
    }
}

private struct DraftProbe: View {
    let title: String
    let state: DraftProbeState
    @State private var draft = ""

    var body: some View {
        TextField(title, text: $draft)
            .onAppear { state.edit = { draft = $0 } }
            .onChange(of: title + ":" + draft, initial: true) { _, value in
                state.rendered = value
            }
    }
}

private actor ThreadSearchRepository:
    CommunityThreadRepository, ThreadConversationRepository, ThreadManagementRepository
{
    var selected = ""
    private var failDetail = false
    private(set) var detailRequests: [String] = []

    func failNextDetailFetch() { failDetail = true }
    let row = CommunityThread(id: "42", title: "한글 결과", description: nil, icon: "💬",
                              isPinned: false, isMuted: false, isJoined: false,
                              membershipState: nil, unread: "0")

    func thread(id: String) async throws -> CommunityThread {
        detailRequests.append(id)
        if failDetail {
            failDetail = false
            throw URLError(.timedOut)
        }
        selected = id
        return row
    }

    func threads(query: String, filter: String, offset: String?) async throws
        -> ThreadPage<CommunityThread> {
        .init(values: query == "한글" ? [row] : [], cursor: nil)
    }

    func messages(id: String, before: String?) async throws -> ThreadPage<ThreadMessage> {
        throw CancellationError()
    }

    func update(_ preference: ThreadPreference, enabled: Bool, id: String) async throws
        -> CommunityThread { throw CancellationError() }

    func create(title: String, description: String, category: String, icon: String) async throws
        -> CommunityThread { throw CancellationError() }

    func history(thread: String, before: String?) async throws
        -> ThreadPage<ThreadConversationMessage> { throw CancellationError() }

    func members(thread: String, query: String) async throws -> [ThreadManagementPerson] { [] }
    func perform(_ command: ThreadConversationCommand, thread: String) async throws {}
    func observeChanges(
        thread: String, changed: @escaping @Sendable () async -> Void
    ) async throws {}
    func upload(name: String, contentType: String, data: Data) async throws -> String {
        throw CancellationError()
    }
    func detail(threadID: String) async throws -> ThreadManagementDetail { throw CancellationError() }
    func people(threadID: String, invitable: Bool, query: String, offset: String?) async throws
        -> ThreadManagementPage { throw CancellationError() }
    func profile(memberID: String) async throws -> ThreadManagementProfile { throw CancellationError() }
    func report(_ target: ThreadReportTarget, reasons: [ThreadReportReason], detail: String)
        async throws -> String { throw CancellationError() }
    func isBlocked(memberID: String) async throws -> Bool { false }
    func setBlocked(_ blocked: Bool, memberID: String) async throws { throw CancellationError() }
    func currentMemberID() async throws -> String { "101" }
    func apply(_ action: ThreadManagementAction, threadID: String) async throws {}
}
