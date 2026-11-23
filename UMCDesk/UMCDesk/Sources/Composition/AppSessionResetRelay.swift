//
//  AppSessionResetRelay.swift
//  UMCDesk
//
//  Created by euijjang97 on 10/20/26.
//

import CoreNetwork
import SettingsPresentation

@MainActor
final class AppSessionResetRelay: SessionLogoutObserving {
    private let discardSession: @MainActor () -> Void

    weak var navigation: AppNavigation?
    weak var windowSettingsViewModel: SettingsViewModel?
    weak var settingsViewModel: SettingsViewModel?

    init(discardSession: @escaping @MainActor () -> Void) {
        self.discardSession = discardSession
    }

    func logoutWillBegin() {
        discardSession()
        navigation?.authEntry = .login
        navigation?.account = nil
        navigation?.section = nil
        navigation?.pendingSection = nil
        navigation?.showsSettings = false
        settingsViewModel?.discardAccountState()
        windowSettingsViewModel?.discardAccountState()
    }

    func resetSession() async {
        await settingsViewModel?.systemActions.clearAccountNotifications()
    }
}
