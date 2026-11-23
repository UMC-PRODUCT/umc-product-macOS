//
//  NetworkClient.swift
//  CoreNetwork
//
//  Created by euijjang97 on 10/7/26.
//

import Aquila
import Foundation
import UMCFoundation

public actor NetworkClient {
    // MARK: - Property

    nonisolated let aquilaClient: Aquila.NetworkClient
    private let logoutTokens: LogoutTokenStore
    nonisolated let accountScope: UUID?
    private var signOutCount: UInt64 = 0
    private var loginTask: Task<Void, Error>?
    private var logoutTask: Task<String?, Error>?
    nonisolated static let logger = Aquila.VerboseLogger(redactedKeys: [
        "authorizationCode", "oAuthVerificationToken", "emailVerificationToken",
        "googleAccessToken", "kakaoAccessToken", "rawPassword", "currentPassword", "newPassword",
        "verificationCode", "code"
    ])

    // MARK: - Init

    public init(
        session: URLSession = .shared,
        tokenStore: TokenStore,
        refreshService: TokenRefreshService,
        authPolicy: AuthenticationPolicy = DefaultAuthenticationPolicy(),
        maxRetryCount: Int = 1,
        sessionResetter: (any SessionResetting)? = nil
    ) {
        self.accountScope = nil
        let logoutTokens = LogoutTokenStore(backing: tokenStore)
        self.logoutTokens = logoutTokens
        aquilaClient = Aquila.NetworkClient(
            session: session,
            tokenStore: logoutTokens,
            refreshService: AppTokenRefreshService(service: refreshService, logoutTokens: logoutTokens),
            authPolicy: authPolicy,
            maxRetryCount: maxRetryCount,
            sessionResetter: sessionResetter,
            logger: Self.logger
        )
    }

    private init(sharing client: NetworkClient, scope: UUID) {
        accountScope = scope
        aquilaClient = client.aquilaClient
        logoutTokens = client.logoutTokens
    }

    public func boundToCurrentAccount() async throws -> NetworkClient {
        if accountScope != nil {
            try await validateScope()
            return self
        }
        guard let scope = await logoutTokens.authenticatedScope() else { throw CancellationError() }
        return NetworkClient(sharing: self, scope: scope)
    }

    nonisolated func validateScope() async throws {
        if let accountScope, await logoutTokens.authenticatedScope() != accountScope {
            throw CancellationError()
        }
    }

    public func currentAccessToken() async throws -> String {
        try await validateScope()
        guard let value = await logoutTokens.getAccessToken() else { throw CancellationError() }
        try await validateScope()
        return value
    }

    // MARK: - Function

    public func request(_ urlRequest: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            try await validateScope()
            let result = try await CredentialRequest.$scope.withValue(accountScope) {
                try await aquilaClient.request(urlRequest)
            }
            try await validateScope()
            return result
        } catch {
            try await validateScope()
            throw Self.appError(from: error)
        }
    }

    public func request<T: Decodable>(
        _ urlRequest: URLRequest,
        decoder: JSONDecoder = .init()
    ) async throws -> T {
        let (data, _) = try await request(urlRequest)
        return try decoder.decode(T.self, from: data)
    }

    public func forceRefreshToken() async throws -> TokenPair {
        do {
            try await validateScope()
            let result = try await CredentialRequest.$scope.withValue(accountScope) {
                try await aquilaClient.forceRefreshToken()
            }
            try await validateScope()
            return result
        } catch {
            throw Self.appError(from: error)
        }
    }

    public func signIn(_ authenticate: @escaping @Sendable () async throws -> TokenPair) async throws {
        guard accountScope == nil, loginTask == nil, logoutTask == nil else { throw CancellationError() }
        let task = Task {
            guard !(await aquilaClient.hasAccessToken()) else { throw CancellationError() }
            let pair = try await authenticate()
            try Task.checkCancellation()
            guard !pair.accessToken.isEmpty, !pair.refreshToken.isEmpty else {
                throw UMCFoundation.NetworkError.invalidResponse
            }
            do {
                try await logoutTokens.save(accessToken: pair.accessToken, refreshToken: pair.refreshToken)
                try Task.checkCancellation()
            } catch {
                try await logoutTokens.clear()
                throw error
            }
        }
        loginTask = task
        defer { loginTask = nil }
        try await withTaskCancellationHandler {
            try await task.value
        } onCancel: {
            task.cancel()
        }
    }

    public func invalidateAccount(_ boundClient: NetworkClient) async throws {
        let expectedSignOutCount = signOutCount
        guard accountScope == nil, let scope = boundClient.accountScope,
              logoutTokens === boundClient.logoutTokens,
              await logoutTokens.authenticatedScope() == scope, expectedSignOutCount == signOutCount
        else { throw CancellationError() }
        _ = try await logoutReturningRefreshToken()
    }

    public func logout() async throws {
        _ = try await logoutReturningRefreshToken()
    }

    public func logoutReturningRefreshToken() async throws -> String? {
        guard accountScope == nil else { throw CancellationError() }
        if let logoutTask { return try await logoutTask.value }
        signOutCount &+= 1
        let pendingLogin = loginTask
        pendingLogin?.cancel()
        let task = Task<String?, Error> {
            _ = await pendingLogin?.result
            defer { logoutTask = nil }
            do {
                try await aquilaClient.logout()
                return await logoutTokens.takeClearedRefreshToken()
            } catch {
                throw Self.appError(from: error)
            }
        }
        logoutTask = task
        return try await task.value
    }

    public func isLoggedIn() async -> Bool {
        if let accountScope { return await logoutTokens.authenticatedScope() == accountScope }
        return await aquilaClient.hasAccessToken()
    }

    nonisolated static func appError(
        from error: Error,
        refreshing: Bool = false
    ) -> Error {
        if let networkError = error as? Aquila.NetworkError {
            switch networkError {
            case .invalidResponse, .authenticationNotConfigured:
                return UMCFoundation.NetworkError.invalidResponse
            case .noRefreshToken:
                return UMCFoundation.NetworkError.noRefreshToken
            case .maxRetryExceeded:
                return UMCFoundation.NetworkError.maxRetryExceeded
            case .requestFailed(let statusCode, let data):
                if refreshing, statusCode == 401 || statusCode == 403 {
                    return UMCFoundation.NetworkError.tokenRefreshFailed(
                        reason: "서버 에러 (status: \(statusCode))"
                    )
                }
                return UMCFoundation.NetworkError.requestFailed(statusCode: statusCode, data: data)
            }
        }
        if let urlError = error as? URLError {
            return UMCFoundation.NetworkError.transientFailure(from: urlError) ?? urlError
        }
        return error
    }
}

private struct AppTokenRefreshService: TokenRefreshService {
    let service: TokenRefreshService
    let logoutTokens: LogoutTokenStore

    func refresh(_ refreshToken: String) async throws -> TokenPair {
        do {
            // Drain rotation even when logout cancels Aquila's waiting refresh task.
            let operation = Task { try await service.refresh(refreshToken) }
            let pair = try await operation.value
            await logoutTokens.recordIssuedRefreshToken(pair.refreshToken)
            return pair
        } catch {
            throw NetworkClient.appError(from: error, refreshing: true)
        }
    }
}

private actor LogoutTokenStore: TokenStore {
    private let backing: any TokenStore
    private var scope = UUID()
    private var issuedRefreshToken: String?
    private var clearedRefreshToken: String?

    init(backing: any TokenStore) {
        self.backing = backing
    }

    func authenticatedScope() async -> UUID? {
        let current = scope
        guard await backing.getAccessToken() != nil, current == scope else { return nil }
        return current
    }

    func getAccessToken() async -> String? {
        let token = await backing.getAccessToken()
        return permitsRead ? token : nil
    }

    func getRefreshToken() async -> String? {
        let token = await backing.getRefreshToken()
        return permitsRead ? token : nil
    }

    private var permitsRead: Bool { CredentialRequest.scope.map { $0 == scope } ?? true }

    func save(accessToken: String, refreshToken: String) async throws {
        try await backing.save(accessToken: accessToken, refreshToken: refreshToken)
        if issuedRefreshToken == refreshToken { issuedRefreshToken = nil }
    }

    func recordIssuedRefreshToken(_ token: String) {
        guard !token.isEmpty else { return }
        issuedRefreshToken = token
    }

    func clear() async throws {
        scope = UUID()
        let refreshToken: String?
        if let issuedRefreshToken {
            refreshToken = issuedRefreshToken
        } else {
            refreshToken = await backing.getRefreshToken()
        }
        try await backing.clear()
        clearedRefreshToken = refreshToken
        issuedRefreshToken = nil
    }

    func takeClearedRefreshToken() -> String? {
        defer { clearedRefreshToken = nil }
        return clearedRefreshToken
    }
}

enum CredentialRequest {
    @TaskLocal static var scope: UUID?
}
