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
    @Test("Progress fill stays within its track", arguments: [
        (0.0, 0.0), (0.5, 100.0), (1.0, 200.0),
        (-1.0, 0.0), (2.0, 200.0), (Double.nan, 0.0),
    ])
    func progressFillStaysWithinTrack(progress: Double, expectedWidth: Double) {
        let fill = AuthDownloadProgressFill(fractionCompleted: progress)
        let path = fill.path(in: CGRect(x: 12, y: 8, width: 200, height: 5))

        #expect(abs(path.boundingRect.width - expectedWidth) < 0.001)
        #expect(!path.contains(CGPoint(x: 11, y: 10)))
        #expect(!path.contains(CGPoint(x: 213, y: 10)))
    }

    @Test("Authentication keeps the brand left and expands input forms", arguments: [
        (CGSize(width: 1040, height: 720), CGFloat(416), CGFloat(624), CGFloat(560), CGFloat(500)),
        (CGSize(width: 1440, height: 960), CGFloat(576), CGFloat(864), CGFloat(652), CGFloat(500)),
        (CGSize(width: 2560, height: 1440), CGFloat(576), CGFloat(1984),
            CGFloat(1080), CGFloat(800)),
        (CGSize(width: 3008, height: 1692), CGFloat(576), CGFloat(2432),
            CGFloat(1080), CGFloat(800)),
    ], [ColorScheme.light, .dark])
    func authenticationInputFormsExpand(
        window: (size: CGSize, brandBoundary: CGFloat, viewportWidth: CGFloat,
            registrationWidth: CGFloat, loginWidth: CGFloat), scheme: ColorScheme
    ) throws {
        for screen in [AuthScreen.signup, .passwordReset, .emailLogin,
            .credentialsError, .loginSelection] {
            let viewModel = AuthViewModel()
            viewModel.screen = screen
            #if DEBUG || UMC_PRERELEASE
            viewModel.playsPreviewFlow = false
            #endif
            let contentWidth: CGFloat
            switch screen {
            case .signup:
                contentWidth = window.registrationWidth
            case .passwordReset:
                contentWidth = window.registrationWidth
            case .emailLogin, .credentialsError:
                contentWidth = window.loginWidth
            default:
                contentWidth = 500
            }
            try withAuthWindow(size: window.size, scheme: scheme, viewModel: viewModel) { host in
                #expect(host.frame.size == window.size)
                let scrollView: NSScrollView = try #require(descendant(in: host))
                let viewportFrame = host.convert(scrollView.bounds, from: scrollView)
                #expect(abs(viewportFrame.minX - window.brandBoundary) < 0.5)
                #expect(abs(viewportFrame.width - window.viewportWidth) < 0.5)
                #expect(abs(viewportFrame.minY) < 0.5)
                #expect(abs(viewportFrame.height - window.size.height) < 0.5)
                if screen == .loginSelection {
                    let bitmap = try snapshot(of: host)
                    let buttonWidth = try kakaoButtonWidth(in: bitmap, viewport: viewportFrame,
                        hostWidth: host.bounds.width)
                    #expect(abs(buttonWidth - contentWidth) <= 1)
                } else {
                    let fields: [NSTextField] = descendants(in: scrollView).filter(\.isEditable)
                    let first = try #require(fields.first)
                    let firstFrame = host.convert(first.bounds, from: first)
                    #expect(viewportFrame.contains(firstFrame))
                    #expect(firstFrame.width > (window.size.width > 1440 ? 500 : 200))
                    // AppKit text bounds leave 24pt of input padding outside the native field.
                    let measuredContentWidth: CGFloat
                    if screen == .signup {
                        #expect(fields.count >= 2)
                        let second = try #require(fields.dropFirst().first)
                        let secondFrame = host.convert(second.bounds, from: second)
                        measuredContentWidth = firstFrame.union(secondFrame).width + 24
                    } else if screen == .passwordReset {
                        // 183pt verification button + 12pt gap + 24pt text padding.
                        measuredContentWidth = firstFrame.width + 219
                    } else {
                        measuredContentWidth = firstFrame.width + 24
                    }
                    #expect(abs(measuredContentWidth - contentWidth) < 0.5)
                }
                if screen == .signup {
                    let bitmap = try snapshot(of: host)
                    let scale = CGFloat(bitmap.pixelsWide) / host.bounds.width
                    let brand = try #require(bitmap.colorAt(
                        x: Int((window.brandBoundary - 2) * scale), y: Int(24 * scale)
                    )?.usingColorSpace(.sRGB))
                    let form = try #require(bitmap.colorAt(
                        x: Int((window.brandBoundary + 2) * scale), y: Int(24 * scale)
                    )?.usingColorSpace(.sRGB))
                    let logo = try #require(bitmap.colorAt(
                        x: Int(80 * scale), y: Int(80 * scale)
                    )?.usingColorSpace(.sRGB))

                    #expect(brand.redComponent < 0.1)
                    #expect(brand.greenComponent < 0.3)
                    #expect(brand.blueComponent < 0.3)
                    #expect(scheme == .dark ? form.redComponent < 0.2 : form.redComponent > 0.9)
                    #expect(logo.redComponent > 0.9)
                    #expect(logo.greenComponent > 0.9)
                    #expect(logo.blueComponent > 0.9)
                }
            }
        }
    }

    @Test("Long registration starts at the top and keeps its final action reachable",
        arguments: [CGSize(width: 1040, height: 720), CGSize(width: 1440, height: 960)])
    func longRegistrationRemainsScrollable(size: CGSize) throws {
        let viewModel = AuthViewModel()
        viewModel.screen = .signup
        viewModel.form.email = "test@example.com"
        viewModel.form.emailVerification = .verified
        viewModel.form.school = "가톨릭대학교"
        viewModel.form.showsPasswordError = true
        #if DEBUG || UMC_PRERELEASE
        viewModel.playsPreviewFlow = false
        #endif
        try withAuthWindow(size: size, scheme: .light, viewModel: viewModel) { host in
            let scrollView: NSScrollView = try #require(descendant(in: host))
            let document = try #require(scrollView.documentView)
            let viewport = scrollView.contentView
            if document.bounds.height > viewport.bounds.height {
                #expect(abs(viewport.bounds.minY) < 0.5)
                viewport.scroll(to: CGPoint(
                    x: 0, y: document.bounds.height - viewport.bounds.height
                ))
                scrollView.reflectScrolledClipView(viewport)
                #expect(abs(scrollView.documentVisibleRect.maxY - document.bounds.maxY) < 0.5)
            } else {
                let centeredOrigin = (document.bounds.height - viewport.bounds.height) / 2
                #expect(abs(viewport.bounds.minY - centeredOrigin) < 0.5)
            }
        }
    }

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
        arguments: [CGSize(width: 1040, height: 720), CGSize(width: 1440, height: 908)],
        [ColorScheme.light, .dark])
    func brandPanelPreservesLightOverride(size: CGSize, scheme: ColorScheme) throws {
        let viewModel = AuthViewModel()
        viewModel.screen = .signup
        #if DEBUG || UMC_PRERELEASE
        viewModel.playsPreviewFlow = false
        #endif
        try withAuthWindow(size: size, scheme: scheme, viewModel: viewModel) { host in
            let bitmap = try snapshot(of: host)
            let scale = CGFloat(bitmap.pixelsWide) / host.bounds.width
            let background = try #require(bitmap.colorAt(
                x: Int(24 * scale), y: Int(24 * scale)
            )?.usingColorSpace(.sRGB))
            let logo = try #require(bitmap.colorAt(
                x: Int(80 * scale), y: Int(80 * scale)
            )?.usingColorSpace(.sRGB))
            let content = try #require(bitmap.colorAt(
                x: Int((size.width - 10) * scale), y: Int(24 * scale)
            )?.usingColorSpace(.sRGB))

            #expect(background.redComponent < 0.1)
            #expect(background.greenComponent < 0.3)
            #expect(background.blueComponent < 0.3)
            #expect(logo.redComponent > 0.9)
            #expect(logo.greenComponent > 0.9)
            #expect(logo.blueComponent > 0.9)
            #expect(scheme == .dark ? content.redComponent < 0.2 : content.redComponent > 0.9)
        }
    }

    private func withAuthWindow(
        size: CGSize, scheme: ColorScheme, viewModel: AuthViewModel,
        check: (NSView) throws -> Void
    ) rethrows {
        let controller = NSHostingController(rootView: AuthView(viewModel: viewModel)
            .environment(\.colorScheme, scheme)
            .frame(minWidth: 1040, minHeight: 720))
        let window = NSWindow(contentViewController: controller)
        window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
        window.toolbarStyle = .unifiedCompact
        window.titleVisibility = .hidden
        let host = controller.view
        defer { window.contentView = nil }
        window.setContentSize(size)
        host.layoutSubtreeIfNeeded()
        window.displayIfNeeded()
        try check(host)
    }

    private func snapshot(of view: NSView) throws -> NSBitmapImageRep {
        let bitmap = try #require(view.bitmapImageRepForCachingDisplay(in: view.bounds))
        view.cacheDisplay(in: view.bounds, to: bitmap)
        return bitmap
    }

    private func descendant<Content: NSView>(in view: NSView) -> Content? {
        for child in view.subviews {
            if let match = child as? Content { return match }
            if let match: Content = descendant(in: child) { return match }
        }
        return nil
    }

    private func descendants<Content: NSView>(in view: NSView) -> [Content] {
        view.subviews.flatMap { child in
            let matches = (child as? Content).map { [$0] } ?? []
            return matches + descendants(in: child)
        }
    }

    private func kakaoButtonWidth(
        in bitmap: NSBitmapImageRep, viewport: CGRect, hostWidth: CGFloat
    ) throws -> CGFloat {
        let scale = CGFloat(bitmap.pixelsWide) / hostWidth
        let centerX = Int(viewport.midX * scale)
        func isYellow(x: Int, y: Int) -> Bool {
            guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else {
                return false
            }
            // Calibrated display snapshots convert Kakao yellow to about 0.42 blue in sRGB.
            return color.redComponent > 0.9 && color.greenComponent > 0.8
                && color.blueComponent < 0.5
        }
        let top = try #require((0..<bitmap.pixelsHigh).first { isYellow(x: centerX, y: $0) })
        let centerY = min(bitmap.pixelsHigh - 1, top + Int(25 * scale))
        let pixels = (0..<bitmap.pixelsWide).filter { isYellow(x: $0, y: centerY) }
        let first = try #require(pixels.first)
        let last = try #require(pixels.last)
        return CGFloat(last - first + 1) / scale
    }
}
