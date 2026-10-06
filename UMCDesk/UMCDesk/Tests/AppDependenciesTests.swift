//
//  AppDependenciesTests.swift
//  UMCDeskTests
//
//  Created by euijjang97 on 10/6/26.
//

import Testing
import CoreNetwork
@testable import UMCDesk

@Suite("App-wide dependency lifetime")
@MainActor
struct AppDependenciesTests {
    @Test("Window consumers share transport after session cache reset")
    func sharedTransportSurvivesSessionReset() throws {
        let dependencies = AppDependencies()
        let client = dependencies.container.resolve(NetworkClient.self)
        let store = try #require(
            dependencies.container.resolve(TokenStore.self) as? KeychainTokenStore
        )
        dependencies.container.resetCache()
        #expect(client === dependencies.container.resolve(NetworkClient.self))
        let resolvedStore = try #require(
            dependencies.container.resolve(TokenStore.self) as? KeychainTokenStore
        )
        #expect(store === resolvedStore)
    }
}
