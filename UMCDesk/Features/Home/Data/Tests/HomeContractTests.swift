//  HomeContractTests.swift
//  HomeDataTests
//
//  Created by euijjang97 on 11/23/26.
//

import CoreNetwork
import Foundation
import Testing

@testable import HomeData

@Test func profileReadsNumericAndStringIdentifiers() throws {
    for id in ["123", "\"123\""] {
        let data = Data("{\"id\":\(id),\"nickname\":\"테스트\"}".utf8)
        let profile = try JSONDecoder().decode(ProfileDTO.self, from: data)
        #expect(profile.id == "123")
        #expect(profile.nickname == "테스트")
    }
}

@Test func noticePageRequiresServerContentField() throws {
    let data = Data(#"{"content":[{"title":"합성 공지"}]}"#.utf8)
    let page = try JSONDecoder().decode(PageDTO<NoticeDTO>.self, from: data)
    #expect(page.content.first?.title == "합성 공지")
}

private actor HomeFixtureStore: TokenStore {
    func getAccessToken() async -> String? { "synthetic-access" }
    func getRefreshToken() async -> String? { "synthetic-refresh" }
    func save(accessToken: String, refreshToken: String) async throws {}
    func clear() async throws {}
}

private final class HomeContractTransport: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url, request.httpMethod == "GET",
            request.value(forHTTPHeaderField: "Authorization") == "Bearer synthetic-access"
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.userAuthenticationRequired))
            return
        }
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let result: String
        switch url.path {
        case "/api/v1/member/me": result = #"{"id":101,"nickname":"합성 회원"}"#
        case "/api/v1/gisu/active": result = #"{"gisuId":10}"#
        case "/api/v2/schedules/me":
            // The server includes ongoing events when the requested interval starts now.
            guard let from = query.first(where: { $0.name == "from" })?.value,
                let lowerBound = try? Date.ISO8601FormatStyle().parse(from),
                abs(lowerBound.timeIntervalSinceNow) < 10
            else {
                client?.urlProtocol(self, didFailWithError: URLError(.badURL))
                return
            }
            result =
                query.contains(URLQueryItem(name: "isAttendanceRequired", value: "true"))
                ? #"[{"name":"합성 발표","startsAt":"2026-11-01T08:00:00Z"}]"# : "[]"
        case "/api/v1/notices"
        where query.contains(URLQueryItem(name: "noticeTab", value: "CHALLENGER"))
            && query.contains(URLQueryItem(name: "gisuId", value: "10")):
            result = #"{"content":[{"title":"합성 공지"}]}"#
        case "/api/v1/projects/me/managed"
        where query.contains(URLQueryItem(name: "gisuId", value: "10")):
            result = #"{"content":[{"name":"합성 프로젝트"}]}"#
        default:
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let response = HTTPURLResponse(
            url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("{\"success\":true,\"result\":\(result)}".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

@Test func homeCardsReadAuthenticatedCurrentMemberData() async throws {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [HomeContractTransport.self]
    let baseURL = try #require(URL(string: "https://fixture.example.test"))
    let client = AuthSystemFactory.makeNetworkClient(
        environment: NetworkEnvironment(baseURL: baseURL), tokenStore: HomeFixtureStore(),
        session: URLSession(configuration: configuration))
    let home = LiveHomeRepository(client: client, baseURL: baseURL)
    #expect(try await home.profile().nickname == "합성 회원")
    #expect(try await home.schedule() == "합성 발표")
    #expect(try await home.notice() == "합성 공지")
    #expect(try await home.project() == "합성 프로젝트")
}
