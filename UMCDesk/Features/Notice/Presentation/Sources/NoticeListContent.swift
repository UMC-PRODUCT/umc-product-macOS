//  NoticeListContent.swift
//  NoticePresentation
//
//  Created by euijjang97 on 11/27/26.

import CoreDesignSystem
import CoreUIComponents
import NoticeDomain
import SwiftUI
import UMCFoundation

/// Reader width is temporary: selecting from the list always starts with the list visible.
struct NoticeReadingLayout {
    private(set) var isFullReader = false
    mutating func toggle() { isFullReader.toggle() }
    mutating func beginSelection() { isFullReader = false }
}

struct NoticeArticleFailure {
    enum Action { case load, vote, confirmRead }
    let message: String
    let hasContent: Bool
    var action: Action = .load
    var isInitialLoad: Bool { !hasContent }
    var heading: String {
        isInitialLoad ? AppLocalization.string("공지를 불러오지 못했습니다")
            : AppLocalization.string("요청을 완료하지 못했습니다")
    }
}

/// Presentation-only classification; pagination and request ownership stay in the board model.
enum NoticeEmptyState: Equatable {
    case none, empty, search, pinnedPage, pinned

    init(entries: [NoticeEntry], loading: Bool, hasError: Bool,
         keyword: String, pinnedOnly: Bool, hasNext: Bool) {
        if loading || hasError { self = .none }
        else if pinnedOnly && !entries.contains(where: \.mustRead) {
            self = hasNext ? .pinnedPage : .pinned
        } else if entries.isEmpty { self = keyword.isEmpty ? .empty : .search }
        else { self = .none }
    }

    var message: String {
        switch self {
        case .none: ""
        case .empty: AppLocalization.string("공지가 없습니다")
        case .search: AppLocalization.string("검색 결과가 없습니다")
        case .pinnedPage: AppLocalization.string("현재 불러온 공지에 고정된 항목이 없습니다")
        case .pinned: AppLocalization.string("고정된 공지가 없습니다.")
        }
    }
}

struct NoticeSearchField: View {
    @Binding var search: String
    let submit: () -> Void

    var body: some View {
        HStack(spacing: UMCSpacing.value8) {
            TextField("제목, 내용 검색", text: $search)
                .textFieldStyle(.roundedBorder)
                .onSubmit(submit)
            Button("검색", action: submit)
        }
    }
}

struct NoticeListPlaceholder: View {
    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value8) {
            Text(AppLocalization.string("공지를 불러오는 중")).umcTypography(.calloutRegular)
            ForEach(0..<3) { _ in
                VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                    RoundedRectangle(cornerRadius: UMCRadius.value4).frame(height: 20)
                    RoundedRectangle(cornerRadius: UMCRadius.value4)
                        .frame(maxWidth: 160).frame(height: 12)
                    RoundedRectangle(cornerRadius: UMCRadius.value4).frame(height: 12)
                }
                .foregroundStyle(UMCColor.Semantic.borderNeutralWeak200)
                .padding(UMCSpacing.value16)
                .background(UMCColor.Custom.backgroundSurface,
                            in: .rect(cornerRadius: UMCRadius.value12))
                .accessibilityHidden(true)
                .allowsHitTesting(false)
            }
        }
    }
}

struct NoticeListRow: View {
    @Environment(\.locale) private var locale
    @Environment(\.timeZone) private var timeZone
    let entry: NoticeEntry
    let selected: Bool
    let confirmed: Bool
    let showsPreview: Bool
    let select: () -> Void

    var body: some View {
        UMCFocusableButton(
            entry.title, identifier: "notice.row." + entry.id,
            cornerRadius: UMCRadius.value12,
            accessibilityValue: entry.rowAccessibilityValue(selected: selected, confirmed: confirmed),
            action: select
        ) { hovered in
            VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                Text(entry.title).umcTypography(.title4Bold).lineLimit(2)
                    .foregroundStyle(UMCColor.Semantic.textNeutralDefault)
                VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                    Text(entry.audienceLabel)
                    HStack(spacing: UMCSpacing.value8) {
                        if entry.mustRead { Label("고정", systemImage: "pin.fill") }
                        if confirmed { Label("읽음", systemImage: "checkmark.circle") }
                        if selected { Label(AppLocalization.string("선택됨"), systemImage: "checkmark") }
                    }
                }.umcTypography(.calloutRegular)
                if showsPreview {
                    Text(entry.content).umcTypography(.headlineRegular).lineLimit(2)
                }
                VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                    Text(entry.authorAndDate).fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: UMCSpacing.value8) {
                        Text("조회 \(entry.viewCount)")
                        if entry.hasLinks == true { Label("링크", systemImage: "link") }
                        if entry.hasImages == true { Label("사진", systemImage: "photo") }
                        if entry.hasVote == true { Label("투표", systemImage: "chart.bar") }
                    }
                    if let deadline = noticeVoteDeadline(
                        entry.vote?.endsAtExclusive, locale: locale, timeZone: timeZone
                    ) {
                        Label("투표 마감 " + deadline, systemImage: "calendar.badge.clock")
                    }
                }.umcTypography(.calloutRegular)
            }
            .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
            .padding(UMCSpacing.value16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? UMCColor.Semantic.fillPrimaryStrong200
                        : UMCColor.Custom.backgroundSurface,
                        in: .rect(cornerRadius: UMCRadius.value12))
            .overlay {
                RoundedRectangle(cornerRadius: UMCRadius.value12)
                    .strokeBorder(selected || hovered ? UMCColor.Semantic.textBrandDefault
                                  : UMCColor.Semantic.borderNeutralWeak200,
                                  lineWidth: selected ? 2 : 1)
            }
        }
    }
}

extension NoticeEntry {
    var authorAndDate: String {
        [author?.organizationName, author?.nickname ?? author?.name,
         String(createdAt.prefix(10))]
            .compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " · ")
    }

    /// Read state is session-confirmed only; absence never implies server-side unread status.
    func rowAccessibilityValue(selected: Bool, confirmed: Bool) -> String {
        [selected ? AppLocalization.string("선택됨") : nil,
         mustRead ? AppLocalization.string("고정") : nil,
         confirmed ? AppLocalization.string("읽음") : nil,
         hasLinks == true ? AppLocalization.string("링크") : nil,
         hasImages == true ? AppLocalization.string("사진") : nil,
         hasVote == true ? AppLocalization.string("투표") : nil]
            .compactMap { $0 }.joined(separator: " · ")
    }
}
