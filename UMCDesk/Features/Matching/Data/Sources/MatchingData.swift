//
//  MatchingData.swift
//  MatchingData
//
//  Created by euijjang97 on 11/22/26.
//

import CoreNetwork
import Foundation
import MatchingDomain
import Moya
import UMCFoundation

public struct LiveMatchingRepository: MatchingRepository {
    let client: NetworkClient
    private let adapter: MoyaNetworkAdapter
    private let environment: NetworkEnvironment
    private let projectsPath = "/api/v1/projects"

    public init(adapter: MoyaNetworkAdapter, client: NetworkClient, environment: NetworkEnvironment) {
        self.client = client
        self.adapter = adapter
        self.environment = environment
    }

    public func activeGisuId() async throws -> String {
        let response: MatchingGisuDTO = try await get("/api/v1/gisu/active")
        return response.gisuId
    }

    public func matchingChapterId(gisuId: String) async throws -> String? {
        let affiliation: MatchingAffiliationDTO = try await get(
            "\(projectsPath)/matching-affiliation/me", query: [.init(name: "gisuId", value: gisuId)]
        )
        guard affiliation.gisuId == gisuId else { throw URLError(.cannotParseResponse) }
        return affiliation.matchingChapter?.id
    }

    public func organization(gisuId: String) async throws -> MatchingOrganization {
        let response: MatchingOrganizationsDTO = try await get("/api/v2/gisu", query: [
            .init(name: "id", value: gisuId),
            .init(name: "includeChapter", value: "true"),
            .init(name: "includeSchool", value: "true")
        ])
        guard let organization = response.gisus.first(where: { $0.gisuId == gisuId }) else {
            throw URLError(.cannotParseResponse)
        }
        return MatchingOrganization(
            chapters: organization.chapters.map { .init(id: $0.chapterId, name: $0.chapterName) },
            schools: organization.schools.map { .init(id: $0.schoolId, name: $0.schoolName) }
        )
    }

    public func projects(
        gisuId: String, keyword: String?, page: Int
    ) async throws -> MatchingProjectPage {
        try await projects(
            gisuId: gisuId, keyword: keyword, page: page, part: nil, quotaStatus: nil, schoolId: nil, chapterId: nil
        )
    }

    public func projects(
        gisuId: String, keyword: String?, page: Int, part: String?,
        quotaStatus: String?, schoolId: String?, chapterId: String?
    ) async throws -> MatchingProjectPage {
        let response: MatchingProjectPageDTO = try await get(projectsPath, query: [
            .init(name: "gisuId", value: gisuId),
            .init(name: "keyword", value: keyword),
            .init(name: "page", value: String(page)),
            .init(name: "size", value: "3"),
            .init(name: "parts", value: part),
            .init(name: "partQuotaStatus", value: quotaStatus),
            .init(name: "schoolIds", value: schoolId),
            .init(name: "chapterId", value: chapterId)
        ])
        return response.model
    }

    public func project(id: String) async throws -> MatchingProject {
        let response: MatchingProjectDTO = try await get("\(projectsPath)/\(id)")
        return response.model
    }

    public func applicationCapability(projectId: String) async throws -> MatchingCapability {
        let response: MatchingAccessListDTO = try await get("\(projectsPath)/permissions", query: [
            .init(name: "ids", value: projectId)
        ])
        guard let access = response.projects.first(where: { $0.projectId == projectId && $0.exists })
        else { throw URLError(.resourceUnavailable) }
        return access.application.canCreate.model
    }

    public func rounds(chapterId: String?) async throws -> [MatchingRound] {
        let response: [MatchingRoundDTO] = try await get("/api/v1/project/matching-rounds", query: [
            .init(name: "chapterId", value: chapterId)
        ])
        return response.map(\.model)
    }

    public func myApplications(gisuId: String, drafts: Bool) async throws -> [MatchingApplication] {
        let response: [MatchingApplicationDTO] = try await get("\(projectsPath)/me/applications", query: [
            .init(name: "gisuId", value: gisuId), .init(name: "status", value: drafts ? "DRAFT" : nil)
        ])
        return response.map(\.model)
    }

    public func applicationForm(projectId: String) async throws -> MatchingForm {
        let response: MatchingFormDTO = try await get("\(projectsPath)/\(projectId)/application-form")
        return response.model
    }

    public func application(
        projectId: String, applicationId: String
    ) async throws -> MatchingApplicationDetail {
        let response: MatchingApplicationDetailDTO = try await get(
            "\(projectsPath)/\(projectId)/applications/\(applicationId)"
        )
        return response.model
    }

    public func createApplication(projectId: String, roundId: String) async throws -> String {
        let response: MatchingApplicationStatusDTO = try await mutation(
            "\(projectsPath)/\(projectId)/applications", method: .post,
            body: CreateApplicationBody(matchingRoundId: try numericId(roundId))
        )
        return response.applicationId
    }

    public func saveAnswers(
        projectId: String, applicationId: String, answers: [MatchingAnswer]
    ) async throws {
        let body = try UpdateAnswersBody(answers: answers.map { answer in
            try UpdateAnswersBody.Answer(
                questionId: numericId(answer.questionId), textValue: answer.textValue,
                selectedOptionIds: answer.selectedOptionIds.map(numericId), fileIds: answer.fileIds
            )
        })
        try await send("\(projectsPath)/\(projectId)/applications/\(applicationId)", method: .put, body: body)
    }

    public func submitApplication(projectId: String, applicationId: String) async throws {
        try await send("\(projectsPath)/\(projectId)/applications/\(applicationId)/submit", method: .post)
    }

    public func cancelApplication(projectId: String, applicationId: String) async throws {
        try await send("\(projectsPath)/\(projectId)/applications/\(applicationId)", method: .delete)
    }

    public func uploadPortfolio(file: URL) async throws -> String {
        guard file.pathExtension.lowercased() == "pdf" else { throw CocoaError(.fileReadCorruptFile) }
        return try await uploadMatchingFile(file: file, contentType: "application/pdf", category: "PORTFOLIO")
    }

    func uploadMatchingFile(file: URL, contentType: String, category: String) async throws -> String {
        let scoped = file.startAccessingSecurityScopedResource()
        defer { if scoped { file.stopAccessingSecurityScopedResource() } }
        let size = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize
        guard file.isFileURL, let size, size > 0
        else { throw CocoaError(.fileReadUnsupportedScheme) }
        let upload: MatchingUploadDTO = try await mutation(
            "/api/v1/storage/prepare-upload", method: .post,
            body: PrepareMatchingUploadBody(
                fileName: file.lastPathComponent, fileSize: size, contentType: contentType, category: category
            )
        )
        guard let destination = URL(string: upload.uploadUrl), destination.scheme == "https",
              destination.host != nil, upload.uploadMethod.uppercased() == "PUT"
        else { throw URLError(.badServerResponse) }
        var request = URLRequest(url: destination)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = upload.headers
        try _Concurrency.Task.checkCancellation()
        if let expected = MatchingOperationSession.generation, await client.sessionGeneration != expected {
            throw CancellationError()
        }
        let (_, response) = try await URLSession.shared.upload(for: request, fromFile: file)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        try await send("/api/v1/storage/\(upload.fileId)/confirm", method: .post)
        return upload.fileId
    }

    private func numericId(_ value: String) throws -> Int64 {
        guard let id = Int64(value), id > 0 else { throw URLError(.badURL) }
        return id
    }

    func get<T: Codable>(_ path: String, query: [URLQueryItem] = []) async throws -> T {
        let parameters = MatchingQuery(items: query).parameters
        return try await request(path, method: .get, task: parameters.isEmpty
            ? .requestPlain : .requestParameters(parameters: parameters, encoding: URLEncoding.default))
    }

    func mutation<Body: Encodable, T: Codable>(
        _ path: String, method: Moya.Method, body: Body
    ) async throws -> T {
        try await request(path, method: method, task: .requestJSONEncodable(body))
    }

    func send<Body: Encodable>(_ path: String, method: Moya.Method, body: Body) async throws {
        let _: EmptyResult = try await request(path, method: method, task: .requestJSONEncodable(body))
    }

    func send(_ path: String, method: Moya.Method, query: [URLQueryItem] = []) async throws {
        let parameters = MatchingQuery(items: query).parameters
        let task: Moya.Task = parameters.isEmpty ? .requestPlain
            : .requestParameters(parameters: parameters, encoding: URLEncoding.queryString)
        let _: EmptyResult = try await request(path, method: method, task: task)
    }

    private func request<T: Codable>(
        _ path: String, method: Moya.Method, task: Moya.Task
    ) async throws -> T {
        try _Concurrency.Task.checkCancellation()
        let generation = await client.sessionGeneration
        if let expected = MatchingOperationSession.generation, generation != expected {
            throw CancellationError()
        }
        let target = MatchingTarget(environment: environment, path: path, method: method, task: task)
        do {
            let result = try await adapter.request(target)
            if result.statusCode == 204, result.data.isEmpty, let empty = EmptyResult() as? T {
                return empty
            }
            return try JSONDecoder().decode(APIResponse<T>.self, from: result.data).unwrap()
        } catch let failure as NetworkError {
            switch failure {
            case .unauthorized, .noRefreshToken, .tokenRefreshFailed, .maxRetryExceeded:
                try await client.invalidateSession(generation: generation)
            default:
                break
            }
            if case .requestFailed(_, let data) = failure, let data, let error = try? JSONDecoder().decode(APIResponse<EmptyResult>.self, from: data),
               !error.isSuccess {
                throw RepositoryError.serverError(code: error.code, message: error.message)
            }
            throw failure
        }
    }
}

enum MatchingOperationSession {
    @TaskLocal static var generation: UUID?
}

private struct MatchingTarget: BaseTargetType {
    let environment: NetworkEnvironment
    let path: String
    let method: Moya.Method
    let task: Moya.Task
}

private struct MatchingQuery {
    let items: [URLQueryItem]
    var parameters: [String: String] {
        var values = [String: String]()
        for item in items { values[item.name] = item.value }
        return values
    }
}

private struct CreateApplicationBody: Encodable {
    let matchingRoundId: Int64
}

private struct UpdateAnswersBody: Encodable {
    struct Answer: Encodable {
        let questionId: Int64
        let textValue: String?
        let selectedOptionIds: [Int64]
        let fileIds: [String]
    }
    let answers: [Answer]
}

private struct PrepareMatchingUploadBody: Encodable {
    let fileName: String
    let fileSize: Int
    let contentType: String
    let category: String
}
