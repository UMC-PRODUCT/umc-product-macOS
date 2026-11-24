//
//  MatchingOperationsModels.swift
//  MatchingDomain
//
//  Created by euijjang97 on 11/22/26.
//

public struct OperationsPerson: Sendable, Equatable {
    public let memberId: String
    public let nickname: String?
    public let name: String?
    public let schoolName: String?
    public let part: String?
    public let matchedRoundInfo: OperationsRound?

    public init(
        memberId: String,
        nickname: String?,
        name: String?,
        schoolName: String?,
        part: String?,
        matchedRoundInfo: OperationsRound? = nil
    ) {
        self.memberId = memberId
        self.nickname = nickname
        self.name = name
        self.schoolName = schoolName
        self.part = part
        self.matchedRoundInfo = matchedRoundInfo
    }
}

public struct ManagedProject: Sendable, Equatable {
    public let id: String
    public let name: String?
    public let status: String
    public let productOwner: OperationsPerson?

    public init(
        id: String,
        name: String?,
        status: String,
        productOwner: OperationsPerson?
    ) {
        self.id = id
        self.name = name
        self.status = status
        self.productOwner = productOwner
    }
}

public struct ApplicantRow: Sendable, Equatable {
    public let applicationId: String
    public let applicant: OperationsPerson
    public let status: String
    public let matchingRound: OperationsRound?
    public let submittedAt: String?

    public init(
        applicationId: String,
        applicant: OperationsPerson,
        status: String,
        matchingRound: OperationsRound?,
        submittedAt: String?
    ) {
        self.applicationId = applicationId
        self.applicant = applicant
        self.status = status
        self.matchingRound = matchingRound
        self.submittedAt = submittedAt
    }
}

public struct OperationsRound: Sendable, Equatable {
    public let id: String?
    public let phase: String?
    public let type: String?

    public init(
        id: String?,
        phase: String?,
        type: String?
    ) {
        self.id = id
        self.phase = phase
        self.type = type
    }
}

public struct RosterGroup: Sendable, Equatable {
    public let part: String
    public let members: [OperationsPerson]

    public init(
        part: String,
        members: [OperationsPerson]
    ) {
        self.part = part
        self.members = members
    }
}

public struct OperationsTeam: Sendable, Equatable {
    public let productOwner: OperationsPerson?
    public let coProductOwners: [OperationsPerson]
    public let partGroups: [RosterGroup]

    public init(
        productOwner: OperationsPerson?,
        coProductOwners: [OperationsPerson],
        partGroups: [RosterGroup]
    ) {
        self.productOwner = productOwner
        self.coProductOwners = coProductOwners
        self.partGroups = partGroups
    }
}

public struct OverviewPart: Sendable, Equatable {
    public let part: String
    public let currentMemberCount: String
    public let quota: String
    public let members: [OperationsPerson]

    public init(
        part: String,
        currentMemberCount: String,
        quota: String,
        members: [OperationsPerson]
    ) {
        self.part = part
        self.currentMemberCount = currentMemberCount
        self.quota = quota
        self.members = members
    }
}

public struct OverviewProject: Sendable, Equatable {
    public let projectId: String
    public let projectName: String
    public let currentMemberCount: String
    public let quota: String
    public let partQuotaStatus: String?
    public let productOwner: OperationsPerson?
    public let coProductOwners: [OperationsPerson]
    public let parts: [OverviewPart]

    public init(
        projectId: String,
        projectName: String,
        currentMemberCount: String,
        quota: String,
        partQuotaStatus: String?,
        productOwner: OperationsPerson?,
        coProductOwners: [OperationsPerson],
        parts: [OverviewPart]
    ) {
        self.projectId = projectId
        self.projectName = projectName
        self.currentMemberCount = currentMemberCount
        self.quota = quota
        self.partQuotaStatus = partQuotaStatus
        self.productOwner = productOwner
        self.coProductOwners = coProductOwners
        self.parts = parts
    }
}

public struct MatchingSchoolCount: Sendable, Equatable {
    public let schoolId: String
    public let schoolName: String
    public let matchedMemberCount: String
    public let totalMemberCount: String

    public init(
        schoolId: String,
        schoolName: String,
        matchedMemberCount: String,
        totalMemberCount: String
    ) {
        self.schoolId = schoolId
        self.schoolName = schoolName
        self.matchedMemberCount = matchedMemberCount
        self.totalMemberCount = totalMemberCount
    }
}

public struct MatchingPhaseCount: Sendable, Equatable {
    public let phase: String
    public let matchedMemberCount: String
    public let availableMemberCount: String

    public init(
        phase: String,
        matchedMemberCount: String,
        availableMemberCount: String
    ) {
        self.phase = phase
        self.matchedMemberCount = matchedMemberCount
        self.availableMemberCount = availableMemberCount
    }
}

public struct PartMatchingCount: Sendable, Equatable {
    public let part: String
    public let matchedMemberCount: String
    public let quota: String

    public init(
        part: String,
        matchedMemberCount: String,
        quota: String
    ) {
        self.part = part
        self.matchedMemberCount = matchedMemberCount
        self.quota = quota
    }
}

public struct PhaseMatchedCount: Sendable, Equatable {
    public let phase: String
    public let matchedMemberCount: String

    public init(
        phase: String,
        matchedMemberCount: String
    ) {
        self.phase = phase
        self.matchedMemberCount = matchedMemberCount
    }
}

public struct ProjectMatchingCount: Sendable, Equatable {
    public let projectId: String
    public let projectName: String
    public let matchedMemberCount: String
    public let quota: String
    public let rounds: [PhaseMatchedCount]
    public let parts: [PartMatchingCount]

    public init(
        projectId: String,
        projectName: String,
        matchedMemberCount: String,
        quota: String,
        rounds: [PhaseMatchedCount],
        parts: [PartMatchingCount]
    ) {
        self.projectId = projectId
        self.projectName = projectName
        self.matchedMemberCount = matchedMemberCount
        self.quota = quota
        self.rounds = rounds
        self.parts = parts
    }
}

public struct PublicMatchingStatistics: Sendable, Equatable {
    public let roundMatchingStatistics: [MatchingPhaseCount]
    public let schoolMatchingStatistics: [MatchingSchoolCount]
    public let projectMatchingStatistics: [ProjectMatchingCount]

    public init(
        roundMatchingStatistics: [MatchingPhaseCount],
        schoolMatchingStatistics: [MatchingSchoolCount],
        projectMatchingStatistics: [ProjectMatchingCount] = []
    ) {
        self.roundMatchingStatistics = roundMatchingStatistics
        self.schoolMatchingStatistics = schoolMatchingStatistics
        self.projectMatchingStatistics = projectMatchingStatistics
    }
}

public struct ApplicationPhaseCount: Sendable, Equatable {
    public let phase: String
    public let applicantCount: String

    public init(
        phase: String,
        applicantCount: String
    ) {
        self.phase = phase
        self.applicantCount = applicantCount
    }
}

public struct ApplicationSchoolCount: Sendable, Equatable {
    public let schoolId: String
    public let schoolName: String
    public let totalMemberCount: String
    public let rounds: [ApplicationPhaseCount]

    public init(
        schoolId: String,
        schoolName: String,
        totalMemberCount: String,
        rounds: [ApplicationPhaseCount]
    ) {
        self.schoolId = schoolId
        self.schoolName = schoolName
        self.totalMemberCount = totalMemberCount
        self.rounds = rounds
    }
}

public struct ApplicationProjectCount: Sendable, Equatable {
    public let projectId: String
    public let projectName: String
    public let rounds: [ApplicationPhaseCount]

    public init(
        projectId: String,
        projectName: String,
        rounds: [ApplicationPhaseCount]
    ) {
        self.projectId = projectId
        self.projectName = projectName
        self.rounds = rounds
    }
}

public struct OperationsStatistics: Sendable, Equatable {
    public let matchingType: String?
    public let schoolApplicationStatistics: [ApplicationSchoolCount]
    public let projectRoundStatistics: [ApplicationProjectCount]

    public init(
        schoolApplicationStatistics: [ApplicationSchoolCount],
        projectRoundStatistics: [ApplicationProjectCount],
        matchingType: String? = nil
    ) {
        self.matchingType = matchingType
        self.schoolApplicationStatistics = schoolApplicationStatistics
        self.projectRoundStatistics = projectRoundStatistics
    }
}

public struct EditableOption: Sendable, Equatable {
    public var optionId: String?
    public var content: String
    public var orderNo: String
    public var isOther: Bool

    public init(
        optionId: String?,
        content: String,
        orderNo: String,
        isOther: Bool
    ) {
        self.optionId = optionId
        self.content = content
        self.orderNo = orderNo
        self.isOther = isOther
    }
}

public struct EditableQuestion: Sendable, Equatable {
    public var questionId: String?
    public var type: String
    public var title: String
    public var description: String?
    public var isRequired: Bool
    public var orderNo: String
    public var options: [EditableOption]

    public init(
        questionId: String?,
        type: String,
        title: String,
        description: String?,
        isRequired: Bool,
        orderNo: String,
        options: [EditableOption]
    ) {
        self.questionId = questionId
        self.type = type
        self.title = title
        self.description = description
        self.isRequired = isRequired
        self.orderNo = orderNo
        self.options = options
    }
}

public struct EditableSection: Sendable, Equatable {
    public var sectionId: String?
    public var type: String
    public var allowedParts: [String]?
    public var title: String
    public var description: String?
    public var orderNo: String
    public var questions: [EditableQuestion]

    public init(
        sectionId: String?,
        type: String,
        allowedParts: [String]?,
        title: String,
        description: String?,
        orderNo: String,
        questions: [EditableQuestion]
    ) {
        self.sectionId = sectionId
        self.type = type
        self.allowedParts = allowedParts
        self.title = title
        self.description = description
        self.orderNo = orderNo
        self.questions = questions
    }
}

public struct EditableMatchingForm: Sendable, Equatable {
    public var title: String?
    public var description: String?
    public var sections: [EditableSection]

    public init(
        title: String?,
        description: String?,
        sections: [EditableSection]
    ) {
        self.title = title
        self.description = description
        self.sections = sections
    }
}

/// 서버 MatchingType.fromPart와 같은 범위로 명단의 표시 파트를 선택한다.
public enum MatchingRosterType: String, CaseIterable, Sendable {
    case all
    case design = "PLAN_DESIGN"
    case developer = "PLAN_DEVELOPER"

    public func includes(part: String) -> Bool {
        switch self {
        case .all: true
        case .design: part == "DESIGN"
        case .developer:
            ["WEB", "ANDROID", "IOS", "NODEJS", "SPRINGBOOT",
             "WEB_PRODUCT_ENGINEER", "MOBILE_PRODUCT_ENGINEER"].contains(part)
        }
    }
}
