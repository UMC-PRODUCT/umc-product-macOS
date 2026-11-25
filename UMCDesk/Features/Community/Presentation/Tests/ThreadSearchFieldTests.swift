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

    @Test func filterMenuShowsOneNativeMarkPerGroupAfterReopening() throws {
        var category = ThreadListFilter.all
        var participation = ThreadParticipationFilter.all

        func openFilters() throws -> NSMenu {
            let tools = ThreadBrowserTools(
                filter: .init(get: { category }, set: { category = $0 }),
                participation: .init(get: { participation }, set: { participation = $0 }),
                focusSearch: {}, create: {}, showAll: {}
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

    @Test func toolsAndSharingUseNativeMenuActionsAndServerPayload() throws {
        var activated: [String] = []
        var filter = ThreadListFilter.all
        var participation = ThreadParticipationFilter.all
        let tools = ThreadBrowserTools(filter: .init(get: { filter }, set: { filter = $0 }),
            participation: .init(get: { participation }, set: { participation = $0 }),
            focusSearch: { activated.append("search") }, create: { activated.append("create") },
            showAll: { activated.append("all") })
        let menu = NSHostingMenu(rootView: tools)
        for title in ["제목·소개 검색", "스레드 만들기", "전체 스레드"] {
            let action = try #require(menu.item(withTitle: title))
            menu.performActionForItem(at: menu.index(of: action))
        }
        #expect(activated == ["search", "create", "all"])
        let filters = try #require(menu.item(withTitle: "분류 · 참여 상태 필터")?.submenu)
        for title in ["프로젝트", "미참여"] {
            let action = try #require(filters.item(withTitle: title))
            filters.performActionForItem(at: filters.index(of: action))
        }
        #expect(filter == .project && participation == .unjoined)

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
        let delegate = control.makeCoordinator()
        let window = NSWindow(contentRect: .init(x: 0, y: 0, width: 320, height: 120),
                              styleMask: [.titled], backing: .buffered, defer: false)
        let field = NSSearchField(frame: .init(x: 0, y: 70, width: 240, height: 32))
        field.delegate = delegate
        window.contentView?.addSubview(field)
        #expect(window.makeFirstResponder(field))
        let editor = try #require(field.currentEditor() as? NSTextView)
        let cursor = NSRange(location: 1, length: 0)
        let insertion = NSRange(location: NSNotFound, length: 0)
        editor.setMarkedText("ㅎ", selectedRange: cursor, replacementRange: insertion)
        editor.setMarkedText("한", selectedRange: cursor, replacementRange: insertion)
        #expect(editor.hasMarkedText())
        #expect(query.isEmpty)
        #expect(!delegate.control(field, textView: editor,
                                  doCommandBy: #selector(NSResponder.insertNewline(_:))))
        #expect(selectedQueries.isEmpty)
        editor.insertText("한", replacementRange: insertion)
        #expect(query == "한")
        #expect(!editor.hasMarkedText())
        editor.doCommand(by: #selector(NSResponder.moveDown(_:)))
        editor.doCommand(by: #selector(NSResponder.insertNewline(_:)))
        #expect(selectedQueries == ["한", "한"])
    }
}

private actor ThreadSearchRepository:
    CommunityThreadRepository, ThreadConversationRepository, ThreadManagementRepository
{
    var selected = ""
    let row = CommunityThread(id: "42", title: "한글 결과", description: nil, icon: "💬",
                              isPinned: false, isMuted: false, isJoined: false,
                              membershipState: nil, unread: "0")

    func thread(id: String) async throws -> CommunityThread {
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
