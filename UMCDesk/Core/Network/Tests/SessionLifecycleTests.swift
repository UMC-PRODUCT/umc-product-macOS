//
//  SessionLifecycleTests.swift
//  CoreNetworkTests
//
//  Created by euijjang97 on 10/6/26.
//

import Foundation
import Testing
import UMCFoundation
@testable import CoreNetwork

@Suite("Session lifecycle")
struct SessionLifecycleTests {
    @Test("Logout drains a pending token save before clearing credentials")
    func logoutDuringTokenSaveKeepsTokensCleared() async throws {
        let store = SuspendedTokenStore()
        let client = NetworkClient(
            tokenStore: store,
            refreshService: MockTokenRefreshService(
                behavior: .success(TokenPair(accessToken: "new", refreshToken: "new-refresh"))
            )
        )
        let refresh = Task { try await client.forceRefreshToken() }
        await store.waitUntilSaveStarted()
        let logout = Task { try await client.logoutReturningRefreshToken() }
        await store.waitUntilSaveCancelled()
        await #expect(throws: CancellationError.self) { try await client.forceRefreshToken() }
        await store.completeSave()
        #expect(try await logout.value == "new-refresh")
        await #expect(throws: CancellationError.self) { try await refresh.value }
        #expect(await store.getAccessToken() == nil)
        #expect(await store.getRefreshToken() == nil)
    }

    @Test("Logging out during refresh cannot restore the old session")
    func logoutDuringRefreshKeepsTokensCleared() async throws {
        let store = MockTokenStore(accessToken: "old", refreshToken: "old-refresh")
        let refresh = ControlledRefreshService()
        let client = NetworkClient(tokenStore: store, refreshService: refresh)
        let operation = Task { try await client.forceRefreshToken() }

        await refresh.waitUntilStarted()
        let logout = Task { try await client.logoutReturningRefreshToken() }
        await Task.yield()
        await refresh.complete(TokenPair(accessToken: "new", refreshToken: "new-refresh"))
        _ = try? await operation.value
        #expect(try await logout.value == "new-refresh")

        #expect(await store.getAccessToken() == nil)
        #expect(await store.getRefreshToken() == nil)
    }

    @Test("Concurrent logout callers receive the same drained refresh token")
    func concurrentLogoutSharesToken() async throws {
        let store = SuspendedTokenStore()
        let resetter = ResetRecorder()
        let client = NetworkClient(
            tokenStore: store,
            refreshService: MockTokenRefreshService(
                behavior: .success(TokenPair(accessToken: "new", refreshToken: "new-refresh"))
            ),
            sessionResetter: resetter
        )
        let refresh = Task { try await client.forceRefreshToken() }
        await store.waitUntilSaveStarted()
        let first = Task { try await client.logoutReturningRefreshToken() }
        await store.waitUntilSaveCancelled()
        let second = Task { try await client.logoutReturningRefreshToken() }
        // Let the second actor call join the logout suspended on token persistence.
        try await Task.sleep(for: .milliseconds(20))
        await store.completeSave()
        #expect(try await first.value == "new-refresh")
        #expect(try await second.value == "new-refresh")
        _ = try? await refresh.value
        #expect(await resetter.resetCount == 1)
    }

    @Test("Failed credential cleanup never returns a token or resets the session")
    func failedClearDoesNotReturnToken() async throws {
        let store = FailingClearTokenStore()
        let resetter = ResetRecorder()
        let client = NetworkClient(
            tokenStore: store,
            refreshService: MockTokenRefreshService(behavior: .failure(.invalidRefreshToken)),
            sessionResetter: resetter
        )
        await #expect(throws: ClearFailure.denied) {
            _ = try await client.logoutReturningRefreshToken()
        }
        #expect(await store.getRefreshToken() == "old-refresh")
        #expect(await resetter.resetCount == 0)
    }

    @Test("A rotated token survives persistence failure for remote revocation")
    func issuedTokenSurvivesSaveFailure() async throws {
        let store = FailingSaveTokenStore()
        let client = NetworkClient(
            tokenStore: store,
            refreshService: MockTokenRefreshService(
                behavior: .success(TokenPair(accessToken: "new", refreshToken: "new-refresh"))
            )
        )
        await #expect(throws: ClearFailure.denied) { _ = try await client.forceRefreshToken() }
        #expect(try await client.logoutReturningRefreshToken() == "new-refresh")
        #expect(await store.getRefreshToken() == nil)
    }

    @Test("An invalid empty rotation does not replace the existing revocation token")
    func emptyRotationKeepsExistingToken() async throws {
        let store = MockTokenStore(accessToken: "old", refreshToken: "old-refresh")
        let client = NetworkClient(
            tokenStore: store,
            refreshService: MockTokenRefreshService(
                behavior: .success(TokenPair(accessToken: "new", refreshToken: ""))
            )
        )
        await #expect(throws: UMCFoundation.NetworkError.invalidResponse) {
            _ = try await client.forceRefreshToken()
        }
        #expect(try await client.logoutReturningRefreshToken() == "old-refresh")
    }

    @Test("App-owned session cleanup is invoked on logout")
    func logoutResetsAppSession() async throws {
        let resetter = ResetRecorder()
        let client = NetworkClient(
            tokenStore: MockTokenStore(),
            refreshService: MockTokenRefreshService(behavior: .failure(.invalidRefreshToken)),
            sessionResetter: resetter
        )
        try await client.logout()
        #expect(await resetter.resetCount == 1)
    }
}

/// Deliberately ignores cancellation while persisting, as an asynchronous store may do.
private actor SuspendedTokenStore: TokenStore {
    private var accessToken: String? = "old"
    private var refreshToken: String? = "old-refresh"
    private var saveContinuation: CheckedContinuation<Void, Never>?
    private var startContinuation: CheckedContinuation<Void, Never>?
    private var cancellationContinuation: CheckedContinuation<Void, Never>?
    private var cancelled = false

    func getAccessToken() -> String? { accessToken }
    func getRefreshToken() -> String? { refreshToken }

    func save(accessToken: String, refreshToken: String) async throws {
        await withTaskCancellationHandler {
            await withCheckedContinuation { continuation in
                saveContinuation = continuation
                startContinuation?.resume()
                startContinuation = nil
            }
        } onCancel: {
            Task { await self.recordCancellation() }
        }
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }

    func clear() {
        accessToken = nil
        refreshToken = nil
    }

    func waitUntilSaveStarted() async {
        guard saveContinuation == nil else { return }
        await withCheckedContinuation { startContinuation = $0 }
    }

    func waitUntilSaveCancelled() async {
        guard !cancelled else { return }
        await withCheckedContinuation { cancellationContinuation = $0 }
    }

    func completeSave() {
        saveContinuation?.resume()
        saveContinuation = nil
    }

    private func recordCancellation() {
        cancelled = true
        cancellationContinuation?.resume()
        cancellationContinuation = nil
    }
}

private actor ResetRecorder: SessionResetting {
    private(set) var resetCount = 0

    func resetSession() {
        resetCount += 1
    }
}

private actor ControlledRefreshService: TokenRefreshService {
    private var continuation: CheckedContinuation<TokenPair, Error>?
    private var waitingForStart: [CheckedContinuation<Void, Never>] = []

    func refresh(_ refreshToken: String) async throws -> TokenPair {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                self.continuation = continuation
                waitingForStart.forEach { $0.resume() }
                waitingForStart.removeAll()
            }
        } onCancel: {
            Task { await self.cancel() }
        }
    }

    func waitUntilStarted() async {
        guard continuation == nil else { return }
        await withCheckedContinuation { waitingForStart.append($0) }
    }

    func complete(_ pair: TokenPair) {
        continuation?.resume(returning: pair)
        continuation = nil
    }

    private func cancel() {
        continuation?.resume(throwing: CancellationError())
        continuation = nil
    }
}

private enum ClearFailure: Error { case denied }

private actor FailingClearTokenStore: TokenStore {
    func getAccessToken() async -> String? { "old" }
    func getRefreshToken() async -> String? { "old-refresh" }
    func save(accessToken: String, refreshToken: String) async throws {}
    func clear() async throws { throw ClearFailure.denied }
}

private actor FailingSaveTokenStore: TokenStore {
    private var cleared = false
    func getAccessToken() async -> String? { cleared ? nil : "old" }
    func getRefreshToken() async -> String? { cleared ? nil : "old-refresh" }
    func save(accessToken: String, refreshToken: String) async throws { throw ClearFailure.denied }
    func clear() async throws { cleared = true }
}
