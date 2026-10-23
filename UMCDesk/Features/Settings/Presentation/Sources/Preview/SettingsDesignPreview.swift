//
//  SettingsDesignPreview.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/20/26.
//

#if DEBUG
import Foundation
import SettingsDomain

@MainActor
public enum SettingsDesignPreview {
    public static let ids = [
        "757:12600", "766:2895", "770:4216", "770:14893", "771:15573", "771:15714",
        "771:15995", "776:16447", "776:16803", "765:15045", "776:17026", "911:19103",
        "807:13303", "903:3596", "903:14091", "903:14321", "903:14750", "906:3869",
        "906:16367", "907:16571", "activity_roles",
    ]

    public static func makeViewModel(
        id: String, preferences: SettingsPreferences
    ) -> SettingsViewModel? {
        let normalized = id.replacingOccurrences(of: "-", with: ":")
        guard ids.contains(normalized) else { return nil }
        let profile = makeProfile(isEmpty: normalized == "765:15045",
            showsAllRoles: normalized == "activity_roles")
        let model = SettingsViewModel(useCase: PreviewSettingsUseCase(profile: profile),
            preferences: preferences, systemActions: PreviewSettingsSystemActions())
        model.seedDesignProfile(profile)
        model.showProfile()
        switch normalized {
        case "766:2895", "770:4216":
            model.editLinks()
        case "770:14893", "771:15573", "771:15714", "771:15995":
            model.addPermission()
            if normalized != "770:14893" { model.challengerCode = "A7B2C9" }
            if normalized == "771:15714" {
                model.dialogMessage = "이미 사용한 코드예요. 새 코드를 받아 주세요."
            }
            if normalized == "771:15995" {
                model.codeStep = .complete
                model.registeredActivities = [SettingsActivity(id: "new", generation: "11",
                    part: "IOS", roles: ["SCHOOL_PART_LEADER"])]
            }
        case "776:16447": model.toast = .init(message: "최신 정보로 업데이트했어요.")
        case "776:16803":
            model.toast = .init(message: "새로고침하지 못했어요. 다시 시도해 주세요.", isError: true)
        case "776:17026": model.previewShowsProfileMenu = true
        case "911:19103": model.dialog = .logout
        case "807:13303": model.navigate(to: .general)
        case "903:3596": model.navigate(to: .appearance)
        case "903:14091": model.navigate(to: .notifications)
        case "903:14321", "903:14750":
            model.navigate(to: .privacy)
            if normalized == "903:14750" { model.dialog = .clearCache }
        case "906:3869": model.navigate(to: .about)
        case "906:16367":
            model.navigate(to: .general)
            model.searchText = "링크"
        case "907:16571":
            model.navigate(to: .general)
            model.searchText = "검색 결과 없음"
        default: break
        }
        return model
    }

    private static func makeProfile(isEmpty: Bool, showsAllRoles: Bool) -> SettingsProfile {
        let roles = [
            "SCHOOL_PRESIDENT", "SCHOOL_VICE_PRESIDENT", "SCHOOL_PART_LEADER", "SCHOOL_ETC_ADMIN",
            "CENTRAL_PRESIDENT", "CENTRAL_VICE_PRESIDENT", "CENTRAL_OPERATING_TEAM_MEMBER",
            "CENTRAL_EDUCATION_TEAM_MEMBER", "CHAPTER_PRESIDENT", "SUPER_ADMIN", "PRODUCT",
            "CHALLENGER",
        ]
        let parts = [
            "PLAN", "DESIGN", "WEB", "ANDROID", "IOS", "NODEJS", "SPRINGBOOT", "ADMIN",
            "WEB_PRODUCT_ENGINEER", "MOBILE_PRODUCT_ENGINEER",
        ]
        let roleActivities = roles.enumerated().map { index, role in
            SettingsActivity(id: role, generation: "11", part: parts[index % parts.count],
                roles: [role])
        }
        return SettingsProfile(id: "preview-member", name: "김유엠", nickname: "유엠",
            email: "umc@example.com", schoolName: "00대학교",
            links: isEmpty ? .init() : .init(github: "https://github.com/umc-member",
                linkedIn: "https://linkedin.com/in/umc-member",
                blog: "https://umc-member.example.com"),
            activities: isEmpty ? [] : showsAllRoles ? roleActivities : [
                .init(id: "10", generation: "10", part: "PLAN", roles: ["SCHOOL_PRESIDENT"]),
                .init(id: "11", generation: "11", part: "PLAN", roles: ["SUPER_ADMIN", "PRODUCT"]),
            ])
    }
}

private actor PreviewSettingsUseCase: SettingsUseCase {
    var profile: SettingsProfile

    init(profile: SettingsProfile) { self.profile = profile }

    func fetchProfile() async throws -> SettingsProfile { profile }

    func updateProfileLinks(_ links: SettingsProfileLinks) async throws -> SettingsProfile {
        profile = SettingsProfile(id: profile.id, name: profile.name, nickname: profile.nickname,
            email: profile.email, schoolName: profile.schoolName, links: links,
            activities: profile.activities)
        return profile
    }

    func registerChallenger(code: String) async throws {
        profile = SettingsProfile(id: profile.id, name: profile.name, nickname: profile.nickname,
            email: profile.email, schoolName: profile.schoolName, links: profile.links,
            activities: profile.activities + [
                .init(id: "new", generation: "11", part: "IOS", roles: ["SCHOOL_PART_LEADER"]),
            ])
    }

    func logout() async throws {}
}

@MainActor
private final class PreviewSettingsSystemActions: SettingsSystemActions {
    var bytes: Int64 = 128_000_000
    var loginItem: SettingsLoginItemStatus = .disabled

    func status() async -> SettingsSystemStatus {
        .init(loginItem: loginItem, notifications: .authorized, location: .authorized)
    }

    func setLaunchAtLogin(_ enabled: Bool) async throws {
        loginItem = enabled ? .enabled : .disabled
    }
    func requestNotificationAuthorization() async throws {}
    func openSystemSettings(_ destination: SettingsSystemDestination) -> Bool { false }
    func cacheSize() async throws -> Int64 { bytes }
    func clearCache() async throws { bytes = 0 }
    func latestRelease() async throws -> SettingsRelease? { nil }
    func clearAccountNotifications() async {}
}
#endif
