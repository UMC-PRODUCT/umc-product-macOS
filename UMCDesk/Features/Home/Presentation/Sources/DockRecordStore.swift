//  DockRecordStore.swift
//  HomePresentation
//
//  Created by euijjang97 on 11/28/26.
//

import Foundation

struct DockRecords: Codable, Equatable {
    var best = 0
    var total = 0
    var recent: [Int] = []
}

struct DockRecordStore: Equatable {
    let defaults: UserDefaults
    let memberID: String?

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.memberID == rhs.memberID && lhs.defaults === rhs.defaults
    }

    func load() -> DockRecords {
        guard let memberID, !memberID.isEmpty else { return DockRecords() }
        let decoder = JSONDecoder()
        if let data = defaults.data(forKey: "home.postmarkDock.records." + memberID),
           let records = try? decoder.decode(DockRecords.self, from: data) {
            return records
        }

        // PR #154 originally stored dock scores alongside the retired games.
        guard let data = defaults.data(forKey: "home.games.records." + memberID),
              let legacy = try? decoder.decode(LegacyRecords.self, from: data)
        else { return DockRecords() }
        let prefix = "소인이 찍겠습니다! "
        let recent = legacy.recent.compactMap { entry -> Int? in
            guard entry.hasPrefix(prefix), entry.hasSuffix("점") else { return nil }
            return Int(entry.dropFirst(prefix.count).dropLast())
        }
        return DockRecords(best: legacy.best["postmarkDock", default: 0],
                           total: legacy.totals["postmarkDock", default: 0],
                           recent: Array(recent.prefix(3)))
    }

    @MainActor
    func record(_ score: Int) -> DockRecords {
        guard let memberID, !memberID.isEmpty else { return DockRecords() }
        var records = load()
        records.best = max(records.best, score)
        records.total += score
        records.recent = Array(([score] + records.recent).prefix(3))
        if let data = try? JSONEncoder().encode(records) {
            defaults.set(data, forKey: "home.postmarkDock.records." + memberID)
        }
        return records
    }

    private struct LegacyRecords: Decodable {
        let best: [String: Int]
        let totals: [String: Int]
        let recent: [String]
    }
}
