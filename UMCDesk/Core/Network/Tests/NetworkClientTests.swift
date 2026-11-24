//
//  NetworkClientTests.swift
//  CoreNetworkTests
//
//  Created by euijjang97 on 10/6/26.
//

import Foundation
import Testing
import Moya
import UMCFoundation
@testable import CoreNetwork

@Suite("NetworkClient", .serialized)
@MainActor
struct NetworkClientTests {

    // MARK: - Fixtures

    private let testURL = URL(string: "https://api.umc.test/api/v1/me")!

    private func makeClient(
        store: MockTokenStore,
        refresh: MockTokenRefreshService,
        maxRetryCount: Int = 1
    ) -> NetworkClient {
        StubURLProtocol.reset()
        let session = makeStubSession()
        return NetworkClient(
            session: session,
            tokenStore: store,
            refreshService: refresh,
            authPolicy: DefaultAuthenticationPolicy(),
            maxRetryCount: maxRetryCount
        )
    }

    // MARK: - isLoggedIn / logout

    @Test("토큰이 있으면 isLoggedIn이 true다")
    func isLoggedInTrue() async {
        let store = MockTokenStore(accessToken: "A", refreshToken: "R")
        let refresh = MockTokenRefreshService(behavior: .success(TokenPair(accessToken: "A", refreshToken: "R")))
        let client = makeClient(store: store, refresh: refresh)

        let loggedIn = await client.isLoggedIn()
        #expect(loggedIn)
    }

    @Test("토큰이 없으면 isLoggedIn이 false다")
    func isLoggedInFalse() async {
        let store = MockTokenStore()
        let refresh = MockTokenRefreshService(behavior: .success(TokenPair(accessToken: "A", refreshToken: "R")))
        let client = makeClient(store: store, refresh: refresh)

        let loggedIn = await client.isLoggedIn()
        #expect(!loggedIn)
    }

    @Test("logout 호출 시 tokenStore.clear()가 1회 호출된다")
    func logoutClearsTokens() async throws {
        let store = MockTokenStore(accessToken: "A", refreshToken: "R")
        let refresh = MockTokenRefreshService(behavior: .success(TokenPair(accessToken: "A", refreshToken: "R")))
        let client = makeClient(store: store, refresh: refresh)

        try await client.logout()

        let clearCount = await store.clearCallCount
        let access = await store.accessToken
        #expect(clearCount == 1)
        #expect(access == nil)
    }

    // MARK: - request: Authorization 주입

    @Test("인증 정책이 true이고 액세스 토큰이 있으면 Authorization 헤더가 주입된다")
    func injectsAuthorizationHeader() async throws {
        let store = MockTokenStore(accessToken: "ACCESS123", refreshToken: "R")
        let refresh = MockTokenRefreshService(behavior: .success(TokenPair(accessToken: "A", refreshToken: "R")))
        let client = makeClient(store: store, refresh: refresh)

        StubURLProtocol.handler = { _ in (Data("{}".utf8), 200, nil) }

        let request = URLRequest(url: testURL)
        _ = try await client.request(request)

        let captured = try #require(StubURLProtocol.capturedRequests.first)
        #expect(captured.value(forHTTPHeaderField: "Authorization") == "Bearer ACCESS123")
    }

    // MARK: - 401 → refresh → retry

    @Test("401 응답 시 refresh 후 새 액세스 토큰으로 재시도하고 200을 반환한다")
    func refreshOn401AndRetry() async throws {
        let store = MockTokenStore(accessToken: "OLD", refreshToken: "REFRESH")
        let refresh = MockTokenRefreshService(
            behavior: .success(TokenPair(accessToken: "NEW", refreshToken: "NEW_R"))
        )
        let client = makeClient(store: store, refresh: refresh)

        // 1번째 호출: 401, 2번째 호출(refresh 후): 200
        let callCount = LockedCounter()
        StubURLProtocol.handler = { _ in
            let n = callCount.increment()
            if n == 1 {
                return (Data(), 401, nil)
            } else {
                return (Data("{\"ok\":true}".utf8), 200, nil)
            }
        }

        let request = URLRequest(url: testURL)
        let (data, response) = try await client.request(request)

        #expect(response.statusCode == 200)
        #expect(String(data: data, encoding: .utf8) == "{\"ok\":true}")

        let refreshCalls = await refresh.callCount
        #expect(refreshCalls == 1)

        let stored = await store.accessToken
        #expect(stored == "NEW")

        // 두 번째 요청에서 새 토큰이 헤더에 들어가야 한다
        let secondRequest = StubURLProtocol.capturedRequests[1]
        #expect(secondRequest.value(forHTTPHeaderField: "Authorization") == "Bearer NEW")
    }

    @Test("401이 재시도 후에도 다시 발생하면 maxRetryExceeded를 throw한다")
    func maxRetryExceededAfterRetry() async {
        let store = MockTokenStore(accessToken: "OLD", refreshToken: "REFRESH")
        let refresh = MockTokenRefreshService(
            behavior: .success(TokenPair(accessToken: "NEW", refreshToken: "NEW_R"))
        )
        let client = makeClient(store: store, refresh: refresh, maxRetryCount: 1)

        StubURLProtocol.handler = { _ in (Data(), 401, nil) }

        await #expect(throws: NetworkError.maxRetryExceeded) {
            _ = try await client.request(URLRequest(url: self.testURL))
        }
    }

    @Test("갱신 중 알 수 없는 오류를 세션 만료로 변환하지 않는다")
    func refreshFailureWraps() async {
        let store = MockTokenStore(accessToken: "OLD", refreshToken: "REFRESH")
        let refresh = MockTokenRefreshService(behavior: .failure(.invalidRefreshToken))
        let client = makeClient(store: store, refresh: refresh)

        StubURLProtocol.handler = { _ in (Data(), 401, nil) }

        await #expect(throws: MockRefreshError.invalidRefreshToken) {
            _ = try await client.request(URLRequest(url: self.testURL))
        }
    }

    @Test("갱신 중 네트워크가 끊기면 noNetwork를 throw하고 저장된 토큰은 유지한다")
    func transportFailureKeepsSession() async {
        let store = MockTokenStore(accessToken: "OLD", refreshToken: "REFRESH")
        let refresh = MockTokenRefreshService(
            behavior: .transportFailure(URLError(.notConnectedToInternet))
        )
        let client = makeClient(store: store, refresh: refresh)

        StubURLProtocol.handler = { _ in (Data(), 401, nil) }

        await #expect(throws: NetworkError.noNetwork) {
            _ = try await client.request(URLRequest(url: self.testURL))
        }

        let clearCount = await store.clearCallCount
        let refreshToken = await store.refreshToken
        #expect(clearCount == 0)
        #expect(refreshToken == "REFRESH")
    }

    @Test("갱신 요청이 타임아웃되면 timeout을 throw한다")
    func transportTimeoutIsNotSessionExpiry() async {
        let store = MockTokenStore(accessToken: "OLD", refreshToken: "REFRESH")
        let refresh = MockTokenRefreshService(behavior: .transportFailure(URLError(.timedOut)))
        let client = makeClient(store: store, refresh: refresh)

        StubURLProtocol.handler = { _ in (Data(), 401, nil) }

        await #expect(throws: NetworkError.timeout) {
            _ = try await client.request(URLRequest(url: self.testURL))
        }
    }

    @Test("서버가 리프레시 토큰을 거부하면 tokenRefreshFailed를 throw한다", arguments: [401, 403])
    func serverRejectionBecomesTokenRefreshFailed(statusCode: Int) async {
        let store = MockTokenStore(accessToken: "OLD", refreshToken: "REFRESH")
        let refresh = MockTokenRefreshService(behavior: .rejectedByServer(statusCode: statusCode))
        let client = makeClient(store: store, refresh: refresh)

        StubURLProtocol.handler = { _ in (Data(), 401, nil) }

        await #expect(
            throws: NetworkError.tokenRefreshFailed(reason: "서버 에러 (status: \(statusCode))")
        ) {
            _ = try await client.request(URLRequest(url: self.testURL))
        }
    }

    @Test("갱신 API가 5xx면 세션 만료가 아니라 requestFailed로 전파된다")
    func serverOutageIsNotSessionExpiry() async {
        let store = MockTokenStore(accessToken: "OLD", refreshToken: "REFRESH")
        let refresh = MockTokenRefreshService(behavior: .rejectedByServer(statusCode: 503))
        let client = makeClient(store: store, refresh: refresh)

        StubURLProtocol.handler = { _ in (Data(), 401, nil) }

        await #expect(throws: NetworkError.requestFailed(statusCode: 503, data: nil)) {
            _ = try await client.request(URLRequest(url: self.testURL))
        }
    }

    @Test("리프레시 토큰이 없으면 NetworkError.noRefreshToken을 throw한다")
    func noRefreshTokenError() async {
        let store = MockTokenStore(accessToken: "OLD", refreshToken: nil)
        let refresh = MockTokenRefreshService(
            behavior: .success(TokenPair(accessToken: "NEW", refreshToken: "NEW_R"))
        )
        let client = makeClient(store: store, refresh: refresh)

        StubURLProtocol.handler = { _ in (Data(), 401, nil) }

        await #expect(throws: NetworkError.self) {
            _ = try await client.request(URLRequest(url: self.testURL))
        }
    }

    // MARK: - Single-flight refresh

    @Test("동시 다발적 401에서도 토큰 갱신은 단 1회만 실행된다 (single-flight)")
    func singleFlightRefresh() async throws {
        let store = MockTokenStore(accessToken: "OLD", refreshToken: "REFRESH")
        let refresh = MockTokenRefreshService(
            behavior: .delayedSuccess(
                TokenPair(accessToken: "NEW", refreshToken: "NEW_R"),
                nanoseconds: 80_000_000  // 80ms
            )
        )
        let client = makeClient(store: store, refresh: refresh)

        // 첫 요청은 401, 이후엔 200
        let callCount = LockedCounter()
        StubURLProtocol.handler = { _ in
            let n = callCount.increment()
            if n <= 5 { // 처음 5개의 동시 요청은 모두 401
                return (Data(), 401, nil)
            } else {
                return (Data("{}".utf8), 200, nil)
            }
        }

        async let r1 = client.request(URLRequest(url: testURL))
        async let r2 = client.request(URLRequest(url: testURL))
        async let r3 = client.request(URLRequest(url: testURL))
        async let r4 = client.request(URLRequest(url: testURL))
        async let r5 = client.request(URLRequest(url: testURL))

        let results = try await [r1, r2, r3, r4, r5]
        #expect(results.allSatisfy { $0.1.statusCode == 200 })

        let refreshCalls = await refresh.callCount
        #expect(refreshCalls == 1, "동시 401에도 refresh는 1회만 호출되어야 한다 — 실제: \(refreshCalls)")
    }

    // MARK: - forceRefreshToken

    @Test("forceRefreshToken은 새 토큰 쌍을 저장하고 반환한다")
    func forceRefreshSavesAndReturns() async throws {
        let store = MockTokenStore(accessToken: "OLD", refreshToken: "REFRESH")
        let newPair = TokenPair(accessToken: "NEW_A", refreshToken: "NEW_R")
        let refresh = MockTokenRefreshService(behavior: .success(newPair))
        let client = makeClient(store: store, refresh: refresh)

        let result = try await client.forceRefreshToken()

        #expect(result == newPair)

        let savedAccess = await store.accessToken
        let savedRefresh = await store.refreshToken
        #expect(savedAccess == "NEW_A")
        #expect(savedRefresh == "NEW_R")
    }

    // MARK: - Decodable overload

    @Test("Decodable 오버로드는 응답 JSON을 자동 디코딩한다")
    func decodableOverloadDecodes() async throws {
        let store = MockTokenStore(accessToken: "A", refreshToken: "R")
        let refresh = MockTokenRefreshService(behavior: .success(TokenPair(accessToken: "A", refreshToken: "R")))
        let client = makeClient(store: store, refresh: refresh)

        StubURLProtocol.handler = { _ in
            (Data("{\"id\":7,\"name\":\"jeong\"}".utf8), 200, nil)
        }

        let dto: SampleDTO = try await client.request(URLRequest(url: testURL))

        #expect(dto.id == 7)
        #expect(dto.name == "jeong")
    }

    // MARK: - Non-2xx error

    @Test("2xx 외 응답은 NetworkError.requestFailed로 변환된다")
    func nonSuccessStatusCodeFails() async {
        let store = MockTokenStore(accessToken: "A", refreshToken: "R")
        let refresh = MockTokenRefreshService(behavior: .success(TokenPair(accessToken: "A", refreshToken: "R")))
        let client = makeClient(store: store, refresh: refresh)

        StubURLProtocol.handler = { _ in (Data(), 500, nil) }

        await #expect(throws: NetworkError.requestFailed(statusCode: 500, data: nil)) {
            _ = try await client.request(URLRequest(url: self.testURL))
        }
    }

    // MARK: - 계정에 귀속된 클라이언트

    @Test("같은 계정의 401은 갱신된 토큰으로 한 번만 재시도한다",
          arguments: AccountTransport.allCases)
    fileprivate func boundClientRefreshes(transport: AccountTransport) async throws {
        let store = MockTokenStore(accessToken: "first", refreshToken: "first-refresh")
        let refresh = MockTokenRefreshService(behavior: .success(
            TokenPair(accessToken: "rotated", refreshToken: "rotated-refresh")
        ))
        let root = makeClient(store: store, refresh: refresh)
        let bound = try await root.boundToCurrentAccount()
        StubURLProtocol.handler = { request in
            let authorized = request.value(forHTTPHeaderField: "Authorization") == "Bearer rotated"
            return (Data(), authorized ? 200 : 401, nil)
        }

        #expect(try await bound.currentAccessToken() == "first")
        #expect(try await transport.status(using: bound) == 200)
        let rebound = try await bound.boundToCurrentAccount()
        #expect(try await rebound.currentAccessToken() == "rotated")
        #expect(await refresh.receivedRefreshTokens == ["first-refresh"])
        #expect(await store.getRefreshToken() == "rotated-refresh")
        #expect(StubURLProtocol.capturedRequests.map {
            $0.value(forHTTPHeaderField: "Authorization")
        } == ["Bearer first", "Bearer rotated"])
    }

    @Test("계정 전환 후 이전 클라이언트의 진행 중인 응답과 새 요청을 거절한다",
          arguments: AccountTransport.allCases, [200, 401])
    fileprivate func boundClientRejectsPreviousAccount(
        transport: AccountTransport, delayedStatus: Int
    ) async throws {
        let store = MockTokenStore(accessToken: "first", refreshToken: "first-refresh")
        let refresh = MockTokenRefreshService(behavior: .failure(.invalidRefreshToken))
        let root = makeClient(store: store, refresh: refresh)
        let first = try await root.boundToCurrentAccount()

        // Hold only the stubbed transport response. Token operations remain free to finish.
        let (started, signal) = AsyncStream<Void>.makeStream()
        let release = DispatchSemaphore(value: 0)
        StubURLProtocol.handler = { _ in
            signal.yield()
            guard release.wait(timeout: .now() + 5) == .success else { throw URLError(.timedOut) }
            return (Data(), delayedStatus, nil)
        }
        let pending = _Concurrency.Task<Int, Error> {
            defer { signal.finish() }
            return try await transport.status(using: first)
        }
        defer { release.signal() }
        var arrival = started.makeAsyncIterator()
        _ = try #require(await arrival.next())
        try await root.logout()
        await #expect(throws: CancellationError.self) { _ = try await root.boundToCurrentAccount() }
        try await root.signIn { TokenPair(accessToken: "second", refreshToken: "second-refresh") }
        release.signal()

        await #expect(throws: CancellationError.self) { _ = try await pending.value }
        await #expect(throws: CancellationError.self) { _ = try await first.currentAccessToken() }
        await #expect(throws: CancellationError.self) { _ = try await transport.status(using: first) }
        #expect(StubURLProtocol.capturedRequests.map {
            $0.value(forHTTPHeaderField: "Authorization")
        } == ["Bearer first"])
        #expect(await refresh.callCount == 0)

        let second = try await root.boundToCurrentAccount()
        #expect(try await second.currentAccessToken() == "second")
        #expect(await store.getRefreshToken() == "second-refresh")
        #expect(await store.clearCallCount == 1)
        #expect(await store.saveCallCount == 1)
    }

    @Test("설정 요청이 끝나기 전 로그아웃하면 기존 REST 요청과 STOMP 토큰 읽기를 즉시 거절한다")
    func logoutRevokesAccountWhileSettingsRequestDrains() async throws {
        let store = MockTokenStore(accessToken: "first", refreshToken: "first-refresh")
        let refresh = MockTokenRefreshService(behavior: .failure(.invalidRefreshToken))
        let root = makeClient(store: store, refresh: refresh)
        let first = try await root.boundToCurrentAccount()
        let generation = await root.sessionGeneration
        let adapter = MoyaNetworkAdapter(networkClient: root)
        let (started, signal) = AsyncStream<Void>.makeStream()
        let release = DispatchSemaphore(value: 0)
        StubURLProtocol.handler = { _ in
            signal.yield()
            guard release.wait(timeout: .now() + 5) == .success else { throw URLError(.timedOut) }
            return (Data(), 200, nil)
        }
        let settings = _Concurrency.Task {
            defer { signal.finish() }
            let target = AdapterTarget(query: AdapterQuery(search: "profile"))
            return try await adapter.request(target, in: generation).statusCode
        }
        defer { release.signal() }
        var arrival = started.makeAsyncIterator()
        _ = try #require(await arrival.next())
        let logout = _Concurrency.Task { try await root.logoutReturningRefreshToken() }
        while await root.sessionGeneration == generation { await _Concurrency.Task.yield() }

        #expect(await store.getAccessToken() == "first")
        #expect(await first.isLoggedIn() == false)
        await #expect(throws: CancellationError.self) { _ = try await first.currentAccessToken() }
        await #expect(throws: CancellationError.self) { _ = try await root.currentAccessToken() }
        await #expect(throws: CancellationError.self) { _ = try await root.boundToCurrentAccount() }
        for transport in AccountTransport.allCases {
            await #expect(throws: CancellationError.self) {
                _ = try await transport.status(using: first)
            }
        }
        await #expect(throws: CancellationError.self) {
            try await root.signIn { TokenPair(accessToken: "second", refreshToken: "second-refresh") }
        }
        #expect(StubURLProtocol.capturedRequests.count == 1)
        #expect(await store.clearCallCount == 0)

        release.signal()
        #expect(try await settings.value == 200)
        #expect(try await logout.value == "first-refresh")
        try await root.signIn { TokenPair(accessToken: "second", refreshToken: "second-refresh") }
        await #expect(throws: CancellationError.self) { _ = try await first.currentAccessToken() }
        let second = try await root.boundToCurrentAccount()
        #expect(try await second.currentAccessToken() == "second")
    }

    @Test("만료된 클라이언트는 새 계정에 재바인딩하거나 자격 증명을 갱신·삭제할 수 없다")
    func expiredAccountCannotRebind() async throws {
        let store = MockTokenStore(accessToken: "first", refreshToken: "first-refresh")
        let refresh = MockTokenRefreshService(behavior: .failure(.invalidRefreshToken))
        let root = makeClient(store: store, refresh: refresh)
        let first = try await root.boundToCurrentAccount()
        try await root.logout()
        try await root.signIn { TokenPair(accessToken: "second", refreshToken: "second-refresh") }

        await #expect(throws: CancellationError.self) { _ = try await first.boundToCurrentAccount() }
        await #expect(throws: CancellationError.self) { _ = try await first.forceRefreshToken() }
        await #expect(throws: CancellationError.self) { try await first.logout() }
        #expect(await first.isLoggedIn() == false)
        #expect(await refresh.callCount == 0)
        #expect(await store.getAccessToken() == "second")
        #expect(await store.getRefreshToken() == "second-refresh")
    }

    @Test("Adapter query DTO preserves URL encoding and skips authentication")
    func adapterEncodesQueryWithoutAuth() async throws {
        let refresh = MockTokenRefreshService(behavior: .failure(.invalidRefreshToken))
        let client = makeClient(
            store: MockTokenStore(accessToken: "access", refreshToken: "refresh"),
            refresh: refresh
        )
        StubURLProtocol.handler = { _ in (Data("{}".utf8), 200, nil) }
        let adapter = MoyaNetworkAdapter(networkClient: client)
        _ = try await adapter.requestWithoutAuth(
            AdapterTarget(query: AdapterQuery(search: "UMC app & macOS"))
        )
        let request = try #require(StubURLProtocol.capturedRequests.first)
        let url = try #require(request.url)
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        #expect(items?.first(where: { $0.name == "search" })?.value == "UMC app & macOS")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(await refresh.callCount == 0)
    }

    @Test("Unauthenticated 401 does not start token refresh")
    func unauthenticatedFailureDoesNotRefresh() async throws {
        let refresh = MockTokenRefreshService(behavior: .failure(.invalidRefreshToken))
        let client = makeClient(store: MockTokenStore(), refresh: refresh)
        StubURLProtocol.handler = { _ in (Data(), 401, nil) }
        let adapter = MoyaNetworkAdapter(networkClient: client)
        await #expect(throws: NetworkError.requestFailed(statusCode: 401, data: nil)) {
            _ = try await adapter.requestWithoutAuth(AdapterTarget(query: AdapterQuery(search: "")))
        }
        #expect(await refresh.callCount == 0)
    }

    @Test("AuthSystemFactory connects the UMC refresh envelope to Aquila retries")
    func factoryRefreshesUsingUMCContract() async throws {
        StubURLProtocol.reset()
        let store = MockTokenStore(accessToken: "old", refreshToken: "refresh-secret")
        let client = AuthSystemFactory.makeNetworkClient(
            environment: NetworkEnvironment(baseURL: URL(string: "https://api.umc.test")!),
            tokenStore: store,
            session: makeStubSession()
        )
        StubURLProtocol.handler = { request in
            if request.url?.path == "/api/v1/auth/token/renew" {
                return (
                    Data("""
                    {"success":true,"code":"200","result":{
                        "accessToken":"new","refreshToken":"new-refresh"
                    }}
                    """.utf8), 200, nil
                )
            }
            let authenticated = request.value(forHTTPHeaderField: "Authorization") == "Bearer new"
            return (Data("{}".utf8), authenticated ? 200 : 401, nil)
        }

        let (_, response) = try await client.request(URLRequest(url: testURL))
        #expect(response.statusCode == 200)
        #expect(await store.getAccessToken() == "new")
        #expect(await store.getRefreshToken() == "new-refresh")
        let refresh = try #require(StubURLProtocol.capturedRequests.first {
            $0.url?.path == "/api/v1/auth/token/renew"
        })
        #expect(refresh.httpMethod == "POST")
        #expect(refresh.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(refresh.value(forHTTPHeaderField: "Authorization") == nil)
        let body = try requestBody(refresh)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: String])
        #expect(json["refreshToken"] == "refresh-secret")
    }
}

// MARK: - Helpers

private func requestBody(_ request: URLRequest) throws -> Data {
    if let body = request.httpBody { return body }
    let stream = try #require(request.httpBodyStream)
    stream.open()
    defer { stream.close() }
    var result = Data()
    var buffer = [UInt8](repeating: 0, count: 1024)
    while true {
        let count = stream.read(&buffer, maxLength: buffer.count)
        if count == 0 { return result }
        guard count > 0 else { throw stream.streamError ?? URLError(.cannotDecodeRawData) }
        result.append(contentsOf: buffer.prefix(count))
    }
}

private struct SampleDTO: Decodable, Equatable, Sendable {
    let id: Int
    let name: String
}

/// 동기화된 카운터 — handler 클로저가 multiple thread/queue에서 호출될 수 있으므로 락 필요
private final class LockedCounter: @unchecked Sendable {
    private var value = 0
    private let lock = NSLock()

    func increment() -> Int {
        lock.lock(); defer { lock.unlock() }
        value += 1
        return value
    }
}

private struct AdapterQuery {
    let search: String
    var toParameters: [String: Any] { ["search": search] }
}

private struct AdapterTarget: TargetType {
    let query: AdapterQuery
    var baseURL: URL { URL(string: "https://api.umc.test")! }
    var path: String { "/query" }
    var method: Moya.Method { .get }
    var task: Moya.Task {
        .requestParameters(parameters: query.toParameters, encoding: URLEncoding.queryString)
    }
    var headers: [String: String]? { nil }
}

private enum AccountTransport: CaseIterable, Sendable {
    case urlRequest
    case moya

    func status(using client: NetworkClient) async throws -> Int {
        switch self {
        case .urlRequest:
            let url = URL(string: "https://api.umc.test/api/v1/me")!
            return try await client.request(URLRequest(url: url)).1.statusCode
        case .moya:
            let adapter = MoyaNetworkAdapter(networkClient: client)
            return try await adapter.request(AdapterTarget(query: AdapterQuery(search: ""))).statusCode
        }
    }
}
