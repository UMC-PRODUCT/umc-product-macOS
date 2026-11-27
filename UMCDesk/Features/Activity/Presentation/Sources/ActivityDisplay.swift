//  ActivityDisplay.swift
//  ActivityPresentation
//
//  Created by euijjang97 on 11/27/26.
//

import ActivityDomain
import CoreDesignSystem
import SwiftUI
import UMCFoundation

/// Display-only projection. Inclusive phase and strict deadline comparisons are intentional.
struct ActivityTiming {
    let schedule: ActivitySchedule
    let now: Date
    var open: Bool {
        schedule.opens.map { $0 <= now } == true
            && schedule.closes.map { now <= $0 } == true && schedule.endsAt >= now
    }
    var phase: String {
        open
            ? ((schedule.onTime ?? now) >= now ? "지금 출석 가능" : "지각 출석 가능")
            : ((schedule.closes ?? schedule.endsAt) < now ? "출석 마감" : "출석 시작 전")
    }
    var deadline: Date? { (schedule.onTime ?? now) > now ? schedule.onTime : schedule.closes }
    var minutes: Int { max(0, Int(ceil((deadline?.timeIntervalSince(now) ?? 0) / 60))) }
    var remainingSummary: String? {
        guard open, minutes > 0, let deadline else {
            return nil
        }
        let label =
            (schedule.onTime ?? now) > now
            ? AppLocalization.string("정시 마감") : AppLocalization.string("지각 마감")
        let time = Self.time(deadline, relativeTo: schedule.startsAt)
        return AppLocalization.string("\(label) \(time), \(minutes)분 남음")
    }
    static func time(_ date: Date, relativeTo start: Date) -> String {
        date.formatted(
            date: Calendar.current.isDate(date, inSameDayAs: start) ? .omitted : .abbreviated,
            time: .shortened)
    }
    static func interval(_ schedule: ActivitySchedule) -> String {
        schedule.startsAt.formatted(date: .abbreviated, time: .shortened)
            + " – " + time(schedule.endsAt, relativeTo: schedule.startsAt)
    }
}

struct ActivityDivider: View {
    @Environment(\.colorSchemeContrast) private var contrast
    var body: some View {
        Rectangle().fill(
            contrast == .increased
                ? UMCColor.Semantic.borderNeutralStrong400
                : UMCColor.Semantic.borderNeutralWeaker100
        ).frame(height: 1)
            .accessibilityHidden(true)
    }
}

struct ActivityFeedback: View {
    let message: String
    let failed: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if failed {
                Label(
                    AppLocalization.string("요청을 완료하지 못했어요"), systemImage: "exclamationmark.circle")
            } else {
                Label(AppLocalization.string("요청 완료"), systemImage: "checkmark.circle")
            }
            Text(message).textSelection(.enabled)
        }.umcTypography(.headlineRegular)
            .foregroundStyle(failed ? UMCColor.Semantic.textError : UMCColor.Semantic.textSuccess)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct ActivityStatus: View {
    let value: String?
    let fallback: String
    private var presentation: (String, String, Color) {
        switch value {
        case "PRESENT": ("출석 완료", "checkmark.circle", UMCColor.Semantic.textSuccess)
        case "EXCUSED": ("출석 인정", "checkmark.circle", UMCColor.Semantic.textSuccess)
        case "LATE": ("지각", "clock", UMCColor.Semantic.textWarning)
        case "ABSENT": ("결석", "xmark.circle", UMCColor.Semantic.textError)
        case let pending? where pending.hasSuffix("_PENDING"):
            ("승인 대기", "clock", UMCColor.Semantic.textNeutralMedium600)
        default: (value ?? fallback, "minus.circle", UMCColor.Semantic.textNeutralMedium600)
        }
    }
    var body: some View {
        Label(presentation.0, systemImage: presentation.1)
            .umcTypography(.calloutRegular).foregroundStyle(presentation.2)
    }
}

struct ActivityScheduleRow: View {
    let schedule: ActivitySchedule
    let selected: Bool
    let select: () -> Void
    var body: some View {
        Button(action: select) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(schedule.startsAt, format: .dateTime.month().day())
                    Text(schedule.startsAt, format: .dateTime.hour().minute())
                }.umcTypography(.calloutRegular).frame(minWidth: 64, alignment: .leading)
                ActivityAdaptiveRow(minimumLeadingWidth: 160, spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(schedule.name).umcTypography(.headlineBold).lineLimit(2)
                        Text(schedule.isOnline ? "비대면 일정" : "대면 일정")
                            .umcTypography(.calloutRegular)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                    ActivityStatus(value: schedule.status, fallback: "예정")
                        .accessibilityHint(
                            schedule.status == nil
                                ? AppLocalization.string("출석 결과 없음, 일정 목록 표시 예정")
                                : AppLocalization.string("내 출석 결과"))
                }

            }.padding(12)
                .background(
                    selected
                        ? UMCColor.Semantic.surfaceBrandWeak
                        : UMCColor.Custom.backgroundSurface, in: .rect(cornerRadius: 8)
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 8).stroke(
                        selected ? UMCColor.Semantic.borderPrimaryStrong500 : .clear, lineWidth: 1)
                }
                .contentShape(.rect)
        }.buttonStyle(.plain).help(schedule.name)
            .accessibilityValue(selected ? "선택됨" : AppLocalization.string("선택 안 됨"))
    }
}

struct ActivityMemberRow: View {
    let member: ActivityRow
    let open: () -> Void
    var body: some View {
        ActivityAdaptiveRow(minimumLeadingWidth: 200) {
            VStack(alignment: .leading, spacing: 4) {
                Text(member.title).umcTypography(.headlineBold)
                Text(member.detail).umcTypography(.calloutRegular)
                    .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
            }.fixedSize(horizontal: false, vertical: true)
            Button("프로필", action: open).fixedSize()
                .accessibilityLabel(AppLocalization.string("\(member.title) 프로필"))
        }.padding(12)
    }
}

struct ActivityLoadMessage: View {
    let section: String
    let message: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(
                AppLocalization.string("\(section)을 불러오지 못했어요"),
                systemImage: "exclamationmark.circle"
            )
            .umcTypography(.title4Bold)
            Text(message).umcTypography(.headlineRegular).textSelection(.enabled)
        }.foregroundStyle(UMCColor.Semantic.textError)
            .fixedSize(horizontal: false, vertical: true)
    }
}

/// A retry reruns the same read without changing text or touching write actions.
struct ActivitySearchRequest: Equatable {
    let keyword: String
    let retry: UUID
}
