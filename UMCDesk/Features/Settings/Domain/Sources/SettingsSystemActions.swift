//
//  SettingsSystemActions.swift
//  SettingsDomain
//
//  Created by euijjang97 on 10/20/26.
//

import Foundation

public enum SettingsLoginItemStatus: Equatable, Sendable {
    case disabled, enabled, requiresApproval, unavailable
}

public enum SettingsNotificationStatus: Equatable, Sendable {
    case notDetermined, denied, authorized, provisional
}

public enum SettingsLocationStatus: Equatable, Sendable {
    case notDetermined, denied, restricted, authorized
}

public struct SettingsSystemStatus: Equatable, Sendable {
    public let loginItem: SettingsLoginItemStatus
    public let notifications: SettingsNotificationStatus
    public let location: SettingsLocationStatus

    public init(
        loginItem: SettingsLoginItemStatus = .disabled,
        notifications: SettingsNotificationStatus = .notDetermined,
        location: SettingsLocationStatus = .notDetermined
    ) {
        self.loginItem = loginItem
        self.notifications = notifications
        self.location = location
    }
}

public enum SettingsSystemDestination: Sendable {
    case loginItems, notifications, location, accessibility, defaultBrowser
}

public struct SettingsRelease: Equatable, Sendable {
    public let tag: String
    public let url: URL

    public init(tag: String, url: URL) {
        self.tag = tag
        self.url = url
    }
}

@MainActor
public protocol SettingsSystemActions {
    func status() async -> SettingsSystemStatus
    func setLaunchAtLogin(_ enabled: Bool) async throws
    func requestNotificationAuthorization() async throws
    func openSystemSettings(_ destination: SettingsSystemDestination) -> Bool
    func cacheSize() async throws -> Int64
    func clearCache() async throws
    func latestRelease() async throws -> SettingsRelease?
    func clearAccountNotifications() async
}
