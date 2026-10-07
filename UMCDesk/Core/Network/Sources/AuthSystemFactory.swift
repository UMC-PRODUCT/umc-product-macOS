//
//  AuthSystemFactory.swift
//  CoreNetwork
//
//  Created by euijjang97 on 10/6/26.
//

import Foundation

public enum AuthSystemFactory {
    /// The host app supplies the shared store and its session cleanup action.
    public static func makeNetworkClient(
        environment: NetworkEnvironment,
        tokenStore: any TokenStore,
        session: URLSession = .shared,
        sessionResetter: (any SessionResetting)? = nil
    ) -> NetworkClient {
        NetworkClient(
            session: session,
            tokenStore: tokenStore,
            refreshService: TokenRefreshServiceImpl(
                baseURL: environment.baseURL,
                session: session
            ),
            sessionResetter: sessionResetter
        )
    }
}
