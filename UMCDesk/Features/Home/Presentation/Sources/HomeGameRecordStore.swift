//
//  HomeGameRecordStore.swift
//  HomePresentation
//
//  Created by euijjang97 on 11/23/26.
//

import Foundation
import HomeDomain

struct HomeGameRecordStore: Equatable {
    let defaults: UserDefaults
    let memberID: String?

    private var key: String? {
        memberID.map { "home.games.records." + $0 }
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.defaults === rhs.defaults && lhs.memberID == rhs.memberID
    }

    func load() -> GameRecords {
        guard let key, let data = defaults.data(forKey: key),
              let records = try? JSONDecoder().decode(GameRecords.self, from: data)
        else { return GameRecords() }
        return records
    }

    func save(_ records: GameRecords) {
        guard let key, let data = try? JSONEncoder().encode(records) else { return }
        defaults.set(data, forKey: key)
    }
}

struct GameRecords: Codable, Equatable {
    var best: [String: Int] = [:]
    var totals: [String: Int] = [:]
    var recent: [String] = []

    mutating func record(_ game: MiniGame, score: Int) {
        let id = game.rawValue
        best[id] = max(score, best[id, default: 0])
        totals[id, default: 0] += score
        recent = Array((["\(game.title) \(score)점"] + recent).prefix(3))
    }
}
