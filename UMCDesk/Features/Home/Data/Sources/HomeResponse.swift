//
//  HomeResponse.swift
//  HomeData
//
//  Created by euijjang97 on 11/23/26.
//

import Foundation
import UMCFoundation

struct ProfileDTO: Codable {
    let id: String
    let nickname: String

    private enum CodingKeys: String, CodingKey {
        case id, nickname
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeFlexibleString(forKey: .id)
        nickname = try values.decode(String.self, forKey: .nickname)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(nickname, forKey: .nickname)
    }
}

struct ScheduleDTO: Codable {
    let name: String
    let startsAt: String

    private enum CodingKeys: String, CodingKey {
        case name, startsAt
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
        startsAt = try values.decode(String.self, forKey: .startsAt)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(name, forKey: .name)
        try values.encode(startsAt, forKey: .startsAt)
    }
}

struct GisuDTO: Codable {
    let gisuId: String

    private enum CodingKeys: String, CodingKey {
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

struct PageDTO<Item: Codable>: Codable {
    let content: [Item]

    private enum CodingKeys: String, CodingKey {
        case content
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        content = try values.decode([Item].self, forKey: .content)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(content, forKey: .content)
    }
}

struct NoticeDTO: Codable {
    let title: String

    private enum CodingKeys: String, CodingKey {
        case title
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        title = try values.decode(String.self, forKey: .title)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(title, forKey: .title)
    }
}

struct ProjectDTO: Codable {
    let name: String

    private enum CodingKeys: String, CodingKey {
        case name
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        name = try values.decode(String.self, forKey: .name)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(name, forKey: .name)
    }
}
