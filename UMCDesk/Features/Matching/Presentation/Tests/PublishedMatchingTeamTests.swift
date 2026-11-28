//
//  PublishedMatchingTeamTests.swift
//  MatchingPresentationTests
//
//  Created by euijjang97 on 11/23/26.
//

import Foundation
import MatchingDomain
@testable import MatchingPresentation
import Testing

struct PublishedMatchingTeamTests {
    @Test("랜덤 선발 검토는 같은 지부와 유형의 3차 발표가 지난 경우만 허용한다")
    func autoDecisionReviewScope() {
        func round(_ phase: String, _ chapter: String, _ type: String,
                   publication: String? = nil, executed: String? = nil) -> MatchingRound {
            MatchingRound(id: phase, name: phase, type: type, phase: phase, chapterId: chapter,
                          startsAt: "", endsAt: "", decisionDeadline: nil,
                          resultPublishAt: publication, autoDecisionExecutedAt: executed)
        }
        let now = Date(timeIntervalSince1970: 3600)
        let past = "1970-01-01T00:00:00Z"
        let random = round("RANDOM_MATCHING", "a", "PLAN_DESIGN")
        let third = round("THIRD", "a", "PLAN_DESIGN", publication: past)
        #expect(random.canReviewAutoDecision(in: [third], at: now))
        #expect(!random.canReviewAutoDecision(in: [
            round("THIRD", "b", "PLAN_DESIGN", publication: past),
            round("THIRD", "a", "PLAN_DEVELOPER", publication: past)
        ], at: now))
        #expect(!round("RANDOM_MATCHING", "a", "PLAN_DESIGN", executed: past)
            .canReviewAutoDecision(in: [third], at: now))
    }

    @Test("공개 명단의 회원 ID와 역할로만 합류를 확인한다")
    func publishedMembership() {
        func person(_ id: String) -> OperationsPerson {
            .init(memberId: id, nickname: "같은 닉네임", name: nil, schoolName: nil, part: nil)
        }
        let team = OperationsTeam(
            productOwner: person("1"), coProductOwners: [person("2")],
            partGroups: [.init(part: "WEB_PRODUCT_ENGINEER", members: [person("3")])]
        )
        #expect(team.publishedMember(withID: "1")?.role == "담당 PM")
        #expect(team.publishedMember(withID: "2")?.role == "보조 PM")
        #expect(team.publishedMember(withID: "3")?.role == "웹")
        #expect(team.publishedMember(withID: "4") == nil)
        #expect(team.publishedMember(withID: "") == nil)
    }

    @Test("발표 예정 시각과 무관하게 같은 차수의 공개된 결과만 표시한다")
    func publishedRoundResult() {
        let round = MatchingRound(
            id: "3", name: "개발자 2차", type: "PLAN_DEVELOPER", phase: "SECOND",
            chapterId: "1", startsAt: "", endsAt: "", decisionDeadline: nil,
            resultPublishAt: nil, autoDecisionExecutedAt: "2026-11-23T00:00:00Z"
        )
        func card(_ id: String, _ status: String?) -> MatchingApplication {
            .init(applicationId: "7", projectId: "4", project: nil,
                  matchingRound: .init(id: id, type: nil, phase: nil), status: status)
        }
        #expect(round.hasPublishedResult(card("3", "APPROVED")))
        #expect(round.hasPublishedResult(card("3", "REJECTED")))
        #expect(!round.hasPublishedResult(card("3", nil)))
        #expect(!round.hasPublishedResult(card("3", "SUBMITTED")))
        #expect(!round.hasPublishedResult(card("2", "APPROVED")))
    }
}
