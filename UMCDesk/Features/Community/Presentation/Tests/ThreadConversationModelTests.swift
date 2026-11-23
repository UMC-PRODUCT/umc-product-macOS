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

    func history(
        thread: String, before: String?
    ) async throws -> ThreadPage<ThreadConversationMessage> { .init(values: [], cursor: nil) }

    func members(thread: String, query: String) async throws -> [ThreadManagementPerson] { [] }

    func perform(_ command: ThreadConversationCommand, thread: String) async throws {
        guard case .create(let key, _, _, _, _) = command else { return }
        keys.append(key)
        if keys.count == 1 { throw URLError(.timedOut) }
    }

    func observeChanges(thread: String, changed: @escaping @Sendable () async -> Void) async throws
    {}

    func upload(name: String, contentType: String, data: Data) async throws -> String { "photo" }
}
