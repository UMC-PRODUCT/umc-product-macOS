//
//  CommunitySelectionTextStyle.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 11/24/26.
//

import AppKit
import SwiftUI

/// Matches the system text color to the native list selection highlight.
struct CommunitySelectionTextStyle: ShapeStyle {
    let isSelected: Bool
    let isListFocused: Bool
    let unselected: Color

    func resolve(in environment: EnvironmentValues) -> Color {
        guard isSelected else { return unselected }
        if environment.appearsActive && isListFocused {
            return Color(nsColor: .alternateSelectedControlTextColor)
        }
        return Color(nsColor: .unemphasizedSelectedTextColor)
    }
}
