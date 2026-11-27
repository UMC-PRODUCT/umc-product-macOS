//  ReviewAccessTests.swift
//  ActivityPresentationTests
//
//  Created by euijjang97 on 11/23/26.
//

import ActivityDomain
import Foundation
import Testing
import UMCFoundation

@testable import ActivityPresentation

private actor ReviewRepository: ActivityRepository {
    var allowed = true
    var denyList = false
    var denyDecision = false
    var delayed = false
    var continuation: CheckedContinuation<Void, Never>?
    var started: CheckedContinuation<Void, Never>?
    var writes = 0

    func configure(allowed: Bool, denyList: Bool = false, delayed: Bool = false) {
        self.allowed = allowed
        self.denyList = denyList
        self.delayed = delayed
    }

    func waitForList() async {
        if continuation == nil { await withCheckedContinuation { started = $0 } }
    }

    func release() {
        continuation?.resume()
        continuation = nil
    }
    func canReadReviews() async throws -> Bool { allowed }
    func capabilities() async throws -> ScheduleCapabilities {
        ScheduleCapabilities(canCreate: false, canTrack: false, participantLimit: "0")
    }
    func reviews() async throws -> [AttendanceReview] {
        if denyList { throw NetworkError.requestFailed(statusCode: 403, data: nil) }
        if delayed {
            await withCheckedContinuation {
                continuation = $0
                started?.resume()
                started = nil
            }
        }
        return [
            AttendanceReview(
                id: "701", name: "합성 일정", mayDecide: true,
                participants: [
                    AttendanceRequestRow(
                        id: "101", name: "회원", status: "EXCUSED_PENDING", reason: "합성 사유")
                ])
        ]
    }
    func denyNextDecision() { denyDecision = true }
    func decide(scheduleID: String, memberID: String, approve: Bool) async throws {
        writes += 1
        if denyDecision { throw NetworkError.requestFailed(statusCode: 403, data: nil) }
    }

    func directory(keyword: String, part: String?, page: Int) async throws -> ActivityMemberPage {
        throw URLError(.unsupportedURL)
    }
    func searchMembers(keyword: String) async throws -> [ActivityRow] {
        throw URLError(.unsupportedURL)
    }
    func createSchedule(_ draft: ScheduleDraft) async throws { throw URLError(.unsupportedURL) }
    func schedules() async throws -> [ActivitySchedule] { throw URLError(.unsupportedURL) }
    func attend(scheduleID: String, reason: String?, coordinate: ActivityCoordinate?) async throws
        -> String
    { throw URLError(.unsupportedURL) }
    func study() async throws -> [ActivityRow] { throw URLError(.unsupportedURL) }
    func studyTools(groupID: String?) async throws -> StudyTools {
        throw URLError(.unsupportedURL)
    }
    func saveGroup(id: String?, name: String, mentors: [String], members: [String]) async throws {
        throw URLError(.unsupportedURL)
    }
    func assign(groupID: String, memberID: String, mentor: Bool) async throws {
        throw URLError(.unsupportedURL)
    }
    func link(groupID: String, scheduleID: String, weekID: String) async throws {
        throw URLError(.unsupportedURL)
    }
    func memberProfile(id: String) async throws -> ActivityMemberProfile {
        throw URLError(.unsupportedURL)
    }
    func canGrantPoints(challengerID: String) async throws -> Bool {
        throw URLError(.unsupportedURL)
    }
    nonisolated func pendingGrant(challengerID: String) throws -> PointGrantIntent? { nil }
    nonisolated func finishManualReview(operationID: UUID) throws {}
    func grantPoints(operationID: UUID, challengerID: String, value: Int, reason: String)
        async throws -> PointGrantResult
    { throw URLError(.unsupportedURL) }
    func groups() async throws -> [ActivityRow] { throw URLError(.unsupportedURL) }
    func members(groupID: String) async throws -> [ActivityRow] { throw URLError(.unsupportedURL) }
}

@MainActor
@Test(arguments: [true, false])
func revokedReviewClearsDataAndConfirmation(permissionChanged: Bool) async {
    let repository = ReviewRepository()
    let model = ActivityViewModel(repository)
    await model.permissions()
    model.tab = .management
    await model.load(.management)
    let selection = ReviewDecision(schedule: "701", member: "101", name: "회원", approve: true)
    #expect(model.canDecide(selection))
    model.decision = selection
    if permissionChanged {
        await repository.configure(allowed: true, delayed: true)
        let late = Task { await model.load(.management) }
        await repository.waitForList()
        await repository.configure(allowed: false)
        await model.permissions()
        await repository.release()
        await late.value
    } else {
        await repository.configure(allowed: true, denyList: true)
        await model.load(.management)
    }
    #expect(model.tab == .attendance)
    #expect(!model.canReview)
    #expect(model.decision == nil)
    if case .idle = model.reviews {} else { Issue.record("회수된 출석 목록이 남아 있습니다") }
    await model.decide(selection)
    #expect(await repository.writes == 0)
}

@MainActor
@Test func displayFeedbackDistinguishesFailureWithoutInspectingMessage() async {
    let repository = ReviewRepository()
    let model = ActivityViewModel(repository)
    var attempts = 0
    let saved = await model.perform(
        {
            attempts += 1
            throw URLError(.timedOut)
        }, reload: .attendance, scope: .attendance("701"))
    #expect(!saved)
    #expect(model.feedbackFailed)
    await model.load(.attendance)
    #expect(attempts == 1)
    let accepted = await model.perform(
        { "실패라는 단어가 있는 성공 메시지" }, reload: .attendance, scope: .attendance("701"))
    #expect(accepted)
    #expect(!model.feedbackFailed)
}

@MainActor
@Test func attendanceAndReviewFeedbackDoNotCrossEvenAfterAccessRevocation() async {
    let repository = ReviewRepository()
    let model = ActivityViewModel(repository)
    _ = await model.perform({ "개인 출석 완료" }, reload: .attendance, scope: .attendance("701"))
    #expect(model.feedback(in: .attendance("701")) == "개인 출석 완료")
    #expect(model.feedback(in: .review("701")) == nil)
    #expect(model.feedback(in: .attendance("702")) == nil)
    await model.permissions()
    model.tab = .management
    await model.load(.management)
    await repository.denyNextDecision()
    await model.decide(ReviewDecision(schedule: "701", member: "101", name: "회원", approve: true))
    #expect(model.tab == .attendance)
    #expect(!model.canReview)
    #expect(model.feedbackFailed)
    #expect(model.feedback(in: .review("701")) != nil)
    #expect(model.feedback(in: .attendance("701")) == nil)
    #expect(await repository.writes == 1)
    _ = await model.perform(
        { throw URLError(.timedOut) }, reload: .attendance,
        scope: .scheduleCreation)
    #expect(model.feedback(in: .scheduleCreation) != nil)
    #expect(model.feedback(in: .attendance("701")) == nil)
    #expect(model.feedback(in: .review("701")) == nil)
}
