//
//  SupportScene.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/28/26.
//

import CoreText
import CoreDesignSystem
import SwiftUI

/// Initial destination for the isolated design fixture. Interaction uses the same controls
/// and models as the customer center window.
enum SupportScene: String {
    case home, operations, empty, conversation, closed, compose, detail
    case operatorDetail, faqManagement, userTools, operatorTools, team, assignee, labels
    case search, results, noResults, waiting, resolved, reference, refreshed
}

extension View {
    func supportCard(padding: CGFloat = 24) -> some View {
        self.padding(padding)
            .background(UMCColor.Custom.backgroundSurfaceWhite, in: .rect(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(UMCColor.Semantic.borderNeutralWeaker100)
                    .allowsHitTesting(false)
            }
    }

    func inquiryFont(_ size: CGFloat, weight: Font.Weight = .regular) -> some View {
        let _ = InquiryFont.registered
        return font(.custom("NotoSansKR-Regular", size: size).weight(weight))
    }
}

private enum InquiryFont {
    static let registered: Void = {
        if let url = Bundle.main.url(forResource: "NotoSansKR", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()
}
