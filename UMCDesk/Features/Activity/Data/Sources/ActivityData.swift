//
//  ActivityData.swift
//  ActivityData
//
//  Created by euijjang97 on 11/23/26.
//

import ActivityDomain
import CoreNetwork
import Foundation

public struct LiveActivityRepository: ActivityRepository {
    let pointGrants: PointGrantCoordinator
    private let client: NetworkClient
    private let baseURL: URL

    public init(
        client: NetworkClient, baseURL: URL, memberID: String, journalDirectory: URL? = nil
    ) {
        pointGrants = PointGrantCoordinator(
            journal: PointGrantJournal(
                baseURL: baseURL, memberID: memberID, directory: journalDirectory))
        self.client = client
        self.baseURL = baseURL
    }

    public func capabilities() async throws -> ScheduleCapabilities {
        let dto: CapabilitiesDTO = try await request("api/v2/schedules/capabilities")
        return ScheduleCapabilities(
            canCreate: dto.canCreateSchedule,
            canTrack: dto.canCreateAttendanceRequiredSchedule,
            participantLimit: dto.maxParticipantCount)
    }

    public func searchMembers(keyword: String) async throws -> [ActivityRow] {
        let response: MemberSearchDTO = try await request(
            "api/v1/member/search",
            query: [
                URLQueryItem(name: "keyword", value: keyword),
                URLQueryItem(name: "size", value: "30"),
            ])
        return memberRows(response)
    }

    public func directory(keyword: String, part: String?, page: Int) async throws
        -> ActivityMemberPage
    {
        let active: GisuDTO = try await request("api/v1/gisu/active")
        var query = [
            URLQueryItem(name: "gisuId", value: active.gisuId),
            URLQueryItem(name: "size", value: "30"),
            URLQueryItem(name: "page", value: String(page)),
        ]
        if !keyword.isEmpty { query.append(URLQueryItem(name: "keyword", value: keyword)) }
        if let part { query.append(URLQueryItem(name: "part", value: part)) }
        let response: MemberSearchDTO = try await request("api/v1/member/search", query: query)
        return ActivityMemberPage(members: memberRows(response), hasNext: response.page.hasNext)
    }

    private func memberRows(_ response: MemberSearchDTO) -> [ActivityRow] {
        var ids = Set<String>()
        return response.page.content.compactMap {
            guard ids.insert($0.memberId).inserted else { return nil }
            let gisu = $0.gisu.map { $0 + "기" }
            let detail = [gisu, $0.part, $0.schoolName].compactMap { $0 }.joined(separator: " · ")
            return ActivityRow(id: $0.memberId, title: $0.name, detail: detail)
        }
    }

    public func createSchedule(_ draft: ScheduleDraft) async throws {
        let participantIDs = try draft.members.map {
            guard let member = Int64($0) else { throw URLError(.cannotParseResponse) }
            return member
        }
        let venue = draft.coordinate.map {
            VenueBody(
                locationName: draft.venue ?? "", latitude: $0.latitude, longitude: $0.longitude)
        }
        let policy = draft.policy.map {
            PolicyBody(
                checkInStartAt: $0.open.ISO8601Format(), onTimeEndAt: $0.onTime.ISO8601Format(),
                lateEndAt: $0.close.ISO8601Format())
        }
        let body = CreateScheduleBody(
            name: draft.title, description: draft.memo, tags: [draft.tag],
            startsAt: draft.start.ISO8601Format(), endsAt: draft.end.ISO8601Format(),
            location: venue, attendancePolicy: policy, participantMemberIds: participantIDs)
        let _: ScheduleIdentifier = try await request(
            "api/v2/schedules", body: JSONEncoder().encode(body))
    }

    public func reviews() async throws -> [AttendanceReview] {
        let rows: [ReviewDTO] = try await request("api/v2/schedules/attendance")
        let pending = rows.filter { row in
            row.participants.contains { $0.attendanceStatus?.hasSuffix("_PENDING") == true }
        }
        let allowed = try await approvableSchedules(pending.map(\.scheduleId))
        return rows.map { schedule in
            AttendanceReview(
                id: schedule.scheduleId, name: schedule.name,
                mayDecide: allowed.contains(schedule.scheduleId),
                participants: schedule.participants.map {
                    AttendanceRequestRow(
                        id: $0.memberId, name: $0.name,
                        status: $0.attendanceStatus, reason: $0.excuseReason)
                })
        }
    }

    public func decide(scheduleID: String, memberID: String, approve: Bool) async throws {
        guard let member = Int64(memberID) else { throw URLError(.cannotParseResponse) }
        let body = [DecisionBody(participantMemberId: member, isApproved: approve)]
        let _: [AttendanceDTO] = try await request(
            "api/v2/schedules/\(scheduleID)/attendances/decide", body: JSONEncoder().encode(body)
        )
    }

    public func schedules() async throws -> [ActivitySchedule] {
        let today = Calendar.current.startOfDay(for: .now)
        let interval = TimeInterval(30 * 24 * 60 * 60)
        let values: [ScheduleDTO] = try await request(
            "api/v2/schedules/me",
            query: [
                URLQueryItem(
                    name: "from", value: today.addingTimeInterval(-interval).ISO8601Format()),
                URLQueryItem(
                    name: "to", value: today.addingTimeInterval(interval).ISO8601Format()),
                URLQueryItem(name: "isAttendanceRequired", value: "true"),
            ])
        return try values.map { value in
            let policy = value.attendancePolicy
            return try ActivitySchedule(
                id: value.scheduleId, name: value.name,
                startsAt: date(value.startsAt), endsAt: date(value.endsAt),
                isOnline: value.isOnline, isParticipant: value.isParticipant,
                status: value.attendanceStatus,
                opens: policy.map { try date($0.checkInStartAt) },
                onTime: policy.map { try date($0.onTimeEndAt) },
                closes: policy.map { try date($0.lateEndAt) },
                location: value.location?.locationName,
                coordinate: value.location.flatMap { location in
                    guard let lat = location.latitude, let lon = location.longitude else {
                        return nil
                    }
                    return ActivityCoordinate(latitude: lat, longitude: lon)
                }
            )
        }.sorted { $0.startsAt < $1.startsAt }
    }

    private func date(_ string: String) throws -> Date {
        if let date = try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(string)
        {
            return date
        }
        return try Date.ISO8601FormatStyle().parse(string)
    }

    public func attend(scheduleID: String, reason: String?, coordinate: ActivityCoordinate?)
        async throws -> String
    {
        let path = "api/v2/schedules/\(scheduleID)/attendances/"
        let response: AttendanceDTO
        if let reason {
            response = try await request(
                path + "excuse",
                body: JSONEncoder().encode(
                    ExcuseBody(isVerified: false, excuseReason: reason)
                ))
        } else {
            response = try await request(
                path + "request",
                body: JSONEncoder().encode(
                    AttendanceBody(
                        locationVerified: coordinate != nil, latitude: coordinate?.latitude,
                        longitude: coordinate?.longitude)
                ))
        }
        return response.status
    }

    public func study() async throws -> [ActivityRow] {
        let gisu: GisuDTO = try await request("api/v1/gisu/active")
        let curriculum: CurriculumDTO = try await request(
            "api/v2/curriculums/progress/me",
            query: [
                URLQueryItem(name: "gisuId", value: gisu.gisuId)
            ])
        return curriculum.weeks.map {
            ActivityRow(
                id: $0.weeklyCurriculumId, title: "\($0.weekNo)주차 · \($0.title)",
                detail: $0.originalWorkbooks.map(\.title).joined(separator: " · "))
        }
    }

    public func groups() async throws -> [ActivityRow] {
        let groups: GroupsDTO = try await request("api/v1/study-groups/names")
        return groups.studyGroups.map { ActivityRow(id: $0.groupId, title: $0.name, detail: "") }
    }

    public func members(groupID: String) async throws -> [ActivityRow] {
        let group: GroupDetailsDTO = try await request("api/v1/study-groups/\(groupID)")
        let mentors = Set(group.mentors.map(\.memberId))
        var seen = Set<String>()
        return (group.mentors + group.members).compactMap { member in
            guard seen.insert(member.memberId).inserted else { return nil }
            let role = mentors.contains(member.memberId) ? "파트장" : "스터디원"
            return ActivityRow(
                id: member.memberId, title: member.memberName,
                detail: "\(member.schoolName) · \(role)")
        }
    }

    func request<T: Codable>(
        _ path: String,
        query: [URLQueryItem] = [],
        body: Data? = nil,
        method: String? = nil
    ) async throws -> T {
        var url = baseURL.appending(path: path)
        if !query.isEmpty { url.append(queryItems: query) }
        var request = URLRequest(url: url)
        request.httpMethod = method ?? (body == nil ? "GET" : "POST")
        if let body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        let (data, _) = try await client.request(request)
        return try JSONDecoder().decode(APIResponse<T>.self, from: data).unwrap()
    }
}

private struct AttendanceBody: Encodable {
    let locationVerified: Bool
    let latitude: Double?
    let longitude: Double?
}

private struct ExcuseBody: Encodable {
    let isVerified: Bool
    let excuseReason: String
}

private struct CreateScheduleBody: Encodable {
    let name: String
    let description: String
    let tags: [String]
    let startsAt: String
    let endsAt: String
    let location: VenueBody?
    let attendancePolicy: PolicyBody?
    let participantMemberIds: [Int64]
}

private struct VenueBody: Encodable {
    let locationName: String
    let latitude: Double
    let longitude: Double
}

private struct PolicyBody: Encodable {
    let checkInStartAt: String
    let onTimeEndAt: String
    let lateEndAt: String
}

private struct DecisionBody: Encodable {
    let participantMemberId: Int64
    let isApproved: Bool
}

struct ScheduleIdentifier: Codable {
    let value: String

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let string = try? container.decode(String.self) {
            value = string
        } else {
            value = String(try container.decode(Int64.self))
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}
