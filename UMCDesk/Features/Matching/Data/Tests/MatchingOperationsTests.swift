//
//  MatchingOperationsTests.swift
//  MatchingDataTests
//
//  Created by euijjang97 on 11/22/26.
//

import Foundation
import MatchingDomain
import Testing
@testable import MatchingData

@Suite("프로젝트 운영 계약")
struct MatchingOperationsTests {
    @Test("지원자 목록 접근과 판정 권한을 별도로 읽고 누락된 권한은 부여하지 않는다")
    func scopedCapabilities() throws {
        let response = Data("""
        {"projectId":42,"canDelete":{"allowed":false,"reason":"삭제 불가"},
         "application":{"canReadList":{"allowed":true},"canDecide":{"allowed":false}}}
        """.utf8)
        let row = try JSONDecoder().decode(OperationsPermissionsDTO.self, from: response)
        #expect(row.id == "42")
        #expect(row.capabilities[.applicants]?.allowed == true)
        #expect(row.capabilities[.decide]?.allowed == false)
        #expect(row.capabilities[.delete]?.reason == "삭제 불가")
        #expect(row.capabilities[.transfer] == nil)
    }

    @Test("폼 순서 변경 시 기존 식별자와 기타 선택지를 유지하고 답변 삭제 동의는 별도로 전송한다")
    func formMutation() throws {
        let option = EditableOption(optionId: "75", content: "기타", orderNo: "8", isOther: true)
        let question = EditableQuestion(questionId: "32", type: "RADIO", title: "관련 경험",
            description: nil, isRequired: true, orderNo: "2", options: [option])
        let form = EditableMatchingForm(title: "지원 폼", description: nil, sections: [
            .init(sectionId: "11", type: "PART", allowedParts: ["DESIGN"], title: "디자인",
                  description: nil, orderNo: "4", questions: [question])
        ])
        for consent in [false, true] {
            let body = try FormBody(form, confirm: consent)
            #expect(body.confirmDeleteAnsweredSections == consent)
            let section = try #require(body.sections.first)
            #expect(section.sectionId == 11)
            #expect(section.orderNo == 0)
            let saved = try #require(section.questions.first)
            #expect(saved.questionId == 32)
            #expect(saved.options.first?.optionId == 75)
            #expect(saved.options.first?.isOther == true)
        }
    }
}

extension MatchingOperationsTests {
    @Test("새 초안은 본인 등록 시 PM을 생략하고 대리 등록 시 선택된 회원 ID를 보낸다")
    func draftRegistration() throws {
        let own = try DraftBody(gisuId: "10", productOwnerMemberId: nil)
        let delegated = try DraftBody(gisuId: "10", productOwnerMemberId: "24")
        func parameters(_ body: DraftBody) throws -> [String: Int64] {
            try JSONDecoder().decode([String: Int64].self, from: JSONEncoder().encode(body))
        }
        #expect(try parameters(own) == ["gisuId": 10])
        #expect(try parameters(delegated) == ["gisuId": 10, "productOwnerMemberId": 24])
        #expect(throws: (any Error).self) { try DraftBody(gisuId: "10", productOwnerMemberId: "invalid") }
    }
}

extension MatchingOperationsTests {
    @Test("명단 유형은 디자인과 신규·기존 개발 파트를 구분하고 운영진을 제외한다")
    func matchingTypeScope() {
        #expect(MatchingRosterType.design.includes(part: "DESIGN"))
        for part in ["IOS", "ANDROID", "WEB", "SPRINGBOOT", "NODEJS",
                     "WEB_PRODUCT_ENGINEER", "MOBILE_PRODUCT_ENGINEER"] {
            #expect(MatchingRosterType.developer.includes(part: part))
            #expect(!MatchingRosterType.design.includes(part: part))
        }
        for part in ["PLAN", "ADMIN", "DESIGN"] {
            #expect(!MatchingRosterType.developer.includes(part: part))
        }
    }
}
