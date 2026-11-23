//
//  MoyaNetworkAdapter.swift
//  CoreNetwork
//
//  Created by euijjang97 on 10/7/26.
//

import AquilaMoya
import Foundation
import Moya

/// Keeps UMC error handling while Aquila performs Moya requests and authentication.
public struct MoyaNetworkAdapter: Sendable {
    private let networkClient: NetworkClient
    private let adapter: AquilaMoya.MoyaNetworkAdapter

    public init(networkClient: NetworkClient) {
        self.networkClient = networkClient
        adapter = AquilaMoya.MoyaNetworkAdapter(networkClient: networkClient.aquilaClient)
    }

    public func request<T: TargetType>(_ target: T) async throws -> Response {
        do {
            try await networkClient.validateScope()
            let response = try await CredentialRequest.$scope.withValue(networkClient.accountScope) {
                try await adapter.request(target)
            }
            try await networkClient.validateScope()
            return response
        } catch {
            try await networkClient.validateScope()
            throw NetworkClient.appError(from: error)
        }
    }

    public func requestWithoutAuth<T: TargetType>(_ target: T) async throws -> Response {
        do {
            return try await adapter.requestWithoutAuth(target)
        } catch {
            throw NetworkClient.appError(from: error)
        }
    }
}
