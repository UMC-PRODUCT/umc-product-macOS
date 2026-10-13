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
    let icon: AuthStatusIcon

    var body: some View {
        ZStack {
            Circle().fill(icon.background)
            Image(systemName: icon.systemName)
                .resizable()
                .scaledToFit()
                .symbolRenderingMode(.monochrome)
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(icon.foreground)
                .frame(width: icon.glyphSize, height: icon.glyphSize)
                .offset(icon.centeringOffset)
        }
        .frame(width: 80, height: 80)
        .accessibilityHidden(true)
    }
}
