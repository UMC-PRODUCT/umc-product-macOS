//
//  SettingsComponents.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/20/26.
//

import CoreDesignSystem
import SwiftUI

struct SettingsCard<Content: View>: View {
    var isSubtle = false
    var minimumHeight: CGFloat?
    @ViewBuilder let content: Content

    var body: some View {
        content
            .padding(UMCSpacing.value24)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: minimumHeight, alignment: .topLeading)
            .background(
                isSubtle ? UMCColor.Custom.backgroundSurfaceGreyWeaker :
                    UMCColor.Custom.backgroundSurfaceWhite,
                in: .rect(cornerRadius: UMCRadius.value16)
            )
            .overlay {
                RoundedRectangle(cornerRadius: UMCRadius.value16)
                    .strokeBorder(UMCColor.Semantic.borderNeutralWeak200, lineWidth: 1)
            }
    }
}

struct SettingsRow<Accessory: View>: View {
    let title: String
    let description: String
    @ViewBuilder let accessory: Accessory

    var body: some View {
        HStack(spacing: UMCSpacing.value24) {
            VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                Text(title)
                    .umcTypography(.title2Bold)
                    .foregroundStyle(UMCColor.Semantic.textNeutralStrong800)
                if !description.isEmpty {
                    Text(description)
                        .umcTypography(.title4Regular)
                        .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            accessory
        }
        .frame(minHeight: 52)
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            Text(title)
                .umcTypography(.title2Regular)
                .foregroundStyle(UMCColor.Semantic.textNeutralStrong800)
                .accessibilityAddTraits(.isHeader)
            content
        }
    }
}

struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(UMCColor.Semantic.borderNeutralWeak200)
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
            .umcTypography(.title4Regular)
            .padding(.horizontal, UMCSpacing.value16)
            .frame(minWidth: 64, maxWidth: fillsWidth ? .infinity : nil, minHeight: 40)
            .contentShape(.rect(cornerRadius: UMCRadius.value12))
        }
        .buttonStyle(SettingsButtonStyle(kind: kind))
    }
}

struct SettingsButtonStyle: ButtonStyle {
    let kind: SettingsButtonKind
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foreground)
            .background(background.opacity(configuration.isPressed ? 0.75 : 1),
                in: .rect(cornerRadius: UMCRadius.value12))
            .overlay {
                RoundedRectangle(cornerRadius: UMCRadius.value12)
                    .strokeBorder(kind == .secondary ?
                        UMCColor.Semantic.borderNeutralWeak200 : .clear, lineWidth: 1)
            }
            .opacity(isEnabled ? 1 : 0.45)
    }

    private var foreground: Color {
        switch kind {
        case .primary: UMCColor.Custom.backgroundTextWhite
        case .destructive: UMCColor.Semantic.textError
        case .brand: UMCColor.Semantic.textBrandDefault
        case .secondary, .quiet: UMCColor.Semantic.textNeutralMedium600
        }
    }

    private var background: Color {
        switch kind {
        case .primary: UMCColor.Semantic.fillPrimaryInverseStrong500
        case .brand: UMCColor.Semantic.fillPrimaryWeak75
        case .secondary: UMCColor.Custom.backgroundSurfaceWhite
        case .quiet: UMCColor.Custom.backgroundSurfaceGreyWeak
        case .destructive: UMCColor.Semantic.fillErrorWeak50
        }
    }
}

struct SettingsStatusText: View {
    let text: String

    var body: some View {
        Text(text)
            .umcTypography(.title4Regular)
            .foregroundStyle(UMCColor.Semantic.textBrandDefault)
            .fixedSize()
    }
}

struct SettingsInlineMessage: View {
    let message: String
    var isError = false

    var body: some View {
        Label(message, systemImage: isError ? "exclamationmark.circle" : "info.circle")
            .umcTypography(.title4Regular)
            .foregroundStyle(isError ? UMCColor.Semantic.textError :
                UMCColor.Semantic.textNeutralMedium600)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
    }
}

struct SettingsAvatar: View {
    var url: URL?
    var size: CGFloat = 64
    var usesDesignImage = false

    var body: some View {
        Group {
            #if DEBUG
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
        .background(UMCColor.Semantic.fillNeutralMedium100, in: .circle)
        .clipShape(.circle)
        .overlay { Circle().strokeBorder(UMCColor.Semantic.borderNeutralWeak200) }
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
                    .foregroundStyle(UMCColor.Semantic.iconNeutralMedium500)
            }
        }
    }
}
