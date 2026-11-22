//
//  MatchingResponseDTO.swift
//  MatchingData
//
//  Created by euijjang97 on 11/22/26.
//

import Foundation
import MatchingDomain
import UMCFoundation

struct MatchingMemberDTO: Codable {
    let memberId: String
    let nickname: String?
    let name: String?
    let schoolName: String?

    enum CodingKeys: String, CodingKey {
        case memberId
        case nickname
        case name
        case schoolName
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        memberId = try values.decodeFlexibleString(forKey: .memberId)
        nickname = try values.decodeIfPresent(String.self, forKey: .nickname)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        schoolName = try values.decodeIfPresent(String.self, forKey: .schoolName)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(memberId, forKey: .memberId)
        try values.encodeIfPresent(nickname, forKey: .nickname)
        try values.encodeIfPresent(name, forKey: .name)
        try values.encodeIfPresent(schoolName, forKey: .schoolName)
    }

    var model: MatchingMember {
        .init(
            memberId: memberId,
            nickname: nickname,
            name: name,
            schoolName: schoolName
        )
    }
}

struct MatchingQuotaDTO: Codable {
    let part: String
    let currentCount: String
    let quota: String
    let status: String

    enum CodingKeys: String, CodingKey {
        case part
        case currentCount
        case quota
        case status
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        part = try values.decode(String.self, forKey: .part)
        currentCount = try values.decodeFlexibleString(forKey: .currentCount)
        quota = try values.decodeFlexibleString(forKey: .quota)
        status = try values.decode(String.self, forKey: .status)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(part, forKey: .part)
        try values.encode(currentCount, forKey: .currentCount)
        try values.encode(quota, forKey: .quota)
        try values.encode(status, forKey: .status)
    }

    var model: MatchingQuota {
        .init(
            part: part,
            currentCount: currentCount,
            quota: quota,
            status: status
        )
    }
}

struct MatchingProjectDTO: Codable {
    let id: String
    let name: String?
    let description: String?
    let thumbnailImageUrl: String?
    let productOwner: MatchingMemberDTO?
    let partQuotas: [MatchingQuotaDTO]
    let partQuotaStatus: String?
    let logoImageUrl: String?
    let externalLink: String?
    let applicationFormId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case thumbnailImageUrl
        case productOwner
        case partQuotas
        case partQuotaStatus
        case logoImageUrl
        case externalLink
        case applicationFormId
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeFlexibleString(forKey: .id)
        name = try values.decodeIfPresent(String.self, forKey: .name)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        thumbnailImageUrl = try values.decodeIfPresent(String.self, forKey: .thumbnailImageUrl)
        productOwner = try values.decodeIfPresent(MatchingMemberDTO.self, forKey: .productOwner)
        partQuotas = try values.decode([MatchingQuotaDTO].self, forKey: .partQuotas)
        partQuotaStatus = try values.decodeIfPresent(String.self, forKey: .partQuotaStatus)
        logoImageUrl = try values.decodeIfPresent(String.self, forKey: .logoImageUrl)
        externalLink = try values.decodeIfPresent(String.self, forKey: .externalLink)
        applicationFormId = try values.decodeFlexibleStringIfPresent(forKey: .applicationFormId)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encodeIfPresent(name, forKey: .name)
        try values.encodeIfPresent(description, forKey: .description)
        try values.encodeIfPresent(thumbnailImageUrl, forKey: .thumbnailImageUrl)
        try values.encodeIfPresent(productOwner, forKey: .productOwner)
        try values.encode(partQuotas, forKey: .partQuotas)
        try values.encodeIfPresent(partQuotaStatus, forKey: .partQuotaStatus)
        try values.encodeIfPresent(logoImageUrl, forKey: .logoImageUrl)
        try values.encodeIfPresent(externalLink, forKey: .externalLink)
        try values.encodeIfPresent(applicationFormId, forKey: .applicationFormId)
    }

    var model: MatchingProject {
        .init(
            id: id,
            name: name ?? "",
            description: description,
            thumbnailImageUrl: thumbnailImageUrl,
            productOwner: productOwner?.model,
            partQuotas: partQuotas.map(\.model),
            partQuotaStatus: partQuotaStatus,
            logoImageUrl: logoImageUrl,
            externalLink: externalLink,
            applicationFormId: applicationFormId
        )
    }
}

struct MatchingProjectPageDTO: Codable {
    let content: [MatchingProjectDTO]
    let hasNext: Bool

    let totalElements: String?

    enum CodingKeys: String, CodingKey {
        case totalElements
        case content
        case hasNext
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        totalElements = try values.decodeFlexibleStringIfPresent(forKey: .totalElements)
        content = try values.decode([MatchingProjectDTO].self, forKey: .content)
        hasNext = try values.decode(Bool.self, forKey: .hasNext)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(totalElements, forKey: .totalElements)
        try values.encode(content, forKey: .content)
        try values.encode(hasNext, forKey: .hasNext)
    }

    var model: MatchingProjectPage {
        .init(
            content: content.map(\.model),
            hasNext: hasNext, totalElements: totalElements
        )
    }
}

struct MatchingCapabilityDTO: Codable {
    let allowed: Bool
    let reasonCode: String?
    let reason: String?

    enum CodingKeys: String, CodingKey {
        case allowed
        case reasonCode
        case reason
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        allowed = try values.decode(Bool.self, forKey: .allowed)
        reasonCode = try values.decodeIfPresent(String.self, forKey: .reasonCode)
        reason = try values.decodeIfPresent(String.self, forKey: .reason)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(allowed, forKey: .allowed)
        try values.encodeIfPresent(reasonCode, forKey: .reasonCode)
        try values.encodeIfPresent(reason, forKey: .reason)
    }

    var model: MatchingCapability {
        .init(
            allowed: allowed,
            reasonCode: reasonCode,
            reason: reason
        )
    }
}

struct MatchingRoundDTO: Codable {
    let id: String
    let name: String
    let type: String
    let phase: String
    let chapterId: String
    let startsAt: String
    let endsAt: String
    let decisionDeadline: String?
    let resultPublishAt: String?

    let description: String?
    let autoDecisionExecutedAt: String?

    enum CodingKeys: String, CodingKey {
        case description
        case autoDecisionExecutedAt
        case id
        case name
        case type
        case phase
        case chapterId
        case startsAt
        case endsAt
        case decisionDeadline
        case resultPublishAt
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        autoDecisionExecutedAt = try values.decodeIfPresent(String.self, forKey: .autoDecisionExecutedAt)
        id = try values.decodeFlexibleString(forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        type = try values.decode(String.self, forKey: .type)
        phase = try values.decode(String.self, forKey: .phase)
        chapterId = try values.decodeFlexibleString(forKey: .chapterId)
        startsAt = try values.decode(String.self, forKey: .startsAt)
        endsAt = try values.decode(String.self, forKey: .endsAt)
        decisionDeadline = try values.decodeIfPresent(String.self, forKey: .decisionDeadline)
        resultPublishAt = try values.decodeIfPresent(String.self, forKey: .resultPublishAt)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(description, forKey: .description)
        try values.encodeIfPresent(autoDecisionExecutedAt, forKey: .autoDecisionExecutedAt)
        try values.encode(id, forKey: .id)
        try values.encode(name, forKey: .name)
        try values.encode(type, forKey: .type)
        try values.encode(phase, forKey: .phase)
        try values.encode(chapterId, forKey: .chapterId)
        try values.encode(startsAt, forKey: .startsAt)
        try values.encode(endsAt, forKey: .endsAt)
        try values.encodeIfPresent(decisionDeadline, forKey: .decisionDeadline)
        try values.encodeIfPresent(resultPublishAt, forKey: .resultPublishAt)
    }

    var model: MatchingRound {
        .init(
            id: id,
            name: name,
            type: type,
            phase: phase,
            chapterId: chapterId,
            startsAt: startsAt,
            endsAt: endsAt,
            decisionDeadline: decisionDeadline,
            resultPublishAt: resultPublishAt,
            description: description,
            autoDecisionExecutedAt: autoDecisionExecutedAt
        )
    }
}

struct MatchingRoundBriefDTO: Codable {
    let id: String?
    let type: String?
    let phase: String?

    enum CodingKeys: String, CodingKey {
        case id
        case type
        case phase
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeFlexibleStringIfPresent(forKey: .id)
        type = try values.decodeIfPresent(String.self, forKey: .type)
        phase = try values.decodeIfPresent(String.self, forKey: .phase)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(id, forKey: .id)
        try values.encodeIfPresent(type, forKey: .type)
        try values.encodeIfPresent(phase, forKey: .phase)
    }

    var model: MatchingRoundBrief {
        .init(
            id: id,
            type: type,
            phase: phase
        )
    }
}

struct MatchingApplicationProjectDTO: Codable {
    let name: String
    let thumbnailImageUrl: String?
    let productOwner: MatchingMemberDTO?
    let partQuotas: [MatchingQuotaDTO]

    enum CodingKeys: String, CodingKey {
        case name
        case thumbnailImageUrl
        case productOwner
        case partQuotas
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        thumbnailImageUrl = try values.decodeIfPresent(String.self, forKey: .thumbnailImageUrl)
        productOwner = try values.decodeIfPresent(MatchingMemberDTO.self, forKey: .productOwner)
        partQuotas = try values.decode([MatchingQuotaDTO].self, forKey: .partQuotas)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(name, forKey: .name)
        try values.encodeIfPresent(thumbnailImageUrl, forKey: .thumbnailImageUrl)
        try values.encodeIfPresent(productOwner, forKey: .productOwner)
        try values.encode(partQuotas, forKey: .partQuotas)
    }

    var model: MatchingApplicationProject {
        .init(
            name: name,
            thumbnailImageUrl: thumbnailImageUrl,
            productOwner: productOwner?.model,
            partQuotas: partQuotas.map(\.model)
        )
    }
}

struct MatchingApplicationDTO: Codable {
    let applicationId: String?
    let projectId: String
    let project: MatchingApplicationProjectDTO?
    let matchingRound: MatchingRoundBriefDTO?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case applicationId
        case projectId
        case project
        case matchingRound
        case status
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        applicationId = try values.decodeFlexibleStringIfPresent(forKey: .applicationId)
        projectId = try values.decodeFlexibleString(forKey: .projectId)
        project = try values.decodeIfPresent(MatchingApplicationProjectDTO.self, forKey: .project)
        matchingRound = try values.decodeIfPresent(MatchingRoundBriefDTO.self, forKey: .matchingRound)
        status = try values.decodeIfPresent(String.self, forKey: .status)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(applicationId, forKey: .applicationId)
        try values.encode(projectId, forKey: .projectId)
        try values.encodeIfPresent(project, forKey: .project)
        try values.encodeIfPresent(matchingRound, forKey: .matchingRound)
        try values.encodeIfPresent(status, forKey: .status)
    }

    var model: MatchingApplication {
        .init(
            applicationId: applicationId,
            projectId: projectId,
            project: project?.model,
            matchingRound: matchingRound?.model,
            status: status
        )
    }
}

struct MatchingFormOptionDTO: Codable {
    let optionId: String
    let content: String

    enum CodingKeys: String, CodingKey {
        case optionId
        case content
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        optionId = try values.decodeFlexibleString(forKey: .optionId)
        content = try values.decode(String.self, forKey: .content)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(optionId, forKey: .optionId)
        try values.encode(content, forKey: .content)
    }

    var model: MatchingFormOption {
        .init(
            optionId: optionId,
            content: content
        )
    }
}

struct MatchingSelectedOptionDTO: Codable {
    let questionOptionId: String?
    let answeredAsContent: String?

    enum CodingKeys: String, CodingKey {
        case questionOptionId
        case answeredAsContent
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        questionOptionId = try values.decodeFlexibleStringIfPresent(forKey: .questionOptionId)
        answeredAsContent = try values.decodeIfPresent(String.self, forKey: .answeredAsContent)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(questionOptionId, forKey: .questionOptionId)
        try values.encodeIfPresent(answeredAsContent, forKey: .answeredAsContent)
    }

    var model: MatchingSelectedOption {
        .init(
            questionOptionId: questionOptionId,
            answeredAsContent: answeredAsContent
        )
    }
}

struct MatchingAttachmentDTO: Codable {
    let fileId: String
    let originalFileName: String?
    let url: String?

    enum CodingKeys: String, CodingKey {
        case fileId
        case originalFileName
        case url
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fileId = try values.decode(String.self, forKey: .fileId)
        originalFileName = try values.decodeIfPresent(String.self, forKey: .originalFileName)
        url = try values.decodeIfPresent(String.self, forKey: .url)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(fileId, forKey: .fileId)
        try values.encodeIfPresent(originalFileName, forKey: .originalFileName)
        try values.encodeIfPresent(url, forKey: .url)
    }

    var model: MatchingAttachment {
        .init(
            fileId: fileId,
            originalFileName: originalFileName,
            url: url
        )
    }
}

struct MatchingSavedAnswerDTO: Codable {
    let textValue: String?
    let selectedOptions: [MatchingSelectedOptionDTO]
    let files: [MatchingAttachmentDTO]

    enum CodingKeys: String, CodingKey {
        case textValue
        case selectedOptions
        case files
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        textValue = try values.decodeIfPresent(String.self, forKey: .textValue)
        selectedOptions = try values.decode([MatchingSelectedOptionDTO].self, forKey: .selectedOptions)
        files = try values.decode([MatchingAttachmentDTO].self, forKey: .files)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(textValue, forKey: .textValue)
        try values.encode(selectedOptions, forKey: .selectedOptions)
        try values.encode(files, forKey: .files)
    }

    var model: MatchingSavedAnswer {
        .init(
            textValue: textValue,
            selectedOptions: selectedOptions.map(\.model),
            files: files.map(\.model)
        )
    }
}

struct MatchingQuestionDTO: Codable {
    let questionId: String
    let type: String
    let title: String
    let description: String?
    let isRequired: Bool
    let options: [MatchingFormOptionDTO]
    let answer: MatchingSavedAnswerDTO?

    enum CodingKeys: String, CodingKey {
        case questionId
        case type
        case title
        case description
        case isRequired
        case options
        case answer
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        questionId = try values.decodeFlexibleString(forKey: .questionId)
        type = try values.decode(String.self, forKey: .type)
        title = try values.decode(String.self, forKey: .title)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        isRequired = try values.decode(Bool.self, forKey: .isRequired)
        options = try values.decode([MatchingFormOptionDTO].self, forKey: .options)
        answer = try values.decodeIfPresent(MatchingSavedAnswerDTO.self, forKey: .answer)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(questionId, forKey: .questionId)
        try values.encode(type, forKey: .type)
        try values.encode(title, forKey: .title)
        try values.encodeIfPresent(description, forKey: .description)
        try values.encode(isRequired, forKey: .isRequired)
        try values.encode(options, forKey: .options)
        try values.encodeIfPresent(answer, forKey: .answer)
    }

    var model: MatchingQuestion {
        .init(
            questionId: questionId,
            type: type,
            title: title,
            description: description,
            isRequired: isRequired,
            options: options.map(\.model),
            answer: answer?.model
        )
    }
}

struct MatchingSectionDTO: Codable {
    let sectionId: String
    let type: String
    let title: String
    let description: String?
    let allowedParts: [String]?
    let questions: [MatchingQuestionDTO]

    enum CodingKeys: String, CodingKey {
        case sectionId
        case type
        case title
        case description
        case allowedParts
        case questions
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        sectionId = try values.decodeFlexibleString(forKey: .sectionId)
        type = try values.decode(String.self, forKey: .type)
        title = try values.decode(String.self, forKey: .title)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        allowedParts = try values.decodeIfPresent([String].self, forKey: .allowedParts)
        questions = try values.decode([MatchingQuestionDTO].self, forKey: .questions)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(sectionId, forKey: .sectionId)
        try values.encode(type, forKey: .type)
        try values.encode(title, forKey: .title)
        try values.encodeIfPresent(description, forKey: .description)
        try values.encodeIfPresent(allowedParts, forKey: .allowedParts)
        try values.encode(questions, forKey: .questions)
    }

    var model: MatchingSection {
        .init(
            sectionId: sectionId,
            type: type,
            title: title,
            description: description,
            allowedParts: allowedParts,
            questions: questions.map(\.model)
        )
    }
}

struct MatchingFormDTO: Codable {
    let title: String?
    let description: String?
    let sections: [MatchingSectionDTO]

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case sections
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decodeIfPresent(String.self, forKey: .title)
        description = try values.decodeIfPresent(String.self, forKey: .description)
        sections = try values.decode([MatchingSectionDTO].self, forKey: .sections)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(title, forKey: .title)
        try values.encodeIfPresent(description, forKey: .description)
        try values.encode(sections, forKey: .sections)
    }

    var model: MatchingForm {
        .init(
            title: title,
            description: description,
            sections: sections.map(\.model)
        )
    }
}

struct MatchingResponseFormDTO: Codable {
    let sections: [MatchingSectionDTO]

    let lastSavedAt: String?

    enum CodingKeys: String, CodingKey {
        case lastSavedAt
        case sections
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        lastSavedAt = try values.decodeIfPresent(String.self, forKey: .lastSavedAt)
        sections = try values.decode([MatchingSectionDTO].self, forKey: .sections)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(lastSavedAt, forKey: .lastSavedAt)
        try values.encode(sections, forKey: .sections)
    }

    var model: MatchingResponseForm {
        .init(
            sections: sections.map(\.model),
            lastSavedAt: lastSavedAt
        )
    }
}

struct MatchingApplicationDetailDTO: Codable {
    let applicationId: String
    let status: String?
    let formResponse: MatchingResponseFormDTO?

    let submittedAt: String?

    enum CodingKeys: String, CodingKey {
        case submittedAt
        case applicationId
        case status
        case formResponse
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        submittedAt = try values.decodeIfPresent(String.self, forKey: .submittedAt)
        applicationId = try values.decodeFlexibleString(forKey: .applicationId)
        status = try values.decodeIfPresent(String.self, forKey: .status)
        formResponse = try values.decodeIfPresent(MatchingResponseFormDTO.self, forKey: .formResponse)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(submittedAt, forKey: .submittedAt)
        try values.encode(applicationId, forKey: .applicationId)
        try values.encodeIfPresent(status, forKey: .status)
        try values.encodeIfPresent(formResponse, forKey: .formResponse)
    }

    var model: MatchingApplicationDetail {
        .init(
            applicationId: applicationId,
            status: status,
            formResponse: formResponse?.model,
            submittedAt: submittedAt
        )
    }
}

struct MatchingGisuDTO: Codable {
    let gisuId: String

    enum CodingKeys: String, CodingKey {
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

struct MatchingApplicationStatusDTO: Codable {
    let applicationId: String

    enum CodingKeys: String, CodingKey {
        case applicationId
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        applicationId = try values.decodeFlexibleString(forKey: .applicationId)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(applicationId, forKey: .applicationId)
    }

}

struct MatchingApplicationCapabilitiesDTO: Codable {
    let canCreate: MatchingCapabilityDTO

    enum CodingKeys: String, CodingKey {
        case canCreate
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        canCreate = try values.decode(MatchingCapabilityDTO.self, forKey: .canCreate)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(canCreate, forKey: .canCreate)
    }

}

struct MatchingProjectAccessDTO: Codable {
    let projectId: String
    let exists: Bool
    let application: MatchingApplicationCapabilitiesDTO

    enum CodingKeys: String, CodingKey {
        case projectId
        case exists
        case application
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        projectId = try values.decodeFlexibleString(forKey: .projectId)
        exists = try values.decode(Bool.self, forKey: .exists)
        application = try values.decode(MatchingApplicationCapabilitiesDTO.self, forKey: .application)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(projectId, forKey: .projectId)
        try values.encode(exists, forKey: .exists)
        try values.encode(application, forKey: .application)
    }

}

struct MatchingAccessListDTO: Codable {
    let projects: [MatchingProjectAccessDTO]

    enum CodingKeys: String, CodingKey {
        case projects
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        projects = try values.decode([MatchingProjectAccessDTO].self, forKey: .projects)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(projects, forKey: .projects)
    }

}

struct MatchingSchoolDTO: Codable {
    let schoolId: String
    let schoolName: String

    enum CodingKeys: String, CodingKey {
        case schoolId
        case schoolName
    }

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

struct MatchingChapterDTO: Codable {
    let chapterId: String
    let chapterName: String

    enum CodingKeys: String, CodingKey {
        case chapterId
        case chapterName
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        chapterId = try values.decodeFlexibleString(forKey: .chapterId)
        chapterName = try values.decode(String.self, forKey: .chapterName)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(chapterId, forKey: .chapterId)
        try values.encode(chapterName, forKey: .chapterName)
    }

}

struct MatchingGisuOrganizationDTO: Codable {
    let gisuId: String
    let schools: [MatchingSchoolDTO]
    let chapters: [MatchingChapterDTO]

    enum CodingKeys: String, CodingKey {
        case gisuId
        case schools
        case chapters
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        gisuId = try values.decodeFlexibleString(forKey: .gisuId)
        schools = try values.decode([MatchingSchoolDTO].self, forKey: .schools)
        chapters = try values.decode([MatchingChapterDTO].self, forKey: .chapters)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(gisuId, forKey: .gisuId)
        try values.encode(schools, forKey: .schools)
        try values.encode(chapters, forKey: .chapters)
    }

}

struct MatchingOrganizationsDTO: Codable {
    let gisus: [MatchingGisuOrganizationDTO]

    enum CodingKeys: String, CodingKey {
        case gisus
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        gisus = try values.decode([MatchingGisuOrganizationDTO].self, forKey: .gisus)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(gisus, forKey: .gisus)
    }

}

struct MatchingUploadDTO: Codable {
    let fileId: String
    let uploadUrl: String
    let uploadMethod: String
    let headers: [String:String]

    enum CodingKeys: String, CodingKey {
        case fileId
        case uploadUrl
        case uploadMethod
        case headers
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        fileId = try values.decode(String.self, forKey: .fileId)
        uploadUrl = try values.decode(String.self, forKey: .uploadUrl)
        uploadMethod = try values.decode(String.self, forKey: .uploadMethod)
        headers = try values.decode([String:String].self, forKey: .headers)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(fileId, forKey: .fileId)
        try values.encode(uploadUrl, forKey: .uploadUrl)
        try values.encode(uploadMethod, forKey: .uploadMethod)
        try values.encode(headers, forKey: .headers)
    }

}

struct MatchingAffiliationDTO: Codable {
    struct Chapter: Codable {
        let id: String
        enum CodingKeys: CodingKey { case id }

        init(from decoder: Decoder) throws {
            let values = try decoder.container(keyedBy: CodingKeys.self)
            id = try values.decodeFlexibleString(forKey: .id)
        }

        func encode(to encoder: Encoder) throws {
            var values = encoder.container(keyedBy: CodingKeys.self)
            try values.encode(id, forKey: .id)
        }
    }

    let gisuId: String
    let matchingChapter: Chapter?
    enum CodingKeys: CodingKey { case gisuId, matchingChapter }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        gisuId = try values.decodeFlexibleString(forKey: .gisuId)
        matchingChapter = try values.decodeIfPresent(Chapter.self, forKey: .matchingChapter)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(gisuId, forKey: .gisuId)
        try values.encodeIfPresent(matchingChapter, forKey: .matchingChapter)
    }
}
