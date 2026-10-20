//
//  SettingsDTO.swift
//  SettingsData
//
//  Created by euijjang97 on 10/20/26.
//

import Foundation
import SettingsDomain
import UMCFoundation

struct SettingsMemberResponse: Codable {
    let id: String
    let name: String
    let nickname: String
    let email: String?
    let schoolName: String?
    let profileImageLink: String?
    let profile: SettingsLinksResponse?
    let challengerRecords: [SettingsActivityResponse]?
    let roles: [SettingsRoleResponse]?

    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case nickname
        case email
        case schoolName
        case profileImageLink
        case profile
        case challengerRecords
        case roles
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeFlexibleString(forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        nickname = try container.decode(String.self, forKey: .nickname)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        schoolName = try container.decodeIfPresent(String.self, forKey: .schoolName)
        profileImageLink = try container.decodeIfPresent(String.self, forKey: .profileImageLink)
        profile = try container.decodeIfPresent(SettingsLinksResponse.self, forKey: .profile)
        challengerRecords = try container.decodeIfPresent(
            [SettingsActivityResponse].self, forKey: .challengerRecords
        )
        roles = try container.decodeIfPresent([SettingsRoleResponse].self, forKey: .roles)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(nickname, forKey: .nickname)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(schoolName, forKey: .schoolName)
        try container.encodeIfPresent(profileImageLink, forKey: .profileImageLink)
        try container.encodeIfPresent(profile, forKey: .profile)
        try container.encodeIfPresent(challengerRecords, forKey: .challengerRecords)
        try container.encodeIfPresent(roles, forKey: .roles)
    }
}

struct SettingsLinksResponse: Codable {
    let github: String?
    let linkedIn: String?
    let instagram: String?
    let blog: String?
    let personal: String?

    private enum CodingKeys: String, CodingKey {
        case github
        case linkedIn
        case instagram
        case blog
        case personal
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        github = try container.decodeIfPresent(String.self, forKey: .github)
        linkedIn = try container.decodeIfPresent(String.self, forKey: .linkedIn)
        instagram = try container.decodeIfPresent(String.self, forKey: .instagram)
        blog = try container.decodeIfPresent(String.self, forKey: .blog)
        personal = try container.decodeIfPresent(String.self, forKey: .personal)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(github, forKey: .github)
        try container.encodeIfPresent(linkedIn, forKey: .linkedIn)
        try container.encodeIfPresent(instagram, forKey: .instagram)
        try container.encodeIfPresent(blog, forKey: .blog)
        try container.encodeIfPresent(personal, forKey: .personal)
    }
}

struct SettingsActivityResponse: Codable {
    let challengerId: String?
    let gisuId: String?
    let gisu: String?
    let part: String?
    let roles: [SettingsRoleResponse]?

    private enum CodingKeys: String, CodingKey {
        case challengerId
        case gisuId
        case gisu
        case part
        case roles
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        challengerId = try container.decodeFlexibleStringIfPresent(forKey: .challengerId)
        gisuId = try container.decodeFlexibleStringIfPresent(forKey: .gisuId)
        gisu = try container.decodeFlexibleStringIfPresent(forKey: .gisu)
        part = try container.decodeIfPresent(String.self, forKey: .part)
        roles = try container.decodeIfPresent([SettingsRoleResponse].self, forKey: .roles)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(challengerId, forKey: .challengerId)
        try container.encodeIfPresent(gisuId, forKey: .gisuId)
        try container.encodeIfPresent(gisu, forKey: .gisu)
        try container.encodeIfPresent(part, forKey: .part)
        try container.encodeIfPresent(roles, forKey: .roles)
    }
}

struct SettingsRoleResponse: Codable {
    let challengerId: String?
    let gisuId: String?
    let gisu: String?
    let roleType: String?

    private enum CodingKeys: String, CodingKey {
        case challengerId
        case gisuId
        case gisu
        case roleType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        challengerId = try container.decodeFlexibleStringIfPresent(forKey: .challengerId)
        gisuId = try container.decodeFlexibleStringIfPresent(forKey: .gisuId)
        gisu = try container.decodeFlexibleStringIfPresent(forKey: .gisu)
        roleType = try container.decodeIfPresent(String.self, forKey: .roleType)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(challengerId, forKey: .challengerId)
        try container.encodeIfPresent(gisuId, forKey: .gisuId)
        try container.encodeIfPresent(gisu, forKey: .gisu)
        try container.encodeIfPresent(roleType, forKey: .roleType)
    }
}

extension SettingsMemberResponse {
    func toDomain() -> SettingsProfile {
        let activities = (challengerRecords ?? []).compactMap { activity -> SettingsActivity? in
            guard let identity = activity.challengerId ?? activity.gisuId else { return nil }
            let matchingRoles = (roles ?? []).filter { role in
                if let challenger = role.challengerId {
                    return challenger == activity.challengerId
                }
                if let generationID = role.gisuId {
                    return generationID == activity.gisuId
                }
                return role.gisu != nil && role.gisu == activity.gisu
            }
            let roleNames = (matchingRoles + (activity.roles ?? [])).compactMap(\.roleType)
            var uniqueRoles: [String] = []
            for role in roleNames where !uniqueRoles.contains(role) { uniqueRoles.append(role) }
            return SettingsActivity(
                id: identity, generation: activity.gisu ?? "", part: activity.part ?? "",
                roles: uniqueRoles
            )
        }
        return SettingsProfile(
            id: id, name: name, nickname: nickname, email: email, schoolName: schoolName,
            profileImageURL: profileImageLink.flatMap(DefaultSettingsUseCase.validatedWebURL),
            links: .init(
                github: profile?.github ?? "", linkedIn: profile?.linkedIn ?? "",
                instagram: profile?.instagram ?? "", blog: profile?.blog ?? "",
                personal: profile?.personal ?? ""
            ), activities: activities
        )
    }
}
