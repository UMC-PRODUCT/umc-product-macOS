//
//  ProjectWorkspaceData.swift
//  ProjectWorkspaceData
//
//  Created by euijjang97 on 10/6/26.
//

import Foundation
import ProjectWorkspaceDomain
import UMCFoundation

/// Reads the most recent public issues and PRs without sending an app session or GitHub cookie.
public enum WorkspaceGitHubClient {
    public static func recentWork(repository: URL) async throws -> [WorkspaceGitHubItem] {
        guard let request = request(for: repository) else { throw URLError(.badURL) }
        let session = URLSession(configuration: .ephemeral)
        defer { session.finishTasksAndInvalidate() }
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        return try decode(data)
    }

    static func request(for repository: URL) -> URLRequest? {
        guard let url = WorkspaceResource.github.validatedURL(repository.absoluteString) else {
            return nil
        }
        var parts = URLComponents()
        parts.scheme = "https"
        parts.host = "api.github.com"
        let slug = url.path.split(separator: "/").joined(separator: "/")
        parts.path = "/repos/\(slug)/issues"
        parts.queryItems = [
            .init(name: "state", value: "all"), .init(name: "sort", value: "updated"),
            .init(name: "direction", value: "desc"), .init(name: "per_page", value: "30")
        ]
        guard let endpoint = parts.url else { return nil }
        var request = URLRequest(url: endpoint, timeoutInterval: 15)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("UMCDesk", forHTTPHeaderField: "User-Agent")
        request.httpShouldHandleCookies = false
        return request
    }

    static func decode(_ data: Data) throws -> [WorkspaceGitHubItem] {
        try JSONDecoder().decode([IssueResponse].self, from: data).map(\.item)
    }
}

private struct IssueResponse: Codable {
    let item: WorkspaceGitHubItem

    enum CodingKeys: String, CodingKey {
        case number, title, body, state
        case pullRequest = "pull_request"
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let summary = try values.decodeIfPresent(String.self, forKey: .body) ?? ""
        item = WorkspaceGitHubItem(
            id: try values.decodeFlexibleString(forKey: .number),
            title: try values.decode(String.self, forKey: .title),
            summary: String(summary.prefix(1500)),
            isPullRequest: values.contains(.pullRequest),
            completed: try values.decode(String.self, forKey: .state) == "closed"
        )
    }

    func encode(to encoder: Encoder) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(item.id, forKey: .number)
        try values.encode(item.title, forKey: .title)
        try values.encode(item.summary, forKey: .body)
        try values.encode(item.completed ? "closed" : "open", forKey: .state)
        if item.isPullRequest { try values.encode([String: String](), forKey: .pullRequest) }
    }
}
