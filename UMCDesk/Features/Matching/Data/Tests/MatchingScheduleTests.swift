//
//  MatchingScheduleTests.swift
//  MatchingDataTests
//
//  Created by euijjang97 on 11/22/26.
//

import Foundation
import MatchingDomain
import Testing
@testable import MatchingData

@Suite("Matching schedule server contracts")
struct MatchingScheduleTests {
    @Test("A chapter president can edit only the assigned organization within the same cohort")
    func scopedRole() throws {
        let json = Data("""
        {"gisuId":10,"roleType":"CHAPTER_PRESIDENT","organizationId":"27","organizationType":"CHAPTER"}
        """.utf8)
        let role = try JSONDecoder().decode(ScheduleRole.self, from: json)
        #expect(role.canManage(gisuId: "10", chapterId: "27"))
        #expect(!role.canManage(gisuId: "9", chapterId: "27"))
        #expect(!role.canManage(gisuId: "10", chapterId: "28"))
    }

    @Test("Batch preserves descriptions and excludes a decision deadline for random matching")
    func fullSchedule() throws {
        let phases = ["FIRST", "SECOND", "THIRD", "RANDOM_MATCHING"]
        let rows = phases.map { phase in
            MatchingRoundChange(phase: phase, name: phase, description: "지부별 일정",
                startsAt: "2026-01-01T00:00:00Z", endsAt: "2026-01-02T00:00:00Z",
                decisionDeadline: phase == "RANDOM_MATCHING" ? nil : "2026-01-03T00:00:00Z",
                resultPublishAt: "2026-01-04T00:00:00Z")
        }
        let data = try JSONEncoder().encode(SaveMatchingScheduleBody(type: "PLAN_DEVELOPER", rounds: rows))
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let changes = try #require(json["rounds"] as? [[String: Any]])
        #expect(changes.compactMap { $0["phase"] as? String } == phases)
        #expect(changes.last?["decisionDeadline"] == nil)
        #expect(changes.last?["description"] as? String == "지부별 일정")
    }
}
