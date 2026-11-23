//
//  ThreadConversationRepository.swift
//  CommunityData
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import CoreNetwork
import Foundation
import Moya

public struct LiveThreadConversationRepository: ThreadConversationRepository {
    private let adapter: MoyaNetworkAdapter
    private let environment: NetworkEnvironment
    private let accessToken: @Sendable () async throws -> String

    /// Supply the adapter and token provider from the same account-bound client.
    public init(
        adapter: MoyaNetworkAdapter, environment: NetworkEnvironment,
        accessToken: @escaping @Sendable () async throws -> String
    ) {
        self.adapter = adapter
        self.environment = environment
        self.accessToken = accessToken
    }

    public func history(
        thread: String, before: String?
    ) async throws -> ThreadPage<ThreadConversationMessage> {
        try ConversationIdentifier.validate(thread)
        if let before { try ConversationIdentifier.validate(before) }
        let query = ConversationHistoryQuery(before: before)
        let page: ConversationHistoryDTO = try await request(
            "/api/v1/community/threads/\(thread)/messages", method: .get,
            task: .requestParameters(
                parameters: query.parameters, encoding: URLEncoding.queryString)
        )
        return ThreadPage(
            values: page.messages.map { $0.model(localBase: environment.baseURL) },
            cursor: page.hasMore ? page.nextBefore : nil)
    }

    public func members(thread: String, query: String) async throws -> [ThreadManagementPerson] {
        try ConversationIdentifier.validate(thread)
        let fields = ConversationMemberQuery(query: String(query.unicodeScalars.prefix(80)))
        let page: ThreadManagementPageResponse = try await request(
            "/api/v1/community/threads/\(thread)/members", method: .get,
            task: .requestParameters(
                parameters: fields.parameters, encoding: URLEncoding.queryString)
        )
        return page.model.items.filter { $0.state == "ACTIVE" }
    }

    public func perform(_ command: ThreadConversationCommand, thread: String) async throws {
        try ConversationIdentifier.validate(thread)
        let transport = ConversationSocket(baseURL: environment.baseURL)
        try await transport.perform(command, thread: thread, token: try await accessToken()) {
            _ = try await accessToken()
        }
    }

    public func observeChanges(
        thread: String, changed: @escaping @Sendable () async -> Void
    ) async throws {
        try ConversationIdentifier.validate(thread)
        let socket = ConversationSocket(baseURL: environment.baseURL)
        try await socket.observe(thread: thread, token: try await accessToken(), changed: changed)
    }

    public func upload(name: String, contentType: String, data: Data) async throws -> String {
        guard (1...10_485_760).contains(data.count), contentType.hasPrefix("image/") else {
            throw ConversationFailure("사진은 한 장에 10MB까지 첨부할 수 있어요.")
        }
        let body = ConversationPrepareUpload(
            fileName: name, contentType: contentType,
            fileSize: data.count)
        let signed: ConversationUploadDTO = try await request(
            "/api/v1/storage/prepare-upload", method: .post, task: .requestJSONEncodable(body)
        )
        guard permitsUpload(signed.uploadUrl), signed.uploadMethod.uppercased() == "PUT",
            !signed.fileId.contains("/"), !signed.fileId.isEmpty
        else {
            throw ConversationFailure("사진 업로드 주소를 확인할 수 없어요.")
        }
        var upload = URLRequest(url: signed.uploadUrl)
        upload.httpMethod = "PUT"
        upload.allHTTPHeaderFields = signed.headers
        let session = URLSession(configuration: .ephemeral)
        defer { session.invalidateAndCancel() }
        let (_, response) = try await session.upload(for: upload, from: data)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw ConversationFailure("사진을 업로드하지 못했어요.")
        }
        let _: EmptyResult = try await request(
            "/api/v1/storage/\(signed.fileId)/confirm",
            method: .post, task: .requestPlain)
        return signed.fileId
    }

    private func permitsUpload(_ url: URL) -> Bool {
        if url.scheme == "https" { return true }
        #if DEBUG
            // The synthetic QA server issues PUT URLs on its own loopback port.
            let base = environment.baseURL
            return base.scheme == "http" && base.host == "127.0.0.1"
                && url.scheme == base.scheme && url.host == base.host && url.port == base.port
        #else
            return false
        #endif
    }

    private func request<T: Codable>(
        _ path: String, method: Moya.Method, task: Moya.Task
    ) async throws -> T {
        let token = try await accessToken()
        try _Concurrency.Task.checkCancellation()
        // Bind this request to its originating account even if the shared session changes.
        let target = ConversationTarget(
            environment: environment, path: path, method: method,
            task: task, token: token)
        let response = try await adapter.request(target)
        _ = try await accessToken()
        try _Concurrency.Task.checkCancellation()
        return try JSONDecoder().decode(APIResponse<T>.self, from: response.data).unwrap()
    }
}

struct ConversationFailure: LocalizedError {
    let errorDescription: String?
    init(_ description: String) { errorDescription = description }
}

enum ConversationIdentifier {
    static func validate(_ value: String) throws {
        guard let parsed = Int64(value), parsed > 0, String(parsed) == value else {
            throw ConversationFailure("대화 식별자를 확인할 수 없어요.")
        }
    }
}

private struct ConversationHistoryQuery {
    let before: String?
    var parameters: [String: String] { before.map { ["before": $0] } ?? [:] }
}

private struct ConversationTarget: BaseTargetType {
    let environment: NetworkEnvironment
    let path: String
    let method: Moya.Method
    let task: Moya.Task
    let token: String
    var headers: [String: String]? {
        ["Authorization": "Bearer " + token, "Content-Type": "application/json"]
    }
}

private struct ConversationPrepareUpload: Encodable {
    let fileName: String
    let contentType: String
    let fileSize: Int
    let category = "POST_IMAGE"
}

private struct ConversationMemberQuery {
    let query: String
    var parameters: [String: String] { ["q": query, "limit": "100"] }
}
