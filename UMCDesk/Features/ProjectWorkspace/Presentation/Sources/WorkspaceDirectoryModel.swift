//
//  WorkspaceDirectoryModel.swift
//  ProjectWorkspacePresentation
//
//  Created by euijjang97 on 11/23/26.
//

import Observation
import ProjectWorkspaceDomain

@MainActor
@Observable
final class WorkspaceDirectoryModel {
    private(set) var projects: [WorkspaceProject]?
    private(set) var selected: WorkspaceProject?
    private(set) var failed = false
    private(set) var revision = 0
    var sheet: WorkspaceSheet?
    private var pendingProjectID: String?

    private(set) var unavailableProjectID: String?

    init(initialProjectID: String? = nil) {
        pendingProjectID = initialProjectID
    }

    var isOpening: Bool { pendingProjectID != nil }

    func open(_ project: WorkspaceProject) {
        unavailableProjectID = nil
        pendingProjectID = project.id
        requestRefresh()
    }

    func close() {
        unavailableProjectID = nil
        sheet = nil
        selected = nil
        pendingProjectID = nil
        requestRefresh()
    }

    func requestRefresh() {
        revision += 1
    }

    func refresh(
        revision: Int,
        load: @Sendable () async throws -> [WorkspaceProject]
    ) async {
        guard revision == self.revision else { return }
        failed = false
        do {
            let fetched = try await load()
            guard revision == self.revision, !Task.isCancelled else { return }
            var seen = Set<String>()
            projects = fetched.filter { seen.insert($0.id).inserted }
            let requestedID = pendingProjectID ?? selected?.id
            let verified = projects?.first { $0.id == requestedID }
            if let requestedID {
                unavailableProjectID = verified == nil ? requestedID : nil
            } else if let unavailableProjectID, seen.contains(unavailableProjectID) {
                self.unavailableProjectID = nil
            }
            if selected?.id != verified?.id { sheet = nil }
            selected = verified
            pendingProjectID = nil
        } catch {
            guard revision == self.revision, !Task.isCancelled else { return }
            failed = true
        }
    }
}
