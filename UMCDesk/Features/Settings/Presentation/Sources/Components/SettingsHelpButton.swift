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
    @Environment(\.settingsAppearancePalette) private var palette
    let foreground: Color
    let openHelp: () -> Void

    var body: some View {
        UMCWindowOpeningButton(AppLocalization.string("도움말"), identifier: "questionmark.circle",
                               cornerRadius: UMCRadius.value8, action: openHelp) { hovered in
            Image(systemName: "questionmark.circle")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(foreground.opacity(contrast == .increased ? 1 : 0.75))
                .frame(width: 44, height: 44)
                .background(hovered ? palette.fillNeutralWeakerHoverPressed : .clear,
                            in: .rect(cornerRadius: UMCRadius.value8))
        }
    }
}
