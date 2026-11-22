//
//  MatchingScheduleData.swift
//  MatchingData
//
//  Created by euijjang97 on 11/22/26.
//

import Foundation
import MatchingDomain
import UMCFoundation

extension LiveMatchingRepository {
    /// The round service checks global administration, core roles in the chapter's cohort,
    /// and chapter presidency against the role's organization (not the member's school).
    public func canManageSchedule(chapterId: String) async throws -> Bool {
        let summary: ScheduleMemberSummary = try await get("/api/v2/member/me")
        if summary.isSuperAdmin { return true }
        let gisuId = try await activeGisuId()
        let scope = try await organization(gisuId: gisuId)
        guard scope.chapters.contains(where: { $0.id == chapterId }) else { return false }
        let profile: ScheduleMemberProfile = try await get("/api/v1/member/me")
        return profile.roles.contains { $0.canManage(gisuId: gisuId, chapterId: chapterId) }
    }

    public func saveSchedule(chapterId: String, type: String, rounds: [MatchingRoundChange]) async throws {
        let body = SaveMatchingScheduleBody(type: type, rounds: rounds)
        try await send("/api/v1/project/matching-rounds/chapters/\(chapterId)", method: .put, body: body)
    }

    public func deleteSchedule(chapterId: String, type: String) async throws {
        try await send("/api/v1/project/matching-rounds/chapters/\(chapterId)", method: .delete,
                       query: [.init(name: "type", value: type)])
    }

    public func autoDecide(roundId: String) async throws {
        try await send("/api/v1/project/matching-rounds/\(roundId)/auto-decide", method: .post)
    }
}

struct SaveMatchingScheduleBody: Encodable {
    let type: String
    let rounds: [MatchingRoundChange]
}

private struct ScheduleMemberSummary: Codable {
    let isSuperAdmin: Bool
    enum CodingKeys: CodingKey { case isSuperAdmin }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        isSuperAdmin = try values.decode(Bool.self, forKey: .isSuperAdmin)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(isSuperAdmin, forKey: .isSuperAdmin)
    }
}

private struct ScheduleMemberProfile: Codable {
    let roles: [ScheduleRole]
    enum CodingKeys: CodingKey { case roles }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        roles = try values.decodeIfPresent([ScheduleRole].self, forKey: .roles) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(roles, forKey: .roles)
    }
}

struct ScheduleRole: Codable {
    let gisuId: String?
    let organizationId: String?
    let organizationType: String?
    let roleType: String
    enum CodingKeys: CodingKey { case gisuId, organizationId, organizationType, roleType }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        gisuId = try values.decodeFlexibleStringIfPresent(forKey: .gisuId)
        organizationId = try values.decodeFlexibleStringIfPresent(forKey: .organizationId)
        organizationType = try values.decodeIfPresent(String.self, forKey: .organizationType)
        roleType = try values.decode(String.self, forKey: .roleType)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(gisuId, forKey: .gisuId)
        try values.encodeIfPresent(organizationId, forKey: .organizationId)
        try values.encodeIfPresent(organizationType, forKey: .organizationType)
        try values.encode(roleType, forKey: .roleType)
    }

    func canManage(gisuId: String, chapterId: String) -> Bool {
        guard self.gisuId == gisuId else { return false }
        if ["CENTRAL_PRESIDENT", "CENTRAL_VICE_PRESIDENT"].contains(roleType) { return true }
        return roleType == "CHAPTER_PRESIDENT" && organizationType == "CHAPTER"
            && organizationId == chapterId
    }
}
