//  NoticeAccessStateTests.swift
//  NoticePresentationTests
//
//  Created by euijjang97 on 11/23/26.

import Foundation
import NoticeDomain
import Testing

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
