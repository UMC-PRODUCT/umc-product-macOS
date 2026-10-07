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
        let logout = Task { try await client.logout() }
        await store.waitUntilSaveCancelled()
        await #expect(throws: CancellationError.self) { try await client.forceRefreshToken() }
        await store.completeSave()
        try await logout.value
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
        try await client.logout()
        await refresh.complete(TokenPair(accessToken: "new", refreshToken: "new-refresh"))
        _ = try? await operation.value

        #expect(await store.getAccessToken() == nil)
        #expect(await store.getRefreshToken() == nil)
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
