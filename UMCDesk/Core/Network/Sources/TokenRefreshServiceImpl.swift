//
//  TokenRefreshServiceImpl.swift
//  CoreNetwork
//
//  Created by euijjang97 on 10/7/26.
//

import Aquila
import Foundation
import UMCFoundation

struct TokenRefreshServiceImpl: TokenRefreshService {
    // MARK: - Property

    private let service: Aquila.HTTPTokenRefreshService

    // MARK: - Init

    nonisolated init(
        baseURL: URL,
        session: URLSession = .shared,
        decoder: JSONDecoder = JSONDecoder()
    ) {
        service = Aquila.HTTPTokenRefreshService(
            session: session,
            logger: NetworkClient.logger,
            makeRequest: { refreshToken in
                var request = URLRequest(url: baseURL.appending(path: "api/v1/auth/token/renew"))
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = try JSONEncoder().encode(
                    RefreshTokenRequestBody(refreshToken: refreshToken)
                )
                return request
            },
            decodeTokens: { data, _ in
                let response = try decoder.decode(APIResponse<TokenResult>.self, from: data)
                let result = try response.unwrap()
                return TokenPair(
                    accessToken: result.accessToken, refreshToken: result.refreshToken
                )
            }
        )
    }

    // MARK: - Function

    func refresh(_ refreshToken: String) async throws -> TokenPair {
        try await service.refresh(refreshToken)
    }
}

private struct RefreshTokenRequestBody: Encodable {
    let refreshToken: String
}

private struct TokenResult: Codable, Sendable {
    let accessToken: String
    let refreshToken: String

    private enum CodingKeys: String, CodingKey {
        case accessToken
        case refreshToken
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
        refreshToken = try container.decode(String.self, forKey: .refreshToken)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(accessToken, forKey: .accessToken)
        try container.encode(refreshToken, forKey: .refreshToken)
    }
}
