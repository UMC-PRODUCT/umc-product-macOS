//
//  SettingsPreferences.swift
//  SettingsDomain
//
//  Created by euijjang97 on 10/20/26.
//

import Foundation
import Observation
import UMCFoundation

public enum SettingsTheme: String, CaseIterable, Identifiable, Sendable {
    case system, light, dark
    public var id: String { rawValue }
}

public enum SettingsFont: String, CaseIterable, Identifiable, Sendable {
    case pretendard, system, rounded, serif
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
    @ObservationIgnored private let languagePreferences: SettingsPreferences?
    private var storedLanguage: AppLanguage

    public var language: AppLanguage {
        get { languagePreferences?.language ?? storedLanguage }
        set {
            if let languagePreferences {
                languagePreferences.language = newValue
            } else {
                storedLanguage = newValue
                save(newValue.rawValue, key: "language")
                AppLocalization.shared.language = newValue
            }
        }
    }
    public var theme: SettingsTheme { didSet { save(theme.rawValue, key: "theme") } }
    public var selectedColorThemeID: String {
        didSet { save(selectedColorThemeID, key: "colorThemeID") }
    }
    public private(set) var customColorThemes: [SettingsColorTheme]
    public var fontFamily: String? { didSet { save(fontFamily, key: "fontFamily") } }
    public var font: SettingsFont { didSet { save(font.rawValue, key: "font") } }
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

    public init(
        defaults: UserDefaults = .standard,
        languagePreferences: SettingsPreferences? = nil
    ) {
        self.defaults = defaults
        self.languagePreferences = languagePreferences
        storedLanguage = defaults.string(forKey: "settings.language")
            .flatMap(AppLanguage.init) ?? .korean
        theme = defaults.string(forKey: "settings.theme").flatMap(SettingsTheme.init) ?? .system
        selectedColorThemeID = defaults.string(forKey: "settings.colorThemeID") ?? "umc"
        let storedThemes = defaults.data(forKey: "settings.colorThemes")
            .flatMap { try? JSONDecoder().decode([SettingsColorTheme].self, from: $0) }?
            .filter { UUID(uuidString: $0.id) != nil && !$0.name.isEmpty
                && $0.name.count <= 40 && $0.light != nil && $0.dark != nil } ?? []
        var identifiers = Set<String>()
        customColorThemes = storedThemes.filter { identifiers.insert($0.id).inserted }
        fontFamily = defaults.string(forKey: "settings.fontFamily")
        font = defaults.string(forKey: "settings.font").flatMap(SettingsFont.init) ?? .pretendard
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

    public var colorThemes: [SettingsColorTheme] { SettingsColorTheme.presets + customColorThemes }

    public var selectedColorTheme: SettingsColorTheme {
        colorThemes.first { $0.id == selectedColorThemeID } ?? .standard
    }

    public var isCustomColorTheme: Bool {
        customColorThemes.contains { $0.id == selectedColorThemeID }
    }

    @discardableResult
    public func duplicateColorTheme(
        name: String, light: SettingsThemeColors, dark: SettingsThemeColors
    ) -> Bool {
        let name = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(40))
        guard !name.isEmpty else { return false }
        var uniqueName = name
        var suffix = 2
        while colorThemes.contains(where: { $0.name == uniqueName }) {
            let ending = " (\(suffix))"
            uniqueName = String(name.prefix(40 - ending.count)) + ending
            suffix += 1
        }
        let theme = SettingsColorTheme(id: UUID().uuidString, name: uniqueName,
            light: light, dark: dark)
        customColorThemes.append(theme)
        persistColorThemes()
        selectedColorThemeID = theme.id
        return true
    }

    public func updateColorTheme(light: SettingsThemeColors, dark: SettingsThemeColors) {
        if let index = customColorThemes.firstIndex(where: { $0.id == selectedColorThemeID }) {
            customColorThemes[index].light = light
            customColorThemes[index].dark = dark
            persistColorThemes()
        } else {
            duplicateColorTheme(name: AppLocalization.string("\(selectedColorTheme.name) 사용자 지정"),
                light: light, dark: dark)
        }
    }

    public func deleteSelectedColorTheme() {
        guard isCustomColorTheme else { return }
        customColorThemes.removeAll { $0.id == selectedColorThemeID }
        selectedColorThemeID = SettingsColorTheme.standard.id
        persistColorThemes()
    }

    private func persistColorThemes() {
        if let data = try? JSONEncoder().encode(customColorThemes) {
            save(data, key: "colorThemes")
        }
    }

    private func save(_ value: Any?, key: String) {
        defaults.set(value, forKey: "settings.\(key)")
    }
}
