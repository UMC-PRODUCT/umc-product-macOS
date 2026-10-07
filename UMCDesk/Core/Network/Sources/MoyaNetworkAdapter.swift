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
    private let adapter: AquilaMoya.MoyaNetworkAdapter

    public init(networkClient: NetworkClient) {
        adapter = AquilaMoya.MoyaNetworkAdapter(networkClient: networkClient.aquilaClient)
    }

    public func request<T: TargetType>(_ target: T) async throws -> Response {
        do {
            return try await adapter.request(target)
        } catch {
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
