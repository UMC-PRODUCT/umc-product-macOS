//
//  MatchingProgressPanel.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/22/26.
//

import CoreDesignSystem
import MatchingDomain
import SwiftUI

struct MatchingProgressPanel: View {
    let controller: MatchingProgressController
    var onClose: (() -> Void)? = nil

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { timeline in
            let stage = MatchingProgressStage(controller: controller, now: timeline.date)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(controller.round?.name ?? "프로젝트 매칭").font(.caption)
                    Spacer()
                    Button("닫기  esc") { if let onClose { onClose() } else { controller.closeExpanded() } }
                        .buttonStyle(.plain)
                        .keyboardShortcut(.cancelAction)
                }
                HStack {
                    Text(stage.title)
                        .font(.title2.bold())
                        .foregroundStyle(UMCColor.Semantic.textBrandDefault)
                    Spacer()
                    if let next = stage.next {
                        Text(next.formatted(date: .omitted, time: .shortened) + " 예정")
                    }
                }
                HStack(spacing: 12) {
                    step("지원", systemImage: "doc.text", active: stage.index == 0)
                    line
                    step("판정", systemImage: "person.text.rectangle", active: stage.index == 1)
                    line
                    step("발표", systemImage: "clock", active: stage.index == 2)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        if let project = controller.card?.project?.name {
                            Text(project).lineLimit(1)
                        }
                        if let checked = controller.lastChecked {
                            Text("마지막 확인 \(checked.formatted(date: .omitted, time: .shortened))")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    Button("내 지원 보기") {
                        controller.closeExpanded()
                        controller.openApplications?()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!controller.isSignedIn)
                }
            }
            .padding(24)
            .background(UMCColor.Custom.backgroundDefault, in: RoundedRectangle(cornerRadius: 24))
            .tint(UMCColor.Semantic.textBrandDefault)
            .environment(\.colorScheme, .dark)
        }
    }

    private var line: some View {
        Capsule().fill(UMCColor.Semantic.textBrandDefault.opacity(0.65))
            .frame(maxWidth: 44, maxHeight: 2).padding(.bottom, 19)
    }

    private func step(_ label: String, systemImage: String, active: Bool) -> some View {
        VStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 18))
                .frame(width: 36, height: 36)
                .background(UMCColor.Custom.backgroundSurfaceWhite, in: Circle())
                .overlay { if active { Circle().stroke(UMCColor.Semantic.textBrandDefault) } }
            Text(label).font(.caption)
        }
        .frame(maxWidth: .infinity)
        .foregroundStyle(active ? UMCColor.Semantic.textBrandDefault : UMCColor.Semantic.textNeutralDefault)
    }
}

struct MatchingProgressStage {
    let title: String
    let index: Int?
    let next: Date?

    @MainActor
    init(controller: MatchingProgressController, now: Date) {
        self.init(
            signedIn: controller.isSignedIn, unavailable: controller.unavailable,
            lastChecked: controller.lastChecked, card: controller.card, round: controller.round, now: now
        )
    }

    init(
        signedIn: Bool, unavailable: Bool, lastChecked: Date?, card: MatchingApplication?,
        round: MatchingRound?, now: Date
    ) {
        if !signedIn {
            (title, index, next) = ("로그인이 필요해요", nil, nil)
        } else if unavailable {
            (title, index, next) = ("연결 확인 중", nil, nil)
        } else if lastChecked == nil {
            (title, index, next) = ("현황 확인 중", nil, nil)
        } else if card == nil {
            (title, index, next) = ("내 지원 내역이 없어요", nil, nil)
        } else if card?.status == "APPROVED" || card?.status == "REJECTED" {
            (title, index, next) = (card?.status == "APPROVED" ? "합격" : "불합격", 2, nil)
        } else if let start = Self.date(round?.startsAt), now < start {
            (title, index, next) = ("지원 예정", 0, start)
        } else if let end = Self.date(round?.endsAt), now <= end {
            (title, index, next) = ("지원 기간", 0, end)
        } else if let deadline = Self.date(round?.decisionDeadline), now <= deadline {
            (title, index, next) = ("판정 기간", 1, deadline)
        } else {
            let publication = Self.date(round?.resultPublishAt)
            (title, index, next) = ("발표 대기", 2, publication.flatMap { now < $0 ? $0 : nil })
        }
    }

    private static func date(_ raw: String?) -> Date? {
        guard let raw else { return nil }
        return (try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(raw))
            ?? (try? Date.ISO8601FormatStyle().parse(raw))
    }
}
