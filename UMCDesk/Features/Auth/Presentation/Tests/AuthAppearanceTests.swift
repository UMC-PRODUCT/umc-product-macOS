//
//  AuthAppearanceTests.swift
//  AuthPresentationTests
//
//  Created by euijjang97 on 10/12/26.
//

import AppKit
import SwiftUI
import Testing
@testable import AuthPresentation

@MainActor
struct AuthAppearanceTests {
    @Test("Status symbols resolve and render centered in both appearances",
        arguments: AuthStatusIcon.allCases, [ColorScheme.light, .dark])
    func statusSymbolsRenderCentered(icon: AuthStatusIcon, scheme: ColorScheme) throws {
        _ = try #require(NSImage(systemSymbolName: icon.systemName, accessibilityDescription: nil))
        let renderer = ImageRenderer(content: AuthStatusIconView(icon: icon)
            .environment(\.colorScheme, scheme))
        renderer.scale = 3
        let appearance = try #require(NSAppearance(named: scheme == .dark ? .darkAqua : .aqua))
        var renderedImage: CGImage?
        appearance.performAsCurrentDrawingAppearance { renderedImage = renderer.cgImage }
        let bitmap = NSBitmapImageRep(cgImage: try #require(renderedImage))
        let background = try #require(bitmap.colorAt(x: 120, y: 24)?.usingColorSpace(.sRGB))
        var horizontalBounds: ClosedRange<Int>?
        var verticalBounds: ClosedRange<Int>?

        for y in 0..<bitmap.pixelsHigh {
            for x in 0..<bitmap.pixelsWide {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.sRGB),
                      color.alphaComponent > 0.95 else { continue }
                let difference = abs(color.redComponent - background.redComponent)
                    + abs(color.greenComponent - background.greenComponent)
                    + abs(color.blueComponent - background.blueComponent)
                guard difference > 0.3 else { continue }
                horizontalBounds = min(horizontalBounds?.lowerBound ?? x, x)...max(
                    horizontalBounds?.upperBound ?? x, x
                )
                verticalBounds = min(verticalBounds?.lowerBound ?? y, y)...max(
                    verticalBounds?.upperBound ?? y, y
                )
            }
        }

        let horizontal = try #require(horizontalBounds)
        let vertical = try #require(verticalBounds)
        let horizontalCenter = CGFloat(horizontal.lowerBound + horizontal.upperBound) / 2
        let verticalCenter = CGFloat(vertical.lowerBound + vertical.upperBound) / 2

        #expect(abs(horizontalCenter - CGFloat(bitmap.pixelsWide - 1) / 2) / renderer.scale <= 1)
        #expect(abs(verticalCenter - CGFloat(bitmap.pixelsHigh - 1) / 2) / renderer.scale <= 1)
        #expect(scheme == .dark
            ? background.greenComponent < 0.2 : background.greenComponent > 0.9)
    }

    @Test("The brand panel preserves Figma's Light override inside a Dark screen",
        arguments: [ColorScheme.light, .dark])
    func brandPanelPreservesLightOverride(scheme: ColorScheme) throws {
        let viewModel = AuthViewModel()
        #if DEBUG || UMC_PRERELEASE
        viewModel.playsPreviewFlow = false
        #endif
        let renderer = ImageRenderer(content: AuthView(viewModel: viewModel)
            .frame(width: 1440, height: 908)
            .environment(\.colorScheme, scheme))
        let bitmap = NSBitmapImageRep(cgImage: try #require(renderer.cgImage))
        let background = try #require(bitmap.colorAt(x: 24, y: 24)?.usingColorSpace(.sRGB))
        let logo = try #require(bitmap.colorAt(x: 80, y: 80)?.usingColorSpace(.sRGB))
        let content = try #require(bitmap.colorAt(x: 1430, y: 24)?.usingColorSpace(.sRGB))

        #expect(background.redComponent < 0.1)
        #expect(background.greenComponent < 0.3)
        #expect(background.blueComponent < 0.3)
        #expect(logo.redComponent > 0.9)
        #expect(logo.greenComponent > 0.9)
        #expect(logo.blueComponent > 0.9)
        #expect(scheme == .dark ? content.redComponent < 0.2 : content.redComponent > 0.9)
    }
}
