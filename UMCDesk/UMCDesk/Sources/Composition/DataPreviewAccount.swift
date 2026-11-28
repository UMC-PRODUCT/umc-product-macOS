//
//  DataPreviewAccount.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/25/26.
//

import CommunityDomain
import CoreNetwork
import Foundation
import HomePresentation
import ProjectWorkspaceDomain

enum DataPreviewAccount {
    static let memberID = "101"

    static func make(defaults: UserDefaults, journalDirectory: URL, baseURL: URL) -> FeatureAccount {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [DataPreviewProtocol.self]
        configuration.urlCache = nil
        configuration.urlCredentialStorage = nil
        configuration.httpCookieStorage = nil
        let credentials = PreviewCredentials()
        let client = NetworkClient(session: URLSession(configuration: configuration),
                                   tokenStore: credentials, refreshService: credentials)
        return FeatureAccount(memberID: memberID, boundClient: client,
                              environment: NetworkEnvironment(baseURL: baseURL), defaults: defaults,
                              journalDirectory: journalDirectory, storeLocalImage: { source in
            let name = UUID().uuidString + "." + source.pathExtension
            try FileManager.default.createDirectory(at: journalDirectory, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: source, to: journalDirectory.appending(path: name))
            return name
        })
    }

    static func recentWork(repository: URL) -> [WorkspaceGitHubItem] {
        switch repository.absoluteString {
        case "https://github.com/umc-preview/moa":
            [
                .init(id: "pr-28", title: "취향 태그로 추천 상품 필터링",
                      summary: "선택한 태그를 홈 추천 목록에 반영합니다.", isPullRequest: true, completed: false),
                .init(id: "issue-19", title: "첫 방문자의 취향 선택 문구 확정",
                      summary: "사용성 테스트에서 혼동한 태그 세 개를 바꿨어요.", isPullRequest: false, completed: true)
            ]
        case "https://github.com/umc-preview/sai":
            [
                .init(id: "pr-12", title: "공동 구매 마감 인원 표시",
                      summary: "모집 카드에 남은 자리와 마감 시간을 함께 표시합니다.", isPullRequest: true, completed: true),
                .init(id: "issue-16", title: "참여 취소 뒤 잔여 인원 갱신",
                      summary: "마감 직전 취소한 자리로 다시 참여할 수 있는지 확인해요.", isPullRequest: false, completed: false)
            ]
        default: []
        }
    }

    @MainActor static func seedWorkspace(in defaults: UserDefaults) {
        HomeView.seedPreviewGameRecords(in: defaults, memberID: memberID)
        for (id, slug, completed, next) in [
            ("1", "moa", "취향 태그 선택 화면 인터뷰 정리", "추천 상품 카드의 가격 표시 확인"),
            ("3", "sai", "공동 구매 참여 흐름 시연 녹화", "모집 마감 직전 참여 취소 테스트")
        ] {
            var record = WorkspaceRecord()
            record.addTodo(completed)
            record.todos[0].completed = true
            record.addTodo(next)
            let repository = URL(string: "https://github.com/umc-preview/" + slug)!
            record.resources = [
                WorkspaceResource.github.rawValue: repository.absoluteString,
                WorkspaceResource.figma.rawValue: "https://www.figma.com/design/Preview\(id)"
            ]
            record.lastOpened = .now
            record.githubItems = recentWork(repository: repository)
            record.githubUpdatedAt = .now
            defaults.set(try? JSONEncoder().encode(record),
                         forKey: WorkspaceRecord.key(accountID: memberID, projectID: id))
        }
    }
}

private struct PreviewCredentials: TokenStore, TokenRefreshService {
    func getAccessToken() async -> String? { "local-data-preview" }
    func getRefreshToken() async -> String? { nil }
    func save(accessToken: String, refreshToken: String) async throws { throw URLError(.unsupportedURL) }
    func clear() async throws {}
    func refresh(_ refreshToken: String) async throws -> TokenPair { throw URLError(.unsupportedURL) }
}

private final class DataPreviewProtocol: URLProtocol, @unchecked Sendable {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        do {
            guard let url = request.url else { throw URLError(.badURL) }
            let data = try DataPreviewFixtures.data(for: request)
            guard let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1",
                                                 headerFields: ["Content-Type": "application/json"])
            else { throw URLError(.badServerResponse) }
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

/// Keeps conversation changes in this preview session, including idempotent sends.
actor DataPreviewConversation: ThreadConversationRepository {
    private let repository: any ThreadConversationRepository
    private var rooms: [String: [ThreadConversationMessage]] = [:]
    private var uploads: [String: ThreadConversationFile] = [:]

    init(repository: any ThreadConversationRepository) { self.repository = repository }

    func history(thread: String, before: String?) async throws -> ThreadPage<ThreadConversationMessage> {
        if rooms[thread] == nil {
            let initial = try await repository.history(thread: thread, before: nil)
            if rooms[thread] == nil { rooms[thread] = initial.values }
        }
        return .init(values: before == nil ? rooms[thread] ?? [] : [], cursor: nil)
    }

    func members(thread: String, query: String) async throws -> [ThreadManagementPerson] {
        try await repository.members(thread: thread, query: query)
    }

    func perform(_ command: ThreadConversationCommand, thread: String) async throws {
        _ = try await history(thread: thread, before: nil)
        switch command {
        case .read: break
        case let .create(key, content, files, reply, _):
            guard rooms[thread]?.contains(where: { $0.id == key }) != true else { return }
            let message = ThreadConversationMessage(id: key, authorID: DataPreviewAccount.memberID,
                author: "유엠", text: content, createdAt: Date.now.ISO8601Format(), replyID: reply,
                files: files.compactMap { uploads[$0] }, reactions: [], isHidden: false)
            rooms[thread, default: []].insert(message, at: 0)
        case let .react(id, emoji, adding):
            try update(id, thread: thread) { row in
                var reactions = row.reactions.filter { $0.emoji != emoji }
                let old = row.reactions.first { $0.emoji == emoji }
                let others = (Int(old?.count ?? "") ?? 0) - (old?.reactedByMe == true ? 1 : 0)
                let count = max(0, others) + (adding ? 1 : 0)
                if count > 0 {
                    reactions.append(.init(emoji: emoji, count: String(count), reactedByMe: adding))
                }
                return row.updated(reactions: reactions)
            }
        case let .edit(id, content):
            try update(id, thread: thread) { row in row.updated(text: content) }
        case let .delete(id):
            try update(id, thread: thread) { row in row.updated(hidden: true) }
        }
    }

    private func update(_ id: String, thread: String,
                        transform: (ThreadConversationMessage) -> ThreadConversationMessage) throws {
        guard var rows = rooms[thread], let index = rows.firstIndex(where: { $0.id == id })
        else { throw URLError(.resourceUnavailable) }
        rows[index] = transform(rows[index])
        rooms[thread] = rows
    }

    func observeChanges(thread: String, changed: @escaping @Sendable () async -> Void) async throws {
        try await Task.sleep(for: .seconds(3600))
    }

    func upload(name: String, contentType: String, data: Data) async throws -> String {
        let id = UUID().uuidString
        uploads[id] = .init(id: id, name: name, url: nil)
        return id
    }
}

private extension ThreadConversationMessage {
    func updated(text: String? = nil, reactions: [ThreadConversationReaction]? = nil,
                 hidden: Bool = false) -> Self {
        .init(id: id, authorID: hidden ? nil : authorID, author: hidden ? "" : author,
              text: hidden ? "삭제된 메시지" : text ?? self.text, createdAt: createdAt,
              replyID: hidden ? nil : replyID, files: hidden ? [] : files,
              reactions: hidden ? [] : reactions ?? self.reactions, isHidden: hidden)
    }
}
