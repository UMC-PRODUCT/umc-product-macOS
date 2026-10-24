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
    @Test("Recommendations use existing searchable settings with stable order")
    func recommendations() {
        #expect(SettingsSearchResult.recommendations.map(\.id) == [
            "theme", "bodyTextSize", "launchAtLogin", "notificationAccess",
        ])
        for result in SettingsSearchResult.recommendations {
            #expect(SettingsPage.search(result.title).contains { $0.id == result.id })
        }
    }

    @Test("Search previews matching setting items and their options")
    func searchFindsItems() {
        #expect(SettingsPage.search("  위치  ").map(\.title) == ["위치 접근"])
        #expect(SettingsPage.search("gItHuB").map(\.title) == ["업데이트"])
        #expect(SettingsPage.search("기본 브라우저").map(\.title) == ["기본 웹 브라우저"])
        #expect(SettingsPage.search("시작 화면").map(\.id) == ["launchPage"])
        #expect(SettingsPage.search("자동 실행").map(\.id) == ["launchAtLogin"])
        #expect(SettingsPage.search("계속 실행").map(\.id) == ["windowClose"])
        #expect(SettingsPage.search("데스크탑").map(\.id) == ["externalLinks"])
        #expect(SettingsPage.search("다크").map(\.title) == ["테마"])
        #expect(SettingsPage.search("더 크게").map(\.title) == ["본문 크기"])
        #expect(SettingsPage.search("\n  ").isEmpty)
        #expect(SettingsPage.search("없는 검색 결과").isEmpty)
    }

    @Test("설정 검색은 사용 가능한 동작과 준비 중 상태를 반환한다")
    func updatedSettingsActions() {
        #expect(SettingsPage.search("복원").map(\.id) == ["resetAppearance"])
        #expect(SettingsPage.search("미리보기").map(\.id) == ["bodyTextSize"])
        #expect(SettingsPage.search("다시 확인").map(\.id) == ["cache"])
        #expect(SettingsPage.search("개인 프로젝트").isEmpty)
        #expect(SettingsPage.search("자동으로 설치").map(\.id) == ["updates"])
        for identifier in ["attendanceNotifications", "noticeNotifications",
            "threadNotifications", "notificationContent", "terms", "privacyPolicy", "contact"] {
            #expect(SettingsPage.search("준비 중").contains { $0.id == identifier })
        }
    }

    @Test("Search returns multiple individual matches with stable unique identities")
    func multipleMatches() {
        let results = SettingsPage.search("알림")
        #expect(results.count == 5)
        #expect(results.allSatisfy { $0.page == .notifications })
        #expect(Set(results.map(\.id)).count == results.count)
        #expect(results.map(\.id) == SettingsPage.search(" 알림 ").map(\.id))
        #expect(Set(SettingsSearchResult.items.map(\.id)).count ==
            SettingsSearchResult.items.count)
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

struct SettingsProfileMenuFocusTests {
    @Test("Automatic focus stays visually idle until keyboard navigation begins")
    func pointerAndKeyboardHighlightSequence() {
        // Opening by pointer still assigns real focus to My Page for accessibility.
        #expect(!profileMenuShowsKeyboardHighlight(
            keyboardNavigation: false, hasHoveredItem: false, isFocused: true))
        // Entering and leaving another row must not resurrect that automatic highlight.
        #expect(!profileMenuShowsKeyboardHighlight(
            keyboardNavigation: false, hasHoveredItem: true, isFocused: true))
        #expect(!profileMenuShowsKeyboardHighlight(
            keyboardNavigation: false, hasHoveredItem: false, isFocused: true))
        // Tab or an arrow key reveals the currently focused row, then follows focus.
        #expect(profileMenuShowsKeyboardHighlight(
            keyboardNavigation: true, hasHoveredItem: false, isFocused: true))
        #expect(!profileMenuShowsKeyboardHighlight(
            keyboardNavigation: true, hasHoveredItem: false, isFocused: false))
        // Pointer re-entry owns highlighting, even before the keyboard flag resets.
        #expect(!profileMenuShowsKeyboardHighlight(
            keyboardNavigation: true, hasHoveredItem: true, isFocused: true))
        #expect(!profileMenuShowsKeyboardHighlight(
            keyboardNavigation: false, hasHoveredItem: true, isFocused: true))
    }
}
