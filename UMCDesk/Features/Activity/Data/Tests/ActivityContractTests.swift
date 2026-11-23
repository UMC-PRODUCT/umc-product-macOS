//  ActivityContractTests.swift
//  ActivityDataTests
//
//  Created by euijjang97 on 11/23/26.
//

import CoreNetwork
import Foundation
import Testing

@testable import ActivityData

@Test func scheduleAcceptsNullablePolicyAndFlexibleIdentifier() throws {
    let data = Data(
        """
        {"scheduleId":123,"name":"합성 일정","startsAt":"2026-01-01T00:00:00Z",
         "endsAt":"2026-01-01T01:00:00Z","isOnline":true,"isParticipant":true,
         "location":null,"attendancePolicy":null,"attendanceStatus":null}
        """.utf8)
    let schedule = try JSONDecoder().decode(ScheduleDTO.self, from: data)
    #expect(schedule.scheduleId == "123")
    #expect(schedule.attendancePolicy == nil)
    #expect(schedule.attendanceStatus == nil)
    let encoded = try JSONEncoder().encode(schedule)
    let restored = try JSONDecoder().decode(ScheduleDTO.self, from: encoded)
    #expect(restored.isOnline)
}

@Test func reviewDistinguishesPendingAndMissingAttendance() throws {
    let data = Data(
        """
        {"scheduleId":"701","name":"합성 일정","participants":[
          {"memberId":101,"name":"첫 챌린저","attendanceStatus":"EXCUSED_PENDING","excuseReason":"합성 사유"},
          {"memberId":"102","name":"둘째 챌린저","attendanceStatus":null,"excuseReason":null}]}
        """.utf8)
    let review = try JSONDecoder().decode(ReviewDTO.self, from: data)
    #expect(review.participants[0].excuseReason == "합성 사유")
    #expect(review.participants[1].attendanceStatus == nil)
}

private actor FixtureTokenStore: TokenStore {
    func getAccessToken() async -> String? { "synthetic-access" }
    func getRefreshToken() async -> String? { "synthetic-refresh" }
    func save(accessToken: String, refreshToken: String) async throws {}
    func clear() async throws {}
}

private final class ActivityContractTransport: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url,
            request.value(forHTTPHeaderField: "Authorization") == "Bearer synthetic-access"
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.userAuthenticationRequired))
            return
        }
        let result: String
        switch (request.httpMethod, url.path) {
        case ("GET", "/api/v2/schedules/me"):
            let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
            guard items.contains(URLQueryItem(name: "isAttendanceRequired", value: "true")),
                items.contains(where: { $0.name == "from" }),
                items.contains(where: { $0.name == "to" })
            else {
                client?.urlProtocol(self, didFailWithError: URLError(.badURL))
                return
            }
            result = """
                [{"scheduleId":701,"name":"합성 일정","startsAt":"2026-11-01T08:10:05.123456Z",
                  "endsAt":"2026-11-01T09:00:00Z","isOnline":true,"isParticipant":true}]
                """
        case ("POST", "/api/v2/schedules/701/attendances/request"):
            result = #"{"status":"PRESENT_PENDING"}"#
        case ("POST", "/api/v2/schedules/701/attendances/excuse"):
            result = #"{"status":"EXCUSED_PENDING"}"#
        case ("POST", "/api/v2/schedules/701/attendances/decide"):
            result = #"[{"status":"PRESENT"}]"#
        default:
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
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

@Test func authenticatedScheduleAndAttendanceRequestsUseServerRoutes() async throws {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [ActivityContractTransport.self]
    let baseURL = try #require(URL(string: "https://fixture.example.test"))
    let client = AuthSystemFactory.makeNetworkClient(
        environment: NetworkEnvironment(baseURL: baseURL), tokenStore: FixtureTokenStore(),
        session: URLSession(configuration: configuration)
    )
    let repository = LiveActivityRepository(client: client, baseURL: baseURL)
    let rows = try await repository.schedules()
    #expect(rows.first?.id == "701")
    let item = try #require(rows.first)
    #expect(abs(item.startsAt.timeIntervalSince1970 - 1793520605.123456) < 0.001)
    let status = try await repository.attend(scheduleID: "701", reason: nil, coordinate: nil)
    #expect(status == "PRESENT_PENDING")
    let excuse = try await repository.attend(scheduleID: "701", reason: "합성 사유", coordinate: nil)
    #expect(excuse == "EXCUSED_PENDING")
    try await repository.decide(scheduleID: "701", memberID: "101", approve: true)
}
