//
//  SettingsUseCase.swift
//  SettingsDomain
//
//  Created by euijjang97 on 10/20/26.
//

import Foundation

public protocol SettingsRepository: Sendable {
    func fetchProfile() async throws -> SettingsProfile
    func updateProfileLinks(_ links: SettingsProfileLinks) async throws -> SettingsProfile
    func registerChallenger(code: String) async throws
    func logout() async throws
}

public protocol SettingsUseCase: Sendable {
    func fetchProfile() async throws -> SettingsProfile
    func updateProfileLinks(_ links: SettingsProfileLinks) async throws -> SettingsProfile
    func registerChallenger(code: String) async throws
    func logout() async throws
}

public enum SettingsError: Error, Equatable, Sendable, LocalizedError {
    case authenticationRequired
    case invalidLink(SettingsLinkKind)
    case invalidChallengerCode
    case serverLogoutFailed

    public var errorDescription: String? {
        switch self {
        case .authenticationRequired: "로그인이 필요해요."
        case .invalidLink: "사용자 정보가 없는 올바른 HTTP(S) 주소를 입력해 주세요."
        case .invalidChallengerCode: "발급받은 6자리 코드를 입력해 주세요."
        case .serverLogoutFailed: "이 Mac에서 로그아웃했지만 서버의 토큰 폐기는 확인하지 못했어요."
        }
    }
}

public struct DefaultSettingsUseCase: SettingsUseCase {
    private let repository: any SettingsRepository

    public init(repository: any SettingsRepository) {
        self.repository = repository
    }

    public func fetchProfile() async throws -> SettingsProfile {
        try await repository.fetchProfile()
    }

    public func updateProfileLinks(_ links: SettingsProfileLinks) async throws -> SettingsProfile {
        var normalized = links
        for kind in SettingsLinkKind.allCases {
            let value = links[kind].trimmingCharacters(in: .whitespacesAndNewlines)
            guard value.isEmpty || Self.validatedWebURL(value) != nil else {
                throw SettingsError.invalidLink(kind)
            }
            normalized[kind] = value
        }
        return try await repository.updateProfileLinks(normalized)
    }

    public func registerChallenger(code: String) async throws {
        let normalized = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard normalized.count == 6, !normalized.allSatisfy(\.isWhitespace) else {
            throw SettingsError.invalidChallengerCode
        }
        try await repository.registerChallenger(code: normalized)
    }

    public func logout() async throws {
        try await repository.logout()
    }

    public static func validatedWebURL(_ value: String) -> URL? {
        guard let components = URLComponents(string: value),
              let scheme = components.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil,
              !value.contains(where: \.isWhitespace) else { return nil }
        return components.url
    }
}
