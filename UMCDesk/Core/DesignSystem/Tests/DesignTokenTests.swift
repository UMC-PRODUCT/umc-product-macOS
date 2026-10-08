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
    @Test("Primitive colors load from the design module resource bundle")
    func primitiveColorLoadsFromModuleBundle() throws {
        let color = try #require(
            NSColor(UMCColor.Primitives.teal500).usingColorSpace(.sRGB)
        )

        #expect(abs(color.redComponent) < 0.00001)
        #expect(abs(color.greenComponent - 0.5411764979362488) < 0.00001)
        #expect(abs(color.blueComponent - 0.501960813999176) < 0.00001)
        #expect(color.alphaComponent == 1)
    }

    @Test("Base white preserves normalized color components")
    func whitePreservesNormalizedComponents() throws {
        let color = try #require(NSColor(UMCColor.Primitives.white).usingColorSpace(.sRGB))

        #expect(color.redComponent == 1)
        #expect(color.greenComponent == 1)
        #expect(color.blueComponent == 1)
        #expect(color.alphaComponent == 1)
    }

    @Test("Semantic text retains its Figma primitive alias")
    func semanticTextRetainsPrimitiveAlias() throws {
        let color = try #require(
            NSColor(UMCColor.Semantic.textNeutralDefault).usingColorSpace(.sRGB)
        )

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
        let resolved = try #require(NSColor(color).usingColorSpace(.sRGB))

        #expect(abs(resolved.redComponent - 0.05882352963089943) < 0.00001)
        #expect(abs(resolved.greenComponent - 0.062745101749897) < 0.00001)
        #expect(abs(resolved.blueComponent - 0.062483664602041245) < 0.00001)
        #expect(abs(resolved.alphaComponent - opacity) < 0.00001)
    }
}
