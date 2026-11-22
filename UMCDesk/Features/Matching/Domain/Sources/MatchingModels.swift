//
//  MatchingModels.swift
//  MatchingDomain
//
//  Created by euijjang97 on 11/22/26.
//

public struct MatchingMember: Equatable, Sendable {
    public let memberId: String
    public let nickname: String?
    public let name: String?
    public let schoolName: String?

    public init(
        memberId: String,
        nickname: String?,
        name: String?,
        schoolName: String?
    ) {
        self.memberId = memberId
        self.nickname = nickname
        self.name = name
        self.schoolName = schoolName
    }
}

public struct MatchingQuota: Equatable, Sendable {
    public let part: String
    public let currentCount: String
    public let quota: String
    public let status: String

    public init(
        part: String,
        currentCount: String,
        quota: String,
        status: String
    ) {
        self.part = part
        self.currentCount = currentCount
        self.quota = quota
        self.status = status
    }
}

public struct MatchingProject: Equatable, Sendable {
    public let id: String
    public let name: String
    public let description: String?
    public let thumbnailImageUrl: String?
    public let productOwner: MatchingMember?
    public let partQuotas: [MatchingQuota]
    public let partQuotaStatus: String?
    public let logoImageUrl: String?
    public let externalLink: String?
    public let applicationFormId: String?

    public init(
        id: String,
        name: String,
        description: String?,
        thumbnailImageUrl: String?,
        productOwner: MatchingMember?,
        partQuotas: [MatchingQuota],
        partQuotaStatus: String?,
        logoImageUrl: String?,
        externalLink: String?,
        applicationFormId: String?
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.thumbnailImageUrl = thumbnailImageUrl
        self.productOwner = productOwner
        self.partQuotas = partQuotas
        self.partQuotaStatus = partQuotaStatus
        self.logoImageUrl = logoImageUrl
        self.externalLink = externalLink
        self.applicationFormId = applicationFormId
    }
}

public struct MatchingProjectPage: Equatable, Sendable {
    public let content: [MatchingProject]
    public let hasNext: Bool

    public let totalElements: String?

    public init(
        content: [MatchingProject],
        hasNext: Bool, totalElements: String? = nil
    ) {
        self.totalElements = totalElements
        self.content = content
        self.hasNext = hasNext
    }
}

public struct MatchingCapability: Equatable, Sendable {
    public let allowed: Bool
    public let reasonCode: String?
    public let reason: String?

    public init(
        allowed: Bool,
        reasonCode: String?,
        reason: String?
    ) {
        self.allowed = allowed
        self.reasonCode = reasonCode
        self.reason = reason
    }
}

public struct MatchingRound: Equatable, Sendable {
    public let id: String
    public let name: String
    public let type: String
    public let phase: String
    public let chapterId: String
    public let startsAt: String
    public let endsAt: String
    public let decisionDeadline: String?
    public let resultPublishAt: String?

    public let description: String?
    public let autoDecisionExecutedAt: String?

    public init(
        id: String,
        name: String,
        type: String,
        phase: String,
        chapterId: String,
        startsAt: String,
        endsAt: String,
        decisionDeadline: String?,
        resultPublishAt: String?,
        description: String? = nil,
        autoDecisionExecutedAt: String? = nil
    ) {
        self.description = description
        self.autoDecisionExecutedAt = autoDecisionExecutedAt
        self.id = id
        self.name = name
        self.type = type
        self.phase = phase
        self.chapterId = chapterId
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.decisionDeadline = decisionDeadline
        self.resultPublishAt = resultPublishAt
    }
}

public struct MatchingRoundBrief: Equatable, Sendable {
    public let id: String?
    public let type: String?
    public let phase: String?

    public init(
        id: String?,
        type: String?,
        phase: String?
    ) {
        self.id = id
        self.type = type
        self.phase = phase
    }
}

public struct MatchingApplicationProject: Equatable, Sendable {
    public let name: String
    public let thumbnailImageUrl: String?
    public let productOwner: MatchingMember?
    public let partQuotas: [MatchingQuota]

    public init(
        name: String,
        thumbnailImageUrl: String?,
        productOwner: MatchingMember?,
        partQuotas: [MatchingQuota]
    ) {
        self.name = name
        self.thumbnailImageUrl = thumbnailImageUrl
        self.productOwner = productOwner
        self.partQuotas = partQuotas
    }
}

public struct MatchingApplication: Equatable, Sendable {
    public let applicationId: String?
    public let projectId: String
    public let project: MatchingApplicationProject?
    public let matchingRound: MatchingRoundBrief?
    public let status: String?

    public init(
        applicationId: String?,
        projectId: String,
        project: MatchingApplicationProject?,
        matchingRound: MatchingRoundBrief?,
        status: String?
    ) {
        self.applicationId = applicationId
        self.projectId = projectId
        self.project = project
        self.matchingRound = matchingRound
        self.status = status
    }
}

public struct MatchingFormOption: Equatable, Sendable {
    public let optionId: String
    public let content: String

    public init(
        optionId: String,
        content: String
    ) {
        self.optionId = optionId
        self.content = content
    }
}

public struct MatchingSelectedOption: Equatable, Sendable {
    public let questionOptionId: String?
    public let answeredAsContent: String?

    public init(
        questionOptionId: String?,
        answeredAsContent: String?
    ) {
        self.questionOptionId = questionOptionId
        self.answeredAsContent = answeredAsContent
    }
}

public struct MatchingAttachment: Equatable, Sendable {
    public let fileId: String
    public let originalFileName: String?
    public let url: String?

    public init(
        fileId: String,
        originalFileName: String?,
        url: String?
    ) {
        self.fileId = fileId
        self.originalFileName = originalFileName
        self.url = url
    }
}

public struct MatchingSavedAnswer: Equatable, Sendable {
    public let textValue: String?
    public let selectedOptions: [MatchingSelectedOption]
    public let files: [MatchingAttachment]

    public init(
        textValue: String?,
        selectedOptions: [MatchingSelectedOption],
        files: [MatchingAttachment]
    ) {
        self.textValue = textValue
        self.selectedOptions = selectedOptions
        self.files = files
    }
}

public struct MatchingQuestion: Equatable, Sendable {
    public let questionId: String
    public let type: String
    public let title: String
    public let description: String?
    public let isRequired: Bool
    public let options: [MatchingFormOption]
    public let answer: MatchingSavedAnswer?

    public init(
        questionId: String,
        type: String,
        title: String,
        description: String?,
        isRequired: Bool,
        options: [MatchingFormOption],
        answer: MatchingSavedAnswer?
    ) {
        self.questionId = questionId
        self.type = type
        self.title = title
        self.description = description
        self.isRequired = isRequired
        self.options = options
        self.answer = answer
    }
}

public struct MatchingSection: Equatable, Sendable {
    public let sectionId: String
    public let type: String
    public let title: String
    public let description: String?
    public let allowedParts: [String]?
    public let questions: [MatchingQuestion]

    public init(
        sectionId: String,
        type: String,
        title: String,
        description: String?,
        allowedParts: [String]?,
        questions: [MatchingQuestion]
    ) {
        self.sectionId = sectionId
        self.type = type
        self.title = title
        self.description = description
        self.allowedParts = allowedParts
        self.questions = questions
    }
}

public struct MatchingForm: Equatable, Sendable {
    public let title: String?
    public let description: String?
    public let sections: [MatchingSection]

    public init(
        title: String?,
        description: String?,
        sections: [MatchingSection]
    ) {
        self.title = title
        self.description = description
        self.sections = sections
    }
}

public struct MatchingResponseForm: Equatable, Sendable {
    public let sections: [MatchingSection]

    public let lastSavedAt: String?

    public init(
        sections: [MatchingSection],
        lastSavedAt: String? = nil
    ) {
        self.lastSavedAt = lastSavedAt
        self.sections = sections
    }
}

public struct MatchingApplicationDetail: Equatable, Sendable {
    public let applicationId: String
    public let status: String?
    public let formResponse: MatchingResponseForm?

    public let submittedAt: String?

    public init(
        applicationId: String,
        status: String?,
        formResponse: MatchingResponseForm?,
        submittedAt: String? = nil
    ) {
        self.submittedAt = submittedAt
        self.applicationId = applicationId
        self.status = status
        self.formResponse = formResponse
    }
}
