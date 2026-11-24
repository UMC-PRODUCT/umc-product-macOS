//
//  WorkspaceContractTests.swift
//  ProjectWorkspaceDataTests
//
//  Created by euijjang97 on 11/23/26.
//

import Foundation
import ProjectWorkspaceDomain
import Testing
@testable import ProjectWorkspaceData

struct WorkspaceContractTests {
    @Test func readsIssueAndPullRequestFromListContract() throws {
        let data = Data("""
        [{"number":81,"title":"목록","body":null,"state":"open"},
         {"number":"82","title":"검색","body":"조회 구현","state":"closed","pull_request":{}}]
        """.utf8)
        let items = try WorkspaceGitHubClient.decode(data)
        #expect(items.map(\.id) == ["81", "82"])
        #expect(items[0].summary.isEmpty && !items[0].isPullRequest && !items[0].completed)
        #expect(items[1].summary == "조회 구현" && items[1].isPullRequest && items[1].completed)
    }

    @Test func githubRequestUsesAnonymousPublicRoute() throws {
        let repo = try #require(URL(string: "https://github.com/example/test"))
        let request = try #require(WorkspaceGitHubClient.request(for: repo))
        #expect(request.url?.host == "api.github.com")
        #expect(request.url?.path == "/repos/example/test/issues")
        #expect(request.value(forHTTPHeaderField: "Authorization") == nil)
        #expect(!request.httpShouldHandleCookies)
    }

    @Test func validatesProviderAndResourceType() {
        let file = "https://www.figma.com/design/Ab12/file"
        #expect(WorkspaceResource.figma.validatedURL(file) != nil)
        let lookalike = "https://figma.com.evil.test/design/a"
        #expect(WorkspaceResource.figma.validatedURL(lookalike) == nil)
        #expect(WorkspaceResource.figma.validatedURL("https://figma.com/login") == nil)
        #expect(WorkspaceResource.github.validatedURL("file:///tmp/file") == nil)
        #expect(WorkspaceResource.github.validatedURL("https://user@github.com/team/repo") == nil)
        let issues = "https://github.com/team/repo/issues"
        #expect(WorkspaceResource.github.validatedURL(issues) == nil)
    }

    @Test func changingARepositoryClearsCachedWorkAndPreservesOtherWindowEdits() {
        var record = WorkspaceRecord()
        record.resources = ["GitHub": "https://github.com/test/first"]
        let initial = record.resources
        record.githubItems = []
        record.githubUpdatedAt = Date()
        record.resources["Figma"] = "https://figma.com/design/Ab12/file"
        record.updateLinks(original: initial, edited: ["GitHub": "https://github.com/test/second"])
        #expect(record.link(for: .figma) != nil)
        #expect(record.githubItems == nil && record.githubUpdatedAt == nil)
    }

    @Test func personalRecordsRoundTripWithoutSharingKeys() throws {
        var record = WorkspaceRecord()
        record.addTodo("   ")
        record.addTodo("  작업 확인  ")
        #expect(record.todos.map(\.title) == ["작업 확인"])
        record.todos[0].completed = true
        record.resources["Figma"] = "https://www.figma.com/design/Ab12/file"
        let bytes = try JSONEncoder().encode(record)
        #expect(try JSONDecoder().decode(WorkspaceRecord.self, from: bytes) == record)
        #expect(WorkspaceRecord.key(accountID: "a.b", projectID: "c") !=
                WorkspaceRecord.key(accountID: "a", projectID: "b.c"))
        #expect(WorkspaceRecord.key(accountID: "a", projectID: "c") !=
                WorkspaceRecord.key(accountID: "b", projectID: "c"))
    }
}
