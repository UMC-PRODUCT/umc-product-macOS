//
//  UMCTypography.swift
//  CoreDesignSystem
//
//  Created by euijjang97 on 10/8/26.
//

import CoreText
import Foundation
import os
import SwiftUI

/// Figma의 macOS Typography 텍스트 스타일. 크기·줄높이·자간의 단위는 pt이다.
public enum UMCTypography: String, CaseIterable, Sendable {
    case largeTitle1Bold = "Large Title/1-Bold"
    case largeTitle1Regular = "Large Title/1-Regular"
    case largeTitle2Bold = "Large Title/2-Bold"
    case largeTitle2Regular = "Large Title/2-Regular"
    case largeTitle3Bold = "Large Title/3-Bold"
    case largeTitle3Regular = "Large Title/3-Regular"
    case title1Bold = "Title/1-Bold"
    case title1Regular = "Title/1-Regular"
    case title2Bold = "Title/2-Bold"
    case title2Regular = "Title/2-Regular"
    case title3Bold = "Title/3-Bold"
    case title3Regular = "Title/3-Regular"
    case headlineBold = "Headline/Bold"
    case headlineRegular = "Headline/Regular"
    case bodyRegular = "Body/Regular"
    case calloutRegular = "Callout/Regular"
    case subheadlineRegular = "Subheadline/Regular"
    case footnoteRegular = "Footnote/Regular"
    case captionRegular = "Caption/Regular"

    public var size: CGFloat { metrics.size }

    public var lineHeight: CGFloat { size * metrics.lineHeightMultiple }

    public var tracking: CGFloat { size * metrics.letterSpacingPercent / 100 }

    public var weight: Font.Weight {
        switch self {
        case .largeTitle1Bold, .largeTitle2Bold, .largeTitle3Bold,
             .title1Bold, .title2Bold, .title3Bold, .headlineBold:
            .bold
        default:
            .regular
        }
    }

    /// 폰트만 필요한 곳에 사용한다. 줄높이·자간은 `.umcTypography(_:)`로 함께 적용한다.
    public var font: Font {
        _ = PretendardFonts.registered
        let name = weight == .bold ? "Pretendard-Bold" : "Pretendard-Regular"
        return .custom(name, size: size, relativeTo: textStyle)
    }

    fileprivate var textStyle: Font.TextStyle { metrics.textStyle }

    private var metrics: (
        size: CGFloat,
        lineHeightMultiple: CGFloat,
        letterSpacingPercent: CGFloat,
        textStyle: Font.TextStyle
    ) {
        switch self {
        case .largeTitle1Bold, .largeTitle1Regular:
            (36, 1.5, -2, .largeTitle)
        case .largeTitle2Bold, .largeTitle2Regular:
            (32, 1.5, -2, .largeTitle)
        case .largeTitle3Bold, .largeTitle3Regular:
            (26, 1.5, -2, .largeTitle)
        case .title1Bold, .title1Regular:
            (22, 1.3, -2, .title)
        case .title2Bold, .title2Regular:
            (20, 1.3, -1, .title2)
        case .title3Bold, .title3Regular:
            (16, 1.4, -1, .title3)
        case .headlineBold, .headlineRegular:
            (14, 1.4, 0, .headline)
        case .bodyRegular:
            (12, 1.4, 0, .body)
        case .calloutRegular:
            (12, 1.4, 0, .callout)
        case .subheadlineRegular:
            (11, 1.4, 0, .subheadline)
        case .footnoteRegular:
            (10, 1.4, 0, .footnote)
        case .captionRegular:
            (10, 1.4, 0, .caption)
        }
    }
}

public extension View {
    /// Pretendard와 Figma의 줄높이·자간을 적용하며 사용자 글자 크기에 함께 맞춘다.
    func umcTypography(_ style: UMCTypography) -> some View {
        modifier(UMCTypographyModifier(style: style))
    }
}

private struct UMCTypographyModifier: ViewModifier {
    let style: UMCTypography
    @ScaledMetric private var scale: CGFloat

    init(style: UMCTypography) {
        self.style = style
        _scale = ScaledMetric(wrappedValue: 1, relativeTo: style.textStyle)
    }

    func body(content: Content) -> some View {
        content
            .font(style.font)
            .tracking(style.tracking * scale)
            .lineHeight(.exact(points: style.lineHeight * scale))
    }
}

private enum PretendardFonts {
    private static let logger = Logger(subsystem: "dev.umc.designsystem", category: "Fonts")

    // static let 초기화로 여러 화면에서 사용해도 프로세스당 한 번만 등록한다.
    static let registered: Void = {
        for name in ["Pretendard-Regular", "Pretendard-Bold"] {
            guard let url = Bundle.module.url(forResource: name, withExtension: "otf") else {
                logger.error("Missing bundled font: \(name, privacy: .public)")
                assertionFailure("Missing bundled font: \(name)")
                continue
            }

            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
                let failure = error?.takeRetainedValue()
                if let failure,
                   CFErrorGetCode(failure) == CTFontManagerError.alreadyRegistered.rawValue {
                    continue
                }
                let message = failure.map { String(describing: $0) } ?? "Unknown font error"
                logger.error("Font registration failed: \(message, privacy: .public)")
                assertionFailure(message)
            }
        }
    }()
}
