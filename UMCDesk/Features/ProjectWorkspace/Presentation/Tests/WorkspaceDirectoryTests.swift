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

    @Test func initialRequestWaitsForVerifiedMembershipAndIsConsumedOnce() async {
        let project = project
        let model = WorkspaceDirectoryModel(initialProjectID: project.id)
        #expect(model.isOpening && model.selected == nil)
        await model.refresh(revision: model.revision) { throw URLError(.timedOut) }
        #expect(model.failed && model.isOpening && model.selected == nil)
        model.requestRefresh()
        await model.refresh(revision: model.revision) { [project] }
        #expect(model.selected == project && !model.isOpening)
        model.close()
        await model.refresh(revision: model.revision) { [project] }
        #expect(model.selected == nil && model.unavailableProjectID == nil)
    }

    @Test func missingInitialProjectShowsVerifiedListAndDoesNotOpenOnLaterRefresh() async {
        let project = project
        let model = WorkspaceDirectoryModel(initialProjectID: "missing")
        await model.refresh(revision: model.revision) { [project] }
        #expect(model.projects == [project] && model.selected == nil)
        #expect(model.unavailableProjectID == "missing" && !model.isOpening && !model.failed)
        model.requestRefresh()
        await model.refresh(revision: model.revision) { [.init(id: "missing", name: "다시 합류한 팀")] }
        #expect(model.selected == nil && model.unavailableProjectID == nil)
    }

    @Test func accountSwitchDiscardsDelayedInitialMembership() async throws {
        let suite = "WorkspaceDirectoryTests." + UUID().uuidString
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let first = project
        let second = WorkspaceProject(id: "42", name: "다른 팀")
        let gate = DelayedMembership()
        let newAccount = DelayedMembership()
        defer {
            gate.release()
            newAccount.release()
        }
        let firstView = ProjectWorkspaceView(accountID: "101", initialProjectID: first.id) {
            await gate.wait()
            return [first]
        }
        let host = NSHostingController(rootView: firstView.defaultAppStorage(defaults))
        let window = NSWindow(contentViewController: host)
        defer { window.contentViewController = nil }
        host.view.layoutSubtreeIfNeeded()
        try await waitUntil { gate.started }
        let secondView = ProjectWorkspaceView(accountID: "102", initialProjectID: first.id) {
            await newAccount.wait()
            return [second]
        }
        host.rootView = secondView.defaultAppStorage(defaults)
        host.view.layoutSubtreeIfNeeded()
        try await waitUntil { newAccount.started }
        gate.release()
        newAccount.release()

        // A subsequent request for the same account must use the new route identity.
        host.rootView = ProjectWorkspaceView(accountID: "102", initialProjectID: second.id) {
            [second]
        }.defaultAppStorage(defaults)
        host.view.layoutSubtreeIfNeeded()
        let validKey = WorkspaceRecord.key(accountID: "102", projectID: second.id)
        try await waitUntil { defaults.data(forKey: validKey) != nil }
        let staleKey = WorkspaceRecord.key(accountID: "101", projectID: first.id)
        let deniedKey = WorkspaceRecord.key(accountID: "102", projectID: first.id)
        #expect(defaults.data(forKey: staleKey) == nil)
        #expect(defaults.data(forKey: deniedKey) == nil)
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
        #expect(model.unavailableProjectID == project.id)
        #expect(model.sheet == nil)
    }

    @Test func enteringAgainRequiresFreshMembership() async {
        let project = project
        let model = WorkspaceDirectoryModel()
        await model.refresh(revision: model.revision) { [project] }
        #expect(model.selected == nil && !model.isOpening)
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

@MainActor
private final class DelayedMembership {
    private var continuations: [CheckedContinuation<Void, Never>] = []
    private var released = false
    var started: Bool { !continuations.isEmpty }

    func wait() async {
        guard !released else { return }
        await withCheckedContinuation { continuations.append($0) }
    }

    func release() {
        released = true
        continuations.forEach { $0.resume() }
        continuations.removeAll()
    }
}
