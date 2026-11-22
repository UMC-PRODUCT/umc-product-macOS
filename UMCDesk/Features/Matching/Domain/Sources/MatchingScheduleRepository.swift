//
//  MatchingScheduleRepository.swift
//  MatchingDomain
//
//  Created by euijjang97 on 11/22/26.
//

public struct MatchingRoundChange: Encodable, Sendable {
    public let phase: String
    public let name: String
    public let description: String?
    public let startsAt: String
    public let endsAt: String
    public let decisionDeadline: String?
    public let resultPublishAt: String

    public init(
        phase: String, name: String, description: String?, startsAt: String,
        endsAt: String, decisionDeadline: String?, resultPublishAt: String
    ) {
        self.phase = phase
        self.name = name
        self.description = description
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.decisionDeadline = decisionDeadline
        self.resultPublishAt = resultPublishAt
    }
}

public protocol MatchingScheduleRepository: Sendable {
    func canManageSchedule(chapterId: String) async throws -> Bool
    func saveSchedule(chapterId: String, type: String, rounds: [MatchingRoundChange]) async throws
    func deleteSchedule(chapterId: String, type: String) async throws
    func autoDecide(roundId: String) async throws
}
