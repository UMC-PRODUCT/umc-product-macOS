//  HomeGameRecordStoreTests.swift
//  HomePresentationTests
//
//  Created by euijjang97 on 11/23/26.
//

import Foundation
import HomeDomain
import Testing

@testable import HomePresentation

@MainActor
@Test func restoresOnlyTheSelectedPortAndMember() throws {
    let prefix = "test.home.records." + UUID().uuidString
    let firstPort = prefix + ".42101"
    let secondPort = prefix + ".42102"
    let first = try #require(UserDefaults(suiteName: firstPort))
    let second = try #require(UserDefaults(suiteName: secondPort))
    defer {
        first.removePersistentDomain(forName: firstPort)
        second.removePersistentDomain(forName: secondPort)
    }

    let member = "101"
    let other = "102"
    let keys = [member, other].map { "home.games.records." + $0 }
    let standard = UserDefaults.standard
    let original = keys.map { standard.data(forKey: $0) }
    let sample = GameRecords(best: ["jump": 73], totals: ["jump": 109], recent: ["블록 점프 73점"])
    let otherSample = GameRecords(best: ["tower": 24], totals: ["tower": 48], recent: ["탑 24점"])
    func store(_ defaults: UserDefaults, _ member: String) -> HomeGameRecordStore {
        HomeView(repository: OfflineHome(), memberID: member, defaults: defaults).recordStore
    }

    store(first, member).save(sample)
    #expect(store(first, other).load() == GameRecords())
    #expect(store(second, member).load() == GameRecords())
    store(first, other).save(otherSample)
    store(second, member).save(otherSample)

    let reopened = try #require(UserDefaults(suiteName: firstPort))
    #expect(store(reopened, member).load() == sample)
    #expect(store(reopened, other).load() == otherSample)
    #expect(store(second, member).load() == otherSample)
    #expect(store(second, other).load() == GameRecords())
    #expect(keys.map { standard.data(forKey: $0) } == original)
}

private struct OfflineHome: HomeRepository {
    func profile() async throws -> HomeProfile { throw URLError(.notConnectedToInternet) }
    func schedule() async throws -> HomeSchedule? { nil }
    func notice() async throws -> String? { nil }
    func project() async throws -> String? { nil }
}
