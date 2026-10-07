//
//  AppDependencies.swift
//  UMCDesk
//
//  Created by euijjang97 on 10/6/26.
//

import Foundation
import CoreDI
import CoreDomain
import UMCFoundation
import CoreNetwork

/// One composition root for every window and app-level scene.
@MainActor
final class AppDependencies {
    let container: DIContainer
    let userSession: UserSessionManager

    init() {
        let container = DIContainer()
        let userSession = UserSessionManager()
        let tokenStore = KeychainTokenStore()
        let environment: NetworkEnvironment
        do {
            environment = NetworkEnvironment(baseURL: try APIConfig.baseURL())
        } catch {
            preconditionFailure("Missing or invalid app BASE_URL configuration")
        }
        let client = AuthSystemFactory.makeNetworkClient(
            environment: environment,
            tokenStore: tokenStore,
            sessionResetter: SessionResetHandler {
                userSession.reset()
                container.resetCache()
            }
        )
        let adapter = MoyaNetworkAdapter(networkClient: client)
        self.container = container
        self.userSession = userSession
        container.registerInstance(TokenStore.self, instance: tokenStore)
        container.registerInstance(NetworkClient.self, instance: client)
        container.registerInstance(MoyaNetworkAdapter.self, instance: adapter)
        container.registerInstance(UserSessionManager.self, instance: userSession)
    }
}
