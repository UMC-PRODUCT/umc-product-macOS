//
//  ThreadConversationModelTests.swift
//  CommunityPresentationTests
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import Foundation
import Testing

@testable import CommunityPresentation

@MainActor
struct ThreadConversationModelTests {
    @Test func restoresAccountScopedDraftAndReusesTheKeyAfterAmbiguousFailure() async throws {
        let repository = ConversationTestRepository()
        let account = UUID().uuidString
        let thread = "71"
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let original = ThreadConversationModel(
            threadID: thread, accountID: account,
            repository: repository, defaults: defaults)
        original.text = "합성 초안"
        original.selectReply("11")
        await original.refresh()
        original.send()
        try await settle(original)
        #expect(original.text == "합성 초안")
        let other = ThreadConversationModel(
            threadID: thread, accountID: UUID().uuidString,
            repository: repository, defaults: defaults)
        #expect(other.text.isEmpty && other.reply == nil)
        let restored = ThreadConversationModel(
            threadID: thread, accountID: account,
            repository: repository, defaults: defaults)
        #expect(restored.text == "합성 초안" && restored.reply == "11")
        await restored.refresh()
        restored.send()
        try await settle(restored)
        let keys = await repository.keys
        #expect(keys.count == 2 && Set(keys).count == 1)
        #expect(restored.text.isEmpty && restored.reply == nil)
    }

    @Test func sameAccountAndThreadKeepSeparateDraftsAcrossSuites() throws {
        let firstSuite = UUID().uuidString
        let secondSuite = UUID().uuidString
        let first = try #require(UserDefaults(suiteName: firstSuite))
        let second = try #require(UserDefaults(suiteName: secondSuite))
        defer {
            first.removePersistentDomain(forName: firstSuite)
            second.removePersistentDomain(forName: secondSuite)
        }
        let repository = ConversationTestRepository()
        func open(_ defaults: UserDefaults) -> ThreadConversationModel {
            ThreadConversationModel(threadID: "71", accountID: "101",
                                    repository: repository, defaults: defaults)
        }
        let live = open(first)
        live.text = "첫 번째 합성 초안"
        live.selectReply("11")
        let qa = open(second)
        #expect(qa.text.isEmpty && qa.reply == nil)
        qa.text = "두 번째 합성 초안"
        #expect(open(first).text == "첫 번째 합성 초안")
        #expect(open(first).reply == "11")
        #expect(open(second).text == "두 번째 합성 초안")
        qa.text = ""
        #expect(second.object(forKey: "community.conversation.101.71") == nil)
        #expect(open(first).text == "첫 번째 합성 초안")
    }

    @Test func windowsShareAttachmentsAndAnOlderSendPreservesNewerDraft() async throws {
        let repository = ConversationTestRepository()
        await repository.pauseNextSend()
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        func open(_ storage: UserDefaults) -> ThreadConversationModel {
            ThreadConversationModel(threadID: "71", accountID: "101",
                                    repository: repository, defaults: storage)
        }
        let main = open(defaults)
        let separate = open(try #require(UserDefaults(suiteName: suite)))
        let image = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString + ".png")
        try Data([1]).write(to: image)
        defer { try? FileManager.default.removeItem(at: image) }
        main.attach([image])
        let file = try #require(separate.attachments.first)
        separate.removeFile(file.id)
        #expect(main.attachments.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: file.localURL.path))

        main.text = "전송 중인 초안"
        await main.refresh()
        main.send()
        await repository.waitForSend()
        separate.text = "새 초안"
        separate.attach([image])
        let newFile = try #require(main.attachments.first)
        defer { separate.removeFile(newFile.id) }
        await repository.resumeSend()
        try await settle(main)
        #expect(main.text == "새 초안")
        #expect(main.attachments.first?.id == newFile.id)
        #expect(FileManager.default.fileExists(atPath: newFile.localURL.path))
        let saved = try #require(defaults.data(forKey: "community.conversation.101.71"))
        let json = try #require(JSONSerialization.jsonObject(with: saved) as? [String: Any])
        #expect(json["text"] as? String == "새 초안")
    }

    @Test(arguments: [true, false])
    func deniedHistoryDiscardsFailedWriteBeforeAnotherUpload(refreshFirst: Bool) async throws {
        let repository = ConversationTestRepository()
        await repository.failUploads()
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = ThreadConversationModel(threadID: "71", accountID: "101",
                                            repository: repository, defaults: defaults)
        let url = FileManager.default.temporaryDirectory.appending(path: suite + ".png")
        try Data([1]).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        model.attach([url])
        let file = try #require(model.attachments.first)
        defer { model.removeFile(file.id) }
        await model.refresh()
        model.send()
        try await settle(model)
        #expect(await repository.uploadCount == 1)
        await repository.revoke()
        if refreshFirst { await model.refresh() }
        model.retry()
        try await settle(model)
        #expect(!model.loaded && !model.canRetry && !model.canSend)
        #expect(await repository.uploadCount == 1)
        #expect(await repository.keys.isEmpty)
    }

    @Test(arguments: [true, false])
    func membershipDenialInSeparateWindowCancelsMainWindowUpload(socketFirst: Bool) async throws {
        let repository = ConversationTestRepository()
        await repository.pauseUploads()
        await repository.seedHistory()
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        func open() -> ThreadConversationModel {
            ThreadConversationModel(threadID: "71", accountID: "101",
                                    repository: repository, defaults: defaults)
        }
        let main = open()
        let separate = open()
        let url = FileManager.default.temporaryDirectory.appending(path: suite + ".png")
        try Data([1]).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        main.attach([url])
        let file = try #require(main.attachments.first)
        defer { main.removeFile(file.id) }
        await main.refresh()
        main.send()
        let deadline = ContinuousClock.now + .seconds(2)
        while await repository.uploadCount == 0 && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(await repository.uploadCount == 1)
        await separate.refresh()
        #expect(main.messages.count == 1 && separate.messages.count == 1)
        if socketFirst {
            await repository.rejectNextCommand(.denied("참여 권한이 없어요."))
            separate.perform(.react(message: "1", emoji: "👍", adding: true))
            try await settle(separate)
        } else {
            await repository.revoke()
            await separate.refresh()
        }
        // REST history can succeed after leaving the thread.
        await main.refresh()
        await separate.refresh()
        #expect(main.messages.isEmpty && separate.messages.isEmpty)
        #expect(!separate.loaded && !separate.canRetry && !separate.canSend)
        main.retry()
        main.send()
        try await settle(main)
        #expect(!main.loaded && !main.canRetry)
        #expect(await repository.uploadCancelled)
        #expect(await repository.keys.isEmpty)
    }

    @Test func commandDenialPreservesMembershipAndAmbiguousSendCanRetry() async throws {
        let repository = ConversationTestRepository()
        let suite = UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let model = ThreadConversationModel(threadID: "71", accountID: "101",
                                            repository: repository, defaults: defaults)
        await model.refresh()
        model.text = "합성 메시지"
        await repository.rejectNextCommand(.commandDenied("수정 권한이 없어요."))
        model.perform(.edit(message: "1", content: "수정"))
        try await settle(model)
        #expect(!model.canRetry && model.loaded && model.canSend)
        model.send()
        try await settle(model)
        #expect(model.canRetry && model.loaded && model.text == "합성 메시지")
        model.retry()
        try await settle(model)
        let keys = await repository.keys
        #expect(keys.count == 2 && Set(keys).count == 1 && model.text.isEmpty)
    }

    private func settle(_ model: ThreadConversationModel) async throws {
        let deadline = ContinuousClock.now + .seconds(2)
        while model.busy && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(!model.busy)
    }
}

private actor ConversationTestRepository: ThreadConversationRepository {
    var keys: [String] = []
    var uploadCount = 0
    var uploadCancelled = false
    private var messages: [ThreadConversationMessage] = []
    private var rejection: ThreadConversationRejection?
    func rejectNextCommand(_ error: ThreadConversationRejection) { rejection = error }
    private var pauseUpload = false
    private var uploadFails = false
    private var denied = false
    private var pause = false
    private var sendStart: CheckedContinuation<Void, Never>?
    private var sendFinish: CheckedContinuation<Void, Never>?

    func seedHistory() {
        messages = [.init(id: "1", authorID: "101", author: "회원", text: "대화",
                          createdAt: nil, replyID: nil, files: [], reactions: [], isHidden: false)]
    }
    func pauseUploads() { pauseUpload = true }
    func failUploads() { uploadFails = true }
    func revoke() { denied = true }
    func pauseNextSend() { pause = true }

    func waitForSend() async {
        if sendFinish == nil { await withCheckedContinuation { sendStart = $0 } }
    }

    func resumeSend() {
        sendFinish?.resume()
        sendFinish = nil
    }

    func history(
        thread: String, before: String?
    ) async throws -> ThreadPage<ThreadConversationMessage> {
        if denied { throw ThreadConversationRejection.denied("참여 권한이 없어요.") }
        return .init(values: messages, cursor: nil)
    }

    func members(thread: String, query: String) async throws -> [ThreadManagementPerson] { [] }

    func perform(_ command: ThreadConversationCommand, thread: String) async throws {
        if let rejection {
            self.rejection = nil
            throw rejection
        }
        guard case .create(let key, _, _, _, _) = command else { return }
        keys.append(key)
        if pause {
            pause = false
            await withCheckedContinuation {
                sendFinish = $0
                sendStart?.resume()
                sendStart = nil
            }
            return
        }
        if keys.count == 1 { throw URLError(.timedOut) }
    }

    func observeChanges(thread: String, changed: @escaping @Sendable () async -> Void) async throws
    {}

    func upload(name: String, contentType: String, data: Data) async throws -> String {
        uploadCount += 1
        if pauseUpload {
            do { try await Task.sleep(for: .seconds(10)) } catch {
                uploadCancelled = true
                throw error
            }
        }
        if uploadFails { throw URLError(.timedOut) }
        return "photo"
    }
}
