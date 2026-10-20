//
//  AppSessionResetRelay.swift
//  UMCDesk
//
//  Created by euijjang97 on 10/20/26.
//

import SettingsPresentation

@MainActor
final class AppSessionResetRelay {
    weak var settingsViewModel: SettingsViewModel?

    func reset() async {
        await settingsViewModel?.invalidateAccount()
    }
}
