//
//  SettingsProfile.swift
//  SettingsDomain
//
//  Created by euijjang97 on 10/20/26.
//

import Foundation

public struct SettingsProfile: Equatable, Sendable {
    public let id: String
    public let name: String
    public let nickname: String
    public let email: String?
    public let schoolName: String?
    public let profileImageURL: URL?
    public let links: SettingsProfileLinks
    public let activities: [SettingsActivity]

    public init(
        id: String, name: String, nickname: String, email: String? = nil,
        schoolName: String? = nil, profileImageURL: URL? = nil,
        links: SettingsProfileLinks = .init(), activities: [SettingsActivity] = []
    ) {
        self.id = id
        self.name = name
        self.nickname = nickname
        self.email = email
        self.schoolName = schoolName
        self.profileImageURL = profileImageURL
        self.links = links
        self.activities = activities
    }
}

public enum SettingsLinkKind: String, CaseIterable, Identifiable, Sendable {
    case github = "GITHUB"
    case linkedIn = "LINKEDIN"
    case instagram = "INSTAGRAM"
    case blog = "BLOG"
    case personal = "PERSONAL"

    public var id: String { rawValue }
}

public struct SettingsProfileLinks: Equatable, Sendable {
    public var github: String
    public var linkedIn: String
    public var instagram: String
    public var blog: String
    public var personal: String

    public init(
        github: String = "", linkedIn: String = "", instagram: String = "",
        blog: String = "", personal: String = ""
    ) {
        self.github = github
        self.linkedIn = linkedIn
        self.instagram = instagram
        self.blog = blog
        self.personal = personal
    }

    public subscript(kind: SettingsLinkKind) -> String {
        get {
            switch kind {
            case .github: github
            case .linkedIn: linkedIn
            case .instagram: instagram
            case .blog: blog
            case .personal: personal
            }
        }
        set {
            switch kind {
            case .github: github = newValue
            case .linkedIn: linkedIn = newValue
            case .instagram: instagram = newValue
            case .blog: blog = newValue
            case .personal: personal = newValue
            }
        }
    }
}

public struct SettingsActivity: Equatable, Identifiable, Sendable {
    public let id: String
    public let generation: String
    public let part: String
    public let roles: [String]

    public init(id: String, generation: String, part: String, roles: [String] = []) {
        self.id = id
        self.generation = generation
        self.part = part
        self.roles = roles
    }
}
