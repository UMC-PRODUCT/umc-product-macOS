//
//  NetworkEnvironment.swift
//  UMCNetworkKit
//
//  Created by euijjang97 on 10/6/26.
//

import Foundation

/// Immutable environment supplied by the host app.
public struct NetworkEnvironment: Sendable {
    public let baseURL: URL
    public let defaultHeaders: [String: String]

    public init(
        baseURL: URL,
        defaultHeaders: [String: String] = ["Content-Type": "application/json"]
    ) {
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
    }
}
