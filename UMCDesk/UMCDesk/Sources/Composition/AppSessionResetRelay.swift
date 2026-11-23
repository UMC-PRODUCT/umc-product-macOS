//
//  AppSessionResetRelay.swift
//  UMCDesk
//
//  Created by euijjang97 on 10/20/26.
//

import SettingsPresentation

@MainActor
final class AppSessionResetRelay {
    weak var windowSettingsViewModel: SettingsViewModel?
    weak var settingsViewModel: SettingsViewModel?

    weak var navigation: AppNavigation?
    weak var matchingProgress: MatchingProgressController?

    func reset() async {
        navigation?.resetAccount()
        matchingProgress?.setAccount(nil)
        await settingsViewModel?.invalidateAccount()
        await windowSettingsViewModel?.invalidateAccount()
    }
}
