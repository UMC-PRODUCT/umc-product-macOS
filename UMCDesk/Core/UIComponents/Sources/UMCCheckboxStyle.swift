//
//  UMCCheckboxStyle.swift
//  CoreUIComponents
//
//  Created by euijjang97 on 10/10/26.
//

import CoreDesignSystem
import SwiftUI

/// Shared macOS checkbox styling with an animated SF Symbol state transition.
public struct UMCCheckboxStyle: ToggleStyle {
    // MARK: - Property

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Init

    public init() { }

    // MARK: - Body

    public func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: UMCSpacing.value4) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(configuration.isOn ?
                        UMCColor.Semantic.textBrandDefault :
                        UMCColor.Semantic.borderNeutralMedium300)
                    .contentTransition(reduceMotion ? .identity : .symbolEffect(
                        .replace.magic(fallback: .replace), options: .speed(2)
                    ))
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.18),
                        value: configuration.isOn)
                    .frame(width: 32, height: 32)
                configuration.label
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.checkbox)
        }
    }
}

#if DEBUG
#Preview("Checkbox") {
    @Previewable @State var isOn = false
    Toggle("Checkbox", isOn: $isOn)
        .toggleStyle(UMCCheckboxStyle())
        .padding()
}

#endif
