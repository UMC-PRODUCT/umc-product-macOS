//
//  DataPreviewTests.swift
//  UMCDeskTests
//
//  Created by euijjang97 on 11/25/26.
//

import Foundation
import Testing
@testable import UMCDesk

@MainActor
struct DataPreviewTests {
    @Test func featureListsAndDetailsUseLocalTransport() async throws {
        let session = DataPreviewSession()
        let account = session.account
        #expect(try await account.home.profile().id == account.memberID)
        #expect(try await account.home.schedule() != nil)
        #expect(try await account.home.notice() != nil)
        #expect(try await account.home.project() != nil)
        let notices = try await account.notices.notices(gisu: "10", tab: "CHALLENGER",
            keyword: "", part: nil, page: 0)
        #expect(!notices.content.isEmpty)
        #expect(try await account.notices.detail(id: "21").id == "21")
        #expect(try await account.notices.readCounts(id: "21").readCount == "2")
        #expect(try await account.activity.schedules().count == 3)
        #expect(try await account.activity.groups().count == 2)
        #expect(try await account.activity.study().count == 4)
        #expect(try await account.activity.reviews().first?.mayDecide == true)
        #expect(try await account.activity.directory(keyword: "", part: nil, page: 0).members.count == 5)
        #expect(try await account.projects().map(\.name) == ["모아", "사이"])
        #expect(try await account.posts.posts(scope: .all, category: nil, keyword: "",
                                               page: "0").values.count == 5)
        #expect(try await account.posts.comments(id: "31").count == 1)
        #expect(try await account.threads.threads(query: "", filter: "all", offset: nil).values.count == 4)
        #expect(try await session.conversations.members(thread: "41", query: "").count == 3)
        await session.progress.refreshOnce()
        #expect(session.progress.card?.status == "APPROVED")
        #expect(session.support.tickets.count > 0)
    }

    @Test func editsAreVisibleOnlyInTheCurrentWorkspace() async throws {
        let session = DataPreviewSession()
        let board = session.account.posts
        let created = try await board.save(id: nil, title: "이번 주 회고", content: "리뷰를 마쳤어요.",
                                           category: .free, meeting: nil)
        #expect(try await board.post(id: created.id).title == "이번 주 회고")
        #expect(try await board.perform(.like, id: created.id) == true)
        #expect(try await board.post(id: created.id).liked)
        _ = try await board.perform(.comment("수고했어요", parentID: nil), id: created.id)
        #expect(try await board.comments(id: created.id).first?.content == "수고했어요")
        let threads = session.account.threads
        let room = try await threads.create(title: "새 스터디", description: "같이 공부해요",
                                            category: "STUDY", icon: "📚")
        #expect(try await threads.update(.pin, enabled: true, id: room.id).isPinned)
        let fresh = DataPreviewSession()
        #expect(try await fresh.account.threads.threads(query: "새 스터디", filter: "all",
                                                        offset: nil).values.isEmpty)
    }

    @Test func previewSessionsKeepAccountAndChangesSeparate() async throws {
        let first = DataPreviewSession()
        first.select(.profile)
        let profile = try #require(first.settings.profile)
        #expect(profile.id == first.account.memberID)
        #expect(Set(profile.activities.flatMap(\.roles)).count == 12)
        #expect(Set(profile.activities.map(\.part)).count == 10)
        #expect(Set(profile.activities.map(\.generation)).count > 1)
        let second = DataPreviewSession()
        first.defaults.set("only-first", forKey: "local-preview-marker")
        #expect(second.defaults.string(forKey: "local-preview-marker") == nil)
        let history = first.conversations
        let initial = try await history.history(thread: "41", before: nil)
        let message = try #require(initial.values.first { !$0.reactions.isEmpty })
        try await history.perform(.react(message: message.id, emoji: "👍", adding: true), thread: "41")
        try await history.perform(.create(key: "12345", content: "팀 회고", files: [],
                                          reply: message.id), thread: "41")
        let changed = try await history.history(thread: "41", before: nil)
        #expect(changed.values.first?.text == "팀 회고")
        #expect(changed.values.first { $0.id == message.id }?.reactions.first?.count == "3")
        let other = try await second.conversations.history(thread: "41", before: nil)
        #expect(initial.values == other.values)
    }
}
