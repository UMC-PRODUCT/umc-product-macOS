//
//  AppNavigation.swift
//  UMCDesk
//
//  Created by euijjang97 on 10/20/26.
//

import AuthPresentation
import CoreRouting
import Observation
import SettingsDomain

@MainActor
@Observable
final class AppNavigation {
    var authEntry = AuthEntry.login
    var section: DeskSection?
    var pendingSection: DeskSection?
    var account: FeatureAccount?
    var showsSettings: Bool

    init(launchPage: SettingsLaunchPage) {
        showsSettings = launchPage != .login
    }
}
