//
//  TypographyTests.swift
//  CoreDesignSystemTests
//
//  Created by euijjang97 on 10/8/26.
//

import AppKit
import CoreDesignSystem
import CoreText
import SwiftUI
import Testing

@Suite("Figma typography")
@MainActor
struct TypographyTests {
    @Test("Pretendard faces resolve from the module bundle", arguments: [
        (UMCTypography.largeTitle1Regular, "Pretendard-Regular"),
        (UMCTypography.largeTitle1Bold, "Pretendard-Bold"),
    ])
    func fontsLoadFromModuleBundle(style: UMCTypography, postScriptName: String) throws {
        let font = style.font.resolve(in: EnvironmentValues().fontResolutionContext).ctFont
        let url = try #require(CTFontCopyAttribute(font, kCTFontURLAttribute) as? URL)

        #expect(CTFontCopyPostScriptName(font) as String == postScriptName)
        #expect(CTFontGetSize(font) == 36)
        #expect(url.path.contains("CoreDesignSystem_CoreDesignSystem.bundle"))
        #expect(url.lastPathComponent == postScriptName + ".otf")
    }

    @Test("Line boxes retain Figma's 150, 130 and 140 percent heights", arguments: [
        (UMCTypography.largeTitle1Bold, CGFloat(54)),
        (UMCTypography.title1Regular, CGFloat(28.6)),
        (UMCTypography.title3Regular, CGFloat(22.4)),
    ])
    func lineBoxesMatchFigma(style: UMCTypography, height: CGFloat) {
        for lineCount in [1, 2] {
            let text = Array(repeating: "UMC 디자인", count: lineCount).joined(separator: "\n")
            let view = NSHostingView(rootView: Text(text).umcTypography(style).fixedSize())

            #expect(abs(view.fittingSize.height - height * CGFloat(lineCount)) < 1)
        }
    }

    @Test("Negative Figma tracking reduces the rendered text width")
    func trackingAppliesToText() {
        let text = "HHHHHHHHHH"
        let style = UMCTypography.largeTitle1Bold
        let styled = NSHostingView(rootView: Text(text).umcTypography(style).fixedSize())
        let untracked = NSHostingView(rootView: Text(text).font(style.font).fixedSize())
        let difference = untracked.fittingSize.width - styled.fittingSize.width

        #expect(difference > 6)
        #expect(difference < 9)
    }
}
