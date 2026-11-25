//  DeskPaper.swift
//  HomePresentation
//
//  Created by euijjang97 on 11/25/26.
//

import SwiftUI

/// Surface colours follow the approved printed-paper palettes in both appearances.
struct DeskPaper {
    let dark: Bool

    private func color(_ light: UInt32, _ night: UInt32) -> Color {
        let rgb = dark ? night : light
        return Color(red: Double(rgb >> 16) / 255, green: Double((rgb >> 8) & 255) / 255,
                     blue: Double(rgb & 255) / 255)
    }

    var background: Color { color(0xF7F8F5, 0x171C1B) }
    var mint: Color { color(0xE6F3EB, 0x143D38) }
    var ink: Color { color(0x173E35, 0xECF8F1) }
    var muted: Color { color(0x3B6054, 0xBBD8CB) }
    var panel: Color { color(0xFFFFFF, 0x242B29) }
    var button: Color { color(0x245843, 0xB2DFCA) }
    var buttonText: Color { color(0xFFFFFF, 0x173E35) }
}

struct DeskPaperSurface: View {
    let paper: DeskPaper
    let showsCalendar: Bool
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 18)
        ZStack {
            shape.fill(paper.muted.opacity(0.30)).offset(y: 5)
            shape.fill(paper.mint).offset(y: 3)
            shape.strokeBorder(paper.muted.opacity(0.23)).offset(y: 3)
            ZStack(alignment: .bottomTrailing) {
                paper.mint
                Image("desk-paper", bundle: .module)
                    .resizable(resizingMode: .tile).opacity(paper.dark ? 0.45 : 0.35)
                if showsCalendar {
                    Image("desk-calendar", bundle: .module)
                        .resizable().scaledToFit()
                        .frame(maxWidth: 245, maxHeight: 272, alignment: .bottomTrailing)
                        .mask {
                            LinearGradient(stops: [.init(color: .clear, location: 0),
                                                   .init(color: .black, location: 0.23)],
                                           startPoint: .leading, endPoint: .trailing)
                        }
                }
            }
            .clipShape(shape)
            shape.strokeBorder(paper.muted.opacity(contrast == .increased ? 0.8 : 0.20))
        }
        .shadow(color: .black.opacity(paper.dark ? 0.22 : 0.08), radius: 4, y: 4)
        .accessibilityHidden(true)
        .allowsHitTesting(false)
    }
}
