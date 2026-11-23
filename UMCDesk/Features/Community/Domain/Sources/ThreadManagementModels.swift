//
//  ThreadManagementModels.swift
//  CommunityDomain
//
//  Created by euijjang97 on 11/23/26.
//

import Foundation

public enum ThreadManagementRole: String, Codable, Sendable {
    case owner = "OWNER"
    case admin = "ADMIN"
    case member = "MEMBER"
}

public struct ThreadManagementDetail: Sendable {
    public let title: String
    public let description: String?
    public let icon: String
    public let category: String
    public let myRole: ThreadManagementRole?
    public let membershipState: String?
    public let memberCount: String
    public let maxMembers: String

    public init(
        title: String,
        description: String?,
        icon: String,
        category: String,
        myRole: ThreadManagementRole?,
        membershipState: String?,
        memberCount: String,
        maxMembers: String
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.category = category
        self.myRole = myRole
        self.membershipState = membershipState
        self.memberCount = memberCount
        self.maxMembers = maxMembers
    }
}

public struct ThreadManagementPerson: Sendable {
    public let memberId: String
    public let name: String
    public let part: String?
    public let generation: String?
    public let role: ThreadManagementRole?
    public let state: String?

    public init(
        memberId: String,
        name: String,
        part: String?,
        generation: String?,
        role: ThreadManagementRole?,
        state: String?
    ) {
        self.memberId = memberId
        self.name = name
        self.part = part
        self.generation = generation
        self.role = role
        self.state = state
    }
}

public struct ThreadManagementPage: Sendable {
    public let items: [ThreadManagementPerson]
    public let nextOffset: String?
    public let total: String

    public init(
        items: [ThreadManagementPerson],
        nextOffset: String?,
        total: String
    ) {
        self.items = items
        self.nextOffset = nextOffset
        self.total = total
    }
}

public struct ThreadManagementRecord: Sendable {
    public let gisu: String?
    public let part: String?

    public init(
        gisu: String?,
        part: String?
    ) {
        self.gisu = gisu
        self.part = part
    }
}

public struct ThreadManagementLinks: Sendable {
    public let linkedIn: String?
    public let instagram: String?
    public let github: String?
    public let blog: String?
    public let personal: String?

    public init(
        linkedIn: String?,
        instagram: String?,
        github: String?,
        blog: String?,
        personal: String?
    ) {
        self.linkedIn = linkedIn
        self.instagram = instagram
        self.github = github
        self.blog = blog
        self.personal = personal
    }
}

public struct ThreadManagementProfile: Sendable {
    public let name: String
    public let nickname: String?
    public let schoolName: String?
    public let profileImageLink: String?
    public let profile: ThreadManagementLinks?
    public let challengerRecords: [ThreadManagementRecord]

    public init(
        name: String,
        nickname: String?,
        schoolName: String?,
        profileImageLink: String?,
        profile: ThreadManagementLinks?,
        challengerRecords: [ThreadManagementRecord]
    ) {
        self.name = name
        self.nickname = nickname
        self.schoolName = schoolName
        self.profileImageLink = profileImageLink
        self.profile = profile
        self.challengerRecords = challengerRecords
    }
}

public enum ThreadManagementAction: Sendable {
    case invite([String])
    case role(memberID: String, ThreadManagementRole)
    case kick(memberID: String)
    case edit(title: String?, description: String?)
    case leave
    case delete
    case acknowledgeKick
}

public enum ThreadReportTarget: Sendable {
    case message(String)
    case member(String)

    public var identifier: String {
        switch self {
        case .message(let id), .member(let id): id
        }
    }

    public var isMember: Bool {
        if case .member = self { return true }
        return false
    }

    public var reasons: [ThreadReportReason] {
        isMember ? [.harassment, .impersonation, .spam, .other]
            : [.spam, .abuse, .inappropriate, .privacy, .other]
    }
}

public enum ThreadReportReason: String, Sendable, Encodable {
    case spam = "SPAM"
    case abuse = "ABUSE"
    case inappropriate = "INAPPROPRIATE"
    case privacy = "PRIVACY"
    case harassment = "HARASSMENT"
    case impersonation = "IMPERSONATION"
    case other = "ETC"
}

public protocol ThreadManagementRepository: Sendable {
    func detail(threadID: String) async throws -> ThreadManagementDetail
    func people(threadID: String, invitable: Bool, query: String, offset: String?)
        async throws -> ThreadManagementPage
    func profile(memberID: String) async throws -> ThreadManagementProfile
    func report(_ target: ThreadReportTarget, reasons: [ThreadReportReason], detail: String)
        async throws -> String
    func isBlocked(memberID: String) async throws -> Bool
    func setBlocked(_ blocked: Bool, memberID: String) async throws
    func currentMemberID() async throws -> String
    func apply(_ action: ThreadManagementAction, threadID: String) async throws
}
