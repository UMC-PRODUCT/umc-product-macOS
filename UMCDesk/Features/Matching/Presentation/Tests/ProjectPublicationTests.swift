//
//  ProjectPublicationTests.swift
//  MatchingPresentationTests
//
//  Created by euijjang97 on 11/23/26.
//

import MatchingDomain
@testable import MatchingPresentation
import Testing

struct ProjectPublicationTests {
    @Test("등록된 폼과 저장된 양수 정원이 모두 있어야 공개 준비 완료로 표시한다")
    func publicationReadiness() {
        func project(form: String?, capacity: String?) -> MatchingProject {
            MatchingProject(
                id: "1", name: "모아", description: nil, thumbnailImageUrl: nil,
                productOwner: nil, partQuotas: capacity.map {
                    [.init(part: "DESIGN", currentCount: "0", quota: $0, status: "RECRUITING")]
                } ?? [], partQuotaStatus: nil, logoImageUrl: nil, externalLink: nil,
                applicationFormId: form
            )
        }
        #expect(project(form: "3", capacity: "2").isReadyForPublication)
        #expect(!project(form: nil, capacity: "2").isReadyForPublication)
        #expect(!project(form: "3", capacity: nil).isReadyForPublication)
        #expect(!project(form: "3", capacity: "0").isReadyForPublication)
    }
}
