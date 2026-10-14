//
//  AuthStatusIcon.swift
//  AuthPresentation
//
//  Created by euijjang97 on 10/13/26.
//

import CoreDesignSystem
import SwiftUI

enum AuthStatusIcon: CaseIterable {
    case offline
    case loginFailure
    case memberFailure
    case sessionExpired
    case signupComplete
    case challengerPending
    case passwordComplete
    case maintenance
    case update
    case updateError
    case logout
    case withdrawal

    var systemName: String {
        switch self {
        case .offline: "wifi.exclamationmark"
        case .loginFailure: "person.crop.circle.badge.xmark"
        case .memberFailure: "person.crop.circle.badge.exclamationmark"
        case .sessionExpired: "arrow.clockwise.circle"
        case .signupComplete: "person.badge.plus"
        case .challengerPending: "person.badge.clock"
        case .passwordComplete: "key.fill"
        case .maintenance: "wrench.and.screwdriver.fill"
        case .update: "arrow.down.circle.fill"
        case .updateError: "xmark.circle"
        case .logout: "rectangle.portrait.and.arrow.right"
        case .withdrawal: "info.circle"
        }
    }

    var glyphSize: CGFloat {
        switch self {
        case .sessionExpired, .update, .updateError, .withdrawal: 40
        case .passwordComplete: 48
        default: 44
        }
    }

    // SF Symbols' optical margins otherwise shift these glyphs inside a centered frame.
    var centeringOffset: CGSize {
        switch self {
        case .loginFailure, .memberFailure: CGSize(width: -1, height: 1.25)
        case .signupComplete, .challengerPending: CGSize(width: 1.5, height: 1.5)
        case .logout: CGSize(width: 1.5, height: 0)
        default: .zero
        }
    }

    var foreground: Color {
        isError ? UMCColor.Semantic.iconError : UMCColor.Semantic.iconBrandMedium500
    }

    var background: Color {
        isError ? UMCColor.Semantic.fillErrorWeak50 : UMCColor.Semantic.fillPrimaryWeaker50
    }

    private var isError: Bool {
        self == .updateError || self == .withdrawal
    }
}

struct AuthStatusIconView: View {
    // MARK: - Property

    let icon: AuthStatusIcon
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var effectTrigger = false

    // MARK: - Body

    var body: some View {
        ZStack {
            Circle().fill(icon.background)
            animatedSymbol
                .scaledToFit()
                .symbolRenderingMode(.monochrome)
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(icon.foreground)
                .frame(width: icon.glyphSize, height: icon.glyphSize)
                .offset(icon.centeringOffset)
        }
        .frame(width: 80, height: 80)
        .accessibilityHidden(true)
        .task(id: icon) {
            guard !Task.isCancelled, !reduceMotion else { return }
            effectTrigger.toggle()
        }
    }

    @ViewBuilder
    private var animatedSymbol: some View {
        let image = Image(systemName: icon.systemName).resizable()
            .symbolEffectsRemoved(reduceMotion)
        switch icon {
        case .signupComplete, .passwordComplete:
            image.symbolEffect(.bounce.up, options: .nonRepeating, value: effectTrigger)
        case .loginFailure, .memberFailure, .updateError:
            image.symbolEffect(.wiggle, options: .nonRepeating.speed(1.5), value: effectTrigger)
        default:
            image.symbolEffect(.pulse, options: .nonRepeating, value: effectTrigger)
        }
    }
}

#if DEBUG
#Preview("Status symbol motion") {
    @Previewable @State var replay = false
    VStack(spacing: UMCSpacing.value24) {
        Button("Replay") { replay.toggle() }
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4),
            spacing: UMCSpacing.value24) {
            ForEach(AuthStatusIcon.allCases, id: \.systemName) { icon in
                VStack(spacing: UMCSpacing.value8) {
                    AuthStatusIconView(icon: icon)
                    Text(icon.systemName)
                        .umcTypography(.captionRegular)
                        .foregroundStyle(UMCColor.Semantic.textNeutralDefault)
                }
            }
        }
        .id(replay)
    }
    .padding(UMCSpacing.value24)
    .frame(width: 720)
    .background(UMCColor.Custom.backgroundDefault)
}
#endif
