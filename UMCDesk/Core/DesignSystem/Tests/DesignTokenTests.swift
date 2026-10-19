//
//  DesignTokenTests.swift
//  CoreDesignSystemTests
//
//  Created by euijjang97 on 10/8/26.
//

import AppKit
import CoreDesignSystem
import SwiftUI
import Testing

@Suite("Figma design tokens")
struct DesignTokenTests {
    private static let darkPalette: [(Color, [CGFloat])] = [
        (UMCColor.Primitives.white, [CGFloat(0), 0, 0, 1]),
        (UMCColor.Primitives.black, [CGFloat(1), 1, 1, 1]),
        (UMCColor.Semantic.backgroundDefault, [CGFloat(0), 0, 0, 1]),
        (UMCColor.Semantic.textInverse, [CGFloat(0), 0, 0, 1]),
        (UMCColor.Semantic.textNeutralDefault, [CGFloat(242) / 255, 245 / 255, 245 / 255, 1]),
        (UMCColor.Semantic.fillPrimaryWeaker50, [CGFloat(8) / 255, 38 / 255, 36 / 255, 1]),
        (UMCColor.Semantic.iconBrandMedium500, [CGFloat(69) / 255, 189 / 255, 180 / 255, 1]),
        (UMCColor.Semantic.borderNeutralMedium300, [CGFloat(56) / 255, 59 / 255, 59 / 255, 1]),
        (UMCColor.Semantic.fillNeutralDisabled, [CGFloat(29) / 255, 32 / 255, 32 / 255, 1]),
        (UMCColor.Primitives.yellow900, [CGFloat(252) / 255, 234 / 255, 198 / 255, 1]),
        (UMCColor.Primitives.violet50, [CGFloat(64) / 255, 48 / 255, 79 / 255, 1]),
        (UMCColor.Primitives.violet500, [CGFloat(169) / 255, 111 / 255, 235 / 255, 1]),
        (UMCColor.Primitives.purple50, [CGFloat(41) / 255, 36 / 255, 53 / 255, 1]),
        (UMCColor.Primitives.purple500, [CGFloat(148) / 255, 117 / 255, 226 / 255, 1]),
        (UMCColor.Primitives.pink50, [CGFloat(64) / 255, 36 / 255, 47 / 255, 1]),
        (UMCColor.Primitives.pink500, [CGFloat(231) / 255, 95 / 255, 159 / 255, 1]),
        (UMCColor.Primitives.cobalt50, [CGFloat(32) / 255, 42 / 255, 66 / 255, 1]),
        (UMCColor.Primitives.cobalt500, [CGFloat(100) / 255, 132 / 255, 245 / 255, 1]),
        (UMCColor.Primitives.blue50, [CGFloat(31) / 255, 43 / 255, 59 / 255, 1]),
        (UMCColor.Primitives.blue500, [CGFloat(91) / 255, 154 / 255, 245 / 255, 1]),
        (UMCColor.Primitives.brown50, [CGFloat(48) / 255, 42 / 255, 37 / 255, 1]),
        (UMCColor.Primitives.brown500, [CGFloat(185) / 255, 139 / 255, 98 / 255, 1]),
        (UMCColor.Custom.backgroundDefault, [CGFloat(23) / 255, 25 / 255, 25 / 255, 1]),
        (UMCColor.Custom.backgroundAppShell, [CGFloat(15) / 255, 16 / 255, 16 / 255, 1]),
        (UMCColor.Custom.backgroundSurface, [CGFloat(29) / 255, 32 / 255, 32 / 255, 1]),
    ]

    @Test("Dark appearance resolves the Figma Dark palette", arguments: darkPalette)
    func darkAppearanceResolvesPalette(color: Color, components: [CGFloat]) throws {
        let value = try resolvedColor(color, appearance: .darkAqua)
        let actual = [value.redComponent, value.greenComponent,
            value.blueComponent, value.alphaComponent]
        for (actual, expected) in zip(actual, components) {
            #expect(abs(actual - expected) < 0.00001)
        }
    }

    @Test("Primitive colors load from the design module resource bundle")
    func primitiveColorLoadsFromModuleBundle() throws {
        let color = try resolvedColor(UMCColor.Primitives.teal500)

        #expect(abs(color.redComponent) < 0.00001)
        #expect(abs(color.greenComponent - 0.5411764979362488) < 0.00001)
        #expect(abs(color.blueComponent - 0.501960813999176) < 0.00001)
        #expect(color.alphaComponent == 1)
    }

    @Test("Base white preserves normalized color components")
    func whitePreservesNormalizedComponents() throws {
        let color = try resolvedColor(UMCColor.Primitives.white)

        #expect(color.redComponent == 1)
        #expect(color.greenComponent == 1)
        #expect(color.blueComponent == 1)
        #expect(color.alphaComponent == 1)
    }

    @Test("Semantic text retains its Figma primitive alias")
    func semanticTextRetainsPrimitiveAlias() throws {
        let color = try resolvedColor(UMCColor.Semantic.textNeutralDefault)

        #expect(abs(color.redComponent - 0.05882352963089943) < 0.00001)
        #expect(abs(color.greenComponent - 0.062745101749897) < 0.00001)
        #expect(abs(color.blueComponent - 0.062483664602041245) < 0.00001)
        #expect(color.alphaComponent == 1)
    }

    @Test("Dimmed overlays preserve Figma percentage opacity", arguments: [
        (UMCColor.Semantic.dimmedWeak, CGFloat(0.20)),
        (UMCColor.Semantic.dimmedMedium, CGFloat(0.65)),
        (UMCColor.Semantic.dimmedStrong, CGFloat(0.85)),
    ])
    func dimmedOverlaysPreserveOpacity(color: Color, opacity: CGFloat) throws {
        for appearance in [NSAppearance.Name.aqua, .darkAqua] {
            let resolved = try resolvedColor(color, appearance: appearance)
            let expected: [CGFloat] = appearance == .aqua ?
                [0.05882352963089943, 0.062745101749897, 0.062483664602041245] :
                [242 / 255, 245 / 255, 245 / 255]
            #expect(abs(resolved.redComponent - expected[0]) < 0.00001)
            #expect(abs(resolved.greenComponent - expected[1]) < 0.00001)
            #expect(abs(resolved.blueComponent - expected[2]) < 0.00001)
            #expect(abs(resolved.alphaComponent - opacity) < 0.00001)
        }
    }

    @Test("Library aliases retain their identical Light and Dark values", arguments: [
        UMCColor.Semantic.fillNeutralStronger300,
        UMCColor.Semantic.fillNeutralStrongerHoverPressed,
    ])
    func libraryAliasesRetainValues(color: Color) throws {
        let light = try resolvedColor(color)
        let dark = try resolvedColor(color, appearance: .darkAqua)
        #expect(abs(light.redComponent - dark.redComponent) < 0.00001)
        #expect(abs(light.greenComponent - dark.greenComponent) < 0.00001)
        #expect(abs(light.blueComponent - dark.blueComponent) < 0.00001)
        #expect(light.alphaComponent == dark.alphaComponent)
    }

    @Test("Custom surfaces preserve their Light and Dark Figma values", arguments: [
        (UMCColor.Custom.backgroundSurfaceWhite, [255, 255, 255, 255], [29, 32, 32, 255]),
        (UMCColor.Custom.backgroundSurfaceGreyWeaker, [251, 252, 252, 255], [29, 32, 32, 255]),
        (UMCColor.Custom.backgroundSurfaceGreyWeak, [239, 240, 240, 255], [56, 59, 59, 255]),
        (UMCColor.Custom.backgroundTagGrey, [239, 240, 240, 255], [56, 59, 59, 255]),
        (UMCColor.Custom.backgroundDimmed, [15, 16, 16, 51], [0, 0, 0, 102]),
        (UMCColor.Custom.backgroundTextWhite, [255, 255, 255, 255], [255, 255, 255, 255]),
    ])
    func customSurfacesPreserveAppearances(color: Color, light: [Int], dark: [Int]) throws {
        for (appearance, expected) in [(NSAppearance.Name.aqua, light), (.darkAqua, dark)] {
            let color = try resolvedColor(color, appearance: appearance)
            let actual = [color.redComponent, color.greenComponent,
                color.blueComponent, color.alphaComponent]
            for (actual, expected) in zip(actual, expected) {
                #expect(abs(actual - CGFloat(expected) / 255) < 0.00001)
            }
        }
    }

    private func resolvedColor(
        _ color: Color, appearance name: NSAppearance.Name = .aqua
    ) throws -> NSColor {
        let appearance = try #require(NSAppearance(named: name))
        var resolved: NSColor?
        appearance.performAsCurrentDrawingAppearance {
            resolved = NSColor(color).usingColorSpace(.sRGB)
        }
        return try #require(resolved)
    }
}
