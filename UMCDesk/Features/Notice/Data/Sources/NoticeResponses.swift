//
//  NoticeResponses.swift
//  NoticeData
//
//  Created by euijjang97 on 11/23/26.
//

import Foundation
import NoticeDomain
import UMCFoundation

struct ActiveGisu: Codable, Sendable {
    let gisuId: String

    private enum CodingKeys: CodingKey {
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

struct CreatedNotice: Codable, Sendable {
    let noticeId: String

    private enum CodingKeys: CodingKey {
        case noticeId
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        noticeId = try values.decodeFlexibleString(forKey: .noticeId)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(noticeId, forKey: .noticeId)
    }
}

struct UploadTicket: Codable, Sendable {
    let fileId: String
    let uploadUrl: String
    let uploadMethod: String
    let headers: [String: String]

    private enum CodingKeys: CodingKey {
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
        headers = try values.decode([String: String].self, forKey: .headers)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(fileId, forKey: .fileId)
        try values.encode(uploadUrl, forKey: .uploadUrl)
        try values.encode(uploadMethod, forKey: .uploadMethod)
        try values.encode(headers, forKey: .headers)
    }
}

struct NoticePermission: Codable, Sendable {
    let permissionType: String
    let hasPermission: Bool

    private enum CodingKeys: CodingKey {
        case permissionType
        case hasPermission
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        permissionType = try values.decode(String.self, forKey: .permissionType)
        hasPermission = try values.decode(Bool.self, forKey: .hasPermission)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(permissionType, forKey: .permissionType)
        try values.encode(hasPermission, forKey: .hasPermission)
    }
}

struct NoticePermissionResponse: Codable, Sendable {
    let permissions: [NoticePermission]

    private enum CodingKeys: CodingKey {
        case permissions
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        permissions = try values.decode([NoticePermission].self, forKey: .permissions)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(permissions, forKey: .permissions)
    }
}

struct OrganizationResponse: Codable, Sendable {
    let gisus: [NoticeOrganization]

    private enum CodingKeys: CodingKey {
        case gisus
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        gisus = try values.decode([NoticeOrganization].self, forKey: .gisus)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(gisus, forKey: .gisus)
    }
}
