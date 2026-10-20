//
//  SettingsUseCaseTests.swift
//  SettingsDomainTests
//
//  Created by euijjang97 on 10/20/26.
//

import Foundation
import Testing
@testable import SettingsDomain

@Suite("Settings validation")
struct SettingsUseCaseTests {
    @Test("Replace-all saves preserve every nonempty link and trim edges")
    func preservesAllLinks() async throws {
        let repository = RecordingSettingsRepository()
        let useCase = DefaultSettingsUseCase(repository: repository)
        _ = try await useCase.updateProfileLinks(.init(
            github: " https://github.com/umc \n", blog: "https://blog.example.com"
        ))
        #expect(await repository.savedLinks == .init(
            github: "https://github.com/umc", blog: "https://blog.example.com"
        ))
        _ = try await useCase.updateProfileLinks(.init())
        #expect(await repository.savedLinks == .init())
    }

    @Test("Unsafe links never reach the repository", arguments: [
        "javascript:alert(1)", "file:///private/data", "https://user:secret@example.com",
        "https://", "example.com", "https://example.com/a b"
    ])
    func rejectsUnsafeLink(value: String) async {
        let repository = RecordingSettingsRepository()
        let useCase = DefaultSettingsUseCase(repository: repository)
        await #expect(throws: SettingsError.invalidLink(.github)) {
            _ = try await useCase.updateProfileLinks(.init(github: value))
        }
        #expect(await repository.savedLinks == nil)
    }

    @Test("Code stays opaque and case-sensitive")
    func preservesCode() async throws {
        let repository = RecordingSettingsRepository()
        let useCase = DefaultSettingsUseCase(repository: repository)
        try await useCase.registerChallenger(code: " a7B2c9\n")
        #expect(await repository.code == "a7B2c9")
        await #expect(throws: SettingsError.invalidChallengerCode) {
            try await useCase.registerChallenger(code: "12345")
        }
    }
}

private actor RecordingSettingsRepository: SettingsRepository {
    private(set) var savedLinks: SettingsProfileLinks?
    private(set) var code: String?

    func fetchProfile() async throws -> SettingsProfile {
        .init(id: "1", name: "이름", nickname: "닉네임")
    }
    func updateProfileLinks(_ links: SettingsProfileLinks) async throws -> SettingsProfile {
        savedLinks = links
        return try await fetchProfile()
    }
    func registerChallenger(code: String) async throws { self.code = code }
    func logout() async throws {}
}
