//
//  MatchingResponseTests.swift
//  MatchingDataTests
//
//  Created by euijjang97 on 11/22/26.
//

import CoreNetwork
import Foundation
import MatchingDomain
import Synchronization
import UMCFoundation
import Testing
@testable import MatchingData

@Suite("Matching server contracts")
struct MatchingResponseTests {
    @Test("Applicants see only rounds in their matching chapter and part")
    func eligibleRounds() {
        let round = MatchingRound(id: "11", name: "디자인 1차", type: "PLAN_DESIGN",
            phase: "FIRST", chapterId: "23", startsAt: "", endsAt: "",
            decisionDeadline: nil, resultPublishAt: nil)
        #expect(round.isEligible(chapterId: "23", parts: ["DESIGN"]))
        #expect(!round.isEligible(chapterId: "24", parts: ["DESIGN"]))
        #expect(!round.isEligible(chapterId: "23", parts: ["IOS"]))
        #expect(!round.isEligible(chapterId: "23", parts: []))
    }

    @Test("A masked result and a random assignment without an application ID both survive decoding")
    func personalCards() throws {
        let json = """
        [{"applicationId":93,"projectId":"18","project":null,"matchingRound":null,"status":null},
         {"applicationId":null,"projectId":17,"project":{"name":"UMC","partQuotas":[]},
          "matchingRound":{"id":null,"type":"PLAN_DESIGN","phase":"RANDOM_MATCHING"},
          "status":"APPROVED"}]
        """
        let cards = try JSONDecoder().decode([MatchingApplicationDTO].self, from: Data(json.utf8))
        #expect(cards[0].model.status == nil)
        #expect(cards[0].model.applicationId == "93")
        #expect(cards[1].model.applicationId == nil)
        #expect(cards[1].model.projectId == "17")
        #expect(cards[1].model.status == "APPROVED")
    }

    @Test("Existing selections and private file IDs are retained when replacing answers")
    func preservedAnswers() throws {
        let json = """
        {"textValue":null,"selectedOptions":[{"questionOptionId":17,"answeredAsContent":"선택"},
         {"questionOptionId":null,"answeredAsContent":"삭제된 선택지"}],
         "files":[{"fileId":"portfolio-id","originalFileName":"portfolio.pdf","url":null}]}
        """
        let answer = try JSONDecoder().decode(MatchingSavedAnswerDTO.self, from: Data(json.utf8))
        #expect(answer.model.selectedOptions.first?.questionOptionId == "17")
        #expect(answer.model.selectedOptions.last?.questionOptionId == nil)
        #expect(answer.model.selectedOptions.last?.answeredAsContent == "삭제된 선택지")
        #expect(answer.model.files.first?.fileId == "portfolio-id")
        #expect(try JSONDecoder().decode(
            MatchingSavedAnswerDTO.self, from: JSONEncoder().encode(answer)
        ).model == answer.model)
    }
}

@Suite("Authenticated Matching HTTP requests", .serialized)
@MainActor
struct MatchingTransportTests {
    private let projectId = "57"
    private let applicationId = "64"

    @Test("Submit uses the application path and withdraw handles an empty no-content response")
    func submitAndWithdraw() async throws {
        let api = makeAPI()
        MatchingHTTPStub.respond(200, json: """
            {"success":true,"result":{"applicationId":"64","status":"SUBMITTED"}}
            """)
        try await api.submitApplication(projectId: projectId, applicationId: applicationId)
        let submit = try #require(MatchingHTTPStub.recorded)
        #expect(submit.url?.path == "/api/v1/projects/57/applications/64/submit")
        #expect(submit.httpMethod == "POST")
        #expect(submit.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")

        MatchingHTTPStub.respond(204)
        try await api.cancelApplication(projectId: projectId, applicationId: applicationId)
        #expect(MatchingHTTPStub.recorded?.url?.path == "/api/v1/projects/57/applications/64")
        #expect(MatchingHTTPStub.recorded?.httpMethod == "DELETE")
    }

    @Test("Chapter batch save targets the singular route and deletion keeps its type query")
    func scheduleMutations() async throws {
        let api = makeAPI()
        let phases = ["FIRST", "SECOND", "THIRD", "RANDOM_MATCHING"]
        let rows = phases.map { phase in
            MatchingRoundChange(phase: phase, name: phase, description: "유지",
                startsAt: "2027-01-01T00:00:00Z", endsAt: "2027-01-02T00:00:00Z",
                decisionDeadline: phase == "RANDOM_MATCHING" ? nil : "2027-01-03T00:00:00Z",
                resultPublishAt: "2027-01-04T00:00:00Z")
        }
        MatchingHTTPStub.respond(200, json: #"{"success":true,"result":[]}"#)
        try await api.saveSchedule(chapterId: "20", type: "PLAN_DESIGN", rounds: rows)
        let save = try #require(MatchingHTTPStub.recorded)
        #expect(save.httpMethod == "PUT")
        #expect(save.url?.path == "/api/v1/project/matching-rounds/chapters/20")
        let body = try #require(MatchingHTTPStub.recordedBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Any])
        #expect(json["type"] as? String == "PLAN_DESIGN")
        let sentRows = try #require(json["rounds"] as? [[String: Any]])
        #expect(sentRows.compactMap { $0["phase"] as? String } == phases)
        #expect(sentRows.last?["decisionDeadline"] == nil)

        MatchingHTTPStub.respond(204)
        try await api.deleteSchedule(chapterId: "20", type: "PLAN_DEVELOPER")
        let delete = try #require(MatchingHTTPStub.recorded)
        #expect(delete.httpMethod == "DELETE")
        #expect(delete.url?.query == "type=PLAN_DEVELOPER")
    }

    @Test("Server rejection preserves the code and reason in the envelope")
    func submissionError() async throws {
        let api = makeAPI()
        MatchingHTTPStub.respond(409, json: """
            {"success":false,"code":"PROJECT-0309","message":"지원 가능한 차수가 아닙니다.","result":null}
            """)
        do {
            try await api.submitApplication(projectId: projectId, applicationId: applicationId)
            Issue.record("Expected rejection from the server")
        } catch let failure as RepositoryError {
            #expect(failure.code == "PROJECT-0309")
            #expect(failure.userMessage == "지원 가능한 차수가 아닙니다.")
        }
    }

    @Test("Checking for a draft is read-only and explicit creation sends the selected PM member ID")
    func draftAndPmSelection() async throws {
        let api = makeAPI()
        MatchingHTTPStub.respond(200, json: #"{"success":true,"result":{"content":[],"hasNext":false}}"#)
        #expect(try await api.latestDraft(gisuId: "8") == nil)
        #expect(MatchingHTTPStub.recorded?.httpMethod == "GET")
        #expect(MatchingHTTPStub.recorded?.url?.path == "/api/v1/projects/me/drafts")
        _ = try await api.pmCandidates(gisuId: "8", keyword: "PM", page: 2)
        let candidates = try #require(MatchingHTTPStub.recorded)
        #expect(candidates.httpMethod == "GET")
        #expect(candidates.url?.path == "/api/v1/projects/admin/pm-candidates")
        let url = try #require(candidates.url)
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        #expect(Set(query) == Set([
            URLQueryItem(name: "gisuId", value: "8"), .init(name: "page", value: "2"),
            .init(name: "keyword", value: "PM")
        ]))
        MatchingHTTPStub.respond(200, json: #"{"success":true,"result":{"projectId":114,"status":"DRAFT"}}"#)
        #expect(try await api.createProjectDraft(gisuId: "8", productOwnerMemberId: "22") == "114")
        #expect(MatchingHTTPStub.recorded?.httpMethod == "POST")
        #expect(MatchingHTTPStub.recorded?.url?.path == "/api/v1/projects")
        let body = try #require(MatchingHTTPStub.recordedBody)
        let json = try #require(JSONSerialization.jsonObject(with: body) as? [String: Int])
        #expect(json == ["gisuId": 8, "productOwnerMemberId": 22])
    }

    private func makeAPI() -> LiveMatchingRepository {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MatchingHTTPStub.self]
        let client = NetworkClient(session: URLSession(configuration: configuration),
                                   tokenStore: MatchingTestSession(), refreshService: MatchingTestSession())
        return LiveMatchingRepository(adapter: MoyaNetworkAdapter(networkClient: client), client: client,
            environment: .init(baseURL: URL(string: "https://matching.example.test")!))
    }
}

private struct MatchingTestSession: TokenStore, TokenRefreshService {
    func getAccessToken() async -> String? { "test-token" }
    func getRefreshToken() async -> String? { nil }
    func save(accessToken: String, refreshToken: String) async throws {}
    func clear() async throws {}
    func refresh(_ refreshToken: String) async throws -> TokenPair { throw URLError(.cancelled) }
}

private final class MatchingHTTPStub: URLProtocol, @unchecked Sendable {
    private struct Exchange: Sendable {
        var request: URLRequest?
        var body: Data?
        let status: Int
        let response: Data
    }

    private static let exchange = Mutex(Exchange(status: 200, response: Data()))
    static var recorded: URLRequest? { exchange.withLock { $0.request } }
    static var recordedBody: Data? { exchange.withLock { $0.body } }

    static func respond(_ status: Int, json: String = "") {
        exchange.withLock { $0 = Exchange(status: status, response: Data(json.utf8)) }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        var body = request.httpBody
        if body == nil, let stream = request.httpBodyStream {
            stream.open()
            defer { stream.close() }
            var bytes = [UInt8](repeating: 0, count: 4096)
            var data = Data()
            while true {
                let read = stream.read(&bytes, maxLength: bytes.count)
                guard read > 0 else { break }
                data.append(contentsOf: bytes.prefix(read))
            }
            body = data
        }
        let (status, response) = Self.exchange.withLock {
            $0.request = request
            $0.body = body
            return ($0.status, $0.response)
        }
        let http = HTTPURLResponse(url: request.url!, statusCode: status,
                                   httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: response)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
