//
//  ThreadManagementRepository.swift
//  CommunityData
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import CoreNetwork
import Foundation
import Moya
import UMCFoundation

public struct LiveThreadManagementRepository: ThreadManagementRepository {
    private let adapter: MoyaNetworkAdapter
    private let environment: NetworkEnvironment

    public init(adapter: MoyaNetworkAdapter, environment: NetworkEnvironment) {
        self.adapter = adapter
        self.environment = environment
    }

    public func detail(threadID: String) async throws -> ThreadManagementDetail {
        let response: ThreadManagementDetailResponse = try await request(threadPath(threadID))
        return response.model
    }

    public func people(threadID: String, invitable: Bool, query: String, offset: String?)
        async throws -> ThreadManagementPage {
        let suffix = invitable ? "/invitable" : "/members"
        let fields = PeopleQuery(text: query, offset: offset)
        let task = Moya.Task.requestParameters(parameters: fields.parameters,
                                               encoding: URLEncoding.queryString)
        let response: ThreadManagementPageResponse = try await request(
            threadPath(threadID) + suffix, task: task)
        return response.model
    }

    public func profile(memberID: String) async throws -> ThreadManagementProfile {
        let response: ThreadManagementProfileResponse = try await request(
            "/api/v1/member/profile/" + identifier(memberID))
        return response.model
    }

    public func report(_ target: ThreadReportTarget, reasons: [ThreadReportReason], detail: String)
        async throws -> String {
        let id = try identifier(target.identifier)
        let body = ReportBody(reasons: reasons, detail: target.isMember ? detail : nil)
        let path = target.isMember ? "/api/v1/reports/members/" + id
            : "/api/v1/community/messages/" + id + "/report"
        let receipt: ReportReceipt = try await request(path, method: .post,
                                                       task: .requestJSONEncodable(body))
        _ = try numericID(receipt.reportID)
        guard (target.isMember ? receipt.memberID : receipt.messageID) == id else {
            throw URLError(.cannotParseResponse)
        }
        return receipt.reportID
    }

    public func isBlocked(memberID: String) async throws -> Bool {
        let id = try identifier(memberID)
        let result: BlockedMembers = try await request("/api/v1/member/blocks")
        return result.members.contains { $0.memberID == id }
    }

    public func setBlocked(_ blocked: Bool, memberID: String) async throws {
        let id = try identifier(memberID)
        let result: BlockEntry = try await request("/api/v1/member/blocks/" + id,
                                                   method: blocked ? .post : .delete)
        guard result.memberID == id, result.isBlocked == blocked else {
            throw URLError(.cannotParseResponse)
        }
    }

    public func currentMemberID() async throws -> String {
        let response: CurrentMember = try await request("/api/v1/member/me")
        return response.id
    }

    public func apply(_ action: ThreadManagementAction, threadID: String) async throws {
        var path = try threadPath(threadID)
        let method: Moya.Method
        var task: Moya.Task = .requestPlain
        switch action {
        case .invite(let members):
            let ids = try members.map { try numericID($0) }
            guard (1...99).contains(ids.count), Set(ids).count == ids.count else {
                throw URLError(.badURL)
            }
            path += "/invite"
            method = .post
            task = .requestJSONEncodable(InviteBody(memberIds: ids))
        case .role(let memberID, let role):
            path += try "/members/" + identifier(memberID) + "/role"
            method = .patch
            task = .requestJSONEncodable(RoleBody(role: role))
        case .kick(let memberID):
            path += try "/members/" + identifier(memberID)
            method = .delete
        case .edit(let title, let description):
            method = .patch
            task = .requestJSONEncodable(EditBody(title: title, description: description))
        case .leave:
            path += "/leave"
            method = .post
        case .delete:
            method = .delete
        case .acknowledgeKick:
            path += "/kick/acknowledge"
            method = .post
        }
        let target = ManagementTarget(environment: environment, path: path,
                                      method: method, task: task)
        let response = try await adapter.request(target)
        try JSONDecoder().decode(APIResponse<EmptyResult>.self, from: response.data)
            .validateSuccess()
    }

    private func request<T: Codable>(_ path: String, method: Moya.Method = .get,
                                     task: Moya.Task = .requestPlain)
        async throws -> T {
        let target = ManagementTarget(environment: environment, path: path,
                                      method: method, task: task)
        let response = try await adapter.request(target)
        return try JSONDecoder().decode(APIResponse<T>.self, from: response.data).unwrap()
    }

    private func threadPath(_ id: String) throws -> String {
        try "/api/v1/community/threads/" + identifier(id)
    }

    private func identifier(_ id: String) throws -> String {
        try String(numericID(id))
    }

    private func numericID(_ id: String) throws -> Int64 {
        guard let number = Int64(id), number > 0, String(number) == id else {
            throw URLError(.badURL)
        }
        return number
    }
}

private struct PeopleQuery {
    let text: String
    let offset: String?
    var parameters: [String: String] {
        var parameters = ["offset": offset ?? "0"]
        if !text.isEmpty { parameters["q"] = String(text.unicodeScalars.prefix(80)) }
        return parameters
    }
}

private struct ManagementTarget: BaseTargetType {
    let environment: NetworkEnvironment
    let path: String
    let method: Moya.Method
    let task: Moya.Task
}

private struct InviteBody: Encodable { let memberIds: [Int64] }
private struct RoleBody: Encodable { let role: ThreadManagementRole }
private struct EditBody: Encodable {
    let title: String?
    let description: String?
}

private struct CurrentMember: Codable {
    let id: String
    enum CodingKeys: CodingKey { case id }
    init(from decoder: Decoder) throws {
        id = try decoder.container(keyedBy: CodingKeys.self).decodeFlexibleString(forKey: .id)
    }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
    }
}

private struct ReportBody: Encodable {
    let reasons: [ThreadReportReason]
    let detail: String?
}

private struct ReportReceipt: Codable {
    let reportID: String
    let messageID: String?
    let memberID: String?

    enum CodingKeys: String, CodingKey {
        case reportID = "reportId"
        case messageID = "messageId"
        case memberID = "memberId"
    }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        reportID = try values.decodeFlexibleString(forKey: .reportID)
        messageID = try values.decodeFlexibleStringIfPresent(forKey: .messageID)
        memberID = try values.decodeFlexibleStringIfPresent(forKey: .memberID)
    }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(reportID, forKey: .reportID)
        try values.encodeIfPresent(messageID, forKey: .messageID)
        try values.encodeIfPresent(memberID, forKey: .memberID)
    }
}

private struct BlockEntry: Codable {
    let memberID: String
    let isBlocked: Bool?
    enum CodingKeys: String, CodingKey { case memberID = "memberId", isBlocked }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        memberID = try values.decodeFlexibleString(forKey: .memberID)
        isBlocked = try values.decodeIfPresent(Bool.self, forKey: .isBlocked)
    }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(memberID, forKey: .memberID)
        try values.encodeIfPresent(isBlocked, forKey: .isBlocked)
    }
}

private struct BlockedMembers: Codable {
    let members: [BlockEntry]
    enum CodingKeys: CodingKey { case members }
    init(from decoder: Decoder) throws {
        members = try decoder.container(keyedBy: CodingKeys.self)
            .decode([BlockEntry].self, forKey: .members)
    }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(members, forKey: .members)
    }
}
