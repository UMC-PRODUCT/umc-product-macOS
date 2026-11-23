//
//  FeatureAccount.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/23/26.
//

import ActivityData
import CommunityData
import CoreNetwork
import Foundation
import HomeData
import NoticeData
import ProjectWorkspaceDomain
import UMCFoundation

struct FeatureAccount: Sendable {
    let memberID: String
    let home: LiveHomeRepository
    let activity: LiveActivityRepository
    let notices: LiveNoticeRepository
    let threads: LiveCommunityThreadRepository
    let conversations: LiveThreadConversationRepository
    let members: LiveThreadManagementRepository
    let client: NetworkClient
    let environment: NetworkEnvironment

    init(memberID: String, boundClient bound: NetworkClient, environment: NetworkEnvironment) {
        self.memberID = memberID
        self.client = bound
        self.environment = environment
        let adapter = MoyaNetworkAdapter(networkClient: bound)
        home = LiveHomeRepository(client: bound, baseURL: environment.baseURL)
        activity = LiveActivityRepository(client: bound, baseURL: environment.baseURL)
        notices = LiveNoticeRepository(adapter: adapter, environment: environment)
        threads = LiveCommunityThreadRepository(adapter: adapter, environment: environment)
        members = LiveThreadManagementRepository(adapter: adapter, environment: environment)
        conversations = LiveThreadConversationRepository(adapter: adapter, environment: environment) {
            try await bound.currentAccessToken()
        }
    }

    func projects() async throws -> [WorkspaceProject] {
        let gisu: WorkspaceGisu = try await get("api/v1/gisu/active")
        let cards: [WorkspaceApplication] = try await get("api/v1/projects/me/applications",
            query: [.init(name: "gisuId", value: gisu.gisuId)])
        let approved = cards.filter { $0.status == "APPROVED" && $0.project != nil }
        guard !approved.isEmpty else { return [] }
        let ids = Set(approved.map(\.projectId)).sorted().joined(separator: ",")
        let teams: [String: WorkspaceTeam] = try await get("api/v1/projects/members",
            query: [.init(name: "projectIds", value: ids)])
        var included = Set<String>()
        return approved.compactMap { card in
            guard let title = card.project?.name, let team = teams[card.projectId],
                  team.contains(memberID), included.insert(card.projectId).inserted else { return nil }
            return WorkspaceProject(id: card.projectId, name: title)
        }
    }

    private func get<T: Codable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        var url = environment.baseURL.appending(path: path)
        if !query.isEmpty { url.append(queryItems: query) }
        let (data, _) = try await client.request(URLRequest(url: url))
        return try JSONDecoder().decode(APIResponse<T>.self, from: data).unwrap()
    }
}

private struct WorkspaceGisu: Codable {
    let gisuId: String
    enum CodingKeys: CodingKey { case gisuId }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        gisuId = try values.decodeFlexibleString(forKey: .gisuId)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(gisuId, forKey: .gisuId)
    }
}

private struct WorkspaceName: Codable {
    let name: String
    enum CodingKeys: CodingKey { case name }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(name, forKey: .name)
    }
}

private struct WorkspaceApplication: Codable {
    let projectId: String
    let project: WorkspaceName?
    let status: String?
    enum CodingKeys: CodingKey { case projectId, project, status }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try values.decodeFlexibleString(forKey: .projectId)
        project = try values.decodeIfPresent(WorkspaceName.self, forKey: .project)
        status = try values.decodeIfPresent(String.self, forKey: .status)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(projectId, forKey: .projectId)
        try values.encodeIfPresent(project, forKey: .project)
        try values.encodeIfPresent(status, forKey: .status)
    }
}

private struct WorkspaceMember: Codable {
    let memberId: String
    enum CodingKeys: CodingKey { case memberId }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        memberId = try values.decodeFlexibleString(forKey: .memberId)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(memberId, forKey: .memberId)
    }
}

private struct WorkspacePart: Codable {
    let members: [WorkspaceMember]
    enum CodingKeys: CodingKey { case members }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        members = try values.decode([WorkspaceMember].self, forKey: .members)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(members, forKey: .members)
    }
}

private struct WorkspaceTeam: Codable {
    let productOwner: WorkspaceMember?
    let coProductOwners: [WorkspaceMember]
    let partGroups: [WorkspacePart]
    enum CodingKeys: CodingKey { case productOwner, coProductOwners, partGroups }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        productOwner = try values.decodeIfPresent(WorkspaceMember.self, forKey: .productOwner)
        coProductOwners = try values.decode([WorkspaceMember].self, forKey: .coProductOwners)
        partGroups = try values.decode([WorkspacePart].self, forKey: .partGroups)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(productOwner, forKey: .productOwner)
        try values.encode(coProductOwners, forKey: .coProductOwners)
        try values.encode(partGroups, forKey: .partGroups)
    }

    func contains(_ identifier: String) -> Bool {
        productOwner?.memberId == identifier || coProductOwners.contains { $0.memberId == identifier }
            || partGroups.contains { $0.members.contains { $0.memberId == identifier } }
    }
}
