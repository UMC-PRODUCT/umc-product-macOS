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

extension LiveEmailLoginRepository: AuthFlowRepository {
    public func isInMaintenance() async throws -> Bool {
        let response: StatusResponse = try await request("/system/status")
        return response.inMaintenance && response.current?.scope == "FULL"
    }

    public func schools() async throws -> [RegistrationSchool] {
        let response: SchoolsResponse = try await request("/schools/all")
        return response.schools.map { RegistrationSchool(id: $0.schoolId, name: $0.schoolName) }
    }

    public func terms() async throws -> [RegistrationTerm] {
        let response: TermsResponse = try await request("/terms")
        return response.terms.map {
            RegistrationTerm(id: $0.id, title: $0.typeDescription, link: $0.link,
                             isMandatory: $0.isMandatory, type: $0.type)
        }
    }

    public func sendCode(email: String, purpose: VerificationPurpose) async throws -> String {
        let body = VerificationRequest(email: email, purpose: purpose.rawValue)
        let response: VerificationSession = try await request(
            "/auth/email-verification", .post, .requestJSONEncodable(body)
        )
        return response.emailVerificationId
    }

    public func resendCode(sessionID: String) async throws {
        let body = VerificationSessionRequest(emailVerificationId: try numericID(sessionID))
        let _: EmptyResult = try await request(
            "/auth/email-verification/resend", .post, .requestJSONEncodable(body)
        )
    }

    public func verifyCode(sessionID: String, code: String) async throws -> String {
        let body = CodeRequest(emailVerificationId: try numericID(sessionID), verificationCode: code)
        let response: VerificationToken = try await request(
            "/auth/email-verification/code", .post, .requestJSONEncodable(body)
        )
        guard !response.emailVerificationToken.isEmpty else { throw NetworkError.invalidResponse }
        return response.emailVerificationToken
    }

    public func register(_ registration: EmailRegistration) async throws {
        let agreements = try registration.agreements.map {
            TermAgreement(termsId: try numericID($0.key), isAgreed: $0.value)
        }
        let body = RegistrationRequest(
            rawPassword: registration.password, name: registration.name,
            nickname: registration.nickname, emailVerificationToken: registration.verificationToken,
            schoolId: try numericID(registration.schoolID), termsAgreements: agreements
        )
        let receipt = RegistrationReceipt()
        do {
            try await client.signIn {
                let result: LoginResponse = try await request(
                    "/member/register/email", .post, .requestJSONEncodable(body)
                )
                await receipt.markCreated()
                guard !result.memberId.isEmpty else { throw NetworkError.invalidResponse }
                return TokenPair(accessToken: result.accessToken, refreshToken: result.refreshToken)
            }
        } catch {
            if await receipt.created { throw AuthFlowError.registrationSessionUnavailable }
            throw error
        }
    }

    public func resetPassword(token: String, password: String) async throws {
        let body = ResetRequest(emailVerificationToken: token, newPassword: password)
        let _: EmptyResult = try await request(
            "/auth/password/reset", .patch, .requestJSONEncodable(body)
        )
    }

    public func linkChallenger(code: String) async throws {
        let _: EmptyResult = try await request(
            "/challenger-record/member", .post, .requestJSONEncodable(ChallengerRequest(code: code)),
            authenticated: true
        )
    }

    public func withdraw() async throws {
        let _: EmptyResult = try await request("/member", .delete, authenticated: true)
    }

    private func numericID(_ id: String) throws -> Int64 {
        guard let value = Int64(id), value > 0 else { throw NetworkError.invalidResponse }
        return value
    }

    private func request<Result: Codable>(
        _ path: String, _ method: Moya.Method = .get, _ task: Moya.Task = .requestPlain,
        authenticated: Bool = false
    ) async throws -> Result {
        let target = AuthTarget(environment: environment, path: "/api/v1" + path,
                                method: method, task: task)
        do {
            let response = try await authenticated
                ? adapter.request(target) : adapter.requestWithoutAuth(target)
            return try JSONDecoder().decode(APIResponse<Result>.self, from: response.data).unwrap()
        } catch NetworkError.requestFailed(let status, let data) {
            guard let data, let envelope = try? JSONDecoder().decode(
                APIResponse<EmptyResult>.self, from: data
            ) else { throw NetworkError.requestFailed(statusCode: status, data: data) }
            switch envelope.code {
            case "AUTHENTICATION-0004": throw AuthFlowError.invalidVerificationCode
            case "AUTHENTICATION-0018": throw AuthFlowError.verificationExpired
            case "CHALLENGER-0012": throw AuthFlowError.usedChallengerCode
            default:
                guard envelope.message != nil else {
                    throw NetworkError.requestFailed(statusCode: status, data: data)
                }
                throw RepositoryError.serverError(code: envelope.code, message: envelope.message)
            }
        }
    }
}

private actor RegistrationReceipt {
    private(set) var created = false
    func markCreated() { created = true }
}

private struct AuthTarget: BaseTargetType {
    let environment: NetworkEnvironment
    let path: String
    let method: Moya.Method
    let task: Moya.Task
}

private struct VerificationRequest: Encodable {
    let email: String
    let purpose: String
}
private struct VerificationSessionRequest: Encodable {
    let emailVerificationId: Int64
}
private struct CodeRequest: Encodable {
    let emailVerificationId: Int64
    let verificationCode: String
}
private struct ChallengerRequest: Encodable {
    let code: String
}
private struct ResetRequest: Encodable {
    let emailVerificationToken: String
    let newPassword: String
}
private struct TermAgreement: Encodable {
    let termsId: Int64
    let isAgreed: Bool
}
private struct RegistrationRequest: Encodable {
    let rawPassword: String
    let name: String
    let nickname: String
    let emailVerificationToken: String
    let schoolId: Int64
    let termsAgreements: [TermAgreement]
}

private struct StatusResponse: Codable {
    let inMaintenance: Bool
    let current: MaintenanceWindow?
    enum CodingKeys: CodingKey { case inMaintenance, current }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        current = try values.decodeIfPresent(MaintenanceWindow.self, forKey: .current)
        inMaintenance = try values.decode(Bool.self, forKey: .inMaintenance)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(current, forKey: .current)
        try values.encode(inMaintenance, forKey: .inMaintenance)
    }
}

private struct SchoolsResponse: Codable {
    let schools: [SchoolItem]
    enum CodingKeys: CodingKey { case schools }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schools = try values.decode([SchoolItem].self, forKey: .schools)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(schools, forKey: .schools)
    }
}

private struct TermsResponse: Codable {
    let terms: [TermItem]
    enum CodingKeys: CodingKey { case terms }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        terms = try values.decode([TermItem].self, forKey: .terms)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(terms, forKey: .terms)
    }
}

private struct SchoolItem: Codable {
    let schoolId: String
    let schoolName: String
    enum CodingKeys: CodingKey { case schoolId, schoolName }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schoolId = try values.decodeFlexibleString(forKey: .schoolId)
        schoolName = try values.decode(String.self, forKey: .schoolName)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(schoolId, forKey: .schoolId)
        try values.encode(schoolName, forKey: .schoolName)
    }
}

private struct TermItem: Codable {
    let id: String
    let type: String?
    let typeDescription: String
    let link: String
    let isMandatory: Bool
    enum CodingKeys: CodingKey { case id, type, typeDescription, link, isMandatory }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeFlexibleString(forKey: .id)
        type = try values.decodeIfPresent(String.self, forKey: .type)
        typeDescription = try values.decode(String.self, forKey: .typeDescription)
        link = try values.decode(String.self, forKey: .link)
        isMandatory = try values.decode(Bool.self, forKey: .isMandatory)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encodeIfPresent(type, forKey: .type)
        try values.encode(typeDescription, forKey: .typeDescription)
        try values.encode(link, forKey: .link)
        try values.encode(isMandatory, forKey: .isMandatory)
    }
}

private struct VerificationSession: Codable {
    let emailVerificationId: String
    enum CodingKeys: CodingKey { case emailVerificationId }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        emailVerificationId = try values.decodeFlexibleString(forKey: .emailVerificationId)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(emailVerificationId, forKey: .emailVerificationId)
    }
}

private struct VerificationToken: Codable {
    let emailVerificationToken: String
    enum CodingKeys: CodingKey { case emailVerificationToken }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        emailVerificationToken = try values.decode(String.self, forKey: .emailVerificationToken)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(emailVerificationToken, forKey: .emailVerificationToken)
    }
}

private struct MaintenanceWindow: Codable {
    let scope: String
    enum CodingKeys: CodingKey { case scope }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        scope = try values.decode(String.self, forKey: .scope)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(scope, forKey: .scope)
    }
}
