//  NoticeAccessStateTests.swift
//  NoticePresentationTests
//
//  Created by euijjang97 on 11/23/26.

import CoreUIComponents
import SwiftUI
import NoticeDomain
import Testing
import UMCFoundation

@testable import NoticePresentation

@MainActor
struct NoticeAccessStateTests {
    @Test func revokeWhileReadingNames() throws {
        let state = NoticeAccessState()
        let json = """
            {"id":"1","title":"합성 공지","content":"본문","mustRead":false,
            "viewCount":"1","createdAt":"2026-11-23T00:00:00Z"}
            """
        state.entry = try JSONDecoder().decode(NoticeEntry.self, from: Data(json.utf8))
        state.permissions = ["READ", "CHECK", "DELETE", "EDIT"]
        state.showReaders = true
        state.editSheet = true
        state.deletePrompt = true
        state.photo = .init(id: "1", url: "https://example.test/photo")
        state.selection = ["2"]
        state.rows = [.init(challengerId: "3", name: "합성 독자", schoolName: nil)]
        state.counts = .init(totalCount: "3", readCount: "2", unreadCount: "1")
        state.targets = ["3"]
        state.cursor = "3"
        state.confirmReminder = true
        let pending = state.requestID
        try state.applyPermissions(["READ"])
        #expect(state.entry != nil && state.permissions == ["READ"])
        #expect(!state.showReaders && !state.editSheet && !state.deletePrompt)
        #expect(state.rows.isEmpty && state.counts == nil && state.targets.isEmpty)
        #expect(state.cursor == nil && !state.confirmReminder && state.requestID != pending)
        #expect(throws: NoticeRequestFailure.accessDenied) { try state.applyPermissions([]) }
        #expect(state.entry == nil && state.photo == nil && state.permissions.isEmpty)
        #expect(state.selection.isEmpty)
    }
}

struct NoticeLetterRunnerTests {
    @Test func handlesOnlyTransportAndServerOutages() {
        for error in [URLError(.cannotConnectToHost), URLError(.notConnectedToInternet)] {
            #expect(NoticeConnectionFailure.matches(error))
        }
        #expect(NoticeConnectionFailure.matches(NetworkError.requestFailed(statusCode: 503, data: nil)))
        #expect(!NoticeConnectionFailure.matches(NetworkError.unauthorized))
        #expect(!NoticeConnectionFailure.matches(NoticeRequestFailure.accessDenied))
        #expect(!NoticeConnectionFailure.matches(NoticeRequestFailure.rejected("validation")))
        #expect(!NoticeConnectionFailure.matches(URLError(.cancelled)))
    }

    @Test func obstacleScoreCollisionAndReplay() {
        var round = LetterRun()
        round.jump()
        for _ in 0..<120 {
            if round.height == 0 && (80...100).contains(round.obstacle) { round.jump() }
            round.step()
        }
        #expect(round.score == 1)
        for _ in 0..<120 { round.step() }
        #expect(round.phase == .finished)
        round.jump()
        #expect(round.phase == .running && round.score == 0)
    }
}

@MainActor
struct NoticeRunnerFocusTests {
    @Test func nativeActionAndReturnRepeat() throws {
        var activations = 0
        let host = NSHostingView(rootView: UMCFocusableButton(
            "편지 배달", accessibilityValue: "1점", action: { activations += 1 }
        ) { _ in Text("편지 배달") })
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 80),
            styleMask: [.titled], backing: .buffered, defer: false)
        window.contentView = host
        defer { window.contentView = nil }
        host.layoutSubtreeIfNeeded()
        let button = try #require(nativeButton(in: host))
        #expect(button.canBecomeKeyView)
        #expect(button.accessibilityLabel() == "편지 배달")
        #expect(button.accessibilityValue() as? String == "1점")
        #expect(button.accessibilityPerformPress())
        #expect(activations == 1)
        #expect(window.firstResponder === button)
        for repeated in [false, true, true] {
            let event = try #require(NSEvent.keyEvent(
                with: .keyDown, location: .zero, modifierFlags: [], timestamp: 0,
                windowNumber: window.windowNumber, context: nil, characters: "\r",
                charactersIgnoringModifiers: "\r", isARepeat: repeated, keyCode: 36))
            button.keyDown(with: event)
        }
        #expect(activations == 2)
    }

    private func nativeButton(in view: NSView) -> NSButton? {
        if let button = view as? NSButton { return button }
        return view.subviews.lazy.compactMap { self.nativeButton(in: $0) }.first
    }
}
