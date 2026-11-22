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
    var matchingDestination: MatchingDestination?
    var showsSettings: Bool {
        didSet {
            if !showsSettings { matchingDestination = nil }
        }
    }

    func openMatching(_ destination: MatchingDestination = .explore) {
        showsSettings = true
        matchingNavigationID = UUID()
        matchingDestination = destination
    }

    init(launchPage: SettingsLaunchPage) {
        showsSettings = launchPage != .login
    }
}
