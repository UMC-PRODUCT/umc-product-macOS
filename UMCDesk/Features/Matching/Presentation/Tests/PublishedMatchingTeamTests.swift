//
//  PublishedMatchingTeamTests.swift
//  MatchingPresentationTests
//
//  Created by euijjang97 on 11/23/26.
//

import MatchingDomain
@testable import MatchingPresentation
import Testing

struct PublishedMatchingTeamTests {
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
}
