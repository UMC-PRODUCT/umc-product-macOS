//
//  MatchingDomain.swift
//  MatchingDomain
//
//  Created by euijjang97 on 11/22/26.
//

import Foundation

public struct MatchingFilterOption: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public struct MatchingOrganization: Equatable, Sendable {
    public let chapters: [MatchingFilterOption]
    public let schools: [MatchingFilterOption]

    public init(chapters: [MatchingFilterOption], schools: [MatchingFilterOption]) {
        self.chapters = chapters
        self.schools = schools
    }
}

public struct MatchingAnswer: Equatable, Sendable {
    public let questionId: String
    public var textValue: String?
    public var selectedOptionIds: [String]
    public var fileIds: [String]

    public init(
        questionId: String, textValue: String? = nil,
        selectedOptionIds: [String] = [], fileIds: [String] = []
    ) {
        self.questionId = questionId
        self.textValue = textValue
        self.selectedOptionIds = selectedOptionIds
        self.fileIds = fileIds
    }
}

public protocol MatchingActions: MatchingOperationsRepository, MatchingScheduleRepository, Sendable {
    func activeGisuId() async throws -> String
    func projects(gisuId: String, keyword: String?, page: Int) async throws -> MatchingProjectPage
    func projects(
        gisuId: String, keyword: String?, page: Int, part: String?,
        quotaStatus: String?, schoolId: String?, chapterId: String?
    ) async throws -> MatchingProjectPage
    func matchingChapterId(gisuId: String) async throws -> String?
    func organization(gisuId: String) async throws -> MatchingOrganization
    func uploadPortfolio(file: URL) async throws -> String
    func project(id: String) async throws -> MatchingProject
    func publishedTeam(projectId: String) async throws -> OperationsTeam?
    func applicationCapability(projectId: String) async throws -> MatchingCapability
    func rounds(chapterId: String?) async throws -> [MatchingRound]
    func myApplications(gisuId: String, drafts: Bool) async throws -> [MatchingApplication]
    func applicationForm(projectId: String) async throws -> MatchingForm
    func application(projectId: String, applicationId: String) async throws -> MatchingApplicationDetail
    func createApplication(projectId: String, roundId: String) async throws -> String
    func saveAnswers(projectId: String, applicationId: String, answers: [MatchingAnswer]) async throws
    func submitApplication(projectId: String, applicationId: String) async throws
    func cancelApplication(projectId: String, applicationId: String) async throws
}

public protocol MatchingRepository: MatchingActions {}
