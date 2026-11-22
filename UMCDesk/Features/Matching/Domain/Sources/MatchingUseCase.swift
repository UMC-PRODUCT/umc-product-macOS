//
//  MatchingUseCase.swift
//  MatchingDomain
//
//  Created by euijjang97 on 11/22/26.
//

import Foundation

public protocol MatchingUseCase: MatchingActions {
    func personalCards(gisuId: String) async throws -> [MatchingApplication]
}

public struct DefaultMatchingUseCase: MatchingUseCase {
    private let repository: any MatchingRepository

    public init(repository: any MatchingRepository) {
        self.repository = repository
    }

    public func personalCards(gisuId: String) async throws -> [MatchingApplication] {
        async let drafts = repository.myApplications(gisuId: gisuId, drafts: true)
        async let submitted = repository.myApplications(gisuId: gisuId, drafts: false)
        let (saved, applied) = try await (drafts, submitted)
        var identifiers = Set<String>()
        return (applied + saved).filter { card in
            let key = card.applicationId.map { "application-" + $0 } ?? "assigned-" + card.projectId
            return identifiers.insert(key).inserted
        }
    }

    public func activeGisuId() async throws -> String {
        try await repository.activeGisuId()
    }

    public func projects(gisuId: String, keyword: String?, page: Int) async throws -> MatchingProjectPage {
        try await repository.projects(gisuId: gisuId, keyword: keyword, page: page)
    }

    public func projects(
        gisuId: String, keyword: String?, page: Int, part: String?,
        quotaStatus: String?, schoolId: String?, chapterId: String?
    ) async throws -> MatchingProjectPage {
        try await repository.projects(
            gisuId: gisuId, keyword: keyword, page: page, part: part,
            quotaStatus: quotaStatus, schoolId: schoolId, chapterId: chapterId
        )
    }

    public func matchingChapterId(gisuId: String) async throws -> String? {
        try await repository.matchingChapterId(gisuId: gisuId)
    }

    public func organization(gisuId: String) async throws -> MatchingOrganization {
        try await repository.organization(gisuId: gisuId)
    }

    public func uploadPortfolio(file: URL) async throws -> String {
        try await repository.uploadPortfolio(file: file)
    }

    public func project(id: String) async throws -> MatchingProject {
        try await repository.project(id: id)
    }

    public func publishedTeam(projectId: String) async throws -> OperationsTeam? {
        try await repository.publishedTeam(projectId: projectId)
    }

    public func applicationCapability(projectId: String) async throws -> MatchingCapability {
        try await repository.applicationCapability(projectId: projectId)
    }

    public func rounds(chapterId: String?) async throws -> [MatchingRound] {
        try await repository.rounds(chapterId: chapterId)
    }

    public func myApplications(gisuId: String, drafts: Bool) async throws -> [MatchingApplication] {
        try await repository.myApplications(gisuId: gisuId, drafts: drafts)
    }

    public func applicationForm(projectId: String) async throws -> MatchingForm {
        try await repository.applicationForm(projectId: projectId)
    }

    public func application(projectId: String, applicationId: String) async throws -> MatchingApplicationDetail {
        try await repository.application(projectId: projectId, applicationId: applicationId)
    }

    public func createApplication(projectId: String, roundId: String) async throws -> String {
        try await repository.createApplication(projectId: projectId, roundId: roundId)
    }

    public func saveAnswers(projectId: String, applicationId: String, answers: [MatchingAnswer]) async throws {
        try await repository.saveAnswers(
            projectId: projectId, applicationId: applicationId, answers: answers
        )
    }

    public func submitApplication(projectId: String, applicationId: String) async throws {
        try await repository.submitApplication(projectId: projectId, applicationId: applicationId)
    }

    public func cancelApplication(projectId: String, applicationId: String) async throws {
        try await repository.cancelApplication(projectId: projectId, applicationId: applicationId)
    }

    public func managedProjects(gisuId: String, keyword: String?, page: Int) async throws
        -> (projects: [ManagedProject], hasNext: Bool) {
        try await repository.managedProjects(gisuId: gisuId, keyword: keyword, page: page)
    }

    public func latestDraft(gisuId: String) async throws -> ManagedProject? {
        try await repository.latestDraft(gisuId: gisuId)
    }

    public func createProjectDraft(
        gisuId: String, productOwnerMemberId: String?
    ) async throws -> String {
        try await repository.createProjectDraft(gisuId: gisuId, productOwnerMemberId: productOwnerMemberId)
    }

    public func pmCandidates(gisuId: String, keyword: String?, page: Int) async throws
        -> (people: [OperationsPerson], hasNext: Bool) {
        try await repository.pmCandidates(gisuId: gisuId, keyword: keyword, page: page)
    }

    public func permissions(projectId: String) async throws -> [ProjectPermission: MatchingCapability] {
        try await repository.permissions(projectId: projectId)
    }

    public func editableForm(projectId: String) async throws -> EditableMatchingForm {
        try await repository.editableForm(projectId: projectId)
    }

    public func applicants(projectId: String) async throws -> [ApplicantRow] {
        try await repository.applicants(projectId: projectId)
    }

    public func team(projectId: String) async throws -> OperationsTeam {
        try await repository.team(projectId: projectId)
    }

    public func candidates(projectId: String, part: String, page: Int) async throws
        -> (people: [OperationsPerson], hasNext: Bool) {
        try await repository.candidates(projectId: projectId, part: part, page: page)
    }

    public func overview(chapterId: String, adjustment: Bool) async throws -> [OverviewProject] {
        try await repository.overview(chapterId: chapterId, adjustment: adjustment)
    }

    public func publicStatistics(chapterId: String) async throws -> PublicMatchingStatistics {
        try await repository.publicStatistics(chapterId: chapterId)
    }

    public func applicationStatistics(projectId: String) async throws -> OperationsStatistics {
        try await repository.applicationStatistics(projectId: projectId)
    }

    public func perform(_ operation: ProjectOperation, projectId: String) async throws {
        try await repository.perform(operation, projectId: projectId)
    }

    public func canManageSchedule(chapterId: String) async throws -> Bool {
        try await repository.canManageSchedule(chapterId: chapterId)
    }

    public func saveSchedule(chapterId: String, type: String, rounds: [MatchingRoundChange]) async throws {
        try await repository.saveSchedule(chapterId: chapterId, type: type, rounds: rounds)
    }

    public func deleteSchedule(chapterId: String, type: String) async throws {
        try await repository.deleteSchedule(chapterId: chapterId, type: type)
    }

    public func autoDecide(roundId: String) async throws {
        try await repository.autoDecide(roundId: roundId)
    }
}
