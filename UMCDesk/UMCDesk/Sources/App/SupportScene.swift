//
//  SupportScene.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/28/26.
//

import CoreDesignSystem
import CoreText
import SwiftUI

/// Initial destination for the isolated design fixture. Interaction uses the same controls
/// and models as the customer center window.
enum SupportScene: String {
    case home, operations, empty, conversation, closed, compose, detail
    case operatorDetail, faqManagement, userTools, operatorTools, team, assignee, labels
    case search, results, noResults, waiting, resolved, reference, refreshed
    case weekly, weeklyRefreshed, mine, unassigned, unclassified, reopened, conversationReference
    case labelsChanged, labelsCancelled, labelsApplied, assigned, faqDraft, faqArchived, faqEditing
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
        let leading: CGFloat =
            switch size {
            case 28: 40
            case 22: 33
            case 20: 28
            case 18: 27
            case 17: 26
            case 15, 16: 24
            case 14: 21
            case 13: 20
            default: size * 1.45
            }
        return font(.custom("NotoSansKR-Regular", size: size).weight(weight))
            .lineHeight(.exact(points: leading))
    }
}

private enum InquiryFont {
    static let registered: Void = {
        if let url = Bundle.main.url(forResource: "NotoSansKR", withExtension: "ttf") {
            CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
        }
    }()
}

extension SupportFixture {
    /// Replays the selected local scenario before presenting the normal support views.
    convenience init(scene: SupportScene) {
        self.init(emptyInquiries: scene == .empty)
        if [.conversation, .closed, .reopened, .conversationReference].contains(scene) {
            tickets[0].reply("확인해 볼게요. 사용 중인 앱 버전과 오류가 나타난 화면을 보내주실 수 있나요?", from: .agent)
            tickets[0].replies[0].sentAt = tickets[0].createdAt.addingTimeInterval(240)
        }
        if [.closed, .reopened].contains(scene) {
            tickets[0].status = .closed
            if scene == .reopened { tickets[0].reply("다시 확인해 주세요.", from: .requester) }
        }
        if scene == .conversationReference { tickets[0].reference = publishedArticles.first }
        if scene == .assigned { tickets[0].assignee = "이지원" }
        if scene == .labelsApplied {
            tickets[0].applyLabels(original: tickets[0].labels, selected: ["기능 요청"])
        }
    }
}
