//
//  SettingsSystemActionsTests.swift
//  SettingsDataTests
//
//  Created by euijjang97 on 10/20/26.
//

import Foundation
import Testing
@testable import SettingsData

@Suite("Bounded temporary cache")
struct SettingsSystemActionsTests {
    @Test("Clearing cache removes symlinks and preserves outside files")
    func preservesOutsideFiles() throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "settings-cache-test-\(UUID().uuidString)")
        let root = directory.appending(path: "cache")
        let external = directory.appending(path: "private")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try Data("private-data".utf8).write(to: external)
        try Data("cache".utf8).write(to: root.appending(path: "entry"))
        try FileManager.default.createSymbolicLink(
            at: root.appending(path: "external-link"), withDestinationURL: external
        )
        #expect(try SettingsCache.size(at: root) == 5)
        try SettingsCache.clear(at: root)
        #expect(try SettingsCache.size(at: root) == 0)
        #expect(try Data(contentsOf: external) == Data("private-data".utf8))
        let link = directory.appending(path: "root-link")
        try FileManager.default.createSymbolicLink(at: link, withDestinationURL: root)
        #expect(throws: CocoaError.self) { try SettingsCache.clear(at: link) }
    }
}
