//
//  AppNavigation.swift
//  UMCDesk
//
//  Created by euijjang97 on 10/20/26.
//

import Observation
import SettingsDomain

@MainActor
@Observable
final class AppNavigation {
    var showsSettings: Bool

    init(launchPage: SettingsLaunchPage) {
        showsSettings = launchPage != .login
    }
}
