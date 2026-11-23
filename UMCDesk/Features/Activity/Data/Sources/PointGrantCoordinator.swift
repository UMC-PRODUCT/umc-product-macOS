//  PointGrantCoordinator.swift
//  ActivityData
//
//  Created by euijjang97 on 11/23/26.
//

import ActivityDomain
import Foundation
import UMCFoundation

struct PointGrant: Hashable, Sendable {
    let challengerID: String
    let value: Int
    let reason: String
}

/// The server has a grant ledger but no request identifier. After an ambiguous write,
/// only a ledger read may resolve the same grant.
actor PointGrantCoordinator {
    private struct Pending {
        let existingIDs: Set<String>
        var operations: Set<UUID>
    }
    private var pending: [PointGrant: Pending] = [:]
    private struct Flight {
        let task: Task<PointGrantResult, Error>
        var operations: Set<UUID>
    }
    private var flights: [PointGrant: Flight] = [:]
    private var completed: [UUID: PointGrantResult] = [:]

    func submit(
        id: UUID, grant: PointGrant,
        read: @escaping @Sendable () async throws -> PointLedgerDTO,
        write: @escaping @Sendable () async throws -> Void
    ) async throws -> PointGrantResult {
        try Task.checkCancellation()
        if let result = completed[id] { return result }
        if var flight = flights[grant] {
            flight.operations.insert(id)
            flights[grant] = flight
            return try await flight.task.value
        }
        let flight = Task {
            defer {
                if let flight = flights.removeValue(forKey: grant) {
                    pending[grant]?.operations.formUnion(flight.operations)
                }
            }
            if pending[grant] == nil {
                let baseline = try await read()
                pending[grant] = Pending(
                    existingIDs: Set(baseline.points.map(\.id)), operations: [id])
                do {
                    try await write()
                    finish(.recorded, grant: grant)
                    return PointGrantResult.recorded
                } catch let NetworkError.requestFailed(code, data)
                    where [400, 401, 403, 404, 422].contains(code)
                {
                    pending.removeValue(forKey: grant)
                    throw NetworkError.requestFailed(statusCode: code, data: data)
                } catch {
                    // A lost response, cancellation, or a malformed receipt may follow a commit.
                }
            }
            pending[grant]?.operations.insert(id)
            guard let baseline = pending[grant]?.existingIDs, let ledger = try? await read(),
                ledger.points.contains(where: {
                    !baseline.contains($0.id) && $0.challengerId == grant.challengerID
                        && $0.pointType == "CUSTOM" && $0.point == Double(grant.value)
                        && $0.description == grant.reason
                })
            else { return .awaitingLedger }
            finish(.ledgerMatch, grant: grant)
            return .ledgerMatch
        }
        flights[grant] = Flight(task: flight, operations: [id])
        return try await flight.value
    }

    private func finish(_ result: PointGrantResult, grant: PointGrant) {
        let earlier = pending.removeValue(forKey: grant)?.operations ?? []
        for operation in earlier.union(flights[grant]?.operations ?? []) {
            completed[operation] = result
        }
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
