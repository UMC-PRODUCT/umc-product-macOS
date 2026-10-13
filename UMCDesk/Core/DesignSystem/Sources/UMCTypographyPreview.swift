//
//  UMCTypographyPreview.swift
//  CoreDesignSystem
//
//  Created by euijjang97 on 10/12/26.
//

#if DEBUG || UMC_PRERELEASE
import SwiftUI

/// 실행 중 화면 비교에만 사용하며 디자인 토큰과 저장된 설정은 변경하지 않는다.
public struct UMCTypographyPreview: Equatable, Sendable {
    public enum Weight: String, CaseIterable, Identifiable, Sendable {
        case design = "디자인 기본"
        case regular = "Regular"
        case bold = "Bold"

        public var id: String { rawValue }
    }

    public var isEnabled = true
    public var sizeScale: CGFloat = 1
    public var weight: Weight = .design
    public var trackingAdjustment: CGFloat = 0
    public var lineHeightScale: CGFloat = 1

    public init() {}

    var appliedSizeScale: CGFloat { isEnabled ? sizeScale : 1 }
    var appliedTrackingAdjustment: CGFloat { isEnabled ? trackingAdjustment : 0 }
    var appliedLineHeightScale: CGFloat { isEnabled ? lineHeightScale : 1 }

    func font(for style: UMCTypography) -> Font {
        let appliedWeight: Font.Weight = switch isEnabled ? weight : .design {
        case .design: style.weight
        case .regular: .regular
        case .bold: .bold
        }
        return style.font(size: style.size * appliedSizeScale, weight: appliedWeight)
    }
}

public extension EnvironmentValues {
    @Entry var umcTypographyPreview = UMCTypographyPreview()
}
#endif
