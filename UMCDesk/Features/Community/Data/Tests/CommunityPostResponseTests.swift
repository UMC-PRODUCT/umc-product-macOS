//
//  CommunityPostResponseTests.swift
//  CommunityDataTests
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import CoreNetwork
import Foundation
import Synchronization
import Testing

@testable import CommunityData

struct CommunityPostResponseTests {
    @Test func decodesMemberOwnershipIndependentlyOfChallengerID() throws {
        let data = Data(
            """
            {"postId":22,"title":"번개","content":"합성","category":"LIGHTNING","authorId":"777",
             "authorMemberId":101,"authorNickname":"별명","writeTime":"2026-11-23T10:00:00Z",
             "commentCount":"3","likeCount":4,"isLiked":true,"isScrapped":false,"scrapCount":0,
             "lightningInfo":{"meetAt":"2026-11-24T10:00:00Z","location":"학교",
             "maxParticipants":5,"openChatUrl":"https://example.test/meet"}}
            """.utf8)
        let row = try JSONDecoder().decode(CommunityPostDTO.self, from: data).model
        #expect(row.id == "22" && row.authorMemberID == "101")
        #expect(row.meeting?.maxParticipants == "5" && row.likeCount == "4")
        #expect(row.liked && !row.scrapped)
    }

    @Test func commentOwnershipIsTheServerFlag() throws {
        let data = Data(
            """
            {"commentId":"5","challengerId":"101","content":"댓글","isAuthor":false}
            """.utf8)
        let row = try JSONDecoder().decode(CommunityPostCommentDTO.self, from: data).model
        #expect(row.id == "5" && !row.isAuthor)
    }
}

extension CommunityPostResponseTests {
    @Test func lostPostAndCommentResponsesRetryByReadingOnly() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [LostWriteProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let environment = NetworkEnvironment(baseURL: URL(string: "https://board.example.test")!)
        let client = AuthSystemFactory.makeNetworkClient(
            environment: environment, tokenStore: BoardTestTokens(), session: session)
        let repository = LiveCommunityPostRepository(
            adapter: .init(networkClient: client), environment: environment)
        LostWriteProtocol.counts.withLock { $0 = [:] }
        func submitPost() async throws -> CommunityPost {
            try await repository.save(
                id: nil, title: "제목", content: "합성", category: .free, meeting: nil)
        }
        // The first read after each committed write still shows the old identical row.
        await #expect(throws: (any Error).self) { try await submitPost() }
        #expect(try await submitPost().id == "21")
        func reply() async throws {
            _ = try await repository.perform(.comment("합성", parentID: "20"), id: "21")
        }
        await #expect(throws: (any Error).self) { try await reply() }
        try await reply()
        let counts = LostWriteProtocol.counts.withLock { $0 }
        #expect(counts["POST /api/v1/posts"] == 1)
        #expect(counts["POST /api/v1/posts/21/comments"] == 1)
        #expect(counts["GET /api/v1/posts/my"] == 3)
        #expect(counts["GET /api/v1/posts/21/comments"] == 3)
    }
}

private final class LostWriteProtocol: URLProtocol, @unchecked Sendable {
    static let counts = Mutex<[String: Int]>([:])

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        guard let url = request.url else { return }
        let method = request.httpMethod ?? "GET"
        let key = method + " " + url.path
        let (readCount, committed) = Self.counts.withLock { counts in
            counts[key, default: 0] += 1
            let writePath = url.path.hasSuffix("/my") ? "/api/v1/posts" : url.path
            return (counts[key] ?? 0, counts["POST " + writePath, default: 0] > 0)
        }
        if method == "POST" {
            client?.urlProtocol(self, didFailWithError: URLError(.networkConnectionLost))
            return
        }
        let ids = committed && readCount >= 3 ? [21, 20] : [20]
        let result: Any
        if url.path.hasSuffix("/my") {
            let rows: [[String: Any]] = ids.map {
                ["postId": $0, "title": "제목", "content": "합성", "category": "FREE",
                 "commentCount": 0, "likeCount": 0, "isLiked": false]
            }
            result = ["content": rows, "page": 0, "hasNext": false]
        } else {
            result = ids.map { ["commentId": $0, "content": "합성", "isAuthor": true] }
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: ["success": true, "result": result])
            let response = HTTPURLResponse(
                url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
}

private actor BoardTestTokens: TokenStore {
    func getAccessToken() async -> String? { "synthetic-board" }
    func getRefreshToken() async -> String? { nil }
    func save(accessToken: String, refreshToken: String) async throws {}
    func clear() async throws {}
}
