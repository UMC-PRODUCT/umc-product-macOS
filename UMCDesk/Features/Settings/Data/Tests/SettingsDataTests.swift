//
//  SettingsDataTests.swift
//  SettingsDataTests
//
//  Created by euijjang97 on 10/20/26.
//

import CoreNetwork
import Foundation
import SettingsDomain
import Testing
import UMCFoundation
@testable import SettingsData

@Suite("Settings server contract")
struct SettingsDataTests {
    @Test("Numeric identifiers and nullable activity roles join top-level roles")
    func decodesProfile() throws {
        let data = Data("""
        {"id":42,"name":"홍길동","nickname":"제옹","email":null,"schoolName":null,
         "profileImageLink":"javascript:alert(1)","profile":{"github":null},
         "challengerRecords":[{"challengerId":"7","gisuId":3,"gisu":"10",
         "part":"NEW_FUTURE_PART","roles":null}],
         "roles":[{"challengerId":7,"gisuId":"3","gisu":10,"roleType":"FUTURE_ROLE"}]}
        """.utf8)
        let response = try JSONDecoder().decode(SettingsMemberResponse.self, from: data)
        let profile = response.toDomain()
        #expect(profile.id == "42")
        #expect(profile.profileImageURL == nil)
        #expect(profile.links.github.isEmpty)
        #expect(profile.activities == [
            .init(id: "7", generation: "10", part: "NEW_FUTURE_PART", roles: ["FUTURE_ROLE"])
        ])
        #expect(try JSONDecoder().decode(
            SettingsMemberResponse.self, from: JSONEncoder().encode(response)
        ).toDomain() == profile)
    }

    @Test("Replace-all body sends all nonempty links and empty list deletes all")
    func encodesCompleteLinks() throws {
        let body = SettingsLinksRequest(links: .init(
            github: "https://github.com/umc", personal: "https://umc.example.com"
        ))
        let json = try #require(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(body)
        ) as? [String: [[String: String]]])
        #expect(json["links"] == [
            ["type": "GITHUB", "link": "https://github.com/umc"],
            ["type": "PERSONAL", "link": "https://umc.example.com"]
        ])
        let empty = try #require(JSONSerialization.jsonObject(
            with: JSONEncoder().encode(SettingsLinksRequest(links: .init()))
        ) as? [String: [[String: String]]])
        #expect(empty["links"] == [])
    }
}

@Suite("Settings transport", .serialized)
@MainActor
struct SettingsTransportTests {
    @Test("Remote logout failure still clears local tokens and reports the distinction")
    func logoutFailureClearsLocalSession() async throws {
        let store = SettingsTestTokenStore()
        let repository = makeRepository(store: store)
        SettingsURLProtocol.state.setResponse(status: 503, data: Data())
        await #expect(throws: SettingsError.serverLogoutFailed) {
            try await repository.logout()
        }
        #expect(await store.getAccessToken() == nil)
        let request = try #require(SettingsURLProtocol.state.lastRequest)
        #expect(request.url?.path == "/api/v1/auth/logout")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test("Keychain cleanup failure is never reported as successful logout")
    func logoutLocalFailurePropagates() async throws {
        let store = SettingsTestTokenStore(failsClearing: true)
        let repository = makeRepository(store: store)
        SettingsURLProtocol.state.setResponse(
            status: 200, data: Data("{\"success\":true,\"result\":null}".utf8)
        )
        await #expect(throws: SettingsTestFailure.localCleanup) {
            try await repository.logout()
        }
        #expect(await store.getAccessToken() != nil)
    }

    @Test("Unauthenticated profile load never calls the server")
    func avoidsUnauthenticatedRequest() async throws {
        let store = SettingsTestTokenStore()
        try await store.clear()
        let repository = makeRepository(store: store)
        SettingsURLProtocol.state.resetRequest()
        await #expect(throws: SettingsError.authenticationRequired) {
            _ = try await repository.fetchProfile()
        }
        #expect(SettingsURLProtocol.state.lastRequest == nil)
    }

    @Test("Terminal refresh failure clears tokens and resets the shared session")
    func terminalAuthenticationClearsSession() async throws {
        let store = SettingsTestTokenStore(refreshToken: nil)
        let resetter = SettingsResetRecorder()
        let repository = makeRepository(store: store, resetter: resetter)
        SettingsURLProtocol.state.setResponse(status: 401, data: Data())
        await #expect(throws: SettingsError.authenticationRequired) {
            _ = try await repository.fetchProfile()
        }
        #expect(await store.getAccessToken() == nil)
        #expect(await resetter.count == 1)
    }

    @Test("Terminal session cleanup failure is propagated")
    func terminalCleanupFailurePropagates() async throws {
        let store = SettingsTestTokenStore(failsClearing: true, refreshToken: nil)
        let repository = makeRepository(store: store)
        SettingsURLProtocol.state.setResponse(status: 401, data: Data())
        await #expect(throws: SettingsTestFailure.localCleanup) {
            _ = try await repository.fetchProfile()
        }
    }

    @Test("A second unauthorized response follows the shared retry policy")
    func repeatedUnauthorizedPreservesSessionPolicy() async throws {
        let store = SettingsTestTokenStore()
        let repository = makeRepository(store: store, refreshService: SettingsSuccessfulRefresh())
        SettingsURLProtocol.state.setResponse(status: 401, data: Data())
        await #expect(throws: UMCFoundation.NetworkError.maxRetryExceeded) {
            _ = try await repository.fetchProfile()
        }
        #expect(await store.getAccessToken() == "new-access")
    }

    @Test("Challenger rejection preserves the server's specific guidance")
    func preservesChallengerRejection() async throws {
        let repository = makeRepository(store: SettingsTestTokenStore())
        SettingsURLProtocol.state.setResponse(status: 400, data: Data("""
        {"success":false,"code":"CHALLENGER-0014","message":"학교가 일치하지 않습니다."}
        """.utf8))
        do {
            try await repository.registerChallenger(code: "A7B2C9")
            Issue.record("The rejected code unexpectedly succeeded")
        } catch let error as RepositoryError {
            #expect(error.code == "CHALLENGER-0014")
            #expect(error.userMessage == "학교가 일치하지 않습니다.")
        }
    }

    @Test("Release lookup distinguishes unpublished, valid and unsafe release URLs")
    func verifiesReleaseURLs() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [SettingsURLProtocol.self]
        let actions = MacSettingsSystemActions(session: URLSession(configuration: configuration))
        SettingsURLProtocol.state.setResponse(status: 404, data: Data())
        #expect(try await actions.latestRelease() == nil)
        SettingsURLProtocol.state.setResponse(status: 200, data: Data("""
        {"tag_name":"v0.0.1","html_url":
        "https://github.com/UMC-PRODUCT/umc-product-macOS/releases/tag/v0.0.1"}
        """.utf8))
        #expect(try await actions.latestRelease()?.tag == "v0.0.1")
        SettingsURLProtocol.state.setResponse(status: 200, data: Data("""
        {"tag_name":"unsafe","html_url":"https://attacker.test/releases/tag/unsafe"}
        """.utf8))
        await #expect(throws: URLError.self) { _ = try await actions.latestRelease() }
    }

    @MainActor
    private func makeRepository(
        store: SettingsTestTokenStore,
        refreshService: any TokenRefreshService = SettingsTestRefresh(),
        resetter: (any SessionResetting)? = nil
    ) -> LiveSettingsRepository {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [SettingsURLProtocol.self]
        let client = NetworkClient(
            session: URLSession(configuration: configuration), tokenStore: store,
            refreshService: refreshService, sessionResetter: resetter
        )
        return LiveSettingsRepository(
            adapter: MoyaNetworkAdapter(networkClient: client), client: client,
            environment: NetworkEnvironment(baseURL: URL(string: "https://api.umc.test")!)
        )
    }
}

private enum SettingsTestFailure: Error { case localCleanup }

private actor SettingsTestTokenStore: TokenStore {
    private var accessToken: String? = "access"
    private var refreshToken: String? = "refresh"
    let failsClearing: Bool

    init(failsClearing: Bool = false, refreshToken: String? = "refresh") {
        self.failsClearing = failsClearing
        self.refreshToken = refreshToken
    }
    func getAccessToken() async -> String? { accessToken }
    func getRefreshToken() async -> String? { refreshToken }
    func save(accessToken: String, refreshToken: String) async throws {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
    func clear() async throws {
        if failsClearing { throw SettingsTestFailure.localCleanup }
        accessToken = nil
        refreshToken = nil
    }
}

private actor SettingsResetRecorder: SessionResetting {
    private(set) var count = 0
    func resetSession() async { count += 1 }
}

private struct SettingsSuccessfulRefresh: TokenRefreshService {
    func refresh(_ refreshToken: String) async throws -> TokenPair {
        TokenPair(accessToken: "new-access", refreshToken: "new-refresh")
    }
}

private struct SettingsTestRefresh: TokenRefreshService {
    func refresh(_ refreshToken: String) async throws -> TokenPair {
        throw SettingsTestFailure.localCleanup
    }
}

private final class SettingsURLProtocol: URLProtocol, @unchecked Sendable {
    static let state = SettingsRequestState()
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let (status, data) = Self.state.record(request)
        let response = HTTPURLResponse(
            url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

private final class SettingsRequestState: @unchecked Sendable {
    private let lock = NSLock()
    private var status = 200
    private var data = Data()
    private var request: URLRequest?
    var lastRequest: URLRequest? {
        lock.lock()
        defer { lock.unlock() }
        return request
    }
    func setResponse(status: Int, data: Data) {
        lock.lock()
        defer { lock.unlock() }
        self.status = status
        self.data = data
        request = nil
    }
    func resetRequest() {
        lock.lock()
        defer { lock.unlock() }
        request = nil
    }
    func record(_ request: URLRequest) -> (Int, Data) {
        lock.lock()
        defer { lock.unlock() }
        self.request = request
        return (status, data)
    }
}
