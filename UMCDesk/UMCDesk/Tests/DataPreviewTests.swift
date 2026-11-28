//
//  DataPreviewTests.swift
//  UMCDeskTests
//
//  Created by euijjang97 on 11/25/26.
//

import AppKit
import Foundation
import ProjectWorkspaceDomain
import Testing
@testable import UMCDesk

@MainActor
struct DataPreviewTests {
    @Test func previewMenusShowTabToolsInBothDataModes() async throws {
        func menu(_ root: NSMenu, named names: [String]) -> NSMenu? {
            for item in root.items {
                guard let submenu = item.submenu else { continue }
                if names.contains(item.title) { return submenu }
                if let nested = menu(submenu, named: names) { return nested }
            }
            return nil
        }

        func press(_ menu: NSMenu, named names: [String]) throws {
            menu.update()
            let index = try #require(menu.items.firstIndex { names.contains($0.title) },
                                     "Menu items: \(menu.items.map(\.title))")
            menu.performActionForItem(at: index)
        }

        func trigger(in view: NSView) -> NSButton? {
            if let button = view as? NSButton,
               button.accessibilityIdentifier() == "sidebar.right" { return button }
            return view.subviews.lazy.compactMap { trigger(in: $0) }.first
        }

        let mainMenu = try #require(NSApp.mainMenu)
        let preview = try #require(menu(mainMenu, named: ["데이터 미리보기", "Data Preview"]))
        defer {
            if let end = preview.items.firstIndex(where: { ["미리보기 종료", "End Preview"].contains($0.title) }) {
                preview.performActionForItem(at: end)
            }
        }

        for empty in [false, true] {
            try press(preview, named: empty ? ["전체 빈 화면", "All Empty Screens"] :
                      ["전체 데이터 있음", "All With Data"])
            try await Task.sleep(for: .milliseconds(350))
            let tabs = try #require(menu(mainMenu, named: ["탭 이동", "Go to Tab", "Switch Tab"]))
            for (tab, english) in [("공지", "Notice"), ("스레드", "Threads")] {
                try press(tabs, named: [tab, english, english + "s"])
                try await Task.sleep(for: .milliseconds(400))
                let window = try #require(NSApp.windows.first { $0.contentView?.superview.flatMap(trigger(in:)) != nil },
                                          "Windows: \(NSApp.windows.map { ($0.title, $0.identifier?.rawValue) })")
                let content = try #require(window.contentView)
                let frame = try #require(content.superview)
                let button = try #require(trigger(in: frame))
                #expect(!button.isBordered)
                #expect(button.image != nil)
                #expect(button.state == .off)
                button.performClick(nil)
                try await Task.sleep(for: .milliseconds(200))
                #expect(button.state == .on)
                let bitmap = try #require(content.bitmapImageRepForCachingDisplay(in: content.bounds))
                content.cacheDisplay(in: content.bounds, to: bitmap)
                let png = try #require(bitmap.representation(using: .png, properties: [:]))
                let file = "umc-preview-\(english)-\(empty ? "empty" : "populated").png"
                try png.write(to: URL(fileURLWithPath: NSTemporaryDirectory()).appending(path: file))
                print("Captured", NSTemporaryDirectory() + file)
                button.performClick(nil)
                try await Task.sleep(for: .milliseconds(120))
                #expect(button.state == .off)
            }
        }
    }

    @Test func matchingCommandsReplaceTheDisplayedPageEvenFromTheSameTab() {
        let preview = DataPreviewMode()
        preview.select(.matching)
        guard let workspace = preview.session else { Issue.record("미리보기 세션 누락"); return }
        let previousID = workspace.matchingNavigationID
        workspace.openMatching(.applications)
        #expect(workspace.destination == .matching)
        #expect(workspace.matchingPage == .applications)
        #expect(workspace.matchingNavigationID != previousID)
        preview.select(.matching)
        #expect(workspace.matchingPage == .explore)
    }

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
        try await account.notices.vote(options: ["1"], replacing: false, id: "21")
        #expect(try await account.notices.detail(id: "21").vote?.mySelectedOptionIds == ["1"])
        #expect(try await account.activity.schedules().count == 3)
        #expect(try await account.activity.groups().count == 2)
        #expect(try await account.activity.study().count == 4)
        #expect(try await account.activity.reviews().first?.mayDecide == true)
        try await account.activity.decide(scheduleID: "801", memberID: "105", approve: true)
        #expect(try await account.activity.reviews().first?.participants.first?.status == "PRESENT")
        _ = try await account.activity.attend(scheduleID: "801", reason: nil, coordinate: nil)
        #expect(try await account.activity.schedules().first { $0.id == "801" }?.status == "PRESENT_PENDING")
        #expect(try await account.activity.directory(keyword: "", part: nil, page: 0).members.count == 5)
        #expect(try await account.projects().map(\.name) == ["모아", "사이"])
        #expect(try await account.posts.posts(scope: .all, category: nil, keyword: "",
                                               page: "0").values.count == 5)
        #expect(try await account.posts.comments(id: "31").count == 1)
        #expect(try await account.threads.threads(query: "", filter: "all", offset: nil).values.count == 4)
        #expect(try await session.conversations.members(thread: "41", query: "").count == 3)
        await session.progress.refreshOnce()
        #expect(session.progress.card?.status == "APPROVED")
        let roster = try await session.matching.publishedTeam(projectId: "3")
        #expect(roster?.partGroups.flatMap(\.members).contains { $0.memberId == account.memberID } == true)
        #expect(try await session.documents.terms().count == 2)
        let ticket = try #require(session.support.create(subject: "확인 요청", content: "문의 내용", team: .product))
        #expect(session.support.myTickets.contains { $0.id == ticket })
        #expect(session.support.tickets.contains { !$0.belongsToCurrentUser })
    }

    @Test func emptyWorkspaceLoadsFeatureListsAndCanCreateContent() async throws {
        let session = DataPreviewSession(isEmpty: true)
        let account = session.account
        #expect(try await account.home.profile().id == account.memberID)
        #expect(try await account.home.schedule() == nil)
        #expect(try await account.home.notice() == nil)
        #expect(try await account.home.project() == nil)
        let notices = try await account.notices.notices(
            gisu: "10", tab: "CHALLENGER", keyword: "", part: nil, page: 0)
        #expect(notices.content.isEmpty)
        #expect(try await account.activity.schedules().isEmpty)
        #expect(try await account.activity.groups().isEmpty)
        #expect(try await account.activity.study().isEmpty)
        #expect(try await account.activity.reviews().isEmpty)
        #expect(try await account.activity.directory(keyword: "", part: nil, page: 0).members.isEmpty)
        #expect(try await account.projects().isEmpty)
        let board = account.posts
        #expect(try await board.posts(scope: .all, category: nil, keyword: "", page: "0").values.isEmpty)
        let threads = account.threads
        #expect(try await threads.threads(query: "", filter: "all", offset: nil).values.isEmpty)

        let post = try await board.save(id: nil, title: "첫 글", content: "안녕하세요",
                                        category: .free, meeting: nil)
        let posts = try await board.posts(scope: .all, category: nil, keyword: "", page: "0")
        #expect(posts.values.map(\.id) == [post.id])
        let room = try await threads.create(title: "첫 스터디", description: "일정 공유",
                                            category: "STUDY", icon: "📚")
        let rooms = try await threads.threads(query: "", filter: "all", offset: nil)
        #expect(rooms.values.map(\.id) == [room.id])
        #expect(try await session.conversations.history(thread: room.id, before: nil).values.isEmpty)
    }

    @Test func sampleProjectsAndThreadsHaveTheirOwnHistory() async throws {
        let session = DataPreviewSession()
        var tasks = Set<String>()
        var recentChanges = Set<String>()
        for project in try await session.account.projects() {
            let key = WorkspaceRecord.key(accountID: session.account.memberID, projectID: project.id)
            let data = try #require(session.defaults.data(forKey: key))
            let record = try JSONDecoder().decode(WorkspaceRecord.self, from: data)
            let repo = try #require(record.link(for: .github))
            #expect(record.githubItems == DataPreviewAccount.recentWork(repository: repo))
            tasks.insert(try #require(record.todos.first?.title))
            recentChanges.insert(try #require(record.githubItems?.first?.title))
        }
        #expect(tasks.count == 2)
        #expect(recentChanges.count == 2)
        let rooms = try await session.account.threads.threads(query: "", filter: "all", offset: nil)
        var messages = Set<String>()
        for room in rooms.values {
            let history = try await session.conversations.history(thread: room.id, before: nil)
            #expect(Set(history.values.compactMap(\.authorID)).count >= 2)
            messages.insert(try #require(history.values.first?.text))
        }
        #expect(messages.count == rooms.values.count)
    }

    @Test func editsAreVisibleOnlyInTheCurrentWorkspace() async throws {
        let session = DataPreviewSession()
        let board = session.account.posts
        let created = try await board.save(id: nil, title: "이번 주 회고", content: "리뷰를 마쳤어요.",
                                           category: .free, meeting: nil)
        let detail = try await board.post(id: created.id)
        #expect(detail.title == "이번 주 회고")
        #expect(detail.likeCount == "0")
        let writtenAt = try Date.ISO8601FormatStyle().parse(try #require(detail.date))
        #expect(abs(writtenAt.timeIntervalSinceNow) < 60)
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
