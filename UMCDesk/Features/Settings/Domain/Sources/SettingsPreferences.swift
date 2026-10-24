//
//  SettingsPreferences.swift
//  SettingsDomain
//
//  Created by euijjang97 on 10/20/26.
//

import Foundation
import Observation

public enum SettingsTheme: String, CaseIterable, Identifiable, Sendable {
    case system, light, dark
    public var id: String { rawValue }
}

public enum SettingsBodyTextSize: String, CaseIterable, Identifiable, Sendable {
    case standard, large, extraLarge
    public var id: String { rawValue }
    public var scale: Double {
        switch self {
        case .standard: 1
        case .large: 1.15
        case .extraLarge: 1.3
        }
    }
}

public enum SettingsLaunchPage: String, CaseIterable, Identifiable, Sendable {
    case login, myPage, settings
    public var id: String { rawValue }
}

public enum SettingsWindowCloseBehavior: String, CaseIterable, Identifiable, Sendable {
    case keepRunning, quit
    public var id: String { rawValue }
}

@MainActor
@Observable
public final class SettingsPreferences {
    @ObservationIgnored private let defaults: UserDefaults
    public var theme: SettingsTheme { didSet { save(theme.rawValue, key: "theme") } }
    public var bodyTextSize: SettingsBodyTextSize {
        didSet { save(bodyTextSize.rawValue, key: "bodyTextSize") }
    }
    public var launchPage: SettingsLaunchPage {
        didSet { save(launchPage.rawValue, key: "launchPage") }
    }
    public var windowCloseBehavior: SettingsWindowCloseBehavior {
        didSet { save(windowCloseBehavior.rawValue, key: "windowCloseBehavior") }
    }
    public var showsMenuBar: Bool { didSet { save(showsMenuBar, key: "showsMenuBar") } }
    public var attendanceNotifications: Bool {
        didSet { save(attendanceNotifications, key: "attendanceNotifications") }
    }
    public var noticeNotifications: Bool {
        didSet { save(noticeNotifications, key: "noticeNotifications") }
    }
    public var threadNotifications: Bool {
        didSet { save(threadNotifications, key: "threadNotifications") }
    }
    public var showsNotificationContent: Bool {
        didSet { save(showsNotificationContent, key: "showsNotificationContent") }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        theme = defaults.string(forKey: "settings.theme").flatMap(SettingsTheme.init) ?? .system
        bodyTextSize = defaults.string(forKey: "settings.bodyTextSize")
            .flatMap(SettingsBodyTextSize.init) ?? .standard
        launchPage = defaults.string(forKey: "settings.launchPage")
            .flatMap(SettingsLaunchPage.init) ?? .login
        let storedShowsMenuBar = defaults.object(forKey: "settings.showsMenuBar") as? Bool ?? true
        showsMenuBar = storedShowsMenuBar
        let storedWindowCloseBehavior = defaults.string(forKey: "settings.windowCloseBehavior")
            .flatMap(SettingsWindowCloseBehavior.init)
        let resolvedWindowCloseBehavior = storedWindowCloseBehavior ??
            (storedShowsMenuBar ? .keepRunning : .quit)
        windowCloseBehavior = resolvedWindowCloseBehavior
        if storedWindowCloseBehavior == nil {
            defaults.set(
                resolvedWindowCloseBehavior.rawValue, forKey: "settings.windowCloseBehavior"
            )
        }
        attendanceNotifications = defaults.object(forKey: "settings.attendanceNotifications")
            as? Bool ?? true
        noticeNotifications = defaults.object(forKey: "settings.noticeNotifications")
            as? Bool ?? true
        threadNotifications = defaults.object(forKey: "settings.threadNotifications")
            as? Bool ?? true
        showsNotificationContent = defaults.object(forKey: "settings.showsNotificationContent")
            as? Bool ?? false
    }

    private func save(_ value: Any, key: String) {
        defaults.set(value, forKey: "settings.\(key)")
    }
}
