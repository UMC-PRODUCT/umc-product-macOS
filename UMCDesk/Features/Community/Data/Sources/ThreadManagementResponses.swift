//
//  ThreadManagementResponses.swift
//  CommunityData
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import Foundation
import UMCFoundation

struct ThreadManagementDetailResponse: Codable {
    let model: ThreadManagementDetail

    private enum CodingKeys: CodingKey {
        case title
        case description
        case icon
        case category
        case myRole
        case membershipState
        case memberCount
        case maxMembers
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        model = try .init(
            title: values.decode(String.self, forKey: .title),
            description: values.decodeIfPresent(String.self, forKey: .description),
            icon: values.decode(String.self, forKey: .icon),
            category: values.decode(String.self, forKey: .category),
            myRole: values.decodeIfPresent(ThreadManagementRole.self, forKey: .myRole),
            membershipState: values.decodeIfPresent(String.self, forKey: .membershipState),
            memberCount: values.decodeFlexibleString(forKey: .memberCount),
            maxMembers: values.decodeFlexibleString(forKey: .maxMembers)
        )
    }

    init(model: ThreadManagementDetail) { self.model = model }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(model.title, forKey: .title)
        try values.encodeIfPresent(model.description, forKey: .description)
        try values.encode(model.icon, forKey: .icon)
        try values.encode(model.category, forKey: .category)
        try values.encodeIfPresent(model.myRole, forKey: .myRole)
        try values.encodeIfPresent(model.membershipState, forKey: .membershipState)
        try values.encode(model.memberCount, forKey: .memberCount)
        try values.encode(model.maxMembers, forKey: .maxMembers)
    }
}

struct ThreadManagementPersonResponse: Codable {
    let model: ThreadManagementPerson

    private enum CodingKeys: CodingKey {
        case memberId
        case name
        case part
        case generation
        case role
        case state
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        model = try .init(
            memberId: values.decodeFlexibleString(forKey: .memberId),
            name: values.decode(String.self, forKey: .name),
            part: values.decodeIfPresent(String.self, forKey: .part),
            generation: values.decodeFlexibleStringIfPresent(forKey: .generation),
            role: values.decodeIfPresent(ThreadManagementRole.self, forKey: .role),
            state: values.decodeIfPresent(String.self, forKey: .state)
        )
    }

    init(model: ThreadManagementPerson) { self.model = model }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(model.memberId, forKey: .memberId)
        try values.encode(model.name, forKey: .name)
        try values.encodeIfPresent(model.part, forKey: .part)
        try values.encodeIfPresent(model.generation, forKey: .generation)
        try values.encodeIfPresent(model.role, forKey: .role)
        try values.encodeIfPresent(model.state, forKey: .state)
    }
}

struct ThreadManagementPageResponse: Codable {
    let model: ThreadManagementPage

    private enum CodingKeys: CodingKey {
        case items
        case nextOffset
        case total
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        model = try .init(
            items: values.decode([ThreadManagementPersonResponse].self, forKey: .items)
                .map(\.model),
            nextOffset: values.decodeFlexibleStringIfPresent(forKey: .nextOffset),
            total: values.decodeFlexibleString(forKey: .total)
        )
    }

    init(model: ThreadManagementPage) { self.model = model }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(model.items.map(ThreadManagementPersonResponse.init(model:)),
                          forKey: .items)
        try values.encodeIfPresent(model.nextOffset, forKey: .nextOffset)
        try values.encode(model.total, forKey: .total)
    }
}

struct ThreadManagementRecordResponse: Codable {
    let model: ThreadManagementRecord

    private enum CodingKeys: CodingKey {
        case gisu
        case part
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        model = try .init(
            gisu: values.decodeFlexibleStringIfPresent(forKey: .gisu),
            part: values.decodeIfPresent(String.self, forKey: .part)
        )
    }

    init(model: ThreadManagementRecord) { self.model = model }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(model.gisu, forKey: .gisu)
        try values.encodeIfPresent(model.part, forKey: .part)
    }
}

struct ThreadManagementLinksResponse: Codable {
    let model: ThreadManagementLinks

    private enum CodingKeys: CodingKey {
        case linkedIn
        case instagram
        case github
        case blog
        case personal
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        model = try .init(
            linkedIn: values.decodeIfPresent(String.self, forKey: .linkedIn),
            instagram: values.decodeIfPresent(String.self, forKey: .instagram),
            github: values.decodeIfPresent(String.self, forKey: .github),
            blog: values.decodeIfPresent(String.self, forKey: .blog),
            personal: values.decodeIfPresent(String.self, forKey: .personal)
        )
    }

    init(model: ThreadManagementLinks) { self.model = model }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(model.linkedIn, forKey: .linkedIn)
        try values.encodeIfPresent(model.instagram, forKey: .instagram)
        try values.encodeIfPresent(model.github, forKey: .github)
        try values.encodeIfPresent(model.blog, forKey: .blog)
        try values.encodeIfPresent(model.personal, forKey: .personal)
    }
}

struct ThreadManagementProfileResponse: Codable {
    let model: ThreadManagementProfile

    private enum CodingKeys: CodingKey {
        case name
        case nickname
        case schoolName
        case profileImageLink
        case profile
        case challengerRecords
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        model = try .init(
            name: values.decode(String.self, forKey: .name),
            nickname: values.decodeIfPresent(String.self, forKey: .nickname),
            schoolName: values.decodeIfPresent(String.self, forKey: .schoolName),
            profileImageLink: values.decodeIfPresent(String.self, forKey: .profileImageLink),
            profile: values.decodeIfPresent(ThreadManagementLinksResponse.self,
                forKey: .profile)?.model,
            challengerRecords: values.decode([ThreadManagementRecordResponse].self,
                forKey: .challengerRecords).map(\.model)
        )
    }

    init(model: ThreadManagementProfile) { self.model = model }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(model.name, forKey: .name)
        try values.encodeIfPresent(model.nickname, forKey: .nickname)
        try values.encodeIfPresent(model.schoolName, forKey: .schoolName)
        try values.encodeIfPresent(model.profileImageLink, forKey: .profileImageLink)
        try values.encodeIfPresent(model.profile.map(ThreadManagementLinksResponse.init(model:)),
                          forKey: .profile)
        try values.encode(model.challengerRecords.map(ThreadManagementRecordResponse.init(model:)),
                          forKey: .challengerRecords)
    }
}
