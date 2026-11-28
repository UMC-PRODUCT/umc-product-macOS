//
//  MatchingOperationsPreview.swift
//  MatchingPresentation
//
//  Created by euijjang97 on 11/22/26.
//

import Foundation
import MatchingDomain

extension MatchingPreviewRepository {
    private var previewPeople: [OperationsPerson] {
        if isEmpty { return [] }
        return [
            .init(memberId: "11", nickname: "김유엠", name: nil, schoolName: "한빛대", part: "MOBILE_PRODUCT_ENGINEER"),
            .init(memberId: "12", nickname: "정모바", name: nil, schoolName: "한빛대", part: "MOBILE_PRODUCT_ENGINEER"),
            .init(memberId: "13", nickname: "최개발", name: nil, schoolName: "새솔대", part: "WEB_PRODUCT_ENGINEER"),
            .init(memberId: "14", nickname: "서웹개", name: nil, schoolName: "새솔대", part: "WEB_PRODUCT_ENGINEER"),
            .init(memberId: "15", nickname: "이로움", name: nil, schoolName: "한빛대", part: "WEB_PRODUCT_ENGINEER")
        ]
    }

    private var previewOwner: OperationsPerson {
        if isEmpty {
            return .init(memberId: "101", nickname: "유엠", name: "김유엠", schoolName: "한빛대학교", part: "PLAN")
        }
        return .init(memberId: "1", nickname: "김모아", name: nil, schoolName: "한빛대", part: "PLAN")
    }

    func managedProjects(gisuId: String, keyword: String?, page: Int) async throws
        -> (projects: [ManagedProject], hasNext: Bool) {
        let rows = names.keys.sorted().compactMap { id -> ManagedProject? in
            guard let name = names[id], (keyword ?? "").isEmpty || name.contains(keyword ?? "") else { return nil }
            return .init(id: id, name: name, status: stages[id] ?? "DRAFT", productOwner: teams[id]?.productOwner ?? previewOwner)
        }
        return (page == 0 ? rows : [], false)
    }

    func latestDraft(gisuId: String) async throws -> ManagedProject? {
        try await managedProjects(gisuId: gisuId, keyword: nil, page: 0).projects.last { $0.status == "DRAFT" }
    }

    func createProjectDraft(gisuId: String, productOwnerMemberId: String?) async throws -> String {
        let id = String(nextProjectID)
        nextProjectID += 1
        names[id] = "새 프로젝트"
        stages[id] = "DRAFT"
        return id
    }

    func pmCandidates(gisuId: String, keyword: String?, page: Int) async throws
        -> (people: [OperationsPerson], hasNext: Bool) {
        if isEmpty { return ([], false) }
        let rows = [previewOwner].filter { ($0.display.contains(keyword ?? "") || (keyword ?? "").isEmpty) }
        return (rows, false)
    }

    func permissions(projectId: String) async throws -> [ProjectPermission: MatchingCapability] {
        Dictionary(uniqueKeysWithValues: ProjectPermission.allCases.map { permission in
            let allowed: Bool
            switch permission {
            case .publish: allowed = stages[projectId] == "PENDING_REVIEW"
            case .delete, .submit, .formCreate: allowed = stages[projectId] == "DRAFT"
            case .formEdit, .quota, .edit, .formRead: allowed = true
            default: allowed = stages[projectId] == "IN_PROGRESS"
            }
            return (permission, MatchingCapability(allowed: allowed, reasonCode: nil,
                                                   reason: allowed ? nil : "이 프로젝트 상태에서는 사용할 수 없어요."))
        })
    }

    func editableForm(projectId: String) async throws -> EditableMatchingForm {
        if let form = forms[projectId] { return form }
        if isEmpty { return .init(title: "", description: nil, sections: []) }
        let question = EditableQuestion(questionId: "21", type: "LONG_TEXT", title: "지원 동기",
                                        description: "지원한 이유를 알려주세요.", isRequired: true,
                                        orderNo: "0", options: [])
        return .init(title: "모아 지원서", description: "함께 만들고 싶은 경험을 알려주세요.",
                     sections: [.init(sectionId: "31", type: "COMMON", allowedParts: [],
                                      title: "공통 질문", description: nil, orderNo: "0", questions: [question])])
    }

    func applicants(projectId: String) async throws -> [ApplicantRow] {
        guard !isEmpty else { return [] }
        let statuses = ["SUBMITTED", "APPROVED", "APPROVED", "REJECTED", "SUBMITTED"]
        return zip(previewPeople, statuses).map { person, status in
            ApplicantRow(applicationId: person.memberId, applicant: person, status: decisions[projectId]?[person.memberId] ?? status,
                         matchingRound: .init(id: "101", phase: "FIRST", type: "PLAN_DEVELOPER"),
                         submittedAt: "2026-09-30T05:30:00Z")
        }
    }

    func team(projectId: String) async throws -> OperationsTeam {
        if let team = teams[projectId] { return team }
        if isEmpty { return .init(productOwner: previewOwner, coProductOwners: [], partGroups: []) }
        return .init(productOwner: previewOwner, coProductOwners: [], partGroups: [
            .init(part: "MOBILE_PRODUCT_ENGINEER", members: [previewPeople[1]]),
            .init(part: "WEB_PRODUCT_ENGINEER", members: [previewPeople[2],
                .init(memberId: "101", nickname: "유엠", name: "김유엠", schoolName: "한빛대학교", part: "WEB_PRODUCT_ENGINEER")])
        ])
    }

    func candidates(projectId: String, part: String, page: Int) async throws
        -> (people: [OperationsPerson], hasNext: Bool) {
        (previewPeople.filter { $0.part == part && ["11", "15"].contains($0.memberId) }, false)
    }

    func overview(chapterId: String, adjustment: Bool) async throws -> [OverviewProject] {
        guard !isEmpty else { return [] }
        let mobile = adjustment ? [previewPeople[0], previewPeople[1]] : [previewPeople[1]]
        return [.init(projectId: "1", projectName: "모아", currentMemberCount: String(mobile.count + 1),
                      quota: "4", partQuotaStatus: "RECRUITING", productOwner: previewOwner, coProductOwners: [],
                      parts: [.init(part: "MOBILE_PRODUCT_ENGINEER", currentMemberCount: String(mobile.count),
                                    quota: "2", members: mobile),
                              .init(part: "WEB_PRODUCT_ENGINEER", currentMemberCount: "1", quota: "2",
                                    members: [previewPeople[2]])])]
    }

    func publicStatistics(chapterId: String) async throws -> PublicMatchingStatistics {
        if isEmpty {
            return .init(roundMatchingStatistics: [], schoolMatchingStatistics: [], projectMatchingStatistics: [])
        }
        return .init(roundMatchingStatistics: [.init(phase: "FIRST", matchedMemberCount: "2", availableMemberCount: "5")],
              schoolMatchingStatistics: [.init(schoolId: "1", schoolName: "한빛대", matchedMemberCount: "1", totalMemberCount: "3"),
                                         .init(schoolId: "2", schoolName: "새솔대", matchedMemberCount: "1", totalMemberCount: "2")],
              projectMatchingStatistics: [.init(projectId: "1", projectName: "모아", matchedMemberCount: "2", quota: "4",
                                                rounds: [.init(phase: "FIRST", matchedMemberCount: "2")],
                                                parts: [.init(part: "MOBILE_PRODUCT_ENGINEER", matchedMemberCount: "1", quota: "2"),
                                                        .init(part: "WEB_PRODUCT_ENGINEER", matchedMemberCount: "1", quota: "2")])])
    }

    func applicationStatistics(projectId: String) async throws -> OperationsStatistics {
        if isEmpty { return .init(schoolApplicationStatistics: [], projectRoundStatistics: []) }
        return .init(schoolApplicationStatistics: [.init(schoolId: "1", schoolName: "한빛대", totalMemberCount: "3",
                                                 rounds: [.init(phase: "FIRST", applicantCount: "3")])],
              projectRoundStatistics: [.init(projectId: "1", projectName: "모아",
                                            rounds: [.init(phase: "FIRST", applicantCount: "5")])])
    }

    func perform(_ operation: ProjectOperation, projectId: String) async throws {
        guard names[projectId] != nil else { throw URLError(.resourceUnavailable) }
        switch operation {
        case let .edit(name, description, link):
            names[projectId] = name
            descriptions[projectId] = description
            links[projectId] = link
        case let .form(form, _): forms[projectId] = form
        case let .quotas(quotas): quotasByProject[projectId] = quotas
        case .submit: stages[projectId] = "PENDING_REVIEW"
        case .publish: stages[projectId] = "IN_PROGRESS"
        case .abort: stages[projectId] = "ABORTED"
        case .complete: stages[projectId] = "COMPLETED"
        case .delete:
            names[projectId] = nil
            stages[projectId] = nil
        case let .decision(member, approved):
            decisions[projectId, default: [:]][member] = approved ? "APPROVED" : "REJECTED"
        case let .changeImage(file, slot):
            images[projectId, default: [:]][slot.rawValue] = file.absoluteString
        case let .changeStatus(member, status, _):
            decisions[projectId, default: [:]][member] = status
        case let .add(member, part), let .assign(member, part):
            try await updateRoster(projectId, member: member, part: part)
        case let .remove(member), let .unassign(member):
            try await updateRoster(projectId, member: member, part: nil)
        case let .transfer(member):
            let old = try await team(projectId: projectId)
            guard let owner = (old.coProductOwners + old.partGroups.flatMap(\.members) + previewPeople)
                .first(where: { $0.memberId == member }) else { throw URLError(.resourceUnavailable) }
            teams[projectId] = .init(productOwner: owner, coProductOwners: old.coProductOwners.filter { $0 != owner },
                                     partGroups: old.partGroups)
        }
    }

    private func updateRoster(_ project: String, member: String, part: String?) async throws {
        let old = try await team(projectId: project)
        var groups = Dictionary(uniqueKeysWithValues: old.partGroups.map {
            ($0.part, $0.members.filter { $0.memberId != member })
        })
        if let part, let person = (previewPeople + old.partGroups.flatMap(\.members))
            .first(where: { $0.memberId == member }) {
            groups[part, default: []].append(person)
        }
        teams[project] = .init(productOwner: old.productOwner, coProductOwners: old.coProductOwners,
            partGroups: groups.keys.sorted().map { .init(part: $0, members: groups[$0] ?? []) })
    }
}
