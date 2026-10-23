//
//  SettingsSearchTests.swift
//  SettingsPresentationTests
//
//  Created by euijjang97 on 10/20/26.
//

import CoreDesignSystem
import SwiftUI
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

struct SettingsActivityRoleTests {
    @Test("Every server and supported display role has a readable title", arguments: [
        ("SCHOOL_PRESIDENT", "교내 회장"), ("SCHOOL_VICE_PRESIDENT", "교내 부회장"),
        ("SCHOOL_PART_LEADER", "교내 파트장"), ("SCHOOL_ETC_ADMIN", "기타 교내 운영진"),
        ("CENTRAL_PRESIDENT", "총괄"), ("CENTRAL_VICE_PRESIDENT", "부총괄"),
        ("CENTRAL_OPERATING_TEAM_MEMBER", "중앙 운영국원"),
        ("CENTRAL_EDUCATION_TEAM_MEMBER", "중앙 교육국원"),
        ("CHAPTER_PRESIDENT", "지부장"), ("SUPER_ADMIN", "Admin"),
        ("PRODUCT", "Product"), ("CHALLENGER", "챌린저"),
        ("FUTURE_ROLE", "FUTURE_ROLE"),
    ])
    func title(role: String, expected: String) {
        #expect(roleTitle(role) == expected)
    }

    @Test("Role badges use their design-system filled colors")
    func filledColors() {
        let groups: [(roles: [String], foreground: Color, background: Color)] = [
            (["SCHOOL_PRESIDENT", "SCHOOL_VICE_PRESIDENT", "SCHOOL_PART_LEADER",
                "SCHOOL_ETC_ADMIN"], UMCColor.Semantic.tagRoleCampusStrong,
                UMCColor.Semantic.tagRoleCampusWeak),
            (["CENTRAL_PRESIDENT", "CENTRAL_VICE_PRESIDENT", "CENTRAL_OPERATING_TEAM_MEMBER",
                "CENTRAL_EDUCATION_TEAM_MEMBER"], UMCColor.Semantic.tagRoleCentralStrong,
                UMCColor.Semantic.tagRoleCentralWeak),
            (["CHAPTER_PRESIDENT"], UMCColor.Semantic.tagRoleChapterStrong,
                UMCColor.Semantic.tagRoleChapterWeak),
            (["SUPER_ADMIN", "CHALLENGER"], UMCColor.Semantic.tagRoleChallengerSuperAdminStrong,
                UMCColor.Semantic.tagRoleChallengerSuperAdminWeak),
            (["PRODUCT"], UMCColor.Semantic.tagRoleProductStrong,
                UMCColor.Custom.backgroundTagGrey),
            (["FUTURE_ROLE", "SCHOOL_FUTURE", "CENTRAL_FUTURE", "CHAPTER_FUTURE"],
                UMCColor.Semantic.textNeutralStrong800, UMCColor.Custom.backgroundTagGrey),
        ]
        for group in groups {
            for role in group.roles {
                #expect(roleColors(role).foreground == group.foreground)
                #expect(roleColors(role).background == group.background)
            }
        }
    }
}
