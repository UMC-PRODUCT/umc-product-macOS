//
//  SettingsSearchTests.swift
//  SettingsPresentationTests
//
//  Created by euijjang97 on 10/20/26.
//

import Testing
@testable import SettingsPresentation

struct SettingsSearchTests {
    @Test("Settings search trims whitespace and matches descriptions")
    func searchFindsDescription() {
        #expect(SettingsPage.search("  위치  ") == [.privacy])
        #expect(SettingsPage.search("\n  ").count == 5)
        #expect(SettingsPage.search("gItHuB") == [.about])
        #expect(SettingsPage.search("없는 검색 결과").isEmpty)
    }
}
