//  DeskSummaryTests.swift
//  HomePresentationTests
//
//  Created by euijjang97 on 11/25/26.
//

import Foundation
import HomeDomain
import Testing

@testable import HomePresentation

@Test @MainActor func promotesOnlyConfirmedItemsAfterAnEmptySchedule() {
    let model = HomeViewModel(DeskFixture())
    model.project = .loaded("프로젝트")
    model.notice = .loaded("공지")
    #expect(model.focus == .schedule)
    model.schedule = .failed(URLError(.badServerResponse))
    #expect(model.focus == .schedule)
    model.schedule = .loaded(nil)
    #expect(model.focus == .project)
    model.project = .loading
    #expect(model.focus == .schedule)
    model.project = .failed(URLError(.badServerResponse))
    #expect(model.focus == .schedule)
    model.project = .loaded(nil)
    #expect(model.focus == .notice)
    model.notice = .loaded(nil)
    #expect(model.focus == .empty)
}

@Test func layoutUsesTheAvailableContentWidth() {
    #expect(DeskCardLayout.Arrangement(width: 619) == .stack)
    #expect(DeskCardLayout.Arrangement(width: 620) == .rows)
    #expect(DeskCardLayout.Arrangement(width: 959) == .rows)
    #expect(DeskCardLayout.Arrangement(width: 960) == .columns)
}

@Test @MainActor func readyScheduleAppearsWhileNoticeRefreshIsPending() async throws {
    let fixture = DeskFixture()
    let model = HomeViewModel(fixture)
    model.notice = .loaded("이전 공지")
    let task = Task { await model.load() }
    let deadline = ContinuousClock.now + .seconds(2)
    while ContinuousClock.now < deadline {
        if case .loaded(.some) = model.schedule { break }
        try await Task.sleep(for: .milliseconds(10))
    }
    if case .loaded(let schedule?) = model.schedule { #expect(schedule.name == "일정") }
    else { Issue.record("먼저 받은 일정은 공지 응답 전에 표시되어야 합니다.") }
    if case .loaded(let title) = model.notice { #expect(title == "이전 공지") }
    else { Issue.record("다시 불러오는 동안 읽던 공지가 유지되어야 합니다.") }
    await fixture.releaseNotice()
    await task.value
    if case .loaded(let title) = model.notice { #expect(title == "새 공지") }
    else { Issue.record("공지 응답이 도착하면 교체되어야 합니다.") }
}

private actor DeskFixture: HomeRepository {
    private var released = false
    private var waiter: CheckedContinuation<Void, Never>?

    func profile() async throws -> HomeProfile { HomeProfile(id: "1", nickname: "회원") }
    func schedule() async throws -> HomeSchedule? { HomeSchedule(name: "일정", startsAt: .now) }
    func project() async throws -> String? { nil }
    func notice() async throws -> String? {
        if !released { await withCheckedContinuation { waiter = $0 } }
        return "새 공지"
    }
    func releaseNotice() {
        released = true
        waiter?.resume()
        waiter = nil
    }
}
