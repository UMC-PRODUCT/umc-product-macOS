//
//  LiveSettingsRepository.swift
//  SettingsData
//
//  Created by euijjang97 on 10/20/26.
//

import CoreNetwork
import Foundation
import SettingsDomain
import UMCFoundation

public struct LiveSettingsRepository: SettingsRepository {
    private let adapter: MoyaNetworkAdapter
    private let client: NetworkClient
    private let environment: NetworkEnvironment

    public init(
        adapter: MoyaNetworkAdapter, client: NetworkClient, environment: NetworkEnvironment
    ) {
        self.adapter = adapter
        self.client = client
        self.environment = environment
    }

    public func fetchProfile() async throws -> SettingsProfile {
        try await requireAuthentication()
        return try await profile(for: .profile)
    }

    public func updateProfileLinks(_ links: SettingsProfileLinks) async throws -> SettingsProfile {
        try await requireAuthentication()
        return try await profile(for: .updateLinks(.init(links: links)))
    }

    public func registerChallenger(code: String) async throws {
        try await requireAuthentication()
        do {
            let response = try await adapter.request(target(.register(.init(code: code))))
            try JSONDecoder().decode(APIResponse<EmptyResult>.self, from: response.data)
                .validateSuccess()
        } catch {
            throw try await accountError(error)
        }
    }

    public func logout() async throws {
        let refreshToken = try await client.logoutReturningRefreshToken()
        if let refreshToken {
            do {
                let response = try await adapter.requestWithoutAuth(
                    target(.logout(.init(refreshToken: refreshToken)))
                )
                try JSONDecoder().decode(APIResponse<EmptyResult>.self, from: response.data)
                    .validateSuccess()
            } catch {
                throw SettingsError.serverLogoutFailed
            }
        }
    }

    private func profile(for endpoint: SettingsTarget.Endpoint) async throws -> SettingsProfile {
        do {
            let response = try await adapter.request(target(endpoint))
            return try JSONDecoder().decode(
                APIResponse<SettingsMemberResponse>.self, from: response.data
            ).unwrap().toDomain()
        } catch {
            throw try await accountError(error)
        }
    }

    private func requireAuthentication() async throws {
        guard await client.isLoggedIn() else {
            try await client.logout()
            throw SettingsError.authenticationRequired
        }
    }

    private func accountError(_ error: Error) async throws -> Error {
        if let networkError = error as? NetworkError {
            switch networkError {
            case .unauthorized, .noRefreshToken, .tokenRefreshFailed:
                try await client.logout()
                return SettingsError.authenticationRequired
            case .requestFailed(_, let data):
                if let data, let response = try? JSONDecoder().decode(
                    APIResponse<EmptyResult>.self, from: data
                ), !response.isSuccess {
                    return RepositoryError.serverError(code: response.code, message: response.message)
                }
            default:
                break
            }
        }
        return error
    }

    private func target(_ endpoint: SettingsTarget.Endpoint) -> SettingsTarget {
        SettingsTarget(environment: environment, endpoint: endpoint)
    }
}
