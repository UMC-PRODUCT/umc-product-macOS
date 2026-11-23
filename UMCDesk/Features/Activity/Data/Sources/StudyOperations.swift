//  StudyOperations.swift
//  ActivityData
//
//  Created by euijjang97 on 11/23/26.
//

import ActivityDomain
import CoreNetwork
import Foundation

extension LiveActivityRepository {
    public func canReadReviews() async throws -> Bool {
        try await permission("ATTENDANCE", "READ", id: nil)
    }

    func approvableSchedules(_ ids: [String]) async throws -> Set<String> {
        guard !ids.isEmpty else { return [] }
        let query = try PermissionBatch.Query(
            resourceType: "ATTENDANCE", resourceIds: ids.map(number),
            permissionTypes: ["APPROVE"])
        let body = PermissionBatch(queries: [query])
        let dto: BatchPermissionsDTO = try await request(
            "api/v1/authorization/resource-permissions/batch",
            body: JSONEncoder().encode(body))
        return Set(
            dto.results.compactMap { result in
                result.permissions.contains { $0.permissionType == "APPROVE" && $0.hasPermission }
                    ? result.resourceId : nil
            })
    }

    public func studyTools(groupID: String?) async throws -> StudyTools {
        async let create = permission("STUDY_GROUP", "WRITE", id: nil)
        guard let groupID else {
            return try await StudyTools(create: create, edit: false, mentor: false)
        }
        async let edit = permission("STUDY_GROUP", "EDIT", id: nil)
        async let profile: MemberProfileDTO = request("api/v1/member/me")
        async let details: GroupDetailsDTO = request("api/v1/study-groups/\(groupID)")
        let (mayCreate, mayEdit, identity, group) = try await (create, edit, profile, details)
        return StudyTools(
            create: mayCreate, edit: mayEdit,
            mentor: group.mentors.contains { $0.memberId == identity.id })
    }

    public func saveGroup(
        id: String?, name: String, mentors: [String],
        members: [String]
    ) async throws {
        let path = "api/v1/study-groups"
        if let id {
            let _: EmptyResult = try await request(
                path + "/" + id,
                body: JSONEncoder().encode(GroupNameBody(name: name)), method: "PATCH")
        } else {
            let active: GisuDTO = try await request("api/v1/gisu/active")
            let body = try NewGroupBody(
                name: name, gisuId: number(active.gisuId),
                mentorIds: mentors.map(number), memberIds: members.map(number))
            let _: EmptyResult = try await request(path, body: JSONEncoder().encode(body))
        }
    }

    public func assign(groupID: String, memberID: String, mentor: Bool) async throws {
        let role = mentor ? "mentors" : "members"
        let _: EmptyResult = try await request(
            "api/v1/study-groups/\(groupID)/\(role)/\(memberID)", method: "PATCH"
        )
    }

    public func link(groupID: String, scheduleID: String, weekID: String) async throws {
        let body = try GroupScheduleBody(
            studyGroupId: number(groupID), scheduleId: number(scheduleID),
            weeklyCurriculumId: number(weekID))
        let _: ScheduleIdentifier = try await request(
            "api/v1/study-groups/schedules",
            body: JSONEncoder().encode(body))
    }

    public func memberProfile(id: String) async throws -> ActivityMemberProfile {
        let profile: MemberProfileDTO = try await request("api/v1/member/profile/\(id)")
        return ActivityMemberProfile(
            name: profile.name, school: profile.schoolName ?? "",
            records: profile.challengerRecords.map {
                ActivityRow(id: $0.challengerId, title: "\($0.gisu)기", detail: $0.part ?? "")
            })
    }

    public func canGrantPoints(challengerID: String) async throws -> Bool {
        try await permission("CHALLENGER_POINT", "WRITE", id: challengerID)
    }

    public func grantPoints(challengerID: String, value: Int, reason: String) async throws {
        let body = PointBody(pointType: "CUSTOM", pointValue: value, description: reason)
        let _: PointReceiptDTO = try await request(
            "api/v1/challenger/\(challengerID)/points",
            body: JSONEncoder().encode(body))
    }

    private func permission(_ resource: String, _ type: String, id: String?) async throws -> Bool {
        var query = [
            URLQueryItem(name: "resourceType", value: resource),
            URLQueryItem(name: "permissionType", value: type),
        ]
        if let id { query.append(URLQueryItem(name: "resourceId", value: id)) }
        let response: PermissionDTO = try await request(
            "api/v1/authorization/resource-permission",
            query: query)
        return response.permissions.contains { $0.permissionType == type && $0.hasPermission }
    }

    private func number(_ id: String) throws -> Int64 {
        guard let value = Int64(id) else { throw URLError(.cannotParseResponse) }
        return value
    }
}

private struct GroupNameBody: Encodable { let name: String }
private struct NewGroupBody: Encodable {
    let name: String
    let gisuId: Int64
    let mentorIds: [Int64]
    let memberIds: [Int64]
}
private struct GroupScheduleBody: Encodable {
    let studyGroupId: Int64
    let scheduleId: Int64
    let weeklyCurriculumId: Int64
}
private struct PointBody: Encodable {
    let pointType: String
    let pointValue: Int
    let description: String
}

private struct PermissionBatch: Encodable {
    struct Query: Encodable {
        let resourceType: String
        let resourceIds: [Int64]
        let permissionTypes: [String]
    }
    let queries: [Query]
}
