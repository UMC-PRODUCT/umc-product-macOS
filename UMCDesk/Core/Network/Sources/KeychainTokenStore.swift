//
//  KeychainTokenStore.swift
//  CoreNetwork
//
//  Created by euijjang97 on 10/6/26.
//

import Foundation
import Security
import UMCNetworkKit

/// Actor-isolated macOS token storage with an app-specific Keychain service.
/// Tokens remain on this device; an in-memory cache avoids repeated Keychain reads.
public actor KeychainTokenStore: TokenStore {

    // MARK: - Property

    private let service: String
    private let accessTokenKey: String
    private let refreshTokenKey: String
    private let deleteItem: @Sendable (CFDictionary) -> OSStatus

    private var cachedAccessToken: String?
    private var cachedRefreshToken: String?
    private var isCacheLoaded: Bool = false

    // MARK: - Init

    public init(
        service: String = "com.umc.product.macos.tokens",
        accessTokenKey: String = "accessToken",
        refreshTokenKey: String = "refreshToken"
    ) {
        self.service = service
        self.accessTokenKey = accessTokenKey
        self.refreshTokenKey = refreshTokenKey
        self.deleteItem = { SecItemDelete($0) }
    }

    init(service: String, deleteItem: @escaping @Sendable (CFDictionary) -> OSStatus) {
        self.service = service
        self.accessTokenKey = "accessToken"
        self.refreshTokenKey = "refreshToken"
        self.deleteItem = deleteItem
    }

    // MARK: - TokenStore

    public func getAccessToken() async -> String? {
        await loadCached()
        return cachedAccessToken
    }

    public func getRefreshToken() async -> String? {
        await loadCached()
        return cachedRefreshToken
    }

    public func save(accessToken: String, refreshToken: String) async throws {
        try saveToKeychain(key: accessTokenKey, value: accessToken)
        try saveToKeychain(key: refreshTokenKey, value: refreshToken)

        cachedAccessToken = accessToken
        cachedRefreshToken = refreshToken
        isCacheLoaded = true
    }

    public func clear() async throws {
        try deleteFromKeychain(key: accessTokenKey)
        try deleteFromKeychain(key: refreshTokenKey)

        cachedAccessToken = nil
        cachedRefreshToken = nil
        isCacheLoaded = true
    }

    // MARK: - Private Methods

    private func loadCached() async {
        guard !isCacheLoaded else { return }

        cachedAccessToken = loadFromKeychain(key: accessTokenKey)
        cachedRefreshToken = loadFromKeychain(key: refreshTokenKey)
        isCacheLoaded = true
    }

    private func saveToKeychain(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }

        try deleteFromKeychain(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]

        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status: status)
        }
    }

    private func loadFromKeychain(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    private func deleteFromKeychain(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        let status = deleteItem(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status: status)
        }
    }
}

// MARK: - KeychainError

public enum KeychainError: Error, LocalizedError, Equatable {
    case encodingFailed
    case saveFailed(status: OSStatus)
    case loadFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)

    public var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "토큰 인코딩 실패"
        case .saveFailed(let status):
            return "Keychain 저장 실패 (status: \(status))"
        case .loadFailed(let status):
            return "Keychain 로드 실패 (status: \(status))"
        case .deleteFailed(let status):
            return "Keychain 삭제 실패 (status: \(status))"
        }
    }
}
