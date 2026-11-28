//  DockRecordStoreTests.swift
//  HomePresentationTests
//
//  Created by euijjang97 on 11/28/26.
//

import Foundation
import Testing

@testable import HomePresentation

@MainActor
@Test func continuesOnlyDockScoresFromTheSharedRecord() throws {
    let suite = "test.home.dock." + UUID().uuidString
    let defaults = try #require(UserDefaults(suiteName: suite))
    defer { defaults.removePersistentDomain(forName: suite) }
    let key = "home.games.records.101"
    let legacy = Data("""
        {"best":{"postmarkDock":20,"jump":900},"totals":{"postmarkDock":35,"jump":999},
        "recent":["소인이 찍겠습니다! 20점","블록 점프 900점","소인이 찍겠습니다! 15점"]}
        """.utf8)
    defaults.set(legacy, forKey: key)

    let store = DockRecordStore(defaults: defaults, memberID: "101")
    #expect(store.load() == DockRecords(best: 20, total: 35, recent: [20, 15]))
    _ = store.record(5)
    let expected = DockRecords(best: 50, total: 90, recent: [50, 5, 20])
    #expect(store.record(50) == expected)
    #expect(store.load() == expected)
    #expect(defaults.data(forKey: key) == legacy)
    #expect(DockRecordStore(defaults: defaults, memberID: "102").load() == DockRecords())
}

@MainActor
@Test func previewScoresStayInTheirSuiteAndGuestsNeverWrite() throws {
    let suite = "test.home.dock." + UUID().uuidString
    let previewSuite = suite + ".preview"
    let live = try #require(UserDefaults(suiteName: suite))
    let preview = try #require(UserDefaults(suiteName: previewSuite))
    defer {
        live.removePersistentDomain(forName: suite)
        preview.removePersistentDomain(forName: previewSuite)
    }
    let previewStore = DockRecordStore(defaults: preview, memberID: "101")
    #expect(previewStore.record(12).best == 12)
    #expect(DockRecordStore(defaults: live, memberID: "101").load() == DockRecords())
    for guest: String? in [nil, ""] {
        #expect(DockRecordStore(defaults: live, memberID: guest).record(20) == DockRecords())
    }
    #expect(live.persistentDomain(forName: suite)?.isEmpty ?? true)
}
