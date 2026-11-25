//
//  SettingsHelpButton.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import CoreDesignSystem
import CoreUIComponents
import SwiftUI
import UMCFoundation

struct SettingsHelpButton: View {
    @Environment(\.colorSchemeContrast) private var contrast
    let foreground: Color
    var focusTarget: UMCWindowButtonFocus? = nil
    let openHelp: () -> Void

    var body: some View {
        UMCWindowOpeningButton(AppLocalization.string("도움말"), identifier: "questionmark.circle",
                               cornerRadius: UMCRadius.value8, focusTarget: focusTarget,
                               action: openHelp) { _ in
            Image(systemName: "questionmark.circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(foreground.opacity(contrast == .increased ? 1 : 0.75))
                .frame(width: 44, height: 44)
        }
    }
}
