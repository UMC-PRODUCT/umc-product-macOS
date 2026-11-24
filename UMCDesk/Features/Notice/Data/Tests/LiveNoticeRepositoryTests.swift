//  LiveNoticeRepositoryTests.swift
//  NoticeDataTests
//
//  Created by euijjang97 on 11/23/26.

import CoreNetwork
import Foundation
import NoticeDomain
import Testing
import XCTest

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

    @Test("대상 선택 후 CHECK 회수 또는 읽음 변경 시 발송하지 않는다")
    func revalidateReminder() async throws {
        let fixture = try NoticeFixture()
        defer { fixture.stop() }
        let repo = fixture.repository()
        let readers = try await repo.readers(id: "21", status: "UNREAD", cursor: nil)
        let selected = readers.content.map(\.challengerId)
        #expect(selected.contains("101"))
        try fixture.mark("lose-check")
        await #expect(throws: NoticeRequestFailure.accessDenied) {
            try await repo.remind(id: "21", challengers: selected)
        }
        #expect(!fixture.exists("reminder-posted"))
        try fixture.remove("lose-check")
        try fixture.mark("page-readers")
        try fixture.mark("revoke-during-check")
        await #expect(throws: NoticeRequestFailure.accessDenied) {
            try await repo.remind(id: "21", challengers: ["104"])
        }
        #expect(!fixture.exists("reminder-posted"))
        try fixture.remove("revoke-during-check")
        try fixture.remove("lose-check")
        try await repo.confirmRead(id: "21")
        await #expect(throws: NoticeRequestFailure.recipientsChanged) {
            try await repo.remind(id: "21", challengers: selected)
        }
        #expect(!fixture.exists("reminder-posted"))
        try await repo.remind(id: "21", challengers: ["104"])
        #expect(fixture.exists("reminder-posted"))
    }

    @MainActor
    @Test("학교 운영진이 전체 대상 거절 후 같은 초안과 첨부를 학교 대상으로 게시한다")
    func changeDeniedAudience() async throws {
        let fixture = try NoticeFixture()
        defer { fixture.stop() }
        try fixture.mark("school-writer")
        let repo = fixture.repository()
        let attempt = NoticePublication()
        var draft = NoticeDraft()
        draft.title = "합성 학교 공지"
        draft.content = "보존할 본문"
        let links = ["https://example.test/school"]
        #expect(try await repo.canCompose(gisu: "10"))
        do {
            _ = try await attempt.submit(draft, gisu: "10", repository: repo)
            Issue.record("전체 대상이 거절되어야 합니다.")
        } catch {
            guard case .rejected = error as? NoticeRequestFailure else { throw error }
        }
        #expect(!attempt.needsListCheck && attempt.noticeID == nil)
        draft.schoolId = "42"
        let id = try await attempt.submit(draft, gisu: "10", repository: repo)
        try await attempt.saveAttachments(files: [], links: links, poll: nil, repository: repo)
        let entry = try await repo.detail(id: id)
        #expect(entry.title == draft.title && entry.content == draft.content)
        #expect(entry.targetInfo?.targetSchoolId == "42" && entry.links?.map(\.url) == links)
    }

    @MainActor
    @Test("이전 동일 공지를 배제하고 사용자가 확인한 후보에만 사진·링크·투표를 이어서 저장한다")
    func confirmLostPublication() async throws {
        let fixture = try NoticeFixture()
        defer { fixture.stop() }
        let repo = fixture.repository()
        var draft = NoticeDraft()
        draft.title = "합성 동일 제목"
        draft.content = "동일한 본문"
        draft.shouldNotify = true
        var poll = NoticePollDraft()
        poll.title = "작성 중인 투표"
        poll.options = ["가", "나"]
        let links = ["https://example.test/retained"]
        let old = try await repo.create(draft, gisu: "10")
        let attempt = NoticePublication()
        try fixture.mark("lose-notice")
        do {
            _ = try await attempt.submit(draft, gisu: "10", repository: repo)
            Issue.record("응답 유실이 전달되어야 합니다.")
        } catch { #expect(error as? NoticeRequestFailure == .publicationUnconfirmed) }
        let foreign = try await fixture.repository(token: "notice-other-writer-fixture")
            .create(draft, gisu: "10")
        let other = try await repo.create(draft, gisu: "10")
        try await attempt.findCandidates(draft, gisu: "10", repository: repo)
        #expect(attempt.noticeID == nil && attempt.candidates.count == 2)
        #expect(!attempt.candidates.contains { $0.id == old || $0.id == foreign })
        let chosen = try #require(attempt.candidates.first { $0.id != other }?.id)
        try await repo.replaceLinks(["https://example.test/independent"], id: other)
        do {
            try await attempt.confirmCandidate(other, draft: draft, gisu: "10", repository: repo)
            Issue.record("새 첨부가 있는 다른 공지를 덮어써서는 안 됩니다.")
        } catch {
            guard case .rejected = error as? NoticeRequestFailure else { throw error }
        }
        #expect(attempt.needsListCheck && attempt.noticeID == nil)
        try await attempt.confirmCandidate(chosen, draft: draft, gisu: "10", repository: repo)
        let resumed = try await attempt.submit(draft, gisu: "10", repository: repo)
        #expect(resumed == chosen && !attempt.needsListCheck)
        var files: [URL] = []
        #if DEBUG
            let file = fixture.control.appending(path: "draft.png")
            try Data([0, 1]).write(to: file)
            files.append(file)
        #endif
        try await attempt.saveAttachments(files: files, links: links, poll: poll, repository: repo)
        let entry = try await repo.detail(id: chosen)
        #expect(entry.vote?.title == poll.title && entry.links?.map(\.url) == links)
        #expect(entry.images?.count == files.count)
        #expect(
            try await repo.detail(id: other).links?.map(\.url) == [
                "https://example.test/independent"
            ])
        #expect(try fixture.count("posts-notice") == 4)
        #expect(try fixture.count("posts-poll") == 1)
    }

    #if DEBUG
        @MainActor
        @Test("프로세스 강제 종료 뒤 공지·첨부 복원, 계정·포트 격리와 프로세스 잠금")
        func recoverBetweenProcesses() async throws {
            let fixture = try NoticeFixture()
            defer { fixture.stop() }
            let otherPort = try NoticeFixture()
            defer { otherPort.stop() }
            try fixture.mark("lose-notice")
            let root = fixture.control
            let bundle = Bundle(for: NoticePublicationChild.self).bundleURL
            for phase in ["submit", "attachments", "finish"] {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
                process.arguments = [
                    "-XCTest", "NoticeDataTests.NoticePublicationChild/testPhase", bundle.path,
                ]
                var env = ProcessInfo.processInfo.environment.filter {
                    !$0.key.hasPrefix("XCTest") && $0.key != "DYLD_INSERT_LIBRARIES"
                }
                env["NOTICE_PROCESS_PHASE"] = phase
                env["NOTICE_PROCESS_ROOT"] = root.path
                env["NOTICE_PROCESS_URL"] = fixture.url.absoluteString
                process.environment = env
                let log = root.appending(path: phase + ".log")
                try Data().write(to: log)
                let output = try FileHandle(forWritingTo: log)
                process.standardOutput = output
                process.standardError = output
                try process.run()
                defer { if process.isRunning { kill(process.processIdentifier, SIGKILL) } }
                let clock = ContinuousClock()
                let deadline = clock.now + .seconds(25)
                while !fixture.exists("ready-" + phase), process.isRunning, clock.now < deadline {
                    try await Task.sleep(for: .milliseconds(50))
                }
                guard fixture.exists("ready-" + phase) else {
                    let logText = try String(contentsOf: log, encoding: .utf8)
                    Issue.record("자식 프로세스 단계 실패 \(phase) \(logText.suffix(1800))")
                    return
                }
                if phase == "submit" {
                    let repo = fixture.repository()
                    do {
                        _ = try await repo.openPublicationJournal(root: root)
                        Issue.record("다른 프로세스가 작성 중이면 열 수 없습니다.")
                    } catch {
                        guard case .rejected = error as? NoticeRequestFailure else { throw error }
                    }
                    for isolated in [
                        fixture.repository(token: "notice-other-writer-fixture"),
                        otherPort.repository(),
                    ] {
                        let fresh = try await NoticePublication(
                            journal: isolated.openPublicationJournal(root: root))
                        #expect(fresh.input == nil && fresh.noticeID == nil)
                    }
                }
                if phase != "finish" { kill(process.processIdentifier, SIGKILL) }
                let exitDeadline = clock.now + .seconds(5)
                while process.isRunning, clock.now < exitDeadline {
                    try await Task.sleep(for: .milliseconds(25))
                }
                try #require(!process.isRunning)
                if phase == "finish" { #expect(process.terminationStatus == 0) }
            }
            #expect(try fixture.count("posts-notice") == 1)
            #expect(try fixture.count("posts-poll") == 1)
            let reopened = try await NoticePublication(
                journal: fixture.repository().openPublicationJournal(root: root))
            #expect(reopened.input == nil)
        }

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

    func repository(
        token: String = "notice-contract-fixture",
        validate: @escaping @Sendable () async throws -> Void = {}
    )
        -> LiveNoticeRepository
    {
        let client = NetworkClient(
            tokenStore: FixtureTokens(token), refreshService: FixtureRefresh())
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
            // Foundation can miss an exit notification when other test suites reap children.
            // The child owns no credentials or external resources. Its directory can be unlinked now.
        }
        try? FileManager.default.removeItem(at: control)
    }
}

#if DEBUG
    /// A separate XCTest process runs one phase against the parent's synthetic server.
    final class NoticePublicationChild: XCTestCase {
        @MainActor
        func testPhase() async throws {
            let env = ProcessInfo.processInfo.environment
            guard let step = env["NOTICE_PROCESS_PHASE"] else { return }
            let root = URL(fileURLWithPath: try XCTUnwrap(env["NOTICE_PROCESS_ROOT"]))
            let base = try XCTUnwrap(URL(string: try XCTUnwrap(env["NOTICE_PROCESS_URL"])))
            let client = NetworkClient(
                tokenStore: FixtureTokens(), refreshService: FixtureRefresh())
            let repo = LiveNoticeRepository(
                adapter: MoyaNetworkAdapter(networkClient: client),
                environment: NetworkEnvironment(baseURL: base)
            ) {}
            let attempt = try await NoticePublication(
                journal: repo.openPublicationJournal(root: root))
            let original = root.appending(path: "synthetic.png")
            switch step {
            case "submit":
                var draft = NoticeDraft()
                draft.title = "재실행 합성 공지"
                draft.content = "강제 종료 전 본문"
                draft.shouldNotify = true
                var poll = NoticePollDraft()
                poll.title = "유지된 투표"
                poll.options = ["가", "나"]
                try Data([0, 1, 2]).write(to: original)
                let input = try attempt.prepare(
                    .init(
                        gisu: "10", draft: draft, files: [original],
                        links: ["https://example.test/relaunch"], poll: poll))
                try FileManager.default.removeItem(at: original)
                XCTAssertTrue(FileManager.default.isReadableFile(atPath: input.files[0].path))
                do {
                    _ = try await attempt.submit(draft, gisu: "10", repository: repo)
                    XCTFail("응답 유실이 전달되어야 합니다.")
                    return
                } catch NoticeRequestFailure.publicationUnconfirmed {}
            case "attachments":
                let input = try XCTUnwrap(attempt.input)
                XCTAssertTrue(attempt.needsListCheck)
                do {
                    _ = try await attempt.submit(input.draft, gisu: input.gisu, repository: repo)
                    XCTFail("확인 전 두 번째 POST를 허용했습니다.")
                    return
                } catch NoticeRequestFailure.publicationUnconfirmed {}
                try await attempt.findCandidates(input.draft, gisu: input.gisu, repository: repo)
                let id = try XCTUnwrap(attempt.candidates.first?.id)
                try await attempt.confirmCandidate(
                    id, draft: input.draft, gisu: input.gisu, repository: repo)
                try await attempt.saveAttachments(
                    files: input.files, links: input.links, poll: input.poll, repository: repo)
                // Uploaded and attached. Later recovery can proceed even if the local copy was lost.
                try FileManager.default.removeItem(at: input.files[0])
            case "finish":
                let input = try XCTUnwrap(attempt.input)
                XCTAssertTrue(
                    attempt.imagesAttached && attempt.linksAttached && attempt.needsPollCheck)
                _ = try attempt.prepare(input)
                try await attempt.saveAttachments(
                    files: input.files, links: input.links, poll: input.poll, repository: repo)
                let id = try XCTUnwrap(attempt.noticeID)
                let detail = try await repo.detail(id: id)
                XCTAssertEqual(detail.title, input.draft.title)
                XCTAssertEqual(detail.images?.count, 1)
                XCTAssertEqual(detail.links?.map(\.url), input.links)
                XCTAssertEqual(detail.vote?.title, input.poll?.title)
                try attempt.finish()
            default:
                XCTFail("알 수 없는 자식 프로세스 단계")
                return
            }
            try Data().write(to: root.appending(path: "ready-" + step))
            if step != "finish" {
                // The parent terminates this process while the journal lock is held.
                try await Task.sleep(for: .seconds(40))
                XCTFail("부모 프로세스가 종료를 요청하지 않았습니다.")
            }
            withExtendedLifetime(attempt) {}
        }
    }
#endif
