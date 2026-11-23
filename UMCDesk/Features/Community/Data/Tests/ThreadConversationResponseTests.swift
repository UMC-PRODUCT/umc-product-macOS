//
//  ThreadConversationResponseTests.swift
//  CommunityDataTests
//
//  Created by euijjang97 on 11/23/26.
//

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
