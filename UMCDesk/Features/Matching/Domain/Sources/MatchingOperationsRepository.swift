//
//  MatchingOperationsRepository.swift
//  MatchingDomain
//
//  Created by euijjang97 on 11/22/26.
//

import Foundation

public enum ProjectPermission: String, CaseIterable, Sendable {
    case edit = "canEditInfo"
    case transfer = "canTransferOwnership"
    case delete = "canDelete"
    case formRead = "applicationForm.canRead"
    case formCreate = "applicationForm.canCreate"
    case formEdit = "applicationForm.canEdit"
    case quota = "partQuota.canEdit"
    case submit = "status.canRequestReview"
    case publish = "status.canPublish"
    case complete = "status.canComplete"
    case abort = "status.canAbort"
    case applicants = "application.canReadList"
    case decide = "application.canDecide"
    case team = "member.canRead"
    case add = "member.canCreate"
    case remove = "member.canDelete"
    case assign = "member.canAssign"
    case unassign = "member.canUnassign"
    case statistics = "statistics.canRead"
}

public enum ProjectImageSlot: String, Sendable {
    case thumbnail = "PROJECT_THUMBNAIL"
    case logo = "PROJECT_LOGO"
}

public enum MatchingFormSaveError: Error, Sendable {
    case answeredSectionDeletion(message: String)
}

public enum ProjectOperation: Sendable {
    case changeImage(file: URL, slot: ProjectImageSlot)
    case edit(name: String, description: String, link: String)
    case form(EditableMatchingForm, confirmDeletion: Bool)
    case quotas([String: Int])
    case submit, publish, complete, delete
    case abort(reason: String)
    case decision(applicationId: String, approved: Bool)
    case add(memberId: String, part: String)
    case remove(memberId: String)
    case changeStatus(memberId: String, status: String, reason: String)
    case transfer(memberId: String)
    case assign(memberId: String, part: String)
    case unassign(memberId: String)
}

public protocol MatchingOperationsRepository: Sendable {
    func managedProjects(gisuId: String, keyword: String?, page: Int) async throws
        -> (projects: [ManagedProject], hasNext: Bool)
    func latestDraft(gisuId: String) async throws -> ManagedProject?
    func createProjectDraft(gisuId: String, productOwnerMemberId: String?) async throws -> String
    func pmCandidates(gisuId: String, keyword: String?, page: Int) async throws
        -> (people: [OperationsPerson], hasNext: Bool)
    func permissions(projectId: String) async throws -> [ProjectPermission: MatchingCapability]
    func editableForm(projectId: String) async throws -> EditableMatchingForm
    func applicants(projectId: String) async throws -> [ApplicantRow]
    func team(projectId: String) async throws -> OperationsTeam
    func candidates(projectId: String, part: String, page: Int) async throws
        -> (people: [OperationsPerson], hasNext: Bool)
    func overview(chapterId: String, adjustment: Bool) async throws -> [OverviewProject]
    func publicStatistics(chapterId: String) async throws -> PublicMatchingStatistics
    func applicationStatistics(projectId: String) async throws -> OperationsStatistics
    func perform(_ operation: ProjectOperation, projectId: String) async throws
}
