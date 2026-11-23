//  LiveNoticeRepositoryTests.swift
//  NoticeDataTests
//
//  Created by euijjang97 on 11/23/26.

import CoreNetwork
import Foundation
import NoticeData
import NoticeDomain
import Testing

@Suite("공지 루프백 API 계약")
struct LiveNoticeRepositoryTests {
    @Test("공지 게시부터 사진·링크·투표·읽음 현황·수정·삭제까지")
    func lifecycle() async throws {
        let process = Process()
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<6 { root.deleteLastPathComponent() }
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [root.appending(path: "tools/qa/notice_fixture.py").path]
        let output = Pipe()
        process.standardOutput = output
        try process.run()
        defer {
            if process.isRunning {
                process.terminate()
                process.waitUntilExit()
            }
        }
        let portText = String(decoding: output.fileHandleForReading.availableData, as: UTF8.self)
        let port = try #require(UInt16(portText.trimmingCharacters(in: .whitespacesAndNewlines)))
        let url = try #require(URL(string: "http://127.0.0.1:\(port)"))
        let client = NetworkClient(tokenStore: FixtureTokens(), refreshService: FixtureRefresh())
        let repository = LiveNoticeRepository(
            adapter: MoyaNetworkAdapter(networkClient: client),
            environment: NetworkEnvironment(baseURL: url))
        let readerClient = NetworkClient(
            tokenStore: FixtureTokens("notice-reader-fixture"),
            refreshService: FixtureRefresh())
        let reader = LiveNoticeRepository(
            adapter: MoyaNetworkAdapter(networkClient: readerClient),
            environment: NetworkEnvironment(baseURL: url))
        let gisu = try await repository.activeGisu()
        #expect(try await repository.organization(gisu: gisu)?.generation == "10")
        var draft = NoticeDraft()
        draft.title = "합성 계약 공지"
        draft.content = "합성 본문"
        draft.chapterId = "1"
        let id = try await repository.create(draft, gisu: gisu)
        #expect(try await reader.permissions(id: id) == ["READ"])
        await #expect(throws: (any Error).self) { try await reader.delete(id: id) }
        await #expect(throws: (any Error).self) { try await reader.readCounts(id: id) }
        let page = try await repository.notices(
            gisu: gisu, tab: "CHALLENGER",
            keyword: "계약", part: nil, page: 0)
        #expect(page.content.map(\.id) == [id])
        #expect(try await repository.permissions(id: id).contains("EDIT"))
        let file = FileManager.default.temporaryDirectory.appending(
            path: UUID().uuidString + ".png")
        let pixel =
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8"
            + "/x8AAwMCAO+jp1sAAAAASUVORK5CYII="
        try #require(Data(base64Encoded: pixel)).write(to: file)
        defer { try? FileManager.default.removeItem(at: file) }
        let imageID = try await repository.uploadImage(file: file)
        try await repository.attachImages([imageID], id: id)
        try await repository.attachLinks(["https://example.test/notice"], id: id)
        var poll = NoticePollDraft()
        poll.title = "합성 투표"
        poll.options = ["첫째", "둘째"]
        try await repository.addPoll(poll, id: id)
        let detail = try await repository.detail(id: id)
        #expect(detail.targetInfo?.targetChapterId == "1")
        #expect(detail.images?.count == 1 && detail.links?.count == 1)
        let options = try #require(detail.vote?.options.map(\.optionId))
        try await repository.vote(options: [options[0]], replacing: false, id: id)
        #expect(try await repository.detail(id: id).vote?.mySelectedOptionIds == [options[0]])
        try await repository.vote(options: [options[1]], replacing: true, id: id)
        try await repository.vote(options: [], replacing: true, id: id)
        #expect(try await repository.detail(id: id).vote?.mySelectedOptionIds.isEmpty == true)
        try await repository.confirmRead(id: id)
        #expect(try await repository.readCounts(id: id).readCount == "1")
        let unread = try await repository.readers(id: id, status: "UNREAD", cursor: nil)
        #expect(unread.content.count == 1)
        try await repository.remind(id: id, challengers: unread.content.map(\.challengerId))
        try await repository.edit(id: id, title: "수정한 공지", content: "수정한 본문", pinned: true)
        #expect(try await repository.detail(id: id).mustRead)
        try await repository.replaceImages([], id: id)
        try await repository.replaceLinks([], id: id)
        try await repository.removePoll(id: id)
        let cleared = try await repository.detail(id: id)
        #expect(
            cleared.images?.isEmpty == true && cleared.links?.isEmpty == true
                && cleared.vote == nil)
        try await repository.delete(id: id)
        let after = try await repository.notices(
            gisu: gisu, tab: "CHALLENGER",
            keyword: "수정한", part: nil, page: 0)
        #expect(after.content.isEmpty)
    }
}

private actor FixtureTokens: TokenStore {
    let access: String
    init(_ access: String = "notice-contract-fixture") { self.access = access }
    func getAccessToken() async -> String? { access }
    func getRefreshToken() async -> String? { nil }
    func save(accessToken: String, refreshToken: String) async throws {}
    func clear() async throws {}
}

private struct FixtureRefresh: TokenRefreshService {
    func refresh(_ refreshToken: String) async throws -> TokenPair {
        throw URLError(.userCancelledAuthentication)
    }
}
