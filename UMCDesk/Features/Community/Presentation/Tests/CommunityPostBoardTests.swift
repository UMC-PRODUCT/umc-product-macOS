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

    private func firstField(_ root: NSView) -> NSTextField? {
        if let field = root as? NSTextField, field.isEditable { return field }
        return root.subviews.lazy.compactMap { firstField($0) }.first
    }
}

private actor BoardFixture: CommunityPostRepository {
    var opened: String?
    let item = CommunityPost(
        id: "15", title: "한글 검색", content: "본문", category: "FREE",
        authorMemberID: "102", author: "합성 작성자", date: nil, commentCount: "0",
        likeCount: "0", liked: false, scrapCount: nil, scrapped: false, meeting: nil)
    func posts(
        scope: CommunityPostScope, category: CommunityPostCategory?, keyword: String,
        page: String
    ) async throws -> CommunityPostPage {
        .init(values: keyword == "한글" ? [item] : [], cursor: nil)
    }
    func post(id: String) async throws -> CommunityPost {
        opened = id
        return item
    }
    func comments(id: String) async throws -> [CommunityPostComment] { [] }
    func save(
        id: String?, title: String, content: String, category: CommunityPostCategory,
        meeting: CommunityPostMeeting?
    ) async throws -> CommunityPost { throw CancellationError() }
    func perform(_ action: CommunityPostAction, id: String) async throws -> Bool? { nil }
}
