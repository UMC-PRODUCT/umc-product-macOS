//
//  AppNavigation.swift
//  UMCDesk
//
//  Created by euijjang97 on 10/20/26.
//

import Foundation
import MatchingPresentation
import AuthPresentation
import CoreRouting
import Observation
import SettingsDomain

@MainActor
@Observable
final class AppNavigation {
    private(set) var matchingNavigationID = UUID()
    private(set) var pendingMatching: MatchingDestination?
    var matchingDestination: MatchingDestination?
    private(set) var workspaceProjectID: String?
    var showsSettings: Bool {
        didSet {
            if !showsSettings { matchingDestination = nil }
        }
    }

    func openMatching(_ destination: MatchingDestination = .explore, memberId: String?) {
        workspaceProjectID = nil
        section = nil
        pendingSection = nil
        guard let memberId, !memberId.isEmpty else {
            pendingMatching = destination
            showsSettings = false
            return
        }
        pendingMatching = nil
        showsSettings = true
        matchingNavigationID = UUID()
        matchingDestination = destination
    }

    func resetAccount() {
        workspaceProjectID = nil
        pendingMatching = nil
        showsSettings = false
    }
    var authEntry = AuthEntry.login
    var section: DeskSection?
    var pendingSection: DeskSection?
    var account: FeatureAccount?

    func selectFeature(_ destination: DeskSection?) {
        workspaceProjectID = nil
        matchingDestination = nil
        section = destination
        showsSettings = true
    }

    func openWorkspace(projectID: String, memberID: String) {
        guard account?.memberID == memberID, !projectID.isEmpty else { return }
        selectFeature(.projects)
        workspaceProjectID = projectID
    }

    init(launchPage: SettingsLaunchPage) {
        showsSettings = launchPage != .login
    }
}
