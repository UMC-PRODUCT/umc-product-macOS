//
//  InfrastructureTests.swift
//  UMCDeskTests
//
//  Created by euijjang97 on 10/6/26.
//

import Foundation
import Security
import Testing
import UMCFoundation
@testable import CoreNetwork

struct InfrastructureTests {
    @Test("Flexible numeric decoding preserves valid values and rejects overflow")
    func numericDecodingDoesNotTrap() throws {
        let decoder = JSONDecoder()
        for value in ["42", "\"42\"", "42.9"] {
            let data = Data("{\"value\":\(value)}".utf8)
            #expect(try decoder.decode(FlexibleInteger.self, from: data).value == 42)
            #expect(try decoder.decode(FlexibleString.self, from: data).value == "42")
        }
        for value in ["1e100", "-1e100"] {
            let data = Data("{\"value\":\(value)}".utf8)
            #expect(throws: DecodingError.self) {
                try decoder.decode(FlexibleInteger.self, from: data)
            }
            #expect(throws: DecodingError.self) {
                try decoder.decode(FlexibleString.self, from: data)
            }
        }
    }

    @Test("Keychain deletion failure is propagated to the logout caller")
    func deletionFailureIsReported() async {
        let store = KeychainTokenStore(service: "test.tokens") { _ in errSecAuthFailed }
        await #expect(throws: KeychainError.deleteFailed(status: errSecAuthFailed)) {
            try await store.clear()
        }
    }

    @Test("Already absent Keychain credentials can be cleared")
    func missingCredentialsCanBeCleared() async throws {
        let store = KeychainTokenStore(service: "test.tokens") { _ in errSecItemNotFound }
        try await store.clear()
        #expect(await store.getAccessToken() == nil)
        #expect(await store.getRefreshToken() == nil)
    }
}

private struct FlexibleInteger: Decodable {
    let value: Int
    private enum CodingKeys: String, CodingKey { case value }

    init(from decoder: Decoder) throws {
        value = try decoder.container(keyedBy: CodingKeys.self).decodeIntFlexible(forKey: .value)
    }
}

private struct FlexibleString: Decodable {
    let value: String
    private enum CodingKeys: String, CodingKey { case value }

    init(from decoder: Decoder) throws {
        value = try decoder.container(keyedBy: CodingKeys.self).decodeFlexibleString(forKey: .value)
    }
}
