//
//  SupportScene.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/28/26.
//

import CoreDesignSystem
import SwiftUI

/// Initial destination for the isolated design fixture. Interaction uses the same controls
/// and models as the customer center window.
enum SupportScene: String {
    case home, operations, empty, conversation, closed, compose, detail
    case operatorDetail, faqManagement, userTools, operatorTools, team, assignee, labels
    case search, results, noResults, waiting, resolved, reference, refreshed
    case weekly, weeklyRefreshed, mine, unassigned, unclassified, reopened, conversationReference
    case labelsChanged, labelsCancelled, labelsApplied, assigned, faqDraft, faqArchived, faqEditing
    case operatorClosed, sendPending, sendFailed, sendUnknown, partialAttachment,
        postWriteReadFailure
    case longFAQ, longConversation, longTeam, longOperations, denied, readFailure
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
        modifier(SupportType(size: size, weight: weight))
    }
}

private struct SupportType: ViewModifier {
    @Environment(\.umcBodyTextScale) var scale
    @Environment(\.umcFontFamily) var family
    @Environment(\.umcFontDesign) var design
    let size: CGFloat
    let weight: Font.Weight

    func body(content: Content) -> some View {
        let font = UMCTypography.bodyRegular.font(
            size: size * scale, weight: weight, design: design, family: family)
        let leading: CGFloat =
            switch size {
            case 28: 40
            case 18...22: 28
            case 15...17: 24
            case 14: 21
            case 13: 20
            default: 18
            }
        let native: NSFont =
            family.flatMap { NSFont(name: $0, size: size * scale) }
            ?? NSFont.systemFont(ofSize: size * scale)
        return content.font(font).tracking(0).lineHeight(
            .exact(
                points: max(leading * scale, native.ascender - native.descender + native.leading)))
    }
}

struct SupportSelectableText: View {
    private let richText: AttributedString
    init(_ text: String) {
        var result = AttributedString(text)
        let matches =
            Self.links?.matches(in: text, range: NSRange(text.startIndex..., in: text)) ?? []
        for match in matches {
            guard let url = match.url, ["https", "http"].contains(url.scheme),
                let range = Range(match.range, in: text),
                let converted = Range(range, in: result)
            else { continue }
            result[converted].link = url
        }
        richText = result
    }
    private static let links = try? NSDataDetector(
        types: NSTextCheckingResult.CheckingType.link.rawValue)
    var body: some View {
        Text(richText).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
    }
}

extension SupportFixture {
    /// Replays the selected local scenario before presenting the normal support views.
    convenience init(scene: SupportScene) {
        self.init(emptyInquiries: scene == .empty)
        if [.longFAQ, .longConversation, .longOperations].contains(scene) {
            let title = String(repeating: "긴 제목 예시 ", count: 12).prefix(80)
            let path = "https://example.invalid/" + String(repeating: "a", count: 276)
            let paragraphs = (1...20).map {
                "문단 " + String($0) + ". 표시 오류를 확인하기 위한 예시 안내입니다. " + path
            }.joined(separator: "\n\n")
            drafts[0].article.question = String(title)
            drafts[0].article.answer = paragraphs
            drafts[0].publish()
            tickets[0].subject = String(title)
            tickets[0].content = paragraphs
            tickets[0].attachmentName = String(repeating: "긴 파일 이름 ", count: 10) + ".png"
            tickets[0].teamDisplayName =
                String(repeating: "운영 담당 ", count: 8).prefix(40).description
            tickets[0].status = .active
        }
        if scene == .operatorClosed { tickets[0].status = .closed }
        if scene == .postWriteReadFailure { transport.simulateFailedRead(hasSnapshot: true) }
        if scene == .denied { transport.access = .denied }
        if scene == .readFailure { transport.simulateFailedRead() }
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
