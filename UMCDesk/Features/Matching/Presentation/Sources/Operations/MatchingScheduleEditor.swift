//
//  MatchingScheduleEditor.swift
//  MatchingPresentation
//
//  Created by euijjang97 on 11/22/26.
//

import CoreDesignSystem
import MatchingDomain
import SwiftUI

struct MatchingScheduleEditor: View {
    let repository: any MatchingUseCase
    let chapterId: String
    let rounds: [MatchingRound]
    let onSaved: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var type = "PLAN_DEVELOPER"
    @State private var rows: [ScheduleRow] = []
    @State private var allowed = false
    @State private var working = false
    @State private var error: String?
    @State private var pending: Action?
    @State private var loadingAccess = true
    @State private var accessAttempt = 0

    private enum Action: Identifiable {
        case save, delete, auto(MatchingRound)
        var id: String {
            switch self {
            case .save: "save"
            case .delete: "delete"
            case .auto(let round): round.id
            }
        }
        var title: String {
            switch self {
            case .save: "지부 전체 일정을 저장할까요?"
            case .delete: "이 유형의 차수 일정을 모두 삭제할까요?"
            case .auto(let round): "\(round.name) 자동 선발을 실행할까요?"
            }
        }
    }

    private var existing: [MatchingRound] {
        rounds.filter { $0.chapterId == chapterId && $0.type == type }
    }

    private func isLocked(_ now: Date) -> Bool {
        existing.first { $0.phase == "FIRST" }.flatMap { MatchingLabel.date($0.startsAt) }
            .map { $0 <= now } ?? false
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 15)) { clock in
            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                HStack {
                    Text("지부 전체 일정").umcTypography(.title1Bold)
                    Spacer()
                    Button("닫기") { dismiss() }.keyboardShortcut(.cancelAction)
                    Button("전체 일정 저장") { pending = .save }
                        .buttonStyle(.borderedProminent)
                        .disabled(!allowed || isLocked(clock.date) || changes == nil || working)
                }
                Picker("매칭 유형", selection: $type) {
                    Text("기획–개발자").tag("PLAN_DEVELOPER")
                    Text("기획–디자인").tag("PLAN_DESIGN")
                }
                .pickerStyle(.segmented)
                .disabled(working)
                if loadingAccess {
                    ProgressView("일정 관리 권한 확인 중")
                } else if !allowed {
                    Text("선택한 지부의 일정은 읽기 전용이에요.")
                    if error != nil { Button("권한 다시 확인") { accessAttempt += 1 } }
                } else if isLocked(clock.date) {
                    Label("1차 지원이 시작되어 전체 일정이 잠겼어요.", systemImage: "lock")
                }
                ScrollView {
                    VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                        ForEach($rows) { $row in
                            VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                                HStack {
                                    Text(row.phaseTitle).umcTypography(.headlineBold)
                                    TextField("차수 이름", text: $row.name)
                                        .disabled(!allowed || isLocked(clock.date) || working)
                                    if let round = existing.first(where: { $0.phase == row.phase }),
                                       allowed {
                                        Button(round.autoDecisionExecutedAt == nil ? "자동 선발" : "실행 완료") {
                                            pending = .auto(round)
                                        }
                                        .disabled(working || !canAutoDecide(round, at: clock.date))
                                    }
                                }
                                HStack(alignment: .top, spacing: UMCSpacing.value12) {
                                    dateField("지원·조정 시작", value: $row.start)
                                    dateField("지원·조정 마감", value: $row.end)
                                    if row.phase == "RANDOM_MATCHING" {
                                        Text("판정 마감\n해당 없음").frame(maxWidth: .infinity)
                                    } else {
                                        dateField("판정 마감", value: $row.deadline)
                                    }
                                    dateField("결과 공개", value: $row.publication)
                                }
                                .disabled(!allowed || isLocked(clock.date) || working)
                            }
                            .matchingPanel()
                        }
                    }
                }
                if let error { Text(error).foregroundStyle(UMCColor.Semantic.textError) }
                Text("지원 시작 → 마감 → 판정 마감 → 공개 순으로 입력해 주세요. 공개는 마감 후 최소 5분 뒤예요.")
                    .foregroundStyle(.secondary)
                if !existing.isEmpty, allowed {
                    Button("이 유형의 전체 일정 삭제", role: .destructive) { pending = .delete }
                        .disabled(isLocked(clock.date) || working)
                }
            }
            .padding(UMCSpacing.value24)
        }
        .frame(minWidth: 940, minHeight: 650)
        .interactiveDismissDisabled(working)
        .onChange(of: type, initial: true) { resetRows() }
        .task(id: accessAttempt) {
            loadingAccess = true
            do { allowed = try await repository.canManageSchedule(chapterId: chapterId); error = nil }
            catch { self.error = error.localizedDescription; allowed = false }
            loadingAccess = false
        }
        .alert(item: $pending) { action in
            Alert(
                title: Text(action.title),
                message: Text(confirmationMessage(action)),
                primaryButton: .destructive(Text(actionLabel(action))) { perform(action) },
                secondaryButton: .cancel(Text("취소"))
            )
        }
    }

    private func confirmationMessage(_ action: Action) -> String {
        switch action {
        case .save: "1·2·3차와 랜덤 조정 일정을 함께 저장해요."
        case .delete: "1·2·3차와 랜덤 조정 일정이 함께 삭제돼요."
        case .auto: "서버가 해당 차수의 대상과 정원을 확인해 선발을 실행해요."
        }
    }

    private func actionLabel(_ action: Action) -> String {
        switch action {
        case .save: "전체 일정 저장"
        case .delete: "전체 일정 삭제"
        case .auto: "자동 선발 실행"
        }
    }

    @ViewBuilder
    private func dateField(_ title: String, value: Binding<Date?>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            if let current = value.wrappedValue {
                DatePicker(title, selection: Binding(
                    get: { value.wrappedValue ?? current }, set: { value.wrappedValue = $0 }
                ))
                .labelsHidden()
                .controlSize(.small)
            } else {
                Button("일시 지정") { value.wrappedValue = Date() }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func resetRows() {
        rows = ScheduleRow.phases.map { phase in
            ScheduleRow(phase: phase, existing: existing.first { $0.phase == phase })
        }
        error = nil
    }

    private var changes: [MatchingRoundChange]? {
        var result = [MatchingRoundChange]()
        var previousPublication: Date?
        for row in rows {
            guard let change = row.change,
                  let start = row.start, let publication = row.publication,
                  previousPublication.map({ $0 < start }) ?? true else { return nil }
            result.append(change)
            previousPublication = publication
        }
        return result.count == ScheduleRow.phases.count ? result : nil
    }

    private func canAutoDecide(_ round: MatchingRound, at now: Date) -> Bool {
        guard round.autoDecisionExecutedAt == nil else { return false }
        // Random eligibility depends on an actual third-round publication. Its timestamp is
        // absent from the read contract, so the command server performs that final check.
        if round.phase == "RANDOM_MATCHING" {
            guard let third = existing.first(where: { $0.phase == "THIRD" }) else { return false }
            let earliest = MatchingLabel.date(third.resultPublishAt ?? third.decisionDeadline)
            return earliest.map { $0 <= now } ?? false
        }
        return MatchingLabel.date(round.decisionDeadline).map { $0 < now } ?? false
    }

    private func perform(_ action: Action) {
        guard allowed, !working else { return }
        working = true
        Task {
            defer { working = false }
            do {
                switch action {
                case .save:
                    guard !isLocked(.now), let changes else { return }
                    try await repository.saveSchedule(chapterId: chapterId, type: type, rounds: changes)
                case .delete:
                    guard !isLocked(.now) else { return }
                    try await repository.deleteSchedule(chapterId: chapterId, type: type)
                case .auto(let round):
                    guard canAutoDecide(round, at: .now) else { return }
                    try await repository.autoDecide(roundId: round.id)
                }
                onSaved()
                dismiss()
            } catch { self.error = error.localizedDescription }
        }
    }
}

private struct ScheduleRow: Identifiable {
    static let phases = ["FIRST", "SECOND", "THIRD", "RANDOM_MATCHING"]
    let phase: String
    let original: MatchingRound?
    var name: String
    var start: Date?
    var end: Date?
    var deadline: Date?
    var publication: Date?
    var id: String { phase }
    var phaseTitle: String { Self.label(phase) }

    init(phase: String, existing: MatchingRound?) {
        self.phase = phase
        original = existing
        name = existing?.name ?? Self.label(phase)
        start = MatchingLabel.date(existing?.startsAt)
        end = MatchingLabel.date(existing?.endsAt)
        deadline = MatchingLabel.date(existing?.decisionDeadline)
        publication = MatchingLabel.date(existing?.resultPublishAt)
    }

    static func label(_ phase: String) -> String {
        switch phase {
        case "FIRST": "1차"
        case "SECOND": "2차"
        case "THIRD": "3차"
        default: "랜덤·조정"
        }
    }

    var change: MatchingRoundChange? {
        let random = phase == "RANDOM_MATCHING"
        guard let start, let end, start < end, let publication,
              !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let decision = random ? end : deadline,
              random || end < decision, publication.timeIntervalSince(decision) >= 300
        else { return nil }
        return MatchingRoundChange(
            phase: phase, name: name, description: original?.description,
            startsAt: timestamp(start, original: original?.startsAt),
            endsAt: timestamp(end, original: original?.endsAt),
            decisionDeadline: random ? nil : timestamp(decision, original: original?.decisionDeadline),
            resultPublishAt: timestamp(publication, original: original?.resultPublishAt)
        )
    }

    private func timestamp(_ date: Date, original: String?) -> String {
        if let original, date == MatchingLabel.date(original) { return original }
        return date.formatted(.iso8601)
    }
}
