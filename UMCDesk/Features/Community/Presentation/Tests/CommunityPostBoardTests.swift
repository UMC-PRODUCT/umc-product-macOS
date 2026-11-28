//
//  CommunityPostBoardTests.swift
//  CommunityPresentationTests
//
//  Created by euijjang97 on 11/23/26.
//

import AppKit
import CommunityDomain
import SwiftUI
import Testing

@testable import CommunityPresentation

@MainActor
struct CommunityPostBoardTests {
    @Test(arguments: [ColorScheme.light, .dark])
    func keyboardSearchAndSelectionInBothAppearances(_ scheme: ColorScheme) async throws {
        let repository = BoardFixture()
        let board = CommunityPostBoardView(accountID: "101", repository: repository)
            .environment(\.colorScheme, scheme)
        let host = NSHostingView(rootView: board.frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity))
        let window = NSWindow(
            contentRect: .init(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled], backing: .buffered, defer: false)
        window.appearance = NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
        window.contentView = host
        defer { window.contentView = nil }
        host.layoutSubtreeIfNeeded()
        let field = try #require(firstField(host))
        #expect(field.accessibilityLabel() == "게시글 검색" || field.placeholderString == "제목·본문 검색")
        let ypos = field.convert(field.bounds,to:host).midY
        let fromTop = host.isFlipped ? ypos : host.bounds.height - ypos
        #expect(fromTop < 120)
        let bitmap = try #require(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        let fill = try #require(
            bitmap.colorAt(x: bitmap.pixelsWide - 16, y: 16)?
                .usingColorSpace(.sRGB))
        #expect(scheme == .light ? fill.redComponent > 0.7 : fill.redComponent < 0.4)
        #expect(window.makeFirstResponder(field))
        let editor = try #require(field.currentEditor() as? NSTextView)
        let cursor = NSRange(location: 1, length: 0)
        let insertion = NSRange(location: NSNotFound, length: 0)
        editor.setMarkedText("ㅎ", selectedRange: cursor, replacementRange: insertion)
        #expect(editor.hasMarkedText())
        editor.insertText("한글", replacementRange: insertion)
        editor.doCommand(by: #selector(NSResponder.insertNewline(_:)))
        let deadline = ContinuousClock.now + .seconds(4)
        while await repository.opened == nil, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(20))
            host.layoutSubtreeIfNeeded()
        }
        #expect(await repository.opened == "15")
        #expect(window.firstResponder !== editor)
        #expect(host.bounds.width == 800)
    }

    @Test(arguments: [1040, 1504])
    func headersAndSelectionStayVisibleInToolbarWindow(_ width: Int) async throws {
        let repository = BoardFixture()
        let board = CommunityPostBoardView(accountID: "101", repository: repository)
        let shell = HStack(spacing: 0) {
            Color.gray.frame(width: 48)
            board.clipShape(.rect(cornerRadius: 16))
        }.padding([.trailing, .bottom], 12)
        let host = NSHostingView(rootView: shell)
        let window = NSWindow(
            contentRect: .init(x: 0, y: 0, width: width, height: width == 1040 ? 752 : 831),
            styleMask: [.titled, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
        window.toolbar = NSToolbar()
        window.toolbarStyle = .unifiedCompact
        window.titleVisibility = .hidden
        window.contentView = host
        defer { window.contentView = nil }
        try await waitUntil(in: host) {
            descendants(host).compactMap { $0 as? NSTableView }.first?.numberOfRows == 50
        }

        let table = try #require(descendants(host).compactMap { $0 as? NSTableView }.first)
        let field = try #require(firstField(host))
        let listScroll = try #require(table.enclosingScrollView)
        #expect(table.numberOfRows == 50)
        let split = try #require(descendants(host).compactMap { $0 as? NSSplitView }.first)
        let splitTop = split.convert(split.bounds, to: nil).maxY
        #expect(splitTop <= window.contentLayoutRect.maxY)
        let fieldFrame = field.convert(field.bounds, to: nil)
        // Reserve room for the complete title above the search field.
        #expect(window.contentLayoutRect.maxY - fieldFrame.maxY >= 40)
        table.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        try await waitUntil(in: host) { await repository.opened == "1" }
        table.scrollRowToVisible(35)
        table.selectRowIndexes(IndexSet(integer: 35), byExtendingSelection: false)
        try await waitUntil(in: host) {
            let scrolls = descendants(host).compactMap { $0 as? NSScrollView }
            return await repository.opened == "36" && scrolls.contains {
                $0 !== listScroll && ($0.documentView?.frame.height ?? 0) > $0.frame.height
            }
        }
        let offset = listScroll.contentView.bounds.minY
        #expect(offset > 0)
        let detailScroll = try #require(descendants(host).compactMap { $0 as? NSScrollView }
            .first { $0 !== listScroll && ($0.documentView?.frame.height ?? 0) > $0.frame.height })
        let detailTop = detailScroll.convert(detailScroll.bounds, to: nil).maxY
        #expect(window.contentLayoutRect.maxY - detailTop >= 40)
        let headerRect = detailScroll.convert(detailScroll.bounds, to: nil)
        let sample = host.convert(NSRect(
            x: headerRect.minX + 72, y: headerRect.maxY, width: 120, height: 28), from: nil)
        let before = try headerPixels(in: sample, host: host)
        let clip = detailScroll.contentView
        let end = max(0, (detailScroll.documentView?.frame.height ?? 0) - clip.bounds.height)
        clip.scroll(to: NSPoint(x: 0, y: end))
        detailScroll.reflectScrolledClipView(clip)
        try await waitUntil(in: host) { (try? headerPixels(in: sample, host: host)) != before }
        #expect(detailScroll.convert(detailScroll.bounds, to: nil).maxY == detailTop)
        clip.scroll(to: .zero)
        detailScroll.reflectScrolledClipView(clip)
        try await waitUntil(in: host) { (try? headerPixels(in: sample, host: host)) == before }
        #expect(listScroll.contentView.bounds.minY == offset)
        #expect(window.makeFirstResponder(table))
        let down = String(UnicodeScalar(NSDownArrowFunctionKey)!)
        let event = try #require(NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: [.function, .numericPad],
            timestamp: 0, windowNumber: window.windowNumber, context: nil,
            characters: down, charactersIgnoringModifiers: down, isARepeat: false, keyCode: 125))
        table.keyDown(with: event)
        try await waitUntil(in: host) { await repository.opened == "37" }
        #expect(listScroll.contentView.bounds.minY > 0)
    }

    private func headerPixels(in rect: NSRect, host: NSView) throws -> Data {
        let bitmap = try #require(host.bitmapImageRepForCachingDisplay(in: rect))
        host.cacheDisplay(in: rect, to: bitmap)
        return try #require(bitmap.representation(using: .png, properties: [:]))
    }

    private func waitUntil(in host: NSView, condition: () async -> Bool) async throws {
        let deadline = ContinuousClock.now + .seconds(5)
        while ContinuousClock.now < deadline {
            host.layoutSubtreeIfNeeded()
            if await condition() { return }
            try await Task.sleep(for: .milliseconds(20))
        }
        try #require(await condition())
    }

    private func descendants(_ view: NSView) -> [NSView] {
        [view] + view.subviews.flatMap(descendants)
    }

    private func firstField(_ root: NSView) -> NSTextField? {
        if let field = root as? NSTextField, field.isEditable { return field }
        return root.subviews.lazy.compactMap { firstField($0) }.first
    }
}

private actor BoardFixture: CommunityPostRepository {
    nonisolated func pendingWrite(postID: String?) throws -> CommunityPostIntent? { nil }
    nonisolated func discard(_ intent: CommunityPostIntent) throws {}
    func check(_ intent: CommunityPostIntent) async throws -> String { "" }
    var opened: String?
    let item = CommunityPost(
        id: "15", title: "한글 검색", content: "본문", category: "FREE",
        authorMemberID: "102", author: "합성 작성자", date: nil, commentCount: "0",
        likeCount: "0", liked: false, scrapCount: nil, scrapped: false, meeting: nil)
    func posts(
        scope: CommunityPostScope, category: CommunityPostCategory?, keyword: String,
        page: String
    ) async throws -> CommunityPostPage {
        if keyword.isEmpty {
            return .init(values: (1...50).map { sample(String($0)) }, cursor: nil)
        }
        return .init(values: keyword == "한글" ? [item] : [], cursor: nil)
    }
    func post(id: String) async throws -> CommunityPost {
        opened = id
        return id == item.id ? item : sample(id)
    }
    private func sample(_ id: String) -> CommunityPost {
        .init(id: id, title: "게시글 " + id, content: String(repeating: "긴 본문\n", count: 80),
              category: "FREE", authorMemberID: "101", author: "합성 회원", date: nil,
              commentCount: "0", likeCount: "0", liked: false, scrapCount: nil,
              scrapped: false, meeting: nil)
    }
    func comments(id: String) async throws -> [CommunityPostComment] {
        (1...80).map {
            .init(id: String($0), author: "합성 회원", content: "댓글 " + String($0),
                  isAuthor: false, date: nil)
        }
    }
    func save(
        id: String?, title: String, content: String, category: CommunityPostCategory,
        meeting: CommunityPostMeeting?
    ) async throws -> CommunityPost { throw CancellationError() }
    func perform(_ action: CommunityPostAction, id: String) async throws -> Bool? { nil }
}
