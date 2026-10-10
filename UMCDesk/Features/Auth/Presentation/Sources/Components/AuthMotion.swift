//
//  AuthMotion.swift
//  AuthPresentation
//
//  Created by euijjang97 on 10/10/26.
//

import SwiftUI

enum AuthMotion {
    static func animation(reduceMotion: Bool, duration: Double = 0.22) -> Animation? {
        guard !reduceMotion else { return nil }
        return .timingCurve(0.23, 1, 0.32, 1, duration: duration)
    }

    static func pageTransition(reduceMotion: Bool) -> AnyTransition {
        .opacity.combined(with: .offset(y: reduceMotion ? 0 : 10))
    }

    static func dropdownTransition(reduceMotion: Bool) -> AnyTransition {
        .opacity.combined(with: .scale(scale: reduceMotion ? 1 : 0.98, anchor: .top))
    }
}

struct AuthPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.modifier(AuthPressFeedback(isPressed: configuration.isPressed))
    }
}

struct AuthPressFeedback: ViewModifier {
    let isPressed: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(!reduceMotion && isPressed ? 0.985 : 1)
            .opacity(isPressed ? 0.8 : isHovered && isEnabled ? 0.9 : 1)
            .animation(AuthMotion.animation(reduceMotion: reduceMotion, duration: 0.12),
                value: isPressed)
            .animation(AuthMotion.animation(reduceMotion: reduceMotion, duration: 0.12),
                value: isHovered)
            .onHover { isHovered = $0 }
    }
}
