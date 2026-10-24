//
//  MacSettingsSystemActions.swift
//  SettingsData
//
//  Created by euijjang97 on 10/20/26.
//

import AppKit
import CoreLocation
import Foundation
import ServiceManagement
import SettingsDomain
import UserNotifications

@MainActor
public final class MacSettingsSystemActions: SettingsSystemActions {
    private let cacheDirectory: URL
    private let session: URLSession
    private let locationManager = CLLocationManager()

    public init(cacheDirectory: URL? = nil, session: URLSession = .shared) {
        self.cacheDirectory = cacheDirectory ?? FileManager.default.urls(
            for: .cachesDirectory, in: .userDomainMask
        )[0].appending(path: "SettingsTemporaryCache", directoryHint: .isDirectory)
        self.session = session
    }

    public func status() async -> SettingsSystemStatus {
        let notifications = await UNUserNotificationCenter.current().notificationSettings()
        let loginItem: SettingsLoginItemStatus = switch SMAppService.mainApp.status {
        case .notRegistered: .disabled
        case .enabled: .enabled
        case .requiresApproval: .requiresApproval
        case .notFound: .unavailable
        @unknown default: .unavailable
        }
        let authorization = notifications.authorizationStatus
        let notificationStatus: SettingsNotificationStatus = switch authorization {
        case .notDetermined: .notDetermined
        case .denied: .denied
        case .authorized: .authorized
        case .provisional: .provisional
        @unknown default: .denied
        }
        let location: SettingsLocationStatus = switch locationManager.authorizationStatus {
        case .notDetermined: .notDetermined
        case .denied: .denied
        case .restricted: .restricted
        case .authorizedAlways, .authorizedWhenInUse: .authorized
        @unknown default: .restricted
        }
        return .init(loginItem: loginItem, notifications: notificationStatus, location: location)
    }

    public func setLaunchAtLogin(_ enabled: Bool) async throws {
        if enabled {
            try SMAppService.mainApp.register()
        } else {
            try await SMAppService.mainApp.unregister()
        }
    }

    public func requestNotificationAuthorization() async throws {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .notDetermined else { return }
        _ = try await center.requestAuthorization(options: [.alert, .badge, .sound])
    }

    public func openSystemSettings(_ destination: SettingsSystemDestination) -> Bool {
        if destination == .loginItems {
            SMAppService.openSystemSettingsLoginItems()
            return true
        }
        let address: String = switch destination {
        case .loginItems: "x-apple.systempreferences:com.apple.LoginItems-Settings.extension"
        case .defaultBrowser: "x-apple.systempreferences:"
        case .notifications: "x-apple.systempreferences:com.apple.Notifications-Settings.extension"
        case .location:
            "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices"
        case .accessibility:
            "x-apple.systempreferences:com.apple.preference.universalaccess"
        }
        guard let url = URL(string: address) else { return false }
        return NSWorkspace.shared.open(url)
    }

    public func cacheSize() async throws -> Int64 {
        let root = cacheDirectory
        return try await Task.detached(priority: .utility) {
            try SettingsCache.size(at: root)
        }.value
    }

    public func clearCache() async throws {
        let root = cacheDirectory
        try await Task.detached(priority: .utility) {
            try SettingsCache.clear(at: root)
        }.value
    }

    public func latestRelease() async throws -> SettingsRelease? {
        let endpoint = URL(
            string: "https://api.github.com/repos/UMC-PRODUCT/umc-product-macOS/releases/latest"
        )!
        var request = URLRequest(url: endpoint)
        request.timeoutInterval = 20
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        if response.statusCode == 404 { return nil }
        guard response.statusCode == 200 else { throw URLError(.badServerResponse) }
        let release = try JSONDecoder().decode(SettingsReleaseResponse.self, from: data)
        guard let url = DefaultSettingsUseCase.validatedWebURL(release.htmlURL),
              url.scheme == "https", url.host?.lowercased() == "github.com",
              url.path.hasPrefix("/UMC-PRODUCT/umc-product-macOS/releases/") else {
            throw URLError(.badServerResponse)
        }
        return SettingsRelease(tag: release.tagName, url: url)
    }

    public func clearAccountNotifications() async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }
}

private struct SettingsReleaseResponse: Codable {
    let tagName: String
    let htmlURL: String

    private enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case htmlURL = "html_url"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        tagName = try container.decode(String.self, forKey: .tagName)
        htmlURL = try container.decode(String.self, forKey: .htmlURL)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(tagName, forKey: .tagName)
        try container.encode(htmlURL, forKey: .htmlURL)
    }
}

enum SettingsCache {
    static func size(at root: URL) throws -> Int64 {
        let manager = FileManager.default
        guard manager.fileExists(atPath: root.path) else { return 0 }
        try validateRoot(root)
        var failure: Error?
        guard let enumerator = manager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isSymbolicLinkKey, .isRegularFileKey, .fileSizeKey],
            errorHandler: { _, error in failure = error; return false }
        ) else { throw CocoaError(.fileReadUnknown) }
        var total: Int64 = 0
        for case let file as URL in enumerator {
            let values = try file.resourceValues(forKeys: [
                .isSymbolicLinkKey, .isRegularFileKey, .fileSizeKey
            ])
            if values.isSymbolicLink == true {
                enumerator.skipDescendants()
            } else if values.isRegularFile == true {
                total += Int64(values.fileSize ?? 0)
            }
        }
        if let failure { throw failure }
        return total
    }

    static func clear(at root: URL) throws {
        let manager = FileManager.default
        guard manager.fileExists(atPath: root.path) else { return }
        try validateRoot(root)
        for child in try manager.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) {
            try manager.removeItem(at: child)
        }
    }

    private static func validateRoot(_ root: URL) throws {
        let values = try root.resourceValues(forKeys: [.isSymbolicLinkKey, .isDirectoryKey])
        guard values.isSymbolicLink != true, values.isDirectory == true else {
            throw CocoaError(.fileWriteNoPermission)
        }
    }
}
