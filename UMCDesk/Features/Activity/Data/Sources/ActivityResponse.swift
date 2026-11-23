//
//  ActivityResponse.swift
//  ActivityData
//
//  Created by euijjang97 on 11/23/26.
//

import Foundation
import UMCFoundation

struct ScheduleDTO: Codable {
    let scheduleId: String
    let name: String
    let startsAt: String
    let endsAt: String
    let isOnline: Bool
    let isParticipant: Bool
    let attendanceStatus: String?
    let attendancePolicy: PolicyDTO?
    let location: LocationDTO?

    private enum CodingKeys: String, CodingKey {
        case scheduleId, name, startsAt, endsAt, isOnline, isParticipant, attendanceStatus,
            attendancePolicy, location
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        scheduleId = try values.decodeFlexibleString(forKey: .scheduleId)
        name = try values.decode(String.self, forKey: .name)
        startsAt = try values.decode(String.self, forKey: .startsAt)
        endsAt = try values.decode(String.self, forKey: .endsAt)
        isOnline = try values.decode(Bool.self, forKey: .isOnline)
        isParticipant = try values.decode(Bool.self, forKey: .isParticipant)
        attendanceStatus = try values.decodeIfPresent(String.self, forKey: .attendanceStatus)
        attendancePolicy = try values.decodeIfPresent(PolicyDTO.self, forKey: .attendancePolicy)
        location = try values.decodeIfPresent(LocationDTO.self, forKey: .location)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(scheduleId, forKey: .scheduleId)
        try values.encode(name, forKey: .name)
        try values.encode(startsAt, forKey: .startsAt)
        try values.encode(endsAt, forKey: .endsAt)
        try values.encode(isOnline, forKey: .isOnline)
        try values.encode(isParticipant, forKey: .isParticipant)
        try values.encodeIfPresent(attendanceStatus, forKey: .attendanceStatus)
        try values.encodeIfPresent(attendancePolicy, forKey: .attendancePolicy)
        try values.encodeIfPresent(location, forKey: .location)
    }
}

struct PolicyDTO: Codable {
    let checkInStartAt: String
    let onTimeEndAt: String
    let lateEndAt: String

    private enum CodingKeys: String, CodingKey {
        case checkInStartAt, onTimeEndAt, lateEndAt
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        checkInStartAt = try values.decode(String.self, forKey: .checkInStartAt)
        onTimeEndAt = try values.decode(String.self, forKey: .onTimeEndAt)
        lateEndAt = try values.decode(String.self, forKey: .lateEndAt)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(checkInStartAt, forKey: .checkInStartAt)
        try values.encode(onTimeEndAt, forKey: .onTimeEndAt)
        try values.encode(lateEndAt, forKey: .lateEndAt)
    }
}

struct LocationDTO: Codable {
    let locationName: String?
    let latitude: Double?
    let longitude: Double?

    private enum CodingKeys: String, CodingKey {
        case locationName, latitude, longitude
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        locationName = try values.decodeIfPresent(String.self, forKey: .locationName)
        latitude = try values.decodeIfPresent(Double.self, forKey: .latitude)
        longitude = try values.decodeIfPresent(Double.self, forKey: .longitude)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(locationName, forKey: .locationName)
        try values.encodeIfPresent(latitude, forKey: .latitude)
        try values.encodeIfPresent(longitude, forKey: .longitude)
    }
}

struct AttendanceDTO: Codable {
    let status: String

    private enum CodingKeys: String, CodingKey {
        case status
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        status = try values.decode(String.self, forKey: .status)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(status, forKey: .status)
    }
}

struct GisuDTO: Codable {
    let gisuId: String

    private enum CodingKeys: String, CodingKey {
        case gisuId
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        gisuId = try values.decodeFlexibleString(forKey: .gisuId)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(gisuId, forKey: .gisuId)
    }
}

struct CurriculumDTO: Codable {
    let weeks: [WeekDTO]

    private enum CodingKeys: String, CodingKey {
        case weeks
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        weeks = try values.decode([WeekDTO].self, forKey: .weeks)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(weeks, forKey: .weeks)
    }
}

struct WeekDTO: Codable {
    let weeklyCurriculumId: String
    let weekNo: String
    let title: String
    let originalWorkbooks: [WorkbookDTO]

    private enum CodingKeys: String, CodingKey {
        case weeklyCurriculumId, weekNo, title, originalWorkbooks
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        weeklyCurriculumId = try values.decodeFlexibleString(forKey: .weeklyCurriculumId)
        weekNo = try values.decodeFlexibleString(forKey: .weekNo)
        title = try values.decode(String.self, forKey: .title)
        originalWorkbooks = try values.decode([WorkbookDTO].self, forKey: .originalWorkbooks)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(weeklyCurriculumId, forKey: .weeklyCurriculumId)
        try values.encode(weekNo, forKey: .weekNo)
        try values.encode(title, forKey: .title)
        try values.encode(originalWorkbooks, forKey: .originalWorkbooks)
    }
}

struct WorkbookDTO: Codable {
    let title: String

    private enum CodingKeys: String, CodingKey {
        case title
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(title, forKey: .title)
    }
}

struct GroupsDTO: Codable {
    let studyGroups: [GroupDTO]

    private enum CodingKeys: String, CodingKey {
        case studyGroups
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        studyGroups = try values.decode([GroupDTO].self, forKey: .studyGroups)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(studyGroups, forKey: .studyGroups)
    }
}

struct GroupDTO: Codable {
    let groupId: String
    let name: String

    private enum CodingKeys: String, CodingKey {
        case groupId, name
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        groupId = try values.decodeFlexibleString(forKey: .groupId)
        name = try values.decode(String.self, forKey: .name)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(groupId, forKey: .groupId)
        try values.encode(name, forKey: .name)
    }
}

struct GroupDetailsDTO: Codable {
    let members: [MemberDTO]
    let mentors: [MemberDTO]

    private enum CodingKeys: String, CodingKey {
        case members, mentors
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        members = try values.decode([MemberDTO].self, forKey: .members)
        mentors = try values.decode([MemberDTO].self, forKey: .mentors)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(members, forKey: .members)
        try values.encode(mentors, forKey: .mentors)
    }
}

struct MemberDTO: Codable {
    let memberId: String
    let memberName: String
    let schoolName: String

    private enum CodingKeys: String, CodingKey {
        case memberId, memberName, schoolName
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        memberId = try values.decodeFlexibleString(forKey: .memberId)
        memberName = try values.decode(String.self, forKey: .memberName)
        schoolName = try values.decode(String.self, forKey: .schoolName)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(memberId, forKey: .memberId)
        try values.encode(memberName, forKey: .memberName)
        try values.encode(schoolName, forKey: .schoolName)
    }
}

struct CapabilitiesDTO: Codable {
    let canCreateSchedule: Bool
    let canCreateAttendanceRequiredSchedule: Bool
    let maxParticipantCount: String

    private enum CodingKeys: String, CodingKey {
        case canCreateSchedule, canCreateAttendanceRequiredSchedule, maxParticipantCount
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        canCreateSchedule = try values.decode(Bool.self, forKey: .canCreateSchedule)
        canCreateAttendanceRequiredSchedule = try values.decode(
            Bool.self, forKey: .canCreateAttendanceRequiredSchedule)
        maxParticipantCount = try values.decodeFlexibleString(forKey: .maxParticipantCount)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(canCreateSchedule, forKey: .canCreateSchedule)
        try values.encode(
            canCreateAttendanceRequiredSchedule, forKey: .canCreateAttendanceRequiredSchedule)
        try values.encode(maxParticipantCount, forKey: .maxParticipantCount)
    }
}

struct ReviewDTO: Codable {
    let scheduleId: String
    let name: String
    let participants: [ParticipantDTO]

    private enum CodingKeys: String, CodingKey {
        case scheduleId, name, participants
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        scheduleId = try values.decodeFlexibleString(forKey: .scheduleId)
        name = try values.decode(String.self, forKey: .name)
        participants = try values.decode([ParticipantDTO].self, forKey: .participants)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(scheduleId, forKey: .scheduleId)
        try values.encode(name, forKey: .name)
        try values.encode(participants, forKey: .participants)
    }
}

struct ParticipantDTO: Codable {
    let memberId: String
    let name: String
    let attendanceStatus: String?
    let excuseReason: String?

    private enum CodingKeys: String, CodingKey {
        case memberId, name, attendanceStatus, excuseReason
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        memberId = try values.decodeFlexibleString(forKey: .memberId)
        name = try values.decode(String.self, forKey: .name)
        attendanceStatus = try values.decodeIfPresent(String.self, forKey: .attendanceStatus)
        excuseReason = try values.decodeIfPresent(String.self, forKey: .excuseReason)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(memberId, forKey: .memberId)
        try values.encode(name, forKey: .name)
        try values.encodeIfPresent(attendanceStatus, forKey: .attendanceStatus)
        try values.encodeIfPresent(excuseReason, forKey: .excuseReason)
    }
}

struct MemberSearchDTO: Codable {
    let page: MemberPageDTO

    private enum CodingKeys: String, CodingKey {
        case page
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        page = try values.decode(MemberPageDTO.self, forKey: .page)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(page, forKey: .page)
    }
}

struct MemberPageDTO: Codable {
    let content: [SearchedMemberDTO]
    let hasNext: Bool

    private enum CodingKeys: String, CodingKey {
        case content, hasNext
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        content = try values.decode([SearchedMemberDTO].self, forKey: .content)
        hasNext = try values.decode(Bool.self, forKey: .hasNext)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(content, forKey: .content)
        try values.encode(hasNext, forKey: .hasNext)
    }
}

struct SearchedMemberDTO: Codable {
    let memberId: String
    let name: String
    let schoolName: String?
    let gisu: String?
    let part: String?

    private enum CodingKeys: String, CodingKey {
        case memberId, name, schoolName, gisu, part
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        memberId = try values.decodeFlexibleString(forKey: .memberId)
        name = try values.decode(String.self, forKey: .name)
        schoolName = try values.decodeIfPresent(String.self, forKey: .schoolName)
        gisu = try values.decodeFlexibleStringIfPresent(forKey: .gisu)
        part = try values.decodeIfPresent(String.self, forKey: .part)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(memberId, forKey: .memberId)
        try values.encode(name, forKey: .name)
        try values.encodeIfPresent(schoolName, forKey: .schoolName)
        try values.encodeIfPresent(gisu, forKey: .gisu)
        try values.encodeIfPresent(part, forKey: .part)
    }
}
