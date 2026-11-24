//
//  MatchingComponents.swift
//  MatchingPresentation
//
//  Created by euijjang97 on 11/22/26.
//

import CoreDesignSystem
import MatchingDomain
import SwiftUI

extension View {
    func matchingPanel(_ color: Color = UMCColor.Custom.backgroundSurfaceGreyWeaker) -> some View {
        padding(UMCSpacing.value20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(color, in: .rect(cornerRadius: UMCRadius.value16))
            .overlay {
                RoundedRectangle(cornerRadius: UMCRadius.value16)
                    .strokeBorder(UMCColor.Semantic.borderNeutralWeaker100)
                    .allowsHitTesting(false)
            }
    }
}

struct MatchingBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .umcTypography(.bodyRegular)
            .foregroundStyle(UMCColor.Semantic.textBrandDefault)
            .padding(UMCSpacing.value8)
            .background(UMCColor.Semantic.surfaceBrandMedium, in: .rect(cornerRadius: UMCRadius.value8))
    }
}

struct MatchingQuotaView: View {
    let quota: MatchingQuota

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value8) {
            HStack(spacing: UMCSpacing.value8) {
                Text(MatchingLabel.part(quota.part))
                Text("\(quota.currentCount) / \(quota.quota)")
                    .foregroundStyle(UMCColor.Semantic.textBrandDefault)
            }
            .umcTypography(.headlineBold)
            if let count = Int(quota.quota), count > 0, count <= 8 {
                HStack(spacing: UMCSpacing.value4) {
                    ForEach(0..<count, id: \.self) { index in
                        Circle()
                            .fill(index < (Int(quota.currentCount) ?? 0)
                                ? UMCColor.Semantic.fillPrimaryInverseStrong500
                                : UMCColor.Semantic.surfaceNeutralMedium)
                            .frame(width: 16, height: 16)
                    }
                }
                .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

enum MatchingLabel {
    static func part(_ raw: String) -> String {
        switch raw {
        case "PLAN": "기획"
        case "DESIGN": "디자인"
        case "MOBILE_PRODUCT_ENGINEER": "모바일"
        case "WEB_PRODUCT_ENGINEER", "WEB": "웹"
        case "ANDROID": "Android"
        case "IOS": "iOS"
        case "SPRINGBOOT": "Spring Boot"
        case "NODEJS": "Node.js"
        default: raw
        }
    }

    static func status(_ raw: String?) -> String {
        switch raw {
        case "DRAFT": "작성 중"
        case "SUBMITTED": "제출 완료"
        case "APPROVED", "ACCEPTED": "합격"
        case "REJECTED": "불합격"
        case "CANCELLED", "WITHDRAWN": "지원 철회"
        case "RECRUITING": "모집 중"
        case "COMPLETED": "모집 완료"
        case nil, "", "PENDING_PUBLICATION", "PENDING", "WAITING": "결과 대기"
        default: raw ?? "결과 대기"
        }
    }

    static func date(_ value: String?) -> Date? {
        guard let value else { return nil }
        return (try? Date(value, strategy: .iso8601))
            ?? (try? Date(value, strategy: .iso8601.time(includingFractionalSeconds: true)))
    }

    static func time(_ value: String?) -> String {
        guard let value, let date = date(value) else { return value ?? "미정" }
        return date.formatted(.dateTime.month(.twoDigits).day(.twoDigits).hour().minute())
    }

    static func webURL(_ string: String?) -> URL? {
        guard let string, let url = URL(string: string),
              ["https", "http"].contains(url.scheme?.lowercased()), url.host != nil
        else { return nil }
        return url
    }
}

extension MatchingRound {
    func isOpen(at now: Date) -> Bool {
        guard phase != "RANDOM_MATCHING", let start = MatchingLabel.date(startsAt),
              let end = MatchingLabel.date(endsAt) else { return false }
        return start <= now && now <= end
    }
}

struct MatchingRoundCard: View {
    let round: MatchingRound
    var chapterName: String?
    var showSchedule: (() -> Void)?

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { timeline in
            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                HStack(spacing: UMCSpacing.value16) {
                    VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                        HStack {
                            MatchingBadge(text: round.isOpen(at: timeline.date) ? "지원 기간" : "매칭 일정")
                            if let chapterName { Text(chapterName).foregroundStyle(.secondary) }
                        }
                        Text(round.name).umcTypography(.title1Bold)
                    }
                    if let showSchedule {
                        Spacer()
                        VStack(alignment: .trailing, spacing: UMCSpacing.value4) {
                            Text("지원 마감").foregroundStyle(.secondary)
                            Text(MatchingLabel.time(round.endsAt)).umcTypography(.headlineBold)
                        }
                        Button("전체 일정", action: showSchedule)
                            .buttonStyle(MatchingActionStyle(appearance: .text))
                    }
                }
                if showSchedule == nil {
                    HStack(alignment: .top, spacing: UMCSpacing.value16) {
                        milestone("지원 시작", round.startsAt, marked: round.isOpen(at: timeline.date))
                        milestone("지원 마감", round.endsAt)
                        milestone("판정 마감", round.decisionDeadline)
                        milestone("결과 공개 예정", round.resultPublishAt)
                    }
                }
            }
            .matchingPanel(UMCColor.Semantic.surfaceBrandWeak)
        }
    }

    private func milestone(_ label: String, _ value: String?, marked: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value8) {
            Text(label).umcTypography(.bodyRegular)
                .foregroundStyle(marked ? UMCColor.Semantic.textBrandDefault
                                        : UMCColor.Semantic.textNeutralMedium600)
                .padding(UMCSpacing.value8)
                .background(marked ? UMCColor.Semantic.surfaceBrandMedium
                                   : UMCColor.Custom.backgroundSurfaceGreyWeak,
                            in: .rect(cornerRadius: UMCRadius.value8))
            Text(MatchingLabel.time(value)).umcTypography(.title3Bold)
            Capsule()
                .fill(marked ? UMCColor.Semantic.fillPrimaryInverseStrong500
                             : UMCColor.Semantic.surfaceNeutralMedium)
                .frame(height: 6)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MatchingPublicationStatus: View {
    let round: MatchingRound
    let repository: any MatchingUseCase
    let gisuId: String
    @State private var checks = 0

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
            if checks == 0 {
                summary(round)
            } else {
                OperationsLoad(key: checks, load: {
                    async let schedule = repository.rounds(chapterId: round.chapterId)
                    async let results = repository.personalCards(gisuId: gisuId)
                    return try await (schedule, results)
                }) { schedule, results in
                    if let current = schedule.first(where: { $0.id == round.id }) {
                        summary(current)
                        let published = results.filter { current.hasPublishedResult($0) }
                        if published.isEmpty {
                            Text("이 차수에서 공개된 내 결과가 조회되지 않았어요.")
                        } else {
                            ForEach(published, id: \.cardId) { result in
                                Text((result.project?.name ?? "프로젝트") + " · " +
                                     MatchingLabel.status(result.status))
                            }
                        }
                    } else {
                        Text("현재 지부 일정에서 이 차수를 찾을 수 없어요.")
                    }
                }
            }
            Button("발표 상태 확인") { checks += 1 }
                .buttonStyle(MatchingActionStyle(appearance: .secondary))
        }.matchingPanel()
    }

    private func summary(_ current: MatchingRound) -> some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value8) {
            if let executed = current.autoDecisionExecutedAt {
                MatchingBadge(text: "자동 처리 완료")
                Text("선발 처리 완료 · " + MatchingLabel.time(executed))
                    .umcTypography(.title3Bold)
                if current.phase != "RANDOM_MATCHING", current.resultPublishAt != nil {
                    Text("미선발 지원서는 결과 공개 시 불합격으로 확정돼요.")
                }
            }
            if let publication = current.resultPublishAt {
                Text("결과 공개 예정 · " + MatchingLabel.time(publication))
            } else {
                Text("공개 예정 시각 미등록")
            }
        }
    }
}

extension MatchingRound {
    func hasPublishedResult(_ application: MatchingApplication) -> Bool {
        application.matchingRound?.id == id &&
            (application.status == "APPROVED" || application.status == "REJECTED")
    }
}

struct MatchingActionStyle: ButtonStyle {
    enum Appearance { case primary, secondary, text }
    let appearance: Appearance
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .umcTypography(.headlineBold)
            .padding(.horizontal, UMCSpacing.value16)
            .frame(minHeight: UMCSpacing.value40)
            .foregroundStyle(foreground)
            .background(background, in: .rect(cornerRadius: UMCRadius.value8))
            .overlay {
                if appearance == .secondary {
                    RoundedRectangle(cornerRadius: UMCRadius.value8)
                        .strokeBorder(UMCColor.Semantic.borderNeutralWeak200)
                }
            }
            .contentShape(.rect(cornerRadius: UMCRadius.value8))
            .opacity(isEnabled ? (configuration.isPressed ? 0.72 : 1) : 0.5)
    }

    private var foreground: Color {
        switch appearance {
        case .primary: UMCColor.Semantic.textInverse
        case .secondary: UMCColor.Semantic.textNeutralDefault
        case .text: UMCColor.Semantic.textBrandDefault
        }
    }

    private var background: Color {
        switch appearance {
        case .primary: UMCColor.Semantic.fillPrimaryInverseStronger600
        case .secondary: UMCColor.Custom.backgroundDefault
        case .text: .clear
        }
    }
}

/// 상세·지원 화면의 두 패널을 제공된 너비에 맞춰 시안의 824:436 비율로 배치한다.
struct MatchingColumns: Layout {
    private func width(at index: Int, available: CGFloat) -> CGFloat {
        let body = max(0, available - UMCSpacing.value24)
        return body * (index == 0 ? 824 : 436) / 1260
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let available = proposal.width ?? 1260
        let height = subviews.enumerated().map { index, view in
            view.sizeThatFits(.init(width: width(at: index, available: available), height: nil)).height
        }.max() ?? 0
        return CGSize(width: available, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        for (index, view) in subviews.enumerated() {
            let column = width(at: index, available: bounds.width)
            view.place(at: CGPoint(x: x, y: bounds.minY), anchor: .topLeading,
                       proposal: .init(width: column, height: nil))
            x += column + UMCSpacing.value24
        }
    }
}
