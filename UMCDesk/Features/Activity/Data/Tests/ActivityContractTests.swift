//  ActivityContractTests.swift
//  ActivityDataTests
//
//  Created by euijjang97 on 11/23/26.
//

import ActivityDomain
import CoreNetwork
import Foundation
import Testing
import XCTest

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
    let repository = LiveActivityRepository(client: client, baseURL: baseURL, memberID: "operator")
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

@Test("동시 지급과 응답 유실 후 재시도는 각 원장에 한 건만 남긴다")
func pointGrantReconciliation() async throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: directory) }
    var root = URL(fileURLWithPath: #filePath)
    for _ in 0..<6 { root.deleteLastPathComponent() }
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
    process.arguments = [
        root.appending(path: "tools/qa/home_activity_fixture.py").path, directory.path,
    ]
    let output = Pipe()
    process.standardOutput = output
    try process.run()
    defer {
        if process.isRunning {
            process.terminate()
            process.waitUntilExit()
        }
    }
    let text = String(decoding: output.fileHandleForReading.availableData, as: UTF8.self)
    let port = try #require(UInt16(text.trimmingCharacters(in: .whitespacesAndNewlines)))
    let url = try #require(URL(string: "http://127.0.0.1:\(port)"))
    let client = AuthSystemFactory.makeNetworkClient(
        environment: NetworkEnvironment(baseURL: url), tokenStore: FixtureTokenStore())
    func makeRepository(_ operatorID: String = "first") -> LiveActivityRepository {
        LiveActivityRepository(
            client: client, baseURL: url, memberID: operatorID, journalDirectory: directory)
    }
    let repository = makeRepository()

    func checkLedger(_ challenger: String, expected: Double, rows: Int = 1) async throws {
        let request = URLRequest(url: url.appending(path: "api/v1/challenger/" + challenger))
        let (data, _) = try await client.request(request)
        let ledger = try JSONDecoder().decode(APIResponse<PointLedgerDTO>.self, from: data)
            .unwrap()
        #expect(ledger.totalPoints == expected)
        #expect(ledger.points.count == rows)
        #expect(ledger.points.map(\.point).reduce(0, +) == expected)
        #expect(ledger.points[0].challengerId == challenger)
    }

    let concurrentID = UUID()
    try await withThrowingTaskGroup(of: Void.self) { group in
        for _ in 0..<8 {
            group.addTask {
                let result = try await repository.grantPoints(
                    operationID: concurrentID, challengerID: "101", value: 3, reason: "합성 동시 지급")
                #expect(result == .recorded)
            }
        }
        try await group.waitForAll()
    }
    try await checkLedger("101", expected: 3)

    try Data().write(to: directory.appending(path: "drop-response"))
    let lostID = UUID()
    // A distinct process sends the POST and exits while the ledger is unavailable.
    let child = Process()
    let testBundle = Bundle(for: PointGrantRestartProcess.self).bundleURL
    child.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
    child.arguments = [
        "xctest", "-XCTest",
        "ActivityDataTests.PointGrantRestartProcess/testCommittedResponseLoss", testBundle.path,
    ]
    var env = [
        "PATH": "/usr/bin:/bin",
        "DYLD_FRAMEWORK_PATH": testBundle.deletingLastPathComponent().path,
    ]
    if let developerDir = ProcessInfo.processInfo.environment["DEVELOPER_DIR"] {
        env["DEVELOPER_DIR"] = developerDir
    }
    env["POINT_TEST_URL"] = url.absoluteString
    env["POINT_TEST_DIRECTORY"] = directory.path
    env["POINT_TEST_ID"] = lostID.uuidString
    child.environment = env
    try child.run()
    child.waitUntilExit()
    #expect(child.terminationStatus == 0)
    let pending = try makeRepository().pendingGrant(challengerID: "102")
    let restored = try #require(pending)
    #expect(restored.id == lostID)
    #expect(restored.reason == "합성 응답 유실")
    #expect(try makeRepository("second").pendingGrant(challengerID: "102") == nil)
    var components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
    components.port = Int(port) == 1 ? 2 : 1
    let isolated = LiveActivityRepository(
        client: client, baseURL: try #require(components.url),
        memberID: "first", journalDirectory: directory)
    #expect(try isolated.pendingGrant(challengerID: "102") == nil)

    func retry() async throws -> PointGrantResult {
        try await makeRepository().grantPoints(
            operationID: lostID, challengerID: "102", value: 7,
            reason: "합성 응답 유실")
    }
    #expect(try await retry() == .awaitingLedger)
    try FileManager.default.removeItem(at: directory.appending(path: "ledger-unavailable"))
    try Data().write(to: directory.appending(path: "stale-ledger"))
    #expect(try await retry() == .awaitingLedger)
    try FileManager.default.removeItem(at: directory.appending(path: "stale-ledger"))
    #expect(try await retry() == .matchingUnverified)
    let additionalID = UUID()
    await #expect(throws: PointJournalError.self) {
        try await makeRepository().grantPoints(
            operationID: additionalID, challengerID: "102",
            value: 7, reason: "합성 응답 유실")
    }
    try await checkLedger("102", expected: 7)
    try FileManager.default.removeItem(at: directory.appending(path: "drop-response"))
    try repository.finishManualReview(operationID: lostID)
    #expect(
        try await makeRepository().grantPoints(
            operationID: additionalID, challengerID: "102",
            value: 7, reason: "합성 응답 유실") == .recorded)
    try await checkLedger("102", expected: 14, rows: 2)

    // Our request times out before the server receives it; only another operator writes.
    let foreignIntent = PointGrantIntent(
        id: UUID(), challengerID: "101", value: 3, reason: "합성 동시 지급")
    let otherOperator = makeRepository("second")
    let observer = PointGrantJournal(baseURL: url, memberID: "first", directory: directory)
    let ledgerURL = url.appending(path: "api/v1/challenger/101")
    let result = try await repository.pointGrants.submit(grant: foreignIntent) {
        let (data, _) = try await client.request(URLRequest(url: ledgerURL))
        return try JSONDecoder().decode(APIResponse<PointLedgerDTO>.self, from: data).unwrap()
    } write: {
        let saved = try observer.lookup(foreignIntent)
        #expect(saved?.intent == foreignIntent)
        #expect(saved?.baseline.count == 1)
        let grant = try await otherOperator.grantPoints(
            operationID: UUID(), challengerID: "101",
            value: 3, reason: "합성 동시 지급")
        #expect(grant == .recorded)
        throw URLError(.timedOut)
    }
    #expect(result == .matchingUnverified)
    #expect(try makeRepository().pendingGrant(challengerID: "101") == foreignIntent)
    #expect(
        try await makeRepository().grantPoints(
            operationID: foreignIntent.id, challengerID: "101",
            value: 3, reason: "합성 동시 지급") == .matchingUnverified)
    try await checkLedger("101", expected: 6, rows: 2)
}

/// The parent owns the synthetic HTTP server and journal directory across process exit.
final class PointGrantRestartProcess: XCTestCase {
    func testCommittedResponseLoss() async throws {
        let env = ProcessInfo.processInfo.environment
        guard let rawURL = env["POINT_TEST_URL"], let path = env["POINT_TEST_DIRECTORY"],
            let rawID = env["POINT_TEST_ID"]
        else { throw XCTSkip("부모 테스트에서 실행") }
        let url = try XCTUnwrap(URL(string: rawURL))
        let client = AuthSystemFactory.makeNetworkClient(
            environment: NetworkEnvironment(baseURL: url), tokenStore: FixtureTokenStore())
        let repo = LiveActivityRepository(
            client: client, baseURL: url, memberID: "first",
            journalDirectory: URL(fileURLWithPath: path))
        let result = try await repo.grantPoints(
            operationID: try XCTUnwrap(UUID(uuidString: rawID)),
            challengerID: "102", value: 7, reason: "합성 응답 유실")
        XCTAssertEqual(result, .awaitingLedger)
    }
}
