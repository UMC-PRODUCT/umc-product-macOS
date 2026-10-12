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
    @Test("The brand panel preserves Figma's Light override inside a Dark screen",
        arguments: [ColorScheme.light, .dark])
    func brandPanelPreservesLightOverride(scheme: ColorScheme) throws {
        let viewModel = AuthViewModel()
        #if DEBUG
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
