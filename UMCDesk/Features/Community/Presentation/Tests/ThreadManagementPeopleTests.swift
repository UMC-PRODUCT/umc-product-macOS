//
//  ThreadManagementPeopleTests.swift
//  CommunityPresentationTests
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import Foundation
import Testing
@testable import CommunityPresentation

@MainActor
struct ThreadManagementPeopleTests {
    @Test("일부 실패 결과를 보존하고 실패한 회원만 다시 내보낸다")
    func retryOnlyFailed() async {
        let repo = PeopleRepository(failures: ["3": 2])
        let model = ThreadManagementPeopleModel()
        let targets = Array(repo.people.suffix(2))
        model.toggleSelectionMode()
        for person in targets { model.selection[person.memberId] = person }
        #expect(await model.apply(.kick, targets: targets, repository: repo, threadID: "1"))
        #expect(model.showsFailure && !model.selecting && model.selection.isEmpty)
        #expect(model.succeeded.map(\.memberId) == ["2"])
        #expect(model.failed.map(\.memberId) == ["3"])
        #expect(model.completion == nil)
        #expect(await !model.retryFailures(repository: repo, threadID: "1"))
        #expect(model.showsFailure && model.succeeded.map(\.memberId) == ["2"])
        #expect(await model.retryFailures(repository: repo, threadID: "1"))
        #expect(!model.showsFailure && model.failed.isEmpty && !model.selecting)
        #expect(model.completion == "이기획님을 내보냈어요.")
        #expect(await repo.calls == ["2", "3", "3", "3"])
        await model.load(threadID: "1", mode: .members, query: "", offset: nil,
                         needsIdentity: true, repository: repo)
        #expect(model.rows.map(\.memberId) == ["1"])
    }

    @Test("첫 시도에서 전체 성공하면 선택을 종료하고 상단 완료 안내를 표시한다")
    func successExitsSelection() async {
        let repo = PeopleRepository()
        let model = ThreadManagementPeopleModel()
        model.toggleSelectionMode()
        #expect(await model.apply(.kick, targets: Array(repo.people.suffix(2)),
                                  repository: repo, threadID: "1"))
        #expect(!model.selecting && !model.showsFailure)
        #expect(model.completion == "2명을 내보냈어요.")
        model.toggleSelectionMode()
        #expect(model.completion == nil)
    }

    @Test("실패 시트를 닫으면 추가 요청을 보내지 않는다")
    func dismissFailure() async {
        let repo = PeopleRepository(failures: ["3": 1])
        let model = ThreadManagementPeopleModel()
        #expect(await !model.apply(.kick, targets: Array(repo.people.suffix(1)),
                                   repository: repo, threadID: "1"))
        model.showsFailure = false
        #expect(await !model.retryFailures(repository: repo, threadID: "1"))
        #expect(await repo.calls == ["3"])
    }
}

private actor PeopleRepository: ThreadManagementRepository {
    nonisolated let people = [
        ThreadManagementPerson(memberId: "1", name: "김유엠", part: "PLAN",
                               generation: "10", role: .owner, state: "ACTIVE"),
        ThreadManagementPerson(memberId: "2", name: "김개발", part: "IOS",
                               generation: "10", role: .member, state: "ACTIVE"),
        ThreadManagementPerson(memberId: "3", name: "이기획", part: "PLAN",
                               generation: "10", role: .member, state: "ACTIVE")
    ]
    private(set) var calls: [String] = []
    private var failures: [String: Int]
    private var removed: Set<String> = []

    init(failures: [String: Int] = [:]) { self.failures = failures }

    func apply(_ action: ThreadManagementAction, threadID: String) async throws {
        guard case .kick(let memberID) = action else { throw URLError(.unsupportedURL) }
        calls.append(memberID)
        if let count = failures[memberID], count > 0 {
            failures[memberID] = count - 1
            throw URLError(.timedOut)
        }
        removed.insert(memberID)
    }

    func people(threadID: String, invitable: Bool, query: String, offset: String?)
        async throws -> ThreadManagementPage {
        let rows = people.filter { !removed.contains($0.memberId) }
        return .init(items: rows, nextOffset: nil, total: String(rows.count))
    }

    func currentMemberID() async throws -> String { "1" }

    func detail(threadID: String) async throws -> ThreadManagementDetail {
        throw URLError(.unsupportedURL)
    }

    func profile(memberID: String) async throws -> ThreadManagementProfile {
        throw URLError(.unsupportedURL)
    }

    func report(_ target: ThreadReportTarget, reasons: [ThreadReportReason], detail: String)
        async throws -> String { throw URLError(.unsupportedURL) }

    func isBlocked(memberID: String) async throws -> Bool { throw URLError(.unsupportedURL) }

    func setBlocked(_ blocked: Bool, memberID: String) async throws {
        throw URLError(.unsupportedURL)
    }
}
