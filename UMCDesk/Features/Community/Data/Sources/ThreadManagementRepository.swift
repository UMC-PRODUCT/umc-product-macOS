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
        let response: ThreadManagementDetailResponse = try await get(threadPath(threadID))
        return response.model
    }

    public func people(threadID: String, invitable: Bool, query: String, offset: String?)
        async throws -> ThreadManagementPage {
        let suffix = invitable ? "/invitable" : "/members"
        let fields = PeopleQuery(text: query, offset: offset)
        let task = Moya.Task.requestParameters(parameters: fields.parameters,
                                               encoding: URLEncoding.queryString)
        let response: ThreadManagementPageResponse = try await get(threadPath(threadID) + suffix,
                                                                   task: task)
        return response.model
    }

    public func profile(memberID: String) async throws -> ThreadManagementProfile {
        let response: ThreadManagementProfileResponse = try await get(
            "/api/v1/member/profile/" + identifier(memberID))
        return response.model
    }

    public func currentMemberID() async throws -> String {
        let response: CurrentMember = try await get("/api/v1/member/me")
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

    private func get<T: Codable>(_ path: String, task: Moya.Task = .requestPlain)
        async throws -> T {
        let target = ManagementTarget(environment: environment, path: path,
                                      method: .get, task: task)
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
