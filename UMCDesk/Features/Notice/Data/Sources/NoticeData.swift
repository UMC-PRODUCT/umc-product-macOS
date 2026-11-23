//  NoticeData.swift
//  NoticeData
//
//  Created by euijjang97 on 11/23/26.

import CoreNetwork
import Foundation
import Moya
import NoticeDomain
import UMCFoundation
import UniformTypeIdentifiers

public struct LiveNoticeRepository: NoticeRepository {
    private let adapter: MoyaNetworkAdapter
    private let environment: NetworkEnvironment
    private let noticesPath = "/api/v1/notices"

    public init(adapter: MoyaNetworkAdapter, environment: NetworkEnvironment) {
        self.adapter = adapter
        self.environment = environment
    }

    public func activeGisu() async throws -> String {
        let value: ActiveGisu = try await request("/api/v1/gisu/active")
        return value.gisuId
    }

    public func organization(gisu: String) async throws -> NoticeOrganization? {
        let query = OrganizationQuery(id: gisu)
        let value: OrganizationResponse = try await request(
            "/api/v2/gisu",
            task: .requestParameters(
                parameters: query.parameters, encoding: URLEncoding.queryString)
        )
        return value.gisus.first { $0.gisuId == gisu }
    }

    public func notices(
        gisu: String, tab: String, keyword: String, part: String?, page: Int
    ) async throws -> NoticePage {
        let query = ListQuery(gisu: gisu, tab: tab, keyword: keyword, part: part, page: page)
        return try await request(
            noticesPath + (keyword.isEmpty ? "" : "/search"),
            task: .requestParameters(
                parameters: query.parameters,
                encoding: URLEncoding.queryString))
    }

    public func detail(id: String) async throws -> NoticeEntry {
        try await request(noticesPath + "/" + id)
    }

    public func create(_ draft: NoticeDraft, gisu: String) async throws -> String {
        guard let gisuId = Int64(gisu) else { throw URLError(.cannotParseResponse) }
        let target = TargetBody(
            targetGisuId: gisuId,
            targetChapterId: try draft.chapterId.map(numericID),
            targetSchoolId: try draft.schoolId.map(numericID),
            targetParts: draft.parts,
            targetNoticeTab: draft.noticeTab)
        let body = CreateBody(
            title: draft.title, content: draft.content,
            shouldNotify: draft.shouldNotify, mustRead: draft.mustRead,
            targetInfo: target)
        let result: CreatedNotice = try await request(
            noticesPath, method: .post,
            task: .requestJSONEncodable(body))
        return result.noticeId
    }

    public func attachLinks(_ links: [String], id: String) async throws {
        try await change(id + "/links", body: LinksBody(links: links))
    }

    public func uploadImage(file: URL) async throws -> String {
        let securityScoped = file.startAccessingSecurityScopedResource()
        defer { if securityScoped { file.stopAccessingSecurityScopedResource() } }
        let size = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
        let ext = file.pathExtension.lowercased()
        guard (1...10_485_760).contains(size),
            ["jpg", "jpeg", "png", "webp", "gif", "heic"].contains(ext),
            let mime = UTType(filenameExtension: ext)?.preferredMIMEType
        else {
            throw ImageUploadError.invalidFile
        }
        let body = UploadBody(fileName: file.lastPathComponent, contentType: mime, fileSize: size)
        let ticket: UploadTicket = try await request(
            "/api/v1/storage/prepare-upload",
            method: .post, task: .requestJSONEncodable(body))
        guard let url = URL(string: ticket.uploadUrl),
            url.scheme == "https" || (url.scheme == "http" && url.host == "127.0.0.1"),
            ticket.uploadMethod.uppercased() == "PUT"
        else { throw URLError(.badURL) }
        var upload = URLRequest(url: url)
        upload.httpMethod = "PUT"
        upload.allHTTPHeaderFields = ticket.headers
        let (_, response) = try await URLSession.shared.upload(for: upload, fromFile: file)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode)
        else { throw URLError(.badServerResponse) }
        try await validate("/api/v1/storage/" + ticket.fileId + "/confirm", method: .post)
        return ticket.fileId
    }

    public func attachImages(_ files: [String], id: String) async throws {
        try await change(id + "/images", body: ImagesBody(imageIds: files))
    }

    public func addPoll(_ poll: NoticePollDraft, id: String) async throws {
        let body = PollBody(
            title: poll.title, isAnonymous: poll.isAnonymous,
            allowMultipleChoice: poll.allowMultipleChoice,
            startsAt: Date.now.ISO8601Format(), endsAtExclusive: poll.endsAt.ISO8601Format(),
            options: poll.options)
        try await change(id + "/votes", body: body)
    }

    public func vote(options: [String], replacing: Bool, id: String) async throws {
        let ids = try options.map { option in
            guard let number = Int64(option) else { throw URLError(.cannotParseResponse) }
            return number
        }
        try await change(
            id + "/votes/responses", method: replacing ? .put : .post,
            body: VoteBody(optionIds: ids))
    }

    public func permissions(id: String) async throws -> Set<String> {
        let query = PermissionQuery(resourceId: id)
        let result: NoticePermissionResponse = try await request(
            "/api/v1/authorization/resource-permission",
            task: .requestParameters(
                parameters: query.parameters, encoding: URLEncoding.queryString)
        )
        return Set(result.permissions.filter(\.hasPermission).map(\.permissionType))
    }

    public func edit(id: String, title: String, content: String, pinned: Bool) async throws {
        try await change(
            id, method: .patch,
            body: EditBody(title: title, content: content, mustRead: pinned))
    }

    public func delete(id: String) async throws {
        try await validate(noticesPath + "/" + id, method: .delete)
    }

    public func remind(id: String, challengers: [String]) async throws {
        let ids = try challengers.map { id in
            guard let value = Int64(id) else { throw URLError(.cannotParseResponse) }
            return value
        }
        try await change(id + "/reminders", body: ReminderBody(targetIds: ids))
    }

    public func replaceImages(_ files: [String], id: String) async throws {
        try await change(id + "/images", method: .patch, body: ImagesBody(imageIds: files))
    }

    public func replaceLinks(_ links: [String], id: String) async throws {
        try await change(id + "/links", method: .patch, body: LinksBody(links: links))
    }

    public func removePoll(id: String) async throws {
        try await validate(noticesPath + "/" + id + "/vote", method: .delete)
    }

    public func confirmRead(id: String) async throws {
        try await validate(noticesPath + "/" + id + "/read", method: .post)
    }

    public func readCounts(id: String) async throws -> NoticeReadCounts {
        try await request(noticesPath + "/" + id + "/read-statics")
    }

    public func readers(id: String, status: String, cursor: String?) async throws -> NoticeReaders
    {
        let query = ReaderQuery(status: status, cursor: cursor)
        return try await request(
            noticesPath + "/" + id + "/read-status",
            task: .requestParameters(
                parameters: query.parameters,
                encoding: URLEncoding.queryString))
    }

    private func numericID(_ value: String) throws -> Int64 {
        guard let id = Int64(value) else { throw URLError(.cannotParseResponse) }
        return id
    }

    private func change<Body: Encodable>(
        _ suffix: String, method: Moya.Method = .post, body: Body
    ) async throws {
        try await validate(
            noticesPath + "/" + suffix, method: method,
            task: .requestJSONEncodable(body))
    }

    private func validate(
        _ path: String, method: Moya.Method, task: Moya.Task = .requestPlain
    ) async throws {
        let data = try await response(path, method: method, task: task)
        if !data.isEmpty {
            try JSONDecoder().decode(APIResponse<EmptyResult>.self, from: data).validateSuccess()
        }
    }

    private func request<Value: Codable>(
        _ path: String, method: Moya.Method = .get, task: Moya.Task = .requestPlain
    ) async throws -> Value {
        let data = try await response(path, method: method, task: task)
        return try JSONDecoder().decode(APIResponse<Value>.self, from: data).unwrap()
    }

    private func response(_ path: String, method: Moya.Method, task: Moya.Task) async throws
        -> Data
    {
        do {
            let target = NoticeTarget(
                environment: environment, path: path, method: method, task: task)
            return try await adapter.request(target).data
        } catch let error as UMCFoundation.NetworkError {
            if case .requestFailed(_, let data) = error, let data,
                let envelope = try? JSONDecoder().decode(
                    APIResponse<EmptyResult>.self, from: data),
                let message = envelope.message
            {
                throw RepositoryError.serverError(code: envelope.code, message: message)
            }
            throw error
        }
    }
}

private struct NoticeTarget: BaseTargetType {
    let environment: NetworkEnvironment
    let path: String
    let method: Moya.Method
    let task: Moya.Task
}

private struct ListQuery {
    let gisu: String
    let tab: String
    let keyword: String
    let part: String?
    let page: Int
    var parameters: [String: String] {
        var fields = ["gisuId": gisu, "noticeTab": tab, "page": String(page), "size": "20"]
        fields["part"] = part
        if !keyword.isEmpty { fields["keyword"] = keyword }
        return fields
    }
}

private struct ReaderQuery {
    let status: String
    let cursor: String?
    var parameters: [String: String] {
        var fields = ["filterType": "ALL", "status": status]
        fields["cursorId"] = cursor
        return fields
    }
}

private struct TargetBody: Encodable {
    let targetGisuId: Int64
    let targetChapterId: Int64?
    let targetSchoolId: Int64?
    let targetParts: [String]
    let targetNoticeTab: String
}

private struct CreateBody: Encodable {
    let title: String
    let content: String
    let shouldNotify: Bool
    let mustRead: Bool
    let targetInfo: TargetBody
}

private struct PollBody: Encodable {
    let title: String
    let isAnonymous: Bool
    let allowMultipleChoice: Bool
    let startsAt: String
    let endsAtExclusive: String
    let options: [String]
}

private struct UploadBody: Encodable {
    let fileName: String
    let contentType: String
    let fileSize: Int
    let category = "NOTICE_ATTACHMENT"
}

private struct LinksBody: Encodable { let links: [String] }
private struct ImagesBody: Encodable { let imageIds: [String] }
private struct VoteBody: Encodable { let optionIds: [Int64] }

private enum ImageUploadError: LocalizedError {
    case invalidFile
    var errorDescription: String? { "10MB 이하의 JPG, PNG, WebP, GIF, HEIC 사진을 선택하세요." }
}

private struct PermissionQuery {
    let resourceId: String
    var parameters: [String: String] { ["resourceType": "NOTICE", "resourceId": resourceId] }
}

private struct EditBody: Encodable {
    let title: String
    let content: String
    let mustRead: Bool
}

private struct ReminderBody: Encodable { let targetIds: [Int64] }

private struct OrganizationQuery {
    let id: String
    var parameters: [String: String] {
        ["id": id, "includeChapter": "true", "includeSchool": "true"]
    }
}
