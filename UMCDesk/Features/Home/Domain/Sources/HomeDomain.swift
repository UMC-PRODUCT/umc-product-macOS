//
//  HomeDomain.swift
//  HomeDomain
//
//  Created by euijjang97 on 11/23/26.
//

import Foundation

public struct HomeProfile: Sendable {
    public let id: String
    public let nickname: String

    public init(
        id: String,
        nickname: String
    ) {
        self.id = id
        self.nickname = nickname
    }
}

public protocol HomeRepository: Sendable {
    func profile() async throws -> HomeProfile
    func schedule() async throws -> String?
    func notice() async throws -> String?
    func project() async throws -> String?
}
