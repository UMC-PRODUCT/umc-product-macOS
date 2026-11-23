//
//  AuthDomain.swift
//  AuthDomain
//
//  Created by euijjang97 on 10/6/26.
//

public protocol EmailLoginRepository: Sendable {
    func login(email: String, password: String) async throws
}

public enum EmailLoginError: Error {
    case invalidCredentials
}
