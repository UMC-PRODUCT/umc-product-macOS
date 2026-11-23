//
//  ThreadConversationResponseTests.swift
//  CommunityDataTests
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import CoreNetwork
import Foundation
import Testing

@testable import CommunityData

struct ThreadConversationResponseTests {
    @Test func redactsNestedContentBeforePassingItToPresentation() throws {
        let source = """
            {"messages":[{"messageId":12,"senderId":"2","senderName":"숨김","content":"비공개",
            "isSenderBlocked":true,"replyTo":{"messageId":1},"files":[{"fileId":"photo",
            "fileName":"숨김.png","fileUrl":"https://example.test/image"}],"reactions":[{"emoji":"🔥",
            "count":2,"reactedByMe":true}]},{"messageId":"11","senderName":"삭제","content":"삭제 원문",
            "deletedAt":"2026-11-23T10:01:00Z","isSenderBlocked":false}],
            "hasMore":true,"nextBefore":11}
            """
        let page = try JSONDecoder().decode(ConversationHistoryDTO.self, from: Data(source.utf8))
        #expect(page.nextBefore == "11")
        let rows = page.messages.map(\.model)
        #expect(rows.map(\.text) == ["차단한 회원의 메시지", "삭제된 메시지"])
        #expect(
            rows.allSatisfy {
                $0.author.isEmpty && $0.authorID == nil && $0.replyID == nil
                    && $0.isHidden && $0.files.isEmpty && $0.reactions.isEmpty
            })
    }

    @Test func classifiesCorrelatedCommandErrorsByServerCode() {
        for code in ["COMMUNITY-0033", "COMMUNITY-0034", "COMMUNITY-0035", "COMMUNITY-0037"] {
            let error = ConversationSocket.commandError(["code": code, "retryable": false])
            guard case ThreadConversationRejection.denied = error else {
                Issue.record("스레드 접근 거절로 분류해야 하는 오류: \(code)")
                continue
            }
        }
        let command = ConversationSocket.commandError([
            "status": 403, "code": "COMMUNITY-0040", "retryable": false])
        guard case ThreadConversationRejection.commandDenied = command else {
            Issue.record("명령 권한 거절은 멤버십을 유지해야 함")
            return
        }
        #expect(ConversationSocket.commandError(["status": 500, "retryable": true])
                is ConversationFailure)
    }

    @Test func invalidAccountCannotStartSignedTransfer() async {
        let probe = UploadProbe()
        await probe.invalidate()
        await #expect(throws: CancellationError.self) {
            try await ConversationUploadTransfer.perform(validate: { try await probe.validate() }) {
                await probe.start()
            }
        }
        #expect(await !probe.started)
    }

    @Test(arguments: [true, false])
    func inFlightSignedTransferCancelsOnAccountOrParentCancellation(revoke: Bool) async {
        let probe = UploadProbe()
        let task = Task {
            try await ConversationUploadTransfer.perform(validate: { try await probe.validate() }) {
                await probe.start()
                do {
                    try await Task.sleep(for: .seconds(10))
                } catch {
                    await probe.recordCancellation()
                    throw error
                }
            }
        }
        await probe.waitForStart()
        if revoke { await probe.invalidate() } else { task.cancel() }
        await #expect(throws: CancellationError.self) { try await task.value }
        #expect(await probe.cancelled)
    }

    @Test func signedTransferRejectsRedirects() async throws {
        let ticket = try #require(URL(string: "https://storage.invalid/one"))
        let redirect = try #require(URL(string: "https://other.invalid/two"))
        let response = try #require(HTTPURLResponse(
            url: ticket, statusCode: 307, httpVersion: nil,
            headerFields: ["Location": redirect.absoluteString]))
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }
        let next: URLRequest? = await withCheckedContinuation { continuation in
            ConversationUploadDelegate().urlSession(
                session, task: session.dataTask(with: ticket),
                willPerformHTTPRedirection: response, newRequest: URLRequest(url: redirect)
            ) { continuation.resume(returning: $0) }
        }
        #expect(next == nil)
    }
}

private actor UploadProbe {
    var started = false
    var cancelled = false
    private var valid = true
    private var waiting: CheckedContinuation<Void, Never>?

    func invalidate() { valid = false }
    func validate() throws {
        if !valid { throw CancellationError() }
    }
    func start() {
        started = true
        waiting?.resume()
        waiting = nil
    }
    func waitForStart() async {
        if !started { await withCheckedContinuation { waiting = $0 } }
    }
    func recordCancellation() { cancelled = true }
}

extension ThreadConversationResponseTests {
    @Test func validatesReportAndBlockReceiptsAgainstTheRequestedTarget() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ModerationReceiptProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let environment = NetworkEnvironment(
            baseURL: try #require(URL(string: "https://thread.example.test")))
        let client = AuthSystemFactory.makeNetworkClient(
            environment: environment, tokenStore: ModerationTokens(), session: session)
        let repository = LiveThreadManagementRepository(
            adapter: .init(networkClient: client), environment: environment)
        #expect(try await repository.report(.message("7"), reasons: [.spam], detail: "") == "51")
        #expect(try await repository.report(.member("8"), reasons: [.other], detail: "내용") == "52")
        await #expect(throws: (any Error).self) {
            try await repository.report(.message("9"), reasons: [.privacy], detail: "")
        }
        #expect(try await repository.isBlocked(memberID: "8"))
        #expect(try await !repository.isBlocked(memberID: "7"))
        try await repository.setBlocked(true, memberID: "8")
        await #expect(throws: (any Error).self) {
            try await repository.setBlocked(false, memberID: "8")
        }
    }
}

private actor ModerationTokens: TokenStore {
    func getAccessToken() async -> String? { "synthetic-thread" }
    func getRefreshToken() async -> String? { nil }
    func save(accessToken: String, refreshToken: String) async throws {}
    func clear() async throws {}
}

private final class ModerationReceiptProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        guard let url = request.url else { return }
        let result: String
        switch (request.httpMethod, url.path) {
        case ("POST", "/api/v1/community/messages/7/report"),
             ("POST", "/api/v1/community/messages/9/report"):
            result = #"{"reportId":"51","messageId":"7"}"#
        case ("POST", "/api/v1/reports/members/8"):
            result = #"{"reportId":"52","memberId":"8"}"#
        case ("GET", "/api/v1/member/blocks"):
            result = #"{"members":[{"memberId":8,"name":"합성 회원"}]}"#
        case ("POST", "/api/v1/member/blocks/8"), ("DELETE", "/api/v1/member/blocks/8"):
            result = #"{"memberId":8,"isBlocked":true}"#
        default:
            client?.urlProtocol(self, didFailWithError: URLError(.unsupportedURL))
            return
        }
        let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("{\"success\":true,\"result\":\(result)}".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
}
