//
//  MoyaNetworkAdapter.swift
//  UMCNetworkKit
//
//  Created by euijjang97 on 10/6/26.
//

import Foundation
import Moya

/// Converts Moya targets to requests and delegates authentication to NetworkClient.
public struct MoyaNetworkAdapter: Sendable {
    private let networkClient: NetworkClient
    private let baseURL: URL
    private let session: URLSession

    public init(
        networkClient: NetworkClient,
        baseURL: URL,
        session: URLSession = .shared
    ) {
        self.networkClient = networkClient
        self.baseURL = baseURL
        self.session = session
    }

    public func request<T: TargetType>(_ target: T) async throws -> Response {
        let request = try buildURLRequest(target)
        let (data, response) = try await networkClient.request(request)
        return Response(
            statusCode: response.statusCode,
            data: data,
            request: request,
            response: response
        )
    }

    /// Login and registration bypass token injection and the refresh policy.
    public func requestWithoutAuth<T: TargetType>(_ target: T) async throws -> Response {
        let request = try buildURLRequest(target)
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        guard (200...299).contains(response.statusCode) else {
            throw NetworkError.requestFailed(statusCode: response.statusCode, data: data)
        }
        return Response(
            statusCode: response.statusCode,
            data: data,
            request: request,
            response: response
        )
    }

    private func buildURLRequest<T: TargetType>(_ target: T) throws -> URLRequest {
        // Endpoint handles Moya's type-erased parameters using its own encoding rules.
        let endpoint = Endpoint(
            url: baseURL.appending(path: target.path).absoluteString,
            sampleResponseClosure: { .networkResponse(200, Data()) },
            method: target.method,
            task: target.task,
            httpHeaderFields: target.headers
        )
        var request = try endpoint.urlRequest()
        switch target.task {
        case .uploadFile(let file):
            request.httpBody = try Data(contentsOf: file)
        case .uploadMultipart, .uploadCompositeMultipart,
             .downloadDestination, .downloadParameters:
            throw NetworkAdapterError.unsupportedTransferTask
        default:
            break
        }
        return request
    }
}

public enum NetworkAdapterError: Error {
    case unsupportedTransferTask
}
