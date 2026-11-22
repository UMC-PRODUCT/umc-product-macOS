//
//  MatchingOperationsData.swift
//  MatchingData
//
//  Created by euijjang97 on 11/22/26.
//

import Foundation
import MatchingDomain
import UMCFoundation

private struct OperationsPersonDTO: Codable {
    let memberId: String
    let nickname: String?
    let name: String?
    let schoolName: String?
    let part: String?
    let matchedRoundInfo: OperationsRoundDTO?

    private enum CodingKeys: String, CodingKey {
        case memberId
        case nickname
        case name
        case schoolName
        case part
        case matchedRoundInfo
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        memberId = try values.decodeFlexibleString(forKey: .memberId)
        nickname = try values.decodeIfPresent(String.self, forKey: .nickname)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        schoolName = try values.decodeIfPresent(String.self, forKey: .schoolName)
        part = try values.decodeIfPresent(String.self, forKey: .part)
        matchedRoundInfo = try values.decodeIfPresent(OperationsRoundDTO.self, forKey: .matchedRoundInfo)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(memberId, forKey: .memberId)
        try values.encodeIfPresent(nickname, forKey: .nickname)
        try values.encodeIfPresent(name, forKey: .name)
        try values.encodeIfPresent(schoolName, forKey: .schoolName)
        try values.encodeIfPresent(part, forKey: .part)
        try values.encodeIfPresent(matchedRoundInfo, forKey: .matchedRoundInfo)
    }

    var model: OperationsPerson {
        OperationsPerson(
            memberId: memberId,
            nickname: nickname,
            name: name,
            schoolName: schoolName,
            part: part,
            matchedRoundInfo: matchedRoundInfo?.model
        )
    }
}

private struct ManagedProjectDTO: Codable {
    let id: String
    let name: String?
    let status: String
    let productOwner: OperationsPersonDTO?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case status
        case productOwner
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeFlexibleString(forKey: .id)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        status = try values.decode(String.self, forKey: .status)
        productOwner = try values.decodeIfPresent(OperationsPersonDTO.self, forKey: .productOwner)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encodeIfPresent(name, forKey: .name)
        try values.encode(status, forKey: .status)
        try values.encodeIfPresent(productOwner, forKey: .productOwner)
    }

    var model: ManagedProject {
        ManagedProject(
            id: id,
            name: name,
            status: status,
            productOwner: productOwner?.model
        )
    }
}

private struct ApplicantRowDTO: Codable {
    let applicationId: String
    let applicant: OperationsPersonDTO
    let status: String
    let matchingRound: OperationsRoundDTO?
    let submittedAt: String?

    private enum CodingKeys: String, CodingKey {
        case applicationId
        case applicant
        case status
        case matchingRound
        case submittedAt
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        applicationId = try values.decodeFlexibleString(forKey: .applicationId)
        applicant = try values.decode(OperationsPersonDTO.self, forKey: .applicant)
        status = try values.decode(String.self, forKey: .status)
        matchingRound = try values.decodeIfPresent(OperationsRoundDTO.self, forKey: .matchingRound)
        submittedAt = try values.decodeIfPresent(String.self, forKey: .submittedAt)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(applicationId, forKey: .applicationId)
        try values.encode(applicant, forKey: .applicant)
        try values.encode(status, forKey: .status)
        try values.encodeIfPresent(matchingRound, forKey: .matchingRound)
        try values.encodeIfPresent(submittedAt, forKey: .submittedAt)
    }

    var model: ApplicantRow {
        ApplicantRow(
            applicationId: applicationId,
            applicant: applicant.model,
            status: status,
            matchingRound: matchingRound?.model,
            submittedAt: submittedAt
        )
    }
}

private struct OperationsRoundDTO: Codable {
    let id: String?
    let phase: String?
    let type: String?

    private enum CodingKeys: String, CodingKey {
        case id
        case phase
        case type
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeFlexibleStringIfPresent(forKey: .id)
        phase = try values.decodeIfPresent(String.self, forKey: .phase)
        type = try values.decodeIfPresent(String.self, forKey: .type)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(id, forKey: .id)
        try values.encodeIfPresent(phase, forKey: .phase)
        try values.encodeIfPresent(type, forKey: .type)
    }

    var model: OperationsRound {
        OperationsRound(
            id: id,
            phase: phase,
            type: type
        )
    }
}

private struct RosterGroupDTO: Codable {
    let part: String
    let members: [OperationsPersonDTO]

    private enum CodingKeys: String, CodingKey {
        case part
        case members
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        part = try values.decode(String.self, forKey: .part)
        members = try values.decode([OperationsPersonDTO].self, forKey: .members)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(part, forKey: .part)
        try values.encode(members, forKey: .members)
    }

    var model: RosterGroup {
        RosterGroup(
            part: part,
            members: members.map(\.model)
        )
    }
}

private struct OperationsTeamDTO: Codable {
    let productOwner: OperationsPersonDTO?
    let coProductOwners: [OperationsPersonDTO]
    let partGroups: [RosterGroupDTO]

    private enum CodingKeys: String, CodingKey {
        case productOwner
        case coProductOwners
        case partGroups
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        productOwner = try values.decodeIfPresent(OperationsPersonDTO.self, forKey: .productOwner)
        coProductOwners = try values.decode([OperationsPersonDTO].self, forKey: .coProductOwners)
        partGroups = try values.decode([RosterGroupDTO].self, forKey: .partGroups)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(productOwner, forKey: .productOwner)
        try values.encode(coProductOwners, forKey: .coProductOwners)
        try values.encode(partGroups, forKey: .partGroups)
    }

    var model: OperationsTeam {
        OperationsTeam(
            productOwner: productOwner?.model,
            coProductOwners: coProductOwners.map(\.model),
            partGroups: partGroups.map(\.model)
        )
    }
}

private struct OverviewPartDTO: Codable {
    let part: String
    let currentMemberCount: String
    let quota: String
    let members: [OperationsPersonDTO]

    private enum CodingKeys: String, CodingKey {
        case part
        case currentMemberCount
        case quota
        case members
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        part = try values.decode(String.self, forKey: .part)
        currentMemberCount = try values.decodeFlexibleString(forKey: .currentMemberCount)
        quota = try values.decodeFlexibleString(forKey: .quota)
        members = try values.decode([OperationsPersonDTO].self, forKey: .members)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(part, forKey: .part)
        try values.encode(currentMemberCount, forKey: .currentMemberCount)
        try values.encode(quota, forKey: .quota)
        try values.encode(members, forKey: .members)
    }

    var model: OverviewPart {
        OverviewPart(
            part: part,
            currentMemberCount: currentMemberCount,
            quota: quota,
            members: members.map(\.model)
        )
    }
}

private struct OverviewProjectDTO: Codable {
    let projectId: String
    let projectName: String
    let currentMemberCount: String
    let quota: String
    let partQuotaStatus: String?
    let productOwner: OperationsPersonDTO?
    let coProductOwners: [OperationsPersonDTO]
    let parts: [OverviewPartDTO]

    private enum CodingKeys: String, CodingKey {
        case projectId
        case projectName
        case currentMemberCount
        case quota
        case partQuotaStatus
        case productOwner
        case coProductOwners
        case parts
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try values.decodeFlexibleString(forKey: .projectId)
        projectName = try values.decode(String.self, forKey: .projectName)
        currentMemberCount = try values.decodeFlexibleString(forKey: .currentMemberCount)
        quota = try values.decodeFlexibleString(forKey: .quota)
        partQuotaStatus = try values.decodeIfPresent(String.self, forKey: .partQuotaStatus)
        productOwner = try values.decodeIfPresent(OperationsPersonDTO.self, forKey: .productOwner)
        coProductOwners = try values.decode([OperationsPersonDTO].self, forKey: .coProductOwners)
        parts = try values.decode([OverviewPartDTO].self, forKey: .parts)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(projectId, forKey: .projectId)
        try values.encode(projectName, forKey: .projectName)
        try values.encode(currentMemberCount, forKey: .currentMemberCount)
        try values.encode(quota, forKey: .quota)
        try values.encodeIfPresent(partQuotaStatus, forKey: .partQuotaStatus)
        try values.encodeIfPresent(productOwner, forKey: .productOwner)
        try values.encode(coProductOwners, forKey: .coProductOwners)
        try values.encode(parts, forKey: .parts)
    }

    var model: OverviewProject {
        OverviewProject(
            projectId: projectId,
            projectName: projectName,
            currentMemberCount: currentMemberCount,
            quota: quota,
            partQuotaStatus: partQuotaStatus,
            productOwner: productOwner?.model,
            coProductOwners: coProductOwners.map(\.model),
            parts: parts.map(\.model)
        )
    }
}

private struct MatchingSchoolCountDTO: Codable {
    let schoolId: String
    let schoolName: String
    let matchedMemberCount: String
    let totalMemberCount: String

    private enum CodingKeys: String, CodingKey {
        case schoolId
        case schoolName
        case matchedMemberCount
        case totalMemberCount
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schoolId = try values.decodeFlexibleString(forKey: .schoolId)
        schoolName = try values.decode(String.self, forKey: .schoolName)
        matchedMemberCount = try values.decodeFlexibleString(forKey: .matchedMemberCount)
        totalMemberCount = try values.decodeFlexibleString(forKey: .totalMemberCount)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(schoolId, forKey: .schoolId)
        try values.encode(schoolName, forKey: .schoolName)
        try values.encode(matchedMemberCount, forKey: .matchedMemberCount)
        try values.encode(totalMemberCount, forKey: .totalMemberCount)
    }

    var model: MatchingSchoolCount {
        MatchingSchoolCount(
            schoolId: schoolId,
            schoolName: schoolName,
            matchedMemberCount: matchedMemberCount,
            totalMemberCount: totalMemberCount
        )
    }
}

private struct MatchingPhaseCountDTO: Codable {
    let phase: String
    let matchedMemberCount: String
    let availableMemberCount: String

    private enum CodingKeys: String, CodingKey {
        case phase
        case matchedMemberCount
        case availableMemberCount
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        phase = try values.decode(String.self, forKey: .phase)
        matchedMemberCount = try values.decodeFlexibleString(forKey: .matchedMemberCount)
        availableMemberCount = try values.decodeFlexibleString(forKey: .availableMemberCount)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(phase, forKey: .phase)
        try values.encode(matchedMemberCount, forKey: .matchedMemberCount)
        try values.encode(availableMemberCount, forKey: .availableMemberCount)
    }

    var model: MatchingPhaseCount {
        MatchingPhaseCount(
            phase: phase,
            matchedMemberCount: matchedMemberCount,
            availableMemberCount: availableMemberCount
        )
    }
}

private struct PartMatchingCountDTO: Codable {
    let part: String
    let matchedMemberCount: String
    let quota: String

    private enum CodingKeys: String, CodingKey {
        case part
        case matchedMemberCount
        case quota
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        part = try values.decode(String.self, forKey: .part)
        matchedMemberCount = try values.decodeFlexibleString(forKey: .matchedMemberCount)
        quota = try values.decodeFlexibleString(forKey: .quota)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(part, forKey: .part)
        try values.encode(matchedMemberCount, forKey: .matchedMemberCount)
        try values.encode(quota, forKey: .quota)
    }

    var model: PartMatchingCount {
        PartMatchingCount(
            part: part,
            matchedMemberCount: matchedMemberCount,
            quota: quota
        )
    }
}

private struct PhaseMatchedCountDTO: Codable {
    let phase: String
    let matchedMemberCount: String

    private enum CodingKeys: String, CodingKey {
        case phase
        case matchedMemberCount
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        phase = try values.decode(String.self, forKey: .phase)
        matchedMemberCount = try values.decodeFlexibleString(forKey: .matchedMemberCount)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(phase, forKey: .phase)
        try values.encode(matchedMemberCount, forKey: .matchedMemberCount)
    }

    var model: PhaseMatchedCount {
        PhaseMatchedCount(
            phase: phase,
            matchedMemberCount: matchedMemberCount
        )
    }
}

private struct ProjectMatchingCountDTO: Codable {
    let projectId: String
    let projectName: String
    let matchedMemberCount: String
    let quota: String
    let rounds: [PhaseMatchedCountDTO]
    let parts: [PartMatchingCountDTO]

    private enum CodingKeys: String, CodingKey {
        case projectId
        case projectName
        case matchedMemberCount
        case quota
        case rounds
        case parts
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try values.decodeFlexibleString(forKey: .projectId)
        projectName = try values.decode(String.self, forKey: .projectName)
        matchedMemberCount = try values.decodeFlexibleString(forKey: .matchedMemberCount)
        quota = try values.decodeFlexibleString(forKey: .quota)
        rounds = try values.decode([PhaseMatchedCountDTO].self, forKey: .rounds)
        parts = try values.decode([PartMatchingCountDTO].self, forKey: .parts)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(projectId, forKey: .projectId)
        try values.encode(projectName, forKey: .projectName)
        try values.encode(matchedMemberCount, forKey: .matchedMemberCount)
        try values.encode(quota, forKey: .quota)
        try values.encode(rounds, forKey: .rounds)
        try values.encode(parts, forKey: .parts)
    }

    var model: ProjectMatchingCount {
        ProjectMatchingCount(
            projectId: projectId,
            projectName: projectName,
            matchedMemberCount: matchedMemberCount,
            quota: quota,
            rounds: rounds.map(\.model),
            parts: parts.map(\.model)
        )
    }
}

private struct PublicMatchingStatisticsDTO: Codable {
    let roundMatchingStatistics: [MatchingPhaseCountDTO]
    let schoolMatchingStatistics: [MatchingSchoolCountDTO]
    let projectMatchingStatistics: [ProjectMatchingCountDTO]

    private enum CodingKeys: String, CodingKey {
        case roundMatchingStatistics
        case schoolMatchingStatistics
        case projectMatchingStatistics
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        roundMatchingStatistics = try values.decode([MatchingPhaseCountDTO].self, forKey: .roundMatchingStatistics)
        schoolMatchingStatistics = try values.decode([MatchingSchoolCountDTO].self, forKey: .schoolMatchingStatistics)
        projectMatchingStatistics = try values.decode([ProjectMatchingCountDTO].self, forKey: .projectMatchingStatistics)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(roundMatchingStatistics, forKey: .roundMatchingStatistics)
        try values.encode(schoolMatchingStatistics, forKey: .schoolMatchingStatistics)
        try values.encode(projectMatchingStatistics, forKey: .projectMatchingStatistics)
    }

    var model: PublicMatchingStatistics {
        PublicMatchingStatistics(
            roundMatchingStatistics: roundMatchingStatistics.map(\.model),
            schoolMatchingStatistics: schoolMatchingStatistics.map(\.model),
            projectMatchingStatistics: projectMatchingStatistics.map(\.model)
        )
    }
}

private struct ApplicationPhaseCountDTO: Codable {
    let phase: String
    let applicantCount: String

    private enum CodingKeys: String, CodingKey {
        case phase
        case applicantCount
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        phase = try values.decode(String.self, forKey: .phase)
        applicantCount = try values.decodeFlexibleString(forKey: .applicantCount)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(phase, forKey: .phase)
        try values.encode(applicantCount, forKey: .applicantCount)
    }

    var model: ApplicationPhaseCount {
        ApplicationPhaseCount(
            phase: phase,
            applicantCount: applicantCount
        )
    }
}

private struct ApplicationSchoolCountDTO: Codable {
    let schoolId: String
    let schoolName: String
    let totalMemberCount: String
    let rounds: [ApplicationPhaseCountDTO]

    private enum CodingKeys: String, CodingKey {
        case schoolId
        case schoolName
        case totalMemberCount
        case rounds
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schoolId = try values.decodeFlexibleString(forKey: .schoolId)
        schoolName = try values.decode(String.self, forKey: .schoolName)
        totalMemberCount = try values.decodeFlexibleString(forKey: .totalMemberCount)
        rounds = try values.decode([ApplicationPhaseCountDTO].self, forKey: .rounds)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(schoolId, forKey: .schoolId)
        try values.encode(schoolName, forKey: .schoolName)
        try values.encode(totalMemberCount, forKey: .totalMemberCount)
        try values.encode(rounds, forKey: .rounds)
    }

    var model: ApplicationSchoolCount {
        ApplicationSchoolCount(
            schoolId: schoolId,
            schoolName: schoolName,
            totalMemberCount: totalMemberCount,
            rounds: rounds.map(\.model)
        )
    }
}

private struct ApplicationProjectCountDTO: Codable {
    let projectId: String
    let projectName: String
    let rounds: [ApplicationPhaseCountDTO]

    private enum CodingKeys: String, CodingKey {
        case projectId
        case projectName
        case rounds
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try values.decodeFlexibleString(forKey: .projectId)
        projectName = try values.decode(String.self, forKey: .projectName)
        rounds = try values.decode([ApplicationPhaseCountDTO].self, forKey: .rounds)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(projectId, forKey: .projectId)
        try values.encode(projectName, forKey: .projectName)
        try values.encode(rounds, forKey: .rounds)
    }

    var model: ApplicationProjectCount {
        ApplicationProjectCount(
            projectId: projectId,
            projectName: projectName,
            rounds: rounds.map(\.model)
        )
    }
}

private struct OperationsStatisticsDTO: Codable {
    let schoolApplicationStatistics: [ApplicationSchoolCountDTO]
    let projectRoundStatistics: [ApplicationProjectCountDTO]

    private enum CodingKeys: String, CodingKey {
        case schoolApplicationStatistics
        case projectRoundStatistics
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        schoolApplicationStatistics = try values.decode([ApplicationSchoolCountDTO].self, forKey: .schoolApplicationStatistics)
        projectRoundStatistics = try values.decode([ApplicationProjectCountDTO].self, forKey: .projectRoundStatistics)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(schoolApplicationStatistics, forKey: .schoolApplicationStatistics)
        try values.encode(projectRoundStatistics, forKey: .projectRoundStatistics)
    }

    var model: OperationsStatistics {
        OperationsStatistics(
            schoolApplicationStatistics: schoolApplicationStatistics.map(\.model),
            projectRoundStatistics: projectRoundStatistics.map(\.model)
        )
    }
}

private struct EditableOptionDTO: Codable {
    let optionId: String?
    let content: String
    let orderNo: String
    let isOther: Bool

    private enum CodingKeys: String, CodingKey {
        case optionId
        case content
        case orderNo
        case isOther
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        optionId = try values.decodeFlexibleStringIfPresent(forKey: .optionId)
        content = try values.decode(String.self, forKey: .content)
        orderNo = try values.decodeFlexibleString(forKey: .orderNo)
        isOther = try values.decode(Bool.self, forKey: .isOther)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(optionId, forKey: .optionId)
        try values.encode(content, forKey: .content)
        try values.encode(orderNo, forKey: .orderNo)
        try values.encode(isOther, forKey: .isOther)
    }

    var model: EditableOption {
        EditableOption(
            optionId: optionId,
            content: content,
            orderNo: orderNo,
            isOther: isOther
        )
    }
}

private struct EditableQuestionDTO: Codable {
    let questionId: String?
    let type: String
    let title: String
    let description: String?
    let isRequired: Bool
    let orderNo: String
    let options: [EditableOptionDTO]

    private enum CodingKeys: String, CodingKey {
        case questionId
        case type
        case title
        case description
        case isRequired
        case orderNo
        case options
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        questionId = try values.decodeFlexibleStringIfPresent(forKey: .questionId)
        type = try values.decode(String.self, forKey: .type)
        title = try values.decode(String.self, forKey: .title)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        isRequired = try values.decode(Bool.self, forKey: .isRequired)
        orderNo = try values.decodeFlexibleString(forKey: .orderNo)
        options = try values.decode([EditableOptionDTO].self, forKey: .options)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(questionId, forKey: .questionId)
        try values.encode(type, forKey: .type)
        try values.encode(title, forKey: .title)
        try values.encodeIfPresent(description, forKey: .description)
        try values.encode(isRequired, forKey: .isRequired)
        try values.encode(orderNo, forKey: .orderNo)
        try values.encode(options, forKey: .options)
    }

    var model: EditableQuestion {
        EditableQuestion(
            questionId: questionId,
            type: type,
            title: title,
            description: description,
            isRequired: isRequired,
            orderNo: orderNo,
            options: options.map(\.model)
        )
    }
}

private struct EditableSectionDTO: Codable {
    let sectionId: String?
    let type: String
    let allowedParts: [String]?
    let title: String
    let description: String?
    let orderNo: String
    let questions: [EditableQuestionDTO]

    private enum CodingKeys: String, CodingKey {
        case sectionId
        case type
        case allowedParts
        case title
        case description
        case orderNo
        case questions
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sectionId = try values.decodeFlexibleStringIfPresent(forKey: .sectionId)
        type = try values.decode(String.self, forKey: .type)
        allowedParts = try values.decodeIfPresent([String].self, forKey: .allowedParts)
        title = try values.decode(String.self, forKey: .title)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        orderNo = try values.decodeFlexibleString(forKey: .orderNo)
        questions = try values.decode([EditableQuestionDTO].self, forKey: .questions)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(sectionId, forKey: .sectionId)
        try values.encode(type, forKey: .type)
        try values.encodeIfPresent(allowedParts, forKey: .allowedParts)
        try values.encode(title, forKey: .title)
        try values.encodeIfPresent(description, forKey: .description)
        try values.encode(orderNo, forKey: .orderNo)
        try values.encode(questions, forKey: .questions)
    }

    var model: EditableSection {
        EditableSection(
            sectionId: sectionId,
            type: type,
            allowedParts: allowedParts,
            title: title,
            description: description,
            orderNo: orderNo,
            questions: questions.map(\.model)
        )
    }
}

private struct EditableMatchingFormDTO: Codable {
    let title: String?
    let description: String?
    let sections: [EditableSectionDTO]

    private enum CodingKeys: String, CodingKey {
        case title
        case description
        case sections
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decodeIfPresent(String.self, forKey: .title)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        sections = try values.decode([EditableSectionDTO].self, forKey: .sections)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(title, forKey: .title)
        try values.encodeIfPresent(description, forKey: .description)
        try values.encode(sections, forKey: .sections)
    }

    var model: EditableMatchingForm {
        EditableMatchingForm(
            title: title,
            description: description,
            sections: sections.map(\.model)
        )
    }
}

private struct OperationsPage<Row: Codable>: Codable {
    let content: [Row]
    let hasNext: Bool

    enum CodingKeys: CodingKey { case content, hasNext }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        content = try values.decode([Row].self, forKey: .content)
        hasNext = try values.decode(Bool.self, forKey: .hasNext)
    }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(content, forKey: .content)
        try values.encode(hasNext, forKey: .hasNext)
    }
}

private struct PermissionKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }
    init(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
}

struct OperationsPermissionsDTO: Codable {
    let id: String
    let capabilities: [ProjectPermission: MatchingCapability]

    init(from decoder: Decoder) throws {
        let row = try decoder.container(keyedBy: PermissionKey.self)
        id = try row.decodeFlexibleString(forKey: PermissionKey(stringValue: "projectId"))
        var flags: [ProjectPermission: MatchingCapability] = [:]
        for permission in ProjectPermission.allCases {
            var node = row
            for piece in permission.rawValue.split(separator: ".") {
                let key = PermissionKey(stringValue: String(piece))
                guard node.contains(key) else { break }
                node = try node.nestedContainer(keyedBy: PermissionKey.self, forKey: key)
            }
            guard let allowed = try node.decodeIfPresent(
                Bool.self, forKey: PermissionKey(stringValue: "allowed")
            ) else { continue }
            flags[permission] = MatchingCapability(
                allowed: allowed,
                reasonCode: try node.decodeIfPresent(String.self, forKey: .init(stringValue: "reasonCode")),
                reason: try node.decodeIfPresent(String.self, forKey: .init(stringValue: "reason"))
            )
        }
        capabilities = flags
    }

    func encode(to encoder: Encoder) throws {
        var row = encoder.container(keyedBy: PermissionKey.self)
        try row.encode(id, forKey: .init(stringValue: "projectId"))
        var groups: [String: [String: CapabilityBody]] = [:]
        for (permission, capability) in capabilities {
            let path = permission.rawValue.split(separator: ".").map(String.init)
            let body = CapabilityBody(capability)
            if path.count == 2 {
                groups[path[0], default: [:]][path[1]] = body
            } else {
                try row.encode(body, forKey: .init(stringValue: path[0]))
            }
        }
        for (name, group) in groups {
            try row.encode(group, forKey: .init(stringValue: name))
        }
    }

    private struct CapabilityBody: Encodable {
        let allowed: Bool
        let reasonCode: String?
        let reason: String?
        init(_ capability: MatchingCapability) {
            allowed = capability.allowed
            reasonCode = capability.reasonCode
            reason = capability.reason
        }
    }
}

private struct OperationsResultID: Codable {
    let projectId: String
    enum CodingKeys: CodingKey { case projectId }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try values.decodeFlexibleString(forKey: .projectId)
    }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(projectId, forKey: .projectId)
    }
}

struct DraftBody: Encodable {
    let gisuId: Int64
    let productOwnerMemberId: Int64?

    init(gisuId: String, productOwnerMemberId: String?) throws {
        self.gisuId = try operationId(gisuId)
        self.productOwnerMemberId = try productOwnerMemberId.map(operationId)
    }
}
private struct ProjectEditBody: Encodable {
    let name: String
    let description: String
    let externalLink: String
}
private struct ProjectImageBody: Encodable {
    let thumbnailFileId: String?
    let logoFileId: String?
}

private struct MemberBody: Encodable { let memberId: Int64; let part: String }
private struct DecisionBody: Encodable { let status: String }
private struct TransferBody: Encodable { let newOwnerMemberId: Int64 }
private struct ReasonBody: Encodable { let reason: String }
private struct MemberStatusBody: Encodable { let status: String; let reason: String }
private struct CompleteBody: Encodable { let projectIds: [Int64] }
private struct QuotaBody: Encodable {
    struct Entry: Encodable { let part: String; let quota: Int }
    let entries: [Entry]
}

extension LiveMatchingRepository {
    public func managedProjects(gisuId: String, keyword: String?, page: Int) async throws
        -> (projects: [ManagedProject], hasNext: Bool) {
        var query = [
            URLQueryItem(name: "gisuId", value: gisuId),
            URLQueryItem(name: "page", value: String(page))
        ]
        if let keyword, !keyword.isEmpty { query.append(.init(name: "keyword", value: keyword)) }
        let result: OperationsPage<ManagedProjectDTO> = try await get(
            "/api/v1/projects/me/managed", query: query
        )
        return (result.content.map(\.model), result.hasNext)
    }

    public func latestDraft(gisuId: String) async throws -> ManagedProject? {
        let result: OperationsPage<ManagedProjectDTO> = try await get(
            "/api/v1/projects/me/drafts", query: [
                .init(name: "gisuId", value: gisuId), .init(name: "size", value: "1")
            ]
        )
        return result.content.first?.model
    }

    public func createProjectDraft(gisuId: String, productOwnerMemberId: String?) async throws -> String {
        let draft: OperationsResultID = try await mutation(
            "/api/v1/projects", method: .post,
            body: try DraftBody(gisuId: gisuId, productOwnerMemberId: productOwnerMemberId)
        )
        return draft.projectId
    }

    public func pmCandidates(gisuId: String, keyword: String?, page: Int) async throws
        -> (people: [OperationsPerson], hasNext: Bool) {
        var query = [URLQueryItem(name: "gisuId", value: gisuId),
                     URLQueryItem(name: "page", value: String(page))]
        if let keyword, !keyword.isEmpty { query.append(.init(name: "keyword", value: keyword)) }
        let result: OperationsPage<OperationsPersonDTO> = try await get(
            "/api/v1/projects/admin/pm-candidates", query: query
        )
        return (result.content.map(\.model), result.hasNext)
    }

    public func permissions(projectId: String) async throws -> [ProjectPermission: MatchingCapability] {
        let response: [String: [OperationsPermissionsDTO]] = try await get(
            "/api/v1/projects/permissions", query: [.init(name: "ids", value: projectId)]
        )
        return response["projects"]?.first { $0.id == projectId }?.capabilities ?? [:]
    }

    public func editableForm(projectId: String) async throws -> EditableMatchingForm {
        let result: EditableMatchingFormDTO = try await get("/api/v1/projects/\(projectId)/application-form")
        return result.model
    }

    public func applicants(projectId: String) async throws -> [ApplicantRow] {
        let rows: [ApplicantRowDTO] = try await get("/api/v1/projects/\(projectId)/applications")
        return rows.map(\.model)
    }

    public func publishedTeam(projectId: String) async throws -> OperationsTeam? {
        let rows: [String: OperationsTeamDTO] = try await get(
            "/api/v1/projects/members", query: [.init(name: "projectIds", value: projectId)]
        )
        return rows[projectId]?.model
    }

    public func team(projectId: String) async throws -> OperationsTeam {
        let row: OperationsTeamDTO = try await get("/api/v1/projects/\(projectId)/members")
        return row.model
    }

    public func candidates(projectId: String, part: String, page: Int) async throws
        -> (people: [OperationsPerson], hasNext: Bool) {
        let rows: OperationsPage<OperationsPersonDTO> = try await get(
            "/api/v1/projects/admin/\(projectId)/members/candidates",
            query: [.init(name: "part", value: part), .init(name: "page", value: String(page))]
        )
        return (rows.content.map(\.model), rows.hasNext)
    }

    public func overview(chapterId: String, adjustment: Bool) async throws -> [OverviewProject] {
        let result: [String: [OverviewProjectDTO]] = try await get(
            "/api/v1/projects/statistics/matching-overview", query: [
                .init(name: "chapterId", value: chapterId),
                .init(name: "view", value: adjustment ? "ADJUSTMENT" : "PUBLISHED")
            ]
        )
        return result["projects"]?.map(\.model) ?? []
    }

    public func publicStatistics(chapterId: String) async throws -> PublicMatchingStatistics {
        let result: PublicMatchingStatisticsDTO = try await get(
            "/api/v1/projects/statistics/matchings", query: [.init(name: "chapterId", value: chapterId)]
        )
        return result.model
    }

    public func applicationStatistics(projectId: String) async throws -> OperationsStatistics {
        let result: ApplicationStatisticsEnvelope = try await get(
            "/api/v1/projects/statistics/applications", query: [.init(name: "projectIds", value: projectId)]
        )
        return OperationsStatistics(
            schoolApplicationStatistics: result.summary.schoolApplicationStatistics.map(\.model),
            projectRoundStatistics: result.summary.projectRoundStatistics.map(\.model),
            matchingType: result.matchingRound?.type
        )
    }

    private func uploadProjectImage(_ file: URL, slot: ProjectImageSlot) async throws -> String {
        let scoped = file.startAccessingSecurityScopedResource()
        defer { if scoped { file.stopAccessingSecurityScopedResource() } }
        let size = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize
        guard file.isFileURL, let size, (1...10_485_760).contains(size) else {
            throw CocoaError(.fileReadTooLarge)
        }
        let mime: String
        switch file.pathExtension.lowercased() {
        case "jpg", "jpeg": mime = "image/jpeg"
        case "png": mime = "image/png"
        case "svg" where slot == .logo: mime = "image/svg+xml"
        default: throw CocoaError(.fileReadUnsupportedScheme)
        }
        return try await uploadMatchingFile(file: file, contentType: mime, category: slot.rawValue)
    }

    public func perform(_ operation: ProjectOperation, projectId: String) async throws {
        let path = "/api/v1/projects/\(try operationId(projectId))"
        let admin = "/api/v1/projects/admin/\(projectId)/members"
        switch operation {
        case let .changeImage(file, slot):
            let fileId = try await uploadProjectImage(file, slot: slot)
            let body = ProjectImageBody(
                thumbnailFileId: slot == .thumbnail ? fileId : nil,
                logoFileId: slot == .logo ? fileId : nil
            )
            try await send(path, method: .patch, body: body)
        case let .edit(name, description, link):
            try await send(path, method: .patch, body: ProjectEditBody(name: name, description: description, externalLink: link))
        case let .form(form, confirm):
            do {
                try await send(path + "/application-form", method: .put,
                               body: try FormBody(form, confirm: confirm))
            } catch let RepositoryError.serverError(code, message) where code == "PROJECT-0026" && !confirm {
                guard let message, !message.isEmpty else {
                    throw RepositoryError.serverError(code: code, message: message)
                }
                throw MatchingFormSaveError.answeredSectionDeletion(message: message)
            }
        case let .quotas(quotas):
            let entries = quotas.map { QuotaBody.Entry(part: $0.key, quota: $0.value) }
            try await send(path + "/part-quotas", method: .put, body: QuotaBody(entries: entries))
        case .submit:
            try await send(path + "/submit", method: .post)
        case .publish:
            try await send(path + "/publish", method: .post)
        case .complete:
            try await send("/api/v1/projects/complete", method: .post, body: CompleteBody(projectIds: [try operationId(projectId)]))
        case .delete:
            try await send(path, method: .delete)
        case let .abort(reason):
            try await send(path + "/abort", method: .post, body: ReasonBody(reason: reason))
        case let .decision(applicationId, approved):
            try await send(path + "/applications/\(try operationId(applicationId))/decision",
                           method: .patch, body: DecisionBody(status: approved ? "APPROVED" : "REJECTED"))
        case let .add(memberId, part):
            try await send(path + "/members", method: .post, body: MemberBody(memberId: try operationId(memberId), part: part))
        case let .assign(memberId, part):
            try await send(admin, method: .post, body: MemberBody(memberId: try operationId(memberId), part: part))
        case let .remove(memberId):
            try await send(path + "/members/\(try operationId(memberId))", method: .delete)
        case let .unassign(memberId):
            try await send(admin + "/\(try operationId(memberId))", method: .delete)
        case let .changeStatus(memberId, status, reason):
            try await send(path + "/members/\(try operationId(memberId))/status", method: .patch,
                           body: MemberStatusBody(status: status, reason: reason))
        case let .transfer(memberId):
            try await send(path + "/transfer-ownership", method: .post,
                           body: TransferBody(newOwnerMemberId: try operationId(memberId)))
        }
    }
}

private func operationId(_ value: String) throws -> Int64 {
    guard let id = Int64(value), id > 0 else { throw CocoaError(.coderInvalidValue) }
    return id
}

private struct ApplicationStatisticsEnvelope: Codable {
    let matchingRound: OperationsRoundDTO?
    let summary: OperationsStatisticsDTO
    enum CodingKeys: CodingKey { case summary, matchingRound }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        matchingRound = try values.decodeIfPresent(OperationsRoundDTO.self, forKey: .matchingRound)
        summary = try values.decode(OperationsStatisticsDTO.self, forKey: .summary)
    }
    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(matchingRound, forKey: .matchingRound)
        try values.encode(summary, forKey: .summary)
    }
}

struct FormBody: Encodable {
    let title: String?
    let description: String?
    let sections: [Section]
    let confirmDeleteAnsweredSections: Bool

    struct Section: Encodable {
        let sectionId: Int64?
        let type: String
        let allowedParts: [String]?
        let title: String
        let description: String?
        let orderNo: Int
        let questions: [Question]
    }
    struct Question: Encodable {
        let questionId: Int64?
        let type: String
        let title: String
        let description: String?
        let isRequired: Bool
        let orderNo: Int
        let options: [Option]
    }
    struct Option: Encodable {
        let optionId: Int64?
        let content: String
        let orderNo: Int
        let isOther: Bool
    }

    init(_ form: EditableMatchingForm, confirm: Bool) throws {
        title = form.title
        description = form.description
        confirmDeleteAnsweredSections = confirm
        sections = try form.sections.enumerated().map { index, section in
            let questions = try section.questions.enumerated().map { offset, question in
                let options = try question.options.enumerated().map { position, option in
                    Option(optionId: try option.optionId.map(operationId), content: option.content,
                           orderNo: position, isOther: option.isOther)
                }
                return Question(questionId: try question.questionId.map(operationId), type: question.type,
                                title: question.title, description: question.description,
                                isRequired: question.isRequired, orderNo: offset, options: options)
            }
            return Section(sectionId: try section.sectionId.map(operationId), type: section.type,
                           allowedParts: section.allowedParts, title: section.title,
                           description: section.description, orderNo: index, questions: questions)
        }
    }
}
