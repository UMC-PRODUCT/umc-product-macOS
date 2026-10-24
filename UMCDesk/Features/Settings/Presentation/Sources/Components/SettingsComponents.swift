//
//  SettingsComponents.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/20/26.
//

import CoreDesignSystem
import SwiftUI

struct SettingsCard<Content: View>: View {
    @Environment(\.settingsAppearancePalette) private var palette
    var isSubtle = false
    var minimumHeight: CGFloat?
    var contentPadding: CGFloat = UMCSpacing.value24
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(contentPadding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: minimumHeight, alignment: .topLeading)
            .background(
                isSubtle ? palette.backgroundSurfaceGreyWeaker :
                    palette.backgroundSurfaceWhite,
                in: .rect(cornerRadius: UMCRadius.value16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: UMCRadius.value16)
                    .strokeBorder(palette.borderNeutralWeak200, lineWidth: 1)
            }
    }
}

struct SettingsRow<Accessory: View>: View {
    @Environment(\.settingsAppearancePalette) private var palette
    let title: String
    let description: String
    @ViewBuilder let accessory: Accessory

    var body: some View {
        HStack(spacing: UMCSpacing.value16) {
            VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                Text(title)
                    .umcTypography(.headlineRegular)
                    .foregroundStyle(palette.textNeutralStrong800)
                if !description.isEmpty {
                    Text(description)
                        .umcTypography(.bodyRegular)
                        .foregroundStyle(palette.textNeutralMedium600)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            accessory
        }
        .frame(minHeight: 44)
        .controlSize(.large)
    }
}

struct SettingsSection<Content: View>: View {
    @Environment(\.settingsAppearancePalette) private var palette
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
            Text(title)
                .umcTypography(.headlineBold)
                .foregroundStyle(palette.textNeutralStrong800)
                .accessibilityAddTraits(.isHeader)
            content
        }
    }
}

struct SettingsDivider: View {
    @Environment(\.settingsAppearancePalette) private var palette
    var body: some View {
        Rectangle()
            .fill(palette.borderNeutralWeak200)
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

enum SettingsButtonKind {
    case primary, secondary, quiet, brand, destructive
}

struct SettingsActionButton: View {
    let title: String
    var symbol: String?
    var kind: SettingsButtonKind = .secondary
    var fillsWidth = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: UMCSpacing.value4) {
                if let symbol { Image(systemName: symbol) }
                Text(title)
            }
            .umcTypography(.headlineRegular)
            .padding(.horizontal, UMCSpacing.value16)
            .frame(minWidth: 64, maxWidth: fillsWidth ? .infinity : nil, minHeight: 40)
            .contentShape(.rect(cornerRadius: UMCRadius.value12))
        }
        .buttonStyle(SettingsButtonStyle(kind: kind))
    }
}

struct SettingsButtonStyle: ButtonStyle {
    @Environment(\.settingsAppearancePalette) private var palette
    let kind: SettingsButtonKind
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .background(isEnabled && (isHovered || configuration.isPressed) ?
                activeBackground : background,
                in: .rect(cornerRadius: UMCRadius.value12))
            .overlay {
                RoundedRectangle(cornerRadius: UMCRadius.value12)
                    .strokeBorder(kind == .secondary ?
                        palette.borderNeutralWeak200 : .clear, lineWidth: 1)
            }
            .opacity(isEnabled ? 1 : 0.45)
            .onHover { hovering in
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.12)) {
                    isHovered = hovering
                }
            }
    }

    private var activeBackground: Color {
        switch kind {
        case .primary: UMCColor.Semantic.fillPrimaryInverseStrongHoverPressed
        case .brand: palette.fillPrimaryWeakHoverPressed
        case .secondary, .quiet: palette.fillNeutralWeakerHoverPressed
        case .destructive: UMCColor.Semantic.fillErrorWeakHoverPressed
        }
    }

    private var foreground: Color {
        switch kind {
        case .primary: UMCColor.Custom.backgroundTextWhite
        case .destructive: UMCColor.Semantic.textError
        case .brand: palette.textBrandDefault
        case .secondary, .quiet: palette.textNeutralMedium600
        }
    }

    private var background: Color {
        switch kind {
        case .primary: UMCColor.Semantic.fillPrimaryInverseStrong500
        case .brand: palette.fillPrimaryWeak75
        case .secondary: palette.backgroundSurfaceWhite
        case .quiet: palette.backgroundSurfaceGreyWeak
        case .destructive: UMCColor.Semantic.fillErrorWeak50
        }
    }
}

struct SettingsPlainButtonStyle: ButtonStyle {
    @Environment(\.settingsAppearancePalette) private var palette
    var highlight: Color?
    var cornerRadius: CGFloat = UMCRadius.value8
    var isFocused = false
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                isEnabled && (isHovered || isFocused || configuration.isPressed)
                    ? (highlight ?? palette.fillNeutralWeakerHoverPressed) : .clear,
                in: .rect(cornerRadius: cornerRadius))
            .contentShape(.rect(cornerRadius: cornerRadius))
            .onHover { hovering in
                withAnimation(reduceMotion ? nil : .easeOut(duration: 0.12)) {
                    isHovered = hovering
                }
            }
    }
}

struct SettingsStatusText: View {
    @Environment(\.settingsAppearancePalette) private var palette
    let text: String

    var body: some View {
        Text(text)
            .umcTypography(.headlineRegular)
            .foregroundStyle(palette.textNeutralMedium600)
            .fixedSize()
    }
}

struct SettingsInlineMessage: View {
    @Environment(\.settingsAppearancePalette) private var palette
    let message: String
    var isError = false
    var typography: UMCTypography = .title4Regular

    var body: some View {
        Label(message, systemImage: isError ? "exclamationmark.circle" : "info.circle")
            .umcTypography(typography)
            .foregroundStyle(isError ? UMCColor.Semantic.textError :
                palette.textNeutralMedium600)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
    }
}

struct SettingsAvatar: View {
    @Environment(\.settingsAppearancePalette) private var palette
    var url: URL?
    var size: CGFloat = 64
    var usesDesignImage = false

    var body: some View {
        Group {
            #if DEBUG || UMC_PRERELEASE
            if usesDesignImage {
                Image("settingsProfileFixture", bundle: .module)
                    .resizable()
                    .scaledToFill()
            } else {
                remoteImage
            }
            #else
            remoteImage
            #endif
        }
        .frame(width: size, height: size)
        .background(palette.fillNeutralMedium100, in: .circle)
        .clipShape(.circle)
        .overlay { Circle().strokeBorder(palette.borderNeutralWeak200) }
        .accessibilityHidden(true)
    }

    private var remoteImage: some View {
        AsyncImage(url: url) { phase in
            if let image = phase.image {
                image.resizable().scaledToFill()
            } else {
                Image(systemName: "person.fill")
                    .resizable()
                    .scaledToFit()
                    .padding(size * 0.22)
                    .foregroundStyle(palette.iconNeutralMedium500)
            }
        }
    }
}

/// Shared field geometry for settings selections, including the theme popover.
struct SettingsSelectionField<Content: View>: View {
    @Environment(\.settingsAppearancePalette) private var palette
    @ViewBuilder var content: Content

    var body: some View {
        HStack(spacing: UMCSpacing.value8) {
            content
            Spacer(minLength: UMCSpacing.value8)
            Image(systemName: "chevron.up.chevron.down")
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(palette.iconNeutralMedium500)
                .accessibilityHidden(true)
        }
        .umcTypography(.headlineRegular)
        .foregroundStyle(palette.textNeutralStrong800)
        .padding(.horizontal, UMCSpacing.value12)
        .frame(width: 268, height: 32)
        .background(palette.backgroundSurfaceGreyWeaker,
            in: .rect(cornerRadius: UMCRadius.value8))
        .overlay {
            RoundedRectangle(cornerRadius: UMCRadius.value8)
                .strokeBorder(palette.borderNeutralWeak200, lineWidth: 1)
        }
        .contentShape(.rect)
    }
}
