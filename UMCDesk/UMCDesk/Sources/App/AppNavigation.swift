//
//  AppNavigation.swift
//  UMCDesk
//
//  Created by euijjang97 on 10/20/26.
//

import Foundation
import MatchingPresentation
import Observation
import SettingsDomain

@MainActor
@Observable
final class AppNavigation {
    private(set) var matchingNavigationID = UUID()
    private(set) var pendingMatching: MatchingDestination?
    var matchingDestination: MatchingDestination?
    var showsSettings: Bool {
        didSet {
            if !showsSettings { matchingDestination = nil }
        }
    }

    func openMatching(_ destination: MatchingDestination = .explore, memberId: String?) {
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
        pendingMatching = nil
        showsSettings = false
    }

    init(launchPage: SettingsLaunchPage) {
        showsSettings = launchPage != .login
    }
}
