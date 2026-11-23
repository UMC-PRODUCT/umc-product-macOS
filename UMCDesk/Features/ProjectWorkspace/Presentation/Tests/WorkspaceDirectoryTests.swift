//
//  WorkspaceDirectoryTests.swift
//  ProjectWorkspacePresentationTests
//
//  Created by euijjang97 on 11/23/26.
//

import AppKit
import Foundation
import SwiftUI
import ProjectWorkspaceDomain
import Testing
@testable import ProjectWorkspacePresentation

@MainActor
struct WorkspaceDirectoryTests {
    private let project = WorkspaceProject(id: "41", name: "팀 프로젝트")

    @Test(arguments: [true, false])
    func activationChecksMembershipAndRetainsPersonalRecords(sceneActivated: Bool) async throws {
        let suite = "WorkspaceDirectoryTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let key = WorkspaceRecord.key(accountID: "101", projectID: project.id)
        var saved = WorkspaceRecord()
        saved.addTodo("개인 할 일")
        saved.resources["Figma"] = "https://figma.com/design/FileId/project"
        defaults.set(try JSONEncoder().encode(saved), forKey: key)

        let model = WorkspaceDirectoryModel()
        let roster = TestRoster(projects: [project])
        let directory = WorkspaceDirectory(
            accountID: "101", loadProjects: { await roster.projects },
            loadGitHub: nil, openMatching: nil, directory: model
        ).defaultAppStorage(defaults)
        let host = NSHostingController(rootView: directory.environment(\.scenePhase, .inactive)
            .environment(\.appearsActive, false))
        let window = NSWindow(contentViewController: host)
        window.setFrame(NSRect(x: -12000, y: -12000, width: 800, height: 600), display: false)
        window.orderBack(nil)
        defer {
            window.orderOut(nil)
            window.contentViewController = nil
        }
        host.view.layoutSubtreeIfNeeded()
        model.open(project)
        try await waitUntil { model.selected == project }
        model.sheet = .connections
        try await waitUntil("connections sheet presented") { window.attachedSheet != nil }
        await roster.removeMembers()
        host.rootView = directory.environment(\.scenePhase, sceneActivated ? .active : .inactive)
            .environment(\.appearsActive, !sceneActivated)
        host.view.layoutSubtreeIfNeeded()
        try await waitUntil { model.projects == [] && model.selected == nil }
        #expect(model.sheet == nil)
        try await waitUntil("connections sheet dismissed") { window.attachedSheet == nil }
        let bytes = try #require(defaults.data(forKey: key))
        let retained = try JSONDecoder().decode(WorkspaceRecord.self, from: bytes)
        #expect(retained.todos == saved.todos)
        #expect(retained.resources == saved.resources)
    }

    private func waitUntil(
        _ description: String = "membership updated", _ predicate: () -> Bool
    ) async throws {
        let deadline = ContinuousClock.now + .seconds(5)
        while !predicate(), ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }
        try #require(predicate(), "\(description)")
    }

    @Test func revokedMembershipClosesDetailAndConnections() async {
        let project = project
        let model = WorkspaceDirectoryModel()
        model.open(project)
        await model.refresh(revision: model.revision) { [project] }
        model.sheet = .connections
        model.requestRefresh()
        await model.refresh(revision: model.revision) { [] }
        #expect(model.projects == [])
        #expect(model.selected == nil)
        #expect(model.sheet == nil)
    }

    @Test func enteringAgainRequiresFreshMembership() async {
        let project = project
        let model = WorkspaceDirectoryModel()
        await model.refresh(revision: model.revision) { [project] }
        model.open(project)
        #expect(model.selected == nil)
        await model.refresh(revision: model.revision) { [project] }
        #expect(model.selected == project)
        model.close()
        model.open(project)
        #expect(model.selected == nil)
        await model.refresh(revision: model.revision) { [] }
        #expect(model.selected == nil)
    }

    @Test func delayedPositiveResponseCannotReopenRevokedProject() async {
        let project = project
        let model = WorkspaceDirectoryModel()
        model.open(project)
        await model.refresh(revision: model.revision) {
            await model.requestRefresh()
            await model.refresh(revision: model.revision) { [] }
            return [project]
        }
        #expect(model.projects == [])
        #expect(model.selected == nil)
    }

    @Test func transientFailureKeepsOpenSheetUntilMembershipIsKnown() async {
        let project = project
        let model = WorkspaceDirectoryModel()
        model.open(project)
        await model.refresh(revision: model.revision) { [project] }
        model.sheet = .connections
        model.requestRefresh()
        await model.refresh(revision: model.revision) { throw URLError(.notConnectedToInternet) }
        #expect(model.failed)
        #expect(model.selected == project)
        #expect(model.sheet?.id == WorkspaceSheet.connections.id)
        model.requestRefresh()
        await model.refresh(revision: model.revision) { [project] }
        #expect(!model.failed)
        #expect(model.sheet?.id == WorkspaceSheet.connections.id)
    }
}

private actor TestRoster {
    private(set) var projects: [WorkspaceProject]

    init(projects: [WorkspaceProject]) {
        self.projects = projects
    }

    func removeMembers() {
        projects = []
    }
}
