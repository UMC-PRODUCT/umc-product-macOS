//  PointGrantCoordinator.swift
//  ActivityData
//
//  Created by euijjang97 on 11/23/26.
//

import ActivityDomain
import Foundation
import UMCFoundation

actor PointGrantCoordinator {
    let journal: PointGrantJournal
    private var flights: [UUID: (PointGrantIntent, Task<PointGrantResult, Error>)] = [:]

    init(journal: PointGrantJournal) { self.journal = journal }

    func submit(
        grant: PointGrantIntent,
        read: @escaping @Sendable () async throws -> PointLedgerDTO,
        write: @escaping @Sendable () async throws -> Void
    ) async throws -> PointGrantResult {
        try Task.checkCancellation()
        if let (prior, flight) = flights[grant.id] {
            guard prior == grant else { throw PointJournalError.reusedID }
            return try await flight.value
        }
        let flight = Task {
            defer { flights.removeValue(forKey: grant.id) }
            var entry = try journal.lookup(grant)
            if entry == nil {
                let baseline = try await read()
                entry = try journal.reserve(grant, baseline: Set(baseline.points.map(\.id)))
            }
            if let entry {
                switch entry.status {
                case .recorded: return PointGrantResult.recorded
                case .reviewed: throw PointJournalError.manuallyReviewed
                case .pending: return await reconcile(entry, read: read)
                }
            }
            do {
                try await write()
            } catch let NetworkError.requestFailed(code, data)
                where [400, 401, 403, 404, 422].contains(code)
            {
                try journal.close(grant.id, as: nil)
                throw NetworkError.requestFailed(statusCode: code, data: data)
            } catch {
                guard let entry = try journal.lookup(grant) else { throw error }
                return await reconcile(entry, read: read)
            }
            try journal.close(grant.id, as: .recorded)
            return .recorded
        }
        flights[grant.id] = (grant, flight)
        return try await flight.value
    }

    private func reconcile(
        _ entry: PointGrantJournal.Entry,
        read: () async throws -> PointLedgerDTO
    ) async -> PointGrantResult {
        guard let ledger = try? await read() else { return .awaitingLedger }
        let grant = entry.intent
        let candidate = ledger.points.contains {
            !entry.baseline.contains($0.id) && $0.challengerId == grant.challengerID
                && $0.pointType == "CUSTOM" && $0.point == Double(grant.value)
                && $0.description == grant.reason
        }
        // The ledger identifies neither the requesting operator nor the client operation.
        return candidate ? .matchingUnverified : .awaitingLedger
    }
}

struct PointLedgerDTO: Codable, Sendable {
    let challengerId: String
    let points: [PointRecordDTO]
    let totalPoints: Double

    enum CodingKeys: String, CodingKey { case challengerId, points, challengerPoints, totalPoints }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        challengerId = try values.decodeFlexibleString(forKey: .challengerId)
        points =
            try values.decodeIfPresent([PointRecordDTO].self, forKey: .points)
            ?? values.decode([PointRecordDTO].self, forKey: .challengerPoints)
        totalPoints = try values.decodeDoubleFlexible(forKey: .totalPoints)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(challengerId, forKey: .challengerId)
        try values.encode(points, forKey: .points)
        try values.encode(totalPoints, forKey: .totalPoints)
    }
}

struct PointRecordDTO: Codable, Sendable {
    let id: String
    let challengerId: String
    let pointType: String
    let point: Double
    let description: String?

    enum CodingKeys: String, CodingKey { case id, challengerId, pointType, point, description }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decodeFlexibleString(forKey: .id)
        challengerId = try values.decodeFlexibleString(forKey: .challengerId)
        pointType = try values.decode(String.self, forKey: .pointType)
        point = try values.decodeDoubleFlexible(forKey: .point)
        description = try values.decodeIfPresent(String.self, forKey: .description)
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(challengerId, forKey: .challengerId)
        try values.encode(pointType, forKey: .pointType)
        try values.encode(point, forKey: .point)
        try values.encodeIfPresent(description, forKey: .description)
    }
}
