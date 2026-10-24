//
//  TypographyTests.swift
//  CoreDesignSystemTests
//
//  Created by euijjang97 on 10/8/26.
//

import AppKit
@testable import CoreDesignSystem
import CoreText
import SwiftUI
import Testing

@Suite("Figma typography")
@MainActor
struct TypographyTests {
    @Test("Pretendard faces resolve from the module bundle", arguments: [
        (UMCTypography.largeTitle1Regular, "Pretendard-Regular", CGFloat(36)),
        (UMCTypography.largeTitle1Bold, "Pretendard-Bold", CGFloat(36)),
        (UMCTypography.title3Regular, "Pretendard-Regular", CGFloat(18)),
        (UMCTypography.title3Bold, "Pretendard-Bold", CGFloat(18)),
        (UMCTypography.title4Regular, "Pretendard-Regular", CGFloat(16)),
        (UMCTypography.title4Bold, "Pretendard-Bold", CGFloat(16)),
    ])
    func fontsLoadFromModuleBundle(
        style: UMCTypography,
        postScriptName: String,
        size: CGFloat
    ) throws {
        let font = style.font.resolve(in: EnvironmentValues().fontResolutionContext).ctFont
        let url = try #require(CTFontCopyAttribute(font, kCTFontURLAttribute) as? URL)

        #expect(CTFontCopyPostScriptName(font) as String == postScriptName)
        #expect(CTFontGetSize(font) == size)
        #expect(url.path.contains("CoreDesignSystem_CoreDesignSystem.bundle"))
        #expect(url.lastPathComponent == postScriptName + ".otf")
    }

    @Test("Line boxes retain Figma's 150, 130 and 140 percent heights", arguments: [
        (UMCTypography.largeTitle1Bold, CGFloat(54)),
        (UMCTypography.title1Regular, CGFloat(28.6)),
        (UMCTypography.title3Regular, CGFloat(25.2)),
        (UMCTypography.title3Bold, CGFloat(25.2)),
        (UMCTypography.title4Regular, CGFloat(22.4)),
        (UMCTypography.title4Bold, CGFloat(22.4)),
    ])
    func lineBoxesMatchFigma(style: UMCTypography, height: CGFloat) {
        for lineCount in [1, 2] {
            let text = Array(repeating: "UMC 디자인", count: lineCount).joined(separator: "\n")
            let view = NSHostingView(rootView: Text(text).umcTypography(style).fixedSize())

            #expect(abs(view.fittingSize.height - height * CGFloat(lineCount)) < 1)
        }
    }

    @Test("Negative Figma tracking reduces the rendered text width", arguments: [
        (UMCTypography.largeTitle1Bold, CGFloat(72)),
        (UMCTypography.title3Regular, CGFloat(18)),
        (UMCTypography.title3Bold, CGFloat(18)),
        (UMCTypography.title4Regular, CGFloat(16)),
        (UMCTypography.title4Bold, CGFloat(16)),
    ])
    func trackingAppliesToText(style: UMCTypography, widthReduction: CGFloat) {
        let text = String(repeating: "H", count: 100)
        let styled = NSHostingView(rootView: Text(text).umcTypography(style).fixedSize())
        let untracked = NSHostingView(rootView: Text(text).font(style.font).fixedSize())
        let difference = untracked.fittingSize.width - styled.fittingSize.width

        #expect(abs(difference - widthReduction) < 1)
    }

    @Test("Body preference scales descriptions and leaves headings unchanged")
    func bodyPreferenceScopesToDescriptions() {
        let description = NSHostingView(rootView: Text("설명")
            .umcTypography(.title4Regular)
            .environment(\.umcBodyTextScale, 1.3)
            .fixedSize())
        let heading = NSHostingView(rootView: Text("제목")
            .umcTypography(.title1Bold)
            .environment(\.umcBodyTextScale, 1.3)
            .fixedSize())
        #expect(abs(description.fittingSize.height - 22.4 * 1.3) < 1)
        #expect(abs(heading.fittingSize.height - 28.6) < 1)
    }

    @Test("Font preference changes rendered glyphs while keeping typography metrics")
    func fontPreferenceChangesRenderedText() {
        let text = "iiii WWWW 0123456789"
        let bundled = NSHostingView(rootView: Text(text)
            .umcTypography(.bodyRegular).fixedSize())
        let serif = NSHostingView(rootView: Text(text)
            .umcTypography(.bodyRegular)
            .environment(\.umcFontDesign, .serif).fixedSize())
        #expect(abs(bundled.fittingSize.width - serif.fittingSize.width) > 1)
        #expect(abs(bundled.fittingSize.height - serif.fittingSize.height) < 1)
        let resolved = UMCTypography.headlineBold.font(size: 18, weight: .bold, design: .rounded)
            .resolve(in: EnvironmentValues().fontResolutionContext).ctFont
        #expect(CTFontGetSize(resolved) == 18)
        #expect(CTFontCopyPostScriptName(resolved) as String != "Pretendard-Bold")
    }

    @Test("Installed font families resolve in the actual typography pipeline")
    func installedFontFamilyResolves() throws {
        let family = try #require(NSFontManager.shared.availableFontFamilies.first {
            $0 == "Arial" || $0 == "Helvetica Neue"
        })
        let font = UMCTypography.bodyRegular.font(size: 12, weight: .regular, family: family)
            .resolve(in: EnvironmentValues().fontResolutionContext).ctFont
        #expect(CTFontCopyFamilyName(font) as String == family)
        let bundled = NSHostingView(rootView: Text("iiii WWWW 0123456789")
            .umcTypography(.bodyRegular).fixedSize())
        let selected = NSHostingView(rootView: Text("iiii WWWW 0123456789")
            .umcTypography(.bodyRegular).environment(\.umcFontFamily, family).fixedSize())
        #expect(abs(bundled.fittingSize.width - selected.fittingSize.width) > 0.1)
    }

    #if DEBUG || UMC_PRERELEASE
    @Test("Preview changes the real font size and bundled face without changing tokens")
    func previewResolvesFont() {
        var preview = UMCTypographyPreview()
        preview.sizeScale = 1.25
        preview.weight = .bold
        let font = preview.font(for: .largeTitle1Regular)
            .resolve(in: EnvironmentValues().fontResolutionContext).ctFont

        #expect(CTFontGetSize(font) == 45)
        #expect(CTFontCopyPostScriptName(font) as String == "Pretendard-Bold")
        #expect(UMCTypography.largeTitle1Regular.size == 36)
    }

    @Test("Preview scales line boxes and adds tracking to rendered text")
    func previewChangesRenderedText() {
        var preview = UMCTypographyPreview()
        preview.sizeScale = 1.25
        preview.lineHeightScale = 1.2
        let text = "HHHHHHHHHH\nHHHHHHHHHH"
        let view = NSHostingView(rootView: Text(text)
            .umcTypography(.largeTitle1Regular)
            .environment(\.umcTypographyPreview, preview)
            .fixedSize())

        #expect(abs(view.fittingSize.height - 162) < 1)
        let originalWidth = view.fittingSize.width
        preview.trackingAdjustment = 2
        view.rootView = Text(text)
            .umcTypography(.largeTitle1Regular)
            .environment(\.umcTypographyPreview, preview)
            .fixedSize()

        #expect(view.fittingSize.width > originalWidth + 15)
    }

    @Test("Disabling preview restores design metrics and preserves adjustments")
    func previewCanCompareWithOriginal() {
        var preview = UMCTypographyPreview()
        preview.sizeScale = 1.5
        preview.weight = .bold
        preview.lineHeightScale = 1.4
        preview.trackingAdjustment = 3
        preview.isEnabled = false
        let font = preview.font(for: .largeTitle1Regular)
            .resolve(in: EnvironmentValues().fontResolutionContext).ctFont
        let view = NSHostingView(rootView: Text("UMC\n디자인")
            .umcTypography(.largeTitle1Regular)
            .environment(\.umcTypographyPreview, preview)
            .fixedSize())

        #expect(CTFontGetSize(font) == 36)
        #expect(CTFontCopyPostScriptName(font) as String == "Pretendard-Regular")
        #expect(abs(view.fittingSize.height - 108) < 1)
        #expect(preview.sizeScale == 1.5)
    }
    #endif
}
