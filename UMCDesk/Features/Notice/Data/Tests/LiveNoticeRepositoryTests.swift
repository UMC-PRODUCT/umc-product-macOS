//  LiveNoticeRepositoryTests.swift
//  NoticeDataTests
//
//  Created by euijjang97 on 11/23/26.

import CoreNetwork
import Foundation
import NoticeDomain
import Testing

@testable import NoticeData

@Suite("공지 루프백 API 계약")
struct LiveNoticeRepositoryTests {
    @Test func signedURLPolicy() throws {
        let url = try #require(URL(string: "http://127.0.0.1:17901"))
        let client = NetworkClient(tokenStore: FixtureTokens(), refreshService: FixtureRefresh())
        let repo = LiveNoticeRepository(
            adapter: MoyaNetworkAdapter(networkClient: client),
            environment: NetworkEnvironment(baseURL: url)
        ) {}
        #if DEBUG
            #expect(repo.permitsUpload(to: url))
        #else
            #expect(!repo.permitsUpload(to: url))
        #endif
        #expect(!repo.permitsUpload(to: URL(string: "http://127.0.0.1:17902")!))
        #expect(!repo.permitsUpload(to: URL(string: "http://example.test")!))
        #expect(!repo.permitsUpload(to: URL(string: "https://user@example.test/object")!))
        #expect(repo.permitsUpload(to: URL(string: "https://storage.example.test/object")!))
    }

    @Test("공지 게시부터 사진·링크·투표·읽음 현황·수정·삭제까지")
    func lifecycle() async throws {
        let fixture = try NoticeFixture()
        defer { fixture.stop() }
        let url = fixture.url
        let client = NetworkClient(tokenStore: FixtureTokens(), refreshService: FixtureRefresh())
        let repository = LiveNoticeRepository(
            adapter: MoyaNetworkAdapter(networkClient: client),
            environment: NetworkEnvironment(baseURL: url)
        ) { _ = try await client.currentAccessToken() }
        let readerClient = NetworkClient(
            tokenStore: FixtureTokens("notice-reader-fixture"),
            refreshService: FixtureRefresh())
        let reader = LiveNoticeRepository(
            adapter: MoyaNetworkAdapter(networkClient: readerClient),
            environment: NetworkEnvironment(baseURL: url)
        ) { _ = try await readerClient.currentAccessToken() }
        let gisu = try await repository.activeGisu()
        #expect(try await repository.organization(gisu: gisu)?.generation == "10")
        #expect(try await repository.canCompose(gisu: gisu))
        #expect(try await !reader.canCompose(gisu: gisu))
        #expect(try await !repository.canCompose(gisu: "9"))
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
        #if DEBUG
            let imageID = try await repository.uploadImage(file: file)
            try await repository.attachImages([imageID], id: id)
        #else
            await #expect(throws: URLError.self) { try await repository.uploadImage(file: file) }
        #endif
        try await repository.attachLinks(["https://example.test/notice"], id: id)
        var poll = NoticePollDraft()
        poll.title = "합성 투표"
        poll.options = ["첫째", "둘째"]
        try await repository.addPoll(poll, id: id)
        let detail = try await repository.detail(id: id)
        #expect(detail.targetInfo?.targetChapterId == "1")
        #if DEBUG
            #expect(detail.images?.count == 1)
        #endif
        #expect(detail.links?.count == 1)
        let options = try #require(detail.vote?.options.map(\.optionId))
        try await repository.vote(options: [options[0]], replacing: false, id: id)
        #expect(try await repository.detail(id: id).vote?.mySelectedOptionIds == [options[0]])
        try await repository.vote(options: [options[1]], replacing: true, id: id)
        try await repository.vote(options: [], replacing: true, id: id)
        #expect(try await repository.detail(id: id).vote?.mySelectedOptionIds.isEmpty == true)
        try await repository.confirmRead(id: id)
        #expect(try await repository.readCounts(id: id).readCount == "1")
        let unread = try await repository.readers(id: id, status: "UNREAD", cursor: nil)
        #expect(unread.content.count == 3)
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
    @MainActor
    @Test("응답 유실 후 공지와 투표 POST가 한 번만 기록된다")
    func uncertainPublication() async throws {
        let fixture = try NoticeFixture()
        defer { fixture.stop() }
        let repo = fixture.repository()
        var draft = NoticeDraft()
        draft.title = "유실 합성 공지"
        draft.content = "본문"
        let attempt = NoticePublication()
        try fixture.mark("lose-notice")
        for _ in 0..<2 {
            do {
                _ = try await attempt.publish { try await repo.create(draft, gisu: "10") }
                Issue.record("게시 응답 유실을 확인해야 합니다.")
            } catch { #expect(error as? NoticeRequestFailure == .publicationUnconfirmed) }
        }
        #expect(try fixture.count("posts-notice") == 1)
        let page = try await repo.notices(
            gisu: "10", tab: "CHALLENGER", keyword: draft.title, part: nil, page: 0)
        let id = try #require(page.content.first?.id)
        #expect(page.content.count == 1)
        var poll = NoticePollDraft()
        poll.title = "유실 합성 투표"
        poll.options = ["가", "나"]
        try fixture.mark("lose-poll")
        do {
            try await attempt.publishPoll {
                try await repo.addPoll(poll, id: id)
            } check: {
                throw URLError(.networkConnectionLost)
            }
            Issue.record("투표 확인 실패가 전달되어야 합니다.")
        } catch { #expect(attempt.needsPollCheck) }
        try await attempt.publishPoll {
            try await repo.addPoll(poll, id: id)
        } check: {
            try await repo.detail(id: id).vote?.title == poll.title ? .matching : .different
        }
        #expect(try fixture.count("posts-poll") == 1)
        _ = try await repo.readers(id: id, status: "UNREAD", cursor: nil)
        try fixture.mark("deny")
        do {
            _ = try await repo.readers(id: id, status: "UNREAD", cursor: nil)
            Issue.record("권한 회수를 전달해야 합니다.")
        } catch { #expect(error as? NoticeRequestFailure == .accessDenied) }
    }

    #if DEBUG
        @Test("PUT 직전 계정 검사와 리디렉션 및 진행 중 계정 만료·취소")
        func signedUploadBoundary() async throws {
            let fixture = try NoticeFixture()
            defer { fixture.stop() }
            let file = fixture.control.appending(path: "synthetic.png")
            try Data([0, 1, 2]).write(to: file)
            let invalid = fixture.repository { throw CancellationError() }
            await #expect(throws: (any Error).self) { try await invalid.uploadImage(file: file) }
            #expect(!fixture.exists("put-started") && !fixture.exists("confirmed"))
            try fixture.mark("redirect")
            let repo = fixture.repository()
            await #expect(throws: (any Error).self) { try await repo.uploadImage(file: file) }
            #expect(fixture.exists("put-started") && !fixture.exists("redirect-followed"))
            #expect(!fixture.exists("confirmed"))
            try fixture.remove("redirect")
            try fixture.mark("hold-put")
            for cancelView in [false, true] {
                try fixture.remove("put-started")
                let session = UploadAccount()
                let bound = fixture.repository { try await session.check() }
                let task = Task { try await bound.uploadImage(file: file) }
                let clock = ContinuousClock()
                let deadline = clock.now + .seconds(3)
                while !fixture.exists("put-started"), clock.now < deadline {
                    try await Task.sleep(for: .milliseconds(10))
                }
                #expect(fixture.exists("put-started"))
                if cancelView { task.cancel() } else { await session.revoke() }
                await #expect(throws: (any Error).self) { try await task.value }
                #expect(!fixture.exists("confirmed"))
            }
            try fixture.remove("hold-put")
        }

    #endif
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

private actor UploadAccount {
    private var active = true
    func revoke() { active = false }
    func check() throws { if !active { throw CancellationError() } }
}

private struct NoticeFixture: Sendable {
    let process: Process
    let url: URL
    let control: URL

    init() throws {
        let control = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: control, withIntermediateDirectories: true)
        self.control = control
        process = Process()
        var root = URL(fileURLWithPath: #filePath)
        for _ in 0..<6 { root.deleteLastPathComponent() }
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [root.appending(path: "tools/qa/notice_fixture.py").path]
        let output = Pipe()
        process.standardOutput = output
        var env = ProcessInfo.processInfo.environment
        env["NOTICE_CONTRACT_CONTROL"] = control.path
        process.environment = env
        try process.run()
        let portText = String(decoding: output.fileHandleForReading.availableData, as: UTF8.self)
        let port = try #require(UInt16(portText.trimmingCharacters(in: .whitespacesAndNewlines)))
        url = try #require(URL(string: "http://127.0.0.1:\(port)"))
    }

    func repository(validate: @escaping @Sendable () async throws -> Void = {})
        -> LiveNoticeRepository
    {
        let client = NetworkClient(tokenStore: FixtureTokens(), refreshService: FixtureRefresh())
        return LiveNoticeRepository(
            adapter: MoyaNetworkAdapter(networkClient: client),
            environment: NetworkEnvironment(baseURL: url), validateAccount: validate)
    }

    func mark(_ name: String) throws { try Data().write(to: control.appending(path: name)) }
    func remove(_ name: String) throws {
        try FileManager.default.removeItem(at: control.appending(path: name))
    }
    func exists(_ name: String) -> Bool {
        FileManager.default.fileExists(atPath: control.appending(path: name).path)
    }
    func count(_ name: String) throws -> Int {
        try String(contentsOf: control.appending(path: name), encoding: .utf8).split(
            separator: "\n"
        ).count
    }

    func stop() {
        if process.isRunning {
            process.terminate()
            process.waitUntilExit()
        }
        try? FileManager.default.removeItem(at: control)
    }
}
