//
//  MatchingDesignPreview.swift
//  MatchingPresentation
//
//  Created by euijjang97 on 11/22/26.
//

import Foundation
import MatchingDomain
import SwiftUI

@MainActor
public enum MatchingDesignPreview {
    public static func makeUseCase(isEmpty: Bool = false) -> any MatchingUseCase {
        DefaultMatchingUseCase(repository: MatchingPreviewRepository(isEmpty: isEmpty))
    }

    #if DEBUG
    @ViewBuilder public static func view(
        destination: MatchingDestination = .explore, showsDetail: Bool = false
    ) -> some View {
        let useCase = DefaultMatchingUseCase(repository: MatchingPreviewRepository())
        if showsDetail {
            let project = MatchingProject(id: "1", name: "모아", description: nil,
                thumbnailImageUrl: nil, productOwner: nil, partQuotas: [], partQuotaStatus: nil,
                logoImageUrl: nil, externalLink: nil, applicationFormId: nil)
            MatchingView(repository: useCase, gisuId: "10", previewProject: project)
        } else {
            MatchingView(repository: useCase, gisuId: "10", initialDestination: destination, applicantParts: ["WEB"])
        }
    }
    #endif
}

actor MatchingPreviewRepository: MatchingRepository {
    private let owner = MatchingMember(memberId: "1", nickname: "김모아",
                                      name: nil, schoolName: "한빛대학교")
    private let roundId = "101"
    private var savedAnswers: [String: [MatchingAnswer]] = [:]
    private var drafts: Set<String> = ["2"]
    private var submitted: Set<String> = ["1", "3"]

    var names = ["1": "모아", "2": "바로", "3": "사이"]
    var stages = ["1": "IN_PROGRESS", "2": "PENDING_REVIEW", "3": "DRAFT"]
    var descriptions = ["1": "취향을 모으고, 나다운 선택을 발견하는 쇼핑.",
                        "2": "우리 동네의 작은 소식을 더 가깝게.", "3": "함께 고르는 즐거움, 함께하는 소비."]
    var links: [String: String] = [:]
    var quotasByProject: [String: [String: Int]] = [:]
    var forms: [String: EditableMatchingForm] = [:]
    var decisions: [String: [String: String]] = [:]
    var teams: [String: OperationsTeam] = [:]
    var images: [String: [String: String]] = [:]
    var nextProjectID = 4
    private var customRounds: [MatchingRound]?

    let isEmpty: Bool

    init(isEmpty: Bool = false) {
        self.isEmpty = isEmpty
        if isEmpty {
            names = [:]
            stages = [:]
            descriptions = [:]
            drafts = []
            submitted = []
            customRounds = []
        }
    }

    private var projects: [MatchingProject] {
        names.keys.sorted().map { id in
            let name = names[id] ?? ""
            let description = descriptions[id]
            let quotas = ["MOBILE_PRODUCT_ENGINEER", "WEB_PRODUCT_ENGINEER", "DESIGN"]
                .enumerated().map { index, part in
                    MatchingQuota(part: part, currentCount: index == 1 ? "0" : "1",
                                  quota: String(quotasByProject[id]?[part] ?? (index == 2 ? 1 : 2)),
                                  status: index == 2 ? "COMPLETED" : "RECRUITING")
                }
            return MatchingProject(id: id, name: name, description: description,
                thumbnailImageUrl: images[id]?["PROJECT_THUMBNAIL"], productOwner: owner, partQuotas: quotas,
                partQuotaStatus: "RECRUITING", logoImageUrl: images[id]?["PROJECT_LOGO"], externalLink: links[id],
                applicationFormId: "11")
        }
    }

    func activeGisuId() async throws -> String { "10" }
    func matchingChapterId(gisuId: String) async throws -> String? { "1" }

    func organization(gisuId: String) async throws -> MatchingOrganization {
        .init(chapters: [.init(id: "1", name: "서울 지부")], schools: [.init(id: "1", name: "한빛대학교")])
    }

    func projects(gisuId: String, keyword: String?, page: Int) async throws -> MatchingProjectPage {
        try await projects(gisuId: gisuId, keyword: keyword, page: page, part: nil,
                           quotaStatus: nil, schoolId: nil, chapterId: nil)
    }

    func projects(gisuId: String, keyword: String?, page: Int, part: String?, quotaStatus: String?,
                  schoolId: String?, chapterId: String?) async throws -> MatchingProjectPage {
        let filtered = projects.filter { project in
            (keyword.map { project.name.contains($0) } ?? true)
                && (quotaStatus == nil || project.partQuotaStatus == quotaStatus)
                && (part == nil || project.partQuotas.contains { $0.part == part })
        }
        return .init(content: page == 0 ? filtered : [], hasNext: false,
                     totalElements: String(filtered.count))
    }

    func project(id: String) async throws -> MatchingProject {
        guard let project = projects.first(where: { $0.id == id }) else { throw unavailable }
        return project
    }

    func rounds(chapterId: String?) async throws -> [MatchingRound] {
        if let customRounds { return customRounds.filter { chapterId == nil || $0.chapterId == chapterId } }
        func instant(_ offset: TimeInterval) -> String {
            Calendar.current.startOfDay(for: .now).addingTimeInterval(offset).ISO8601Format()
        }
        return [.init(id: roundId, name: "기획–개발자 1차 매칭", type: "PLAN_DEVELOPER",
                      phase: "FIRST", chapterId: "1", startsAt: instant(-86400),
                      endsAt: instant(86400 * 6), decisionDeadline: instant(86400 * 8),
                      resultPublishAt: instant(86400 * 9))]
    }

    func applicationCapability(projectId: String) async throws -> MatchingCapability {
        .init(allowed: true, reasonCode: nil, reason: nil)
    }

    func myApplications(gisuId: String, drafts: Bool) async throws -> [MatchingApplication] {
        let ids = drafts ? self.drafts : submitted
        return projects.filter { ids.contains($0.id) }.map { project in
            .init(applicationId: project.id == "3" ? nil : project.id, projectId: project.id,
                  project: .init(name: project.name, thumbnailImageUrl: nil,
                                 productOwner: owner, partQuotas: project.partQuotas),
                  matchingRound: .init(id: roundId, type: "PLAN_DEVELOPER", phase: "FIRST"),
                  status: drafts ? "DRAFT" : (project.id == "3" ? "APPROVED" : nil))
        }
    }

    private func sections(for id: String) -> [MatchingSection] {
        let questions = [("1", "지원 동기", "LONG_TEXT"), ("2", "관련 경험", "LONG_TEXT"),
                         ("3", "포트폴리오", "PORTFOLIO")].map { key, title, type in
            let saved = savedAnswers[id]?.first { $0.questionId == key }
            let seed = id == "1" && key == "1" ? "사용자의 취향을 발견하는 경험을 만들고 싶어요." : nil
            let text = savedAnswers[id] == nil ? seed : saved?.textValue
            return MatchingQuestion(questionId: key, type: type, title: title, description: nil,
                isRequired: key != "3", options: [],
                answer: text.map { .init(textValue: $0, selectedOptions: [], files: []) })
        }
        return [.init(sectionId: "1", type: "COMMON", title: "공통 질문",
                      description: nil, allowedParts: nil, questions: questions)]
    }

    func applicationForm(projectId: String) async throws -> MatchingForm {
        .init(title: "프로젝트 지원서", description: nil, sections: sections(for: projectId))
    }

    func application(projectId: String, applicationId: String) async throws -> MatchingApplicationDetail {
        let stamp = Calendar.current.startOfDay(for: .now).addingTimeInterval(-3600).ISO8601Format()
        let draft = drafts.contains(projectId)
        return .init(applicationId: applicationId, status: draft ? "DRAFT" : (projectId == "3" ? "APPROVED" : nil),
                     formResponse: .init(sections: sections(for: projectId), lastSavedAt: stamp),
                     submittedAt: draft ? nil : stamp)
    }

    func createApplication(projectId: String, roundId: String) async throws -> String {
        drafts.insert(projectId)
        return projectId
    }

    func saveAnswers(projectId: String, applicationId: String, answers: [MatchingAnswer]) async throws {
        savedAnswers[applicationId] = answers
    }

    func submitApplication(projectId: String, applicationId: String) async throws {
        drafts.remove(projectId)
        submitted.insert(projectId)
    }

    func cancelApplication(projectId: String, applicationId: String) async throws {
        drafts.remove(projectId)
        submitted.remove(projectId)
    }

    func canManageSchedule(chapterId: String) async throws -> Bool { chapterId == "1" }

    func saveSchedule(chapterId: String, type: String, rounds changes: [MatchingRoundChange]) async throws {
        let previous = try await rounds(chapterId: nil)
        customRounds = previous.filter { $0.chapterId != chapterId || $0.type != type }
            + changes.enumerated().map { index, change in
                let old = previous.first { $0.chapterId == chapterId && $0.type == type && $0.phase == change.phase }
                return MatchingRound(id: old?.id ?? type + "-" + String(index), name: change.name,
                    type: type, phase: change.phase, chapterId: chapterId, startsAt: change.startsAt,
                    endsAt: change.endsAt, decisionDeadline: change.decisionDeadline,
                    resultPublishAt: change.resultPublishAt, description: change.description)
            }
    }

    func deleteSchedule(chapterId: String, type: String) async throws {
        customRounds = try await rounds(chapterId: nil).filter { $0.chapterId != chapterId || $0.type != type }
    }

    func autoDecide(roundId: String) async throws {
        customRounds = try await rounds(chapterId: nil).map { round in
            guard round.id == roundId else { return round }
            return .init(id: round.id, name: round.name, type: round.type, phase: round.phase,
                chapterId: round.chapterId, startsAt: round.startsAt, endsAt: round.endsAt,
                decisionDeadline: round.decisionDeadline, resultPublishAt: round.resultPublishAt,
                description: round.description, autoDecisionExecutedAt: Date.now.ISO8601Format())
        }
    }

    func publishedTeam(projectId: String) async throws -> OperationsTeam? {
        guard names[projectId] != nil else { return nil }
        return try await team(projectId: projectId)
    }

    private var unavailable: URLError { URLError(.resourceUnavailable) }
    func uploadPortfolio(file: URL) async throws -> String { UUID().uuidString }


}

#if DEBUG
#Preview("Light") { MatchingDesignPreview.view().preferredColorScheme(.light) }
#Preview("Dark") { MatchingDesignPreview.view().preferredColorScheme(.dark) }
#endif
