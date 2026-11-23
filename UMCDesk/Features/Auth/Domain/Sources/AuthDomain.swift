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

public enum VerificationPurpose: String, Sendable {
    case registration = "REGISTER"
    case passwordReset = "PASSWORD_RESET"
}

public struct RegistrationSchool: Sendable, Identifiable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct RegistrationTerm: Sendable, Identifiable {
    public let id: String
    public let type: String?
    public let title: String
    public let link: String
    public let isMandatory: Bool

    public init(id: String, title: String, link: String, isMandatory: Bool, type: String? = nil) {
        self.type = type
        self.id = id
        self.title = title
        self.link = link
        self.isMandatory = isMandatory
    }
}

public struct EmailRegistration: Sendable {
    public let name: String
    public let nickname: String
    public let password: String
    public let verificationToken: String
    public let schoolID: String
    public let agreements: [String: Bool]

    public init(name: String, nickname: String, password: String, verificationToken: String,
                schoolID: String, agreements: [String: Bool]) {
        self.name = name
        self.nickname = nickname
        self.password = password
        self.verificationToken = verificationToken
        self.schoolID = schoolID
        self.agreements = agreements
    }
}

public protocol AuthFlowRepository: Sendable {
    func isInMaintenance() async throws -> Bool
    func schools() async throws -> [RegistrationSchool]
    func terms() async throws -> [RegistrationTerm]
    func sendCode(email: String, purpose: VerificationPurpose) async throws -> String
    func resendCode(sessionID: String) async throws
    func verifyCode(sessionID: String, code: String) async throws -> String
    func register(_ registration: EmailRegistration) async throws
    func resetPassword(token: String, password: String) async throws
    func linkChallenger(code: String) async throws
    func withdraw() async throws
}

public enum AuthFlowError: Error {
    case registrationSessionUnavailable
    case verificationExpired
    case invalidVerificationCode
    case usedChallengerCode
}
