//
//  ProjectWorkspaceDomain.swift
//  ProjectWorkspaceDomain
//
//  Created by euijjang97 on 10/6/26.
//

import Foundation

/// A project whose membership has been verified for the current session.
public struct WorkspaceProject: Identifiable, Equatable, Sendable {
    public let id: String
    public let name: String

    public init(id: String, name: String) {
        self.id = id
        self.name = name
    }
}

public enum WorkspaceResource: String, CaseIterable, Identifiable, Sendable {
    case github = "GitHub"
    case figma = "Figma"

    public var id: Self { self }

    public func validatedURL(_ input: String) -> URL? {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed, encodingInvalidCharacters: false),
              let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              parts.scheme?.lowercased() == "https", parts.port == nil,
              parts.user == nil, parts.password == nil, let host = parts.host?.lowercased()
        else { return nil }
        let path = parts.path.split(separator: "/")
        switch self {
        case .github:
            guard host == "github.com", path.count == 2,
                  path.allSatisfy({ $0 != "." && $0 != ".." && $0.range(
                    of: #"^[A-Za-z0-9_.-]+$"#, options: .regularExpression
                  ) != nil }) else { return nil }
        case .figma:
            guard ["figma.com", "www.figma.com"].contains(host), path.count >= 2,
                  ["design", "file", "proto", "board", "slides"].contains(path[0]),
                  path[1].range(of: #"^[A-Za-z0-9]+$"#, options: .regularExpression) != nil,
                  !path.contains(".."), !path.contains(".") else { return nil }
        }
        return url
    }
}

/// Personal records stored on this Mac, scoped by signed-in account and project.
public struct WorkspaceRecord: Codable, Equatable, Sendable {
    public struct Todo: Codable, Equatable, Identifiable, Sendable {
        public let id: UUID
        public let title: String
        public var completed: Bool
        public let createdAt: Date
    }

    public var todos: [Todo] = []
    public var resources: [String: String] = [:]
    public var lastOpened: Date?
    public var githubItems: [WorkspaceGitHubItem]?
    public var githubUpdatedAt: Date?

    public init() {}

    public static func key(accountID: String, projectID: String) -> String {
        let account = Data(accountID.utf8).base64EncodedString()
        let project = Data(projectID.utf8).base64EncodedString()
        return "umc.project-workspace.v1.\(account).\(project)"
    }

    public mutating func addTodo(_ input: String) {
        let title = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }
        todos.insert(Todo(id: UUID(), title: title, completed: false, createdAt: Date()), at: 0)
    }

    /// Edits only the links changed by this form, preserving edits from another window.
    public mutating func updateLinks(original: [String: String], edited: [String: String]) {
        for key in WorkspaceResource.allCases.map(\.rawValue) where original[key] != edited[key] {
            if key == WorkspaceResource.github.rawValue, resources[key] != edited[key] {
                githubItems = nil
                githubUpdatedAt = nil
            }
            resources[key] = edited[key]
        }
    }

    public func link(for resource: WorkspaceResource) -> URL? {
        resources[resource.rawValue].flatMap(resource.validatedURL)
    }
}

public struct WorkspaceGitHubItem: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public let title: String
    public let summary: String
    public let isPullRequest: Bool
    public let completed: Bool

    public init(id: String, title: String, summary: String, isPullRequest: Bool, completed: Bool) {
        self.id = id
        self.title = title
        self.summary = summary
        self.isPullRequest = isPullRequest
        self.completed = completed
    }
}

public typealias WorkspaceGitHubLoader = @Sendable (URL) async throws -> [WorkspaceGitHubItem]
