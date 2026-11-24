//
//  StudyResponse.swift
//  ActivityData
//
//  Created by euijjang97 on 11/23/26.
//

import Foundation
import UMCFoundation

struct PermissionDTO: Codable {
    let resourceId: String?
    let permissions: [PermissionInfoDTO]

    private enum CodingKeys: String, CodingKey {
        case resourceId, permissions
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        resourceId = try values.decodeFlexibleStringIfPresent(forKey: .resourceId)
        permissions = try values.decode([PermissionInfoDTO].self, forKey: .permissions)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encodeIfPresent(resourceId, forKey: .resourceId)
        try values.encode(permissions, forKey: .permissions)
    }
}

struct BatchPermissionsDTO: Codable {
    let results: [PermissionDTO]

    private enum CodingKeys: String, CodingKey {
        case results
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        results = try values.decode([PermissionDTO].self, forKey: .results)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(results, forKey: .results)
    }
}

struct PermissionInfoDTO: Codable {
    let permissionType: String
    let hasPermission: Bool

    private enum CodingKeys: String, CodingKey {
        case permissionType, hasPermission
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

struct MemberProfileDTO: Codable {
    let id: String
    let name: String
    let schoolName: String?
    let challengerRecords: [RecordDTO]

    private enum CodingKeys: String, CodingKey {
        case id, name, schoolName, challengerRecords
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeFlexibleString(forKey: .id)
        name = try values.decode(String.self, forKey: .name)
        schoolName = try values.decodeIfPresent(String.self, forKey: .schoolName)
        challengerRecords = try values.decode([RecordDTO].self, forKey: .challengerRecords)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(name, forKey: .name)
        try values.encodeIfPresent(schoolName, forKey: .schoolName)
        try values.encode(challengerRecords, forKey: .challengerRecords)
    }
}

struct RecordDTO: Codable {
    let challengerId: String
    let gisu: String
    let part: String?

    private enum CodingKeys: String, CodingKey {
        case challengerId, gisu, part
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        challengerId = try values.decodeFlexibleString(forKey: .challengerId)
        gisu = try values.decodeFlexibleString(forKey: .gisu)
        part = try values.decodeIfPresent(String.self, forKey: .part)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(challengerId, forKey: .challengerId)
        try values.encode(gisu, forKey: .gisu)
        try values.encodeIfPresent(part, forKey: .part)
    }
}

struct PointReceiptDTO: Codable {
    let challengerId: String

    private enum CodingKeys: String, CodingKey {
        case challengerId
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        challengerId = try values.decodeFlexibleString(forKey: .challengerId)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(challengerId, forKey: .challengerId)
    }
}
