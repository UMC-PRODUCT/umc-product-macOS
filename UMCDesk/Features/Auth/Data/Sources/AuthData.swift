//
//  AuthData.swift
//  AuthData
//
//  Created by euijjang97 on 10/6/26.
//

import AuthDomain
import CoreNetwork
import Foundation
import Moya
import UMCFoundation

public struct LiveEmailLoginRepository: EmailLoginRepository {
    private let client: NetworkClient
    private let adapter: MoyaNetworkAdapter
    private let environment: NetworkEnvironment

    public init(client: NetworkClient, adapter: MoyaNetworkAdapter, environment: NetworkEnvironment) {
        self.client = client
        self.adapter = adapter
        self.environment = environment
    }

    public func login(email: String, password: String) async throws {
        let target = EmailLoginTarget(environment: environment, body: .init(
            email: email.trimmingCharacters(in: .whitespacesAndNewlines), password: password
        ))
        try await client.signIn {
            do {
                let response = try await adapter.requestWithoutAuth(target)
                let result = try JSONDecoder().decode(
                    APIResponse<LoginResponse>.self, from: response.data
                ).unwrap()
                guard !result.memberId.isEmpty else { throw NetworkError.invalidResponse }
                return TokenPair(accessToken: result.accessToken, refreshToken: result.refreshToken)
            } catch NetworkError.requestFailed(let status, _) where status == 401 {
                throw EmailLoginError.invalidCredentials
            }
        }
    }
}

private struct EmailLoginTarget: BaseTargetType {
    struct Body: Encodable, Sendable {
        let email: String
        let password: String
    }
    let environment: NetworkEnvironment
    let body: Body
    let path = "/api/v1/auth/login/email"
    var method: Moya.Method { .post }
    var task: Moya.Task { .requestJSONEncodable(body) }
}

private struct LoginResponse: Codable {
    let memberId: String
    let accessToken: String
    let refreshToken: String
    enum CodingKeys: CodingKey { case memberId, accessToken, refreshToken }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        memberId = try values.decodeFlexibleString(forKey: .memberId)
        accessToken = try values.decode(String.self, forKey: .accessToken)
        refreshToken = try values.decode(String.self, forKey: .refreshToken)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(memberId, forKey: .memberId)
        try values.encode(accessToken, forKey: .accessToken)
        try values.encode(refreshToken, forKey: .refreshToken)
    }
}
