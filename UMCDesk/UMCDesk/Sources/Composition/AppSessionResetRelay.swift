//
//  AppSessionResetRelay.swift
//  UMCDesk
//
//  Created by euijjang97 on 10/20/26.
//

import SettingsPresentation

@MainActor
final class AppSessionResetRelay {
    weak var navigation: AppNavigation?
    weak var windowSettingsViewModel: SettingsViewModel?
    weak var settingsViewModel: SettingsViewModel?

    func reset() async {
        navigation?.showsSettings = false
        await settingsViewModel?.invalidateAccount()
        await windowSettingsViewModel?.invalidateAccount()
    }
}
