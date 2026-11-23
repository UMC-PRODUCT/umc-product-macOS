//
//  ActivityDomain.swift
//  ActivityDomain
//
//  Created by euijjang97 on 11/23/26.
//

import Foundation

public struct ActivityCoordinate: Sendable {
    public let latitude: Double
    public let longitude: Double

    public init(
        latitude: Double,
        longitude: Double
    ) {
        self.latitude = latitude
        self.longitude = longitude
    }
}

public struct ActivitySchedule: Sendable, Identifiable {
    public let id: String
    public let name: String
    public let startsAt: Date
    public let endsAt: Date
    public let isOnline: Bool
    public let isParticipant: Bool
    public let status: String?
    public let opens: Date?
    public let onTime: Date?
    public let closes: Date?
    public let coordinate: ActivityCoordinate?
    public let location: String?

    public init(
        id: String,
        name: String,
        startsAt: Date,
        endsAt: Date,
        isOnline: Bool,
        isParticipant: Bool,
        status: String?,
        opens: Date?,
        onTime: Date?,
        closes: Date?,
        location: String?,
        coordinate: ActivityCoordinate? = nil
    ) {
        self.id = id
        self.name = name
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.isOnline = isOnline
        self.isParticipant = isParticipant
        self.status = status
        self.opens = opens
        self.onTime = onTime
        self.closes = closes
        self.coordinate = coordinate
        self.location = location
    }
}

public struct ActivityRow: Sendable, Identifiable {
    public let id: String
    public let title: String
    public let detail: String

    public init(
        id: String,
        title: String,
        detail: String
    ) {
        self.id = id
        self.title = title
        self.detail = detail
    }
}

public struct AttendanceRequestRow: Sendable, Identifiable {
    public let id: String
    public let name: String
    public let status: String?
    public let reason: String?

    public init(
        id: String,
        name: String,
        status: String?,
        reason: String?
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.reason = reason
    }
}

public struct AttendanceReview: Sendable, Identifiable {
    public let id: String
    public let name: String
    public let mayDecide: Bool
    public let participants: [AttendanceRequestRow]

    public init(
        id: String,
        name: String,
        mayDecide: Bool,
        participants: [AttendanceRequestRow]
    ) {
        self.id = id
        self.name = name
        self.mayDecide = mayDecide
        self.participants = participants
    }
}

public struct ScheduleCapabilities: Sendable {
    public let canCreate: Bool
    public let canTrack: Bool
    public let participantLimit: String

    public init(
        canCreate: Bool,
        canTrack: Bool,
        participantLimit: String
    ) {
        self.canCreate = canCreate
        self.canTrack = canTrack
        self.participantLimit = participantLimit
    }
}

public struct ScheduleDraft: Sendable {
    public let title: String
    public let memo: String
    public let tag: String
    public let start: Date
    public let end: Date
    public let venue: String?
    public let coordinate: ActivityCoordinate?
    public let policy: AttendanceWindow?
    public let members: [String]

    public init(
        title: String,
        memo: String,
        tag: String,
        start: Date,
        end: Date,
        venue: String?,
        coordinate: ActivityCoordinate?,
        policy: AttendanceWindow?,
        members: [String]
    ) {
        self.title = title
        self.memo = memo
        self.tag = tag
        self.start = start
        self.end = end
        self.venue = venue
        self.coordinate = coordinate
        self.policy = policy
        self.members = members
    }
}

public struct AttendanceWindow: Sendable {
    public let open: Date
    public let onTime: Date
    public let close: Date

    public init(
        open: Date,
        onTime: Date,
        close: Date
    ) {
        self.open = open
        self.onTime = onTime
        self.close = close
    }
}

public struct ActivityMemberProfile: Sendable {
    public let name: String
    public let school: String
    public let records: [ActivityRow]

    public init(
        name: String,
        school: String,
        records: [ActivityRow]
    ) {
        self.name = name
        self.school = school
        self.records = records
    }
}

public struct StudyTools: Sendable {
    public let create: Bool
    public let edit: Bool
    public let mentor: Bool

    public init(
        create: Bool,
        edit: Bool,
        mentor: Bool
    ) {
        self.create = create
        self.edit = edit
        self.mentor = mentor
    }
}

public struct ActivityMemberPage: Sendable {
    public let members: [ActivityRow]
    public let hasNext: Bool

    public init(
        members: [ActivityRow],
        hasNext: Bool
    ) {
        self.members = members
        self.hasNext = hasNext
    }
}

public struct PointGrantIntent: Codable, Equatable, Sendable {
    public let id: UUID
    public let challengerID: String
    public let value: Int
    public let reason: String

    public init(id: UUID, challengerID: String, value: Int, reason: String) {
        self.id = id
        self.challengerID = challengerID
        self.value = value
        self.reason = reason
    }
}

public enum PointGrantResult: Equatable, Sendable {
    case recorded
    case matchingUnverified
    case awaitingLedger
}

public protocol ActivityRepository: Sendable {
    func capabilities() async throws -> ScheduleCapabilities
    func directory(keyword: String, part: String?, page: Int) async throws -> ActivityMemberPage
    func searchMembers(keyword: String) async throws -> [ActivityRow]
    func createSchedule(_ draft: ScheduleDraft) async throws
    func canReadReviews() async throws -> Bool
    func reviews() async throws -> [AttendanceReview]
    func decide(scheduleID: String, memberID: String, approve: Bool) async throws
    func schedules() async throws -> [ActivitySchedule]
    func attend(scheduleID: String, reason: String?, coordinate: ActivityCoordinate?) async throws
        -> String
    func study() async throws -> [ActivityRow]
    func studyTools(groupID: String?) async throws -> StudyTools
    func saveGroup(id: String?, name: String, mentors: [String], members: [String]) async throws
    func assign(groupID: String, memberID: String, mentor: Bool) async throws
    func link(groupID: String, scheduleID: String, weekID: String) async throws
    func memberProfile(id: String) async throws -> ActivityMemberProfile
    func canGrantPoints(challengerID: String) async throws -> Bool
    func pendingGrant(challengerID: String) throws -> PointGrantIntent?
    func finishManualReview(operationID: UUID) throws
    func grantPoints(operationID: UUID, challengerID: String, value: Int, reason: String)
        async throws -> PointGrantResult
    func groups() async throws -> [ActivityRow]
    func members(groupID: String) async throws -> [ActivityRow]
}
