//
//  MatchingOperationsPreview.swift
//  MatchingPresentation
//
//  Created by euijjang97 on 11/22/26.
//

#if DEBUG
import Foundation
import MatchingDomain

extension MatchingPreviewRepository {
    private var previewPeople: [OperationsPerson] {
        [
            .init(memberId: "11", nickname: "김유엠", name: nil, schoolName: "한빛대", part: "MOBILE_PRODUCT_ENGINEER"),
            .init(memberId: "12", nickname: "정모바", name: nil, schoolName: "한빛대", part: "MOBILE_PRODUCT_ENGINEER"),
            .init(memberId: "13", nickname: "최개발", name: nil, schoolName: "새솔대", part: "WEB_PRODUCT_ENGINEER"),
            .init(memberId: "14", nickname: "서웹개", name: nil, schoolName: "새솔대", part: "WEB_PRODUCT_ENGINEER"),
            .init(memberId: "15", nickname: "이로움", name: nil, schoolName: "한빛대", part: "WEB_PRODUCT_ENGINEER")
        ]
    }

    private var previewOwner: OperationsPerson {
        .init(memberId: "1", nickname: "김모아", name: nil, schoolName: "한빛대", part: "PLAN")
    }

    func managedProjects(gisuId: String, keyword: String?, page: Int) async throws
        -> (projects: [ManagedProject], hasNext: Bool) {
        let rows = [("1", "모아", "IN_PROGRESS"), ("2", "바로", "PENDING_REVIEW"), ("3", "장바구니", "DRAFT")]
            .map { ManagedProject(id: $0.0, name: $0.1, status: $0.2, productOwner: previewOwner) }
        return (rows.filter { $0.name?.contains(keyword ?? "") == true || (keyword ?? "").isEmpty }, false)
    }

    func latestDraft(gisuId: String) async throws -> ManagedProject? {
        .init(id: "3", name: "장바구니", status: "DRAFT", productOwner: previewOwner)
    }
    func createProjectDraft(gisuId: String, productOwnerMemberId: String?) async throws -> String { "3" }
    func pmCandidates(gisuId: String, keyword: String?, page: Int) async throws
        -> (people: [OperationsPerson], hasNext: Bool) {
        let rows = [previewOwner].filter { ($0.display.contains(keyword ?? "") || (keyword ?? "").isEmpty) }
        return (rows, false)
    }

    func permissions(projectId: String) async throws -> [ProjectPermission: MatchingCapability] {
        Dictionary(uniqueKeysWithValues: ProjectPermission.allCases.map { permission in
            let allowed: Bool
            switch permission {
            case .publish: allowed = projectId == "2"
            case .delete, .submit, .formCreate: allowed = projectId == "3"
            case .formEdit, .quota, .edit, .formRead: allowed = true
            default: allowed = projectId == "1"
            }
            return (permission, MatchingCapability(allowed: allowed, reasonCode: nil,
                                                   reason: allowed ? nil : "이 프로젝트 상태에서는 사용할 수 없어요."))
        })
    }

    func editableForm(projectId: String) async throws -> EditableMatchingForm {
        let question = EditableQuestion(questionId: "21", type: "LONG_TEXT", title: "지원 동기",
                                        description: "지원한 이유를 알려주세요.", isRequired: true,
                                        orderNo: "0", options: [])
        return .init(title: "모아 지원서", description: "함께 만들고 싶은 경험을 알려주세요.",
                     sections: [.init(sectionId: "31", type: "COMMON", allowedParts: [],
                                      title: "공통 질문", description: nil, orderNo: "0", questions: [question])])
    }

    func applicants(projectId: String) async throws -> [ApplicantRow] {
        let statuses = ["SUBMITTED", "APPROVED", "APPROVED", "REJECTED", "SUBMITTED"]
        return zip(previewPeople, statuses).map { person, status in
            ApplicantRow(applicationId: person.memberId, applicant: person, status: status,
                         matchingRound: .init(id: "101", phase: "FIRST", type: "PLAN_DEVELOPER"),
                         submittedAt: "2026-09-30T05:30:00Z")
        }
    }

    func team(projectId: String) async throws -> OperationsTeam {
        .init(productOwner: previewOwner, coProductOwners: [], partGroups: [
            .init(part: "MOBILE_PRODUCT_ENGINEER", members: [previewPeople[1]]),
            .init(part: "WEB_PRODUCT_ENGINEER", members: [previewPeople[2]])
        ])
    }

    func candidates(projectId: String, part: String, page: Int) async throws
        -> (people: [OperationsPerson], hasNext: Bool) {
        (previewPeople.filter { $0.part == part && ["11", "15"].contains($0.memberId) }, false)
    }

    func overview(chapterId: String, adjustment: Bool) async throws -> [OverviewProject] {
        let mobile = adjustment ? [previewPeople[0], previewPeople[1]] : [previewPeople[1]]
        return [.init(projectId: "1", projectName: "모아", currentMemberCount: String(mobile.count + 1),
                      quota: "4", partQuotaStatus: "RECRUITING", productOwner: previewOwner, coProductOwners: [],
                      parts: [.init(part: "MOBILE_PRODUCT_ENGINEER", currentMemberCount: String(mobile.count),
                                    quota: "2", members: mobile),
                              .init(part: "WEB_PRODUCT_ENGINEER", currentMemberCount: "1", quota: "2",
                                    members: [previewPeople[2]])])]
    }

    func publicStatistics(chapterId: String) async throws -> PublicMatchingStatistics {
        .init(roundMatchingStatistics: [.init(phase: "FIRST", matchedMemberCount: "2", availableMemberCount: "5")],
              schoolMatchingStatistics: [.init(schoolId: "1", schoolName: "한빛대", matchedMemberCount: "1", totalMemberCount: "3"),
                                         .init(schoolId: "2", schoolName: "새솔대", matchedMemberCount: "1", totalMemberCount: "2")],
              projectMatchingStatistics: [.init(projectId: "1", projectName: "모아", matchedMemberCount: "2", quota: "4",
                                                rounds: [.init(phase: "FIRST", matchedMemberCount: "2")],
                                                parts: [.init(part: "MOBILE_PRODUCT_ENGINEER", matchedMemberCount: "1", quota: "2"),
                                                        .init(part: "WEB_PRODUCT_ENGINEER", matchedMemberCount: "1", quota: "2")])])
    }

    func applicationStatistics(projectId: String) async throws -> OperationsStatistics {
        .init(schoolApplicationStatistics: [.init(schoolId: "1", schoolName: "한빛대", totalMemberCount: "3",
                                                 rounds: [.init(phase: "FIRST", applicantCount: "3")])],
              projectRoundStatistics: [.init(projectId: "1", projectName: "모아",
                                            rounds: [.init(phase: "FIRST", applicantCount: "5")])])
    }

    func perform(_ operation: ProjectOperation, projectId: String) async throws {
        throw URLError(.resourceUnavailable)
    }
}
#endif
