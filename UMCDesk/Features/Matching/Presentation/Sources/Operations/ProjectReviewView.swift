//
//  ProjectReviewView.swift
//  MatchingPresentation
//
//  Created by euijjang97 on 11/22/26.
//

import CoreDesignSystem
import CoreUIComponents
import MatchingDomain
import SwiftUI

struct ProjectReviewView: View {
    let context: ProjectContext
    @State private var selectedId: String?
    @State private var status = ""
    @State private var part = ""
    @State private var phase = ""

    var body: some View {
        OperationsLoad(key: context.project.id, load: {
            let service = context.service
            let id = context.project.id
            async let rows = service.applicants(projectId: id)
            async let rounds = service.rounds(chapterId: nil)
            return try await (rows, rounds)
        }) { applicants, rounds in
            let rows = applicants.filter {
                (status.isEmpty || $0.status == status) &&
                (part.isEmpty || $0.applicant.part == part) &&
                (phase.isEmpty || $0.matchingRound?.phase == phase)
            }
            HStack(alignment: .top, spacing: UMCSpacing.value16) {
                VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                    ReviewDistribution(rows: rows)
                    HStack {
                        filter("차수", values: applicants.compactMap(\.matchingRound?.phase),
                               value: $phase, label: OperationsPart.phase)
                        filter("파트", values: applicants.compactMap(\.applicant.part),
                               value: $part, label: MatchingLabel.part)
                        filter("상태", values: applicants.map(\.status),
                               value: $status, label: reviewStatus)
                    }
                    if rows.isEmpty { Text("해당하는 지원자가 없어요.").foregroundStyle(.secondary) }
                    ForEach(rows, id: \.applicationId) { row in
                        Button {
                            selectedId = row.applicationId
                        } label: {
                            HStack {
                                Text(row.applicant.display)
                                Spacer()
                                Text(MatchingLabel.part(row.applicant.part ?? "—"))
                                MatchingBadge(text: reviewStatus(row.status))
                            }
                            .padding(UMCSpacing.value8)
                            .contentShape(Rectangle())
                            .background(selectedId == row.applicationId ?
                                UMCColor.Semantic.surfaceBrandWeak : Color.clear, in: .rect(cornerRadius: 8))
                        }.buttonStyle(.plain)
                    }
                    Divider()
                    Text("파트별 선발 현황").umcTypography(.headlineBold)
                    ForEach(context.project.partQuotas, id: \.part) { quota in
                        let approved = applicants.filter {
                            $0.status == "APPROVED" && $0.applicant.part == quota.part &&
                            (phase.isEmpty || $0.matchingRound?.phase == phase)
                        }.count
                        LabeledContent(MatchingLabel.part(quota.part), value: "선발 " + String(approved) + " / TO " + quota.quota)
                        if let total = Double(quota.quota), total > 0 {
                            ProgressView(value: min(Double(approved), total), total: total)
                                .accessibilityHidden(true)
                        }
                    }
                }.matchingPanel().frame(maxWidth: 455)
                VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                    if let row = rows.first(where: { $0.applicationId == selectedId }) ?? rows.first {
                        Text(row.applicant.display).umcTypography(.title2Bold)
                        Text("제출 " + MatchingLabel.time(row.submittedAt)).foregroundStyle(.secondary)
                        OperationsLoad(key: row.applicationId, load: {
                            try await context.service.application(projectId: context.project.id,
                                                                  applicationId: row.applicationId)
                        }) { detail in
                            ForEach(detail.formResponse?.sections ?? [], id: \.sectionId) { section in
                                Divider()
                                Text(section.title).umcTypography(.headlineBold)
                                ForEach(section.questions, id: \.questionId) { question in
                                    Text(question.title).bold()
                                    if let answer = question.answer {
                                        if let text = answer.textValue { Text(text).textSelection(.enabled) }
                                        ForEach(Array(answer.selectedOptions.enumerated()), id: \.offset) { _, choice in
                                            Text(choice.answeredAsContent ?? "—")
                                        }
                                        ForEach(answer.files, id: \.fileId) { file in
                                            if let url = MatchingLabel.webURL(file.url) {
                                                Link(file.originalFileName ?? "첨부 파일 열기", destination: url)
                                            }
                                        }
                                    } else { Text("미응답").foregroundStyle(.secondary) }
                                }
                            }
                            if context.allows(.decide) {
                                TimelineView(.periodic(from: .now, by: 1)) { timer in
                                    let round = rounds.first { $0.id == row.matchingRound?.id }
                                    let opens = MatchingLabel.date(round?.endsAt)
                                    let closes = MatchingLabel.date(round?.decisionDeadline)
                                    if let opens, let closes, opens < timer.date, timer.date <= closes {
                                        HStack {
                                            Button("불합격 판정") { decision(row, approved: false) }
                                                .disabled(row.status == "REJECTED")
                                            Button("합격 처리") { decision(row, approved: true) }
                                                .buttonStyle(.borderedProminent)
                                                .disabled(row.status == "APPROVED")
                                        }
                                    } else {
                                        Label("심사 기간에만 판정할 수 있어요.", systemImage: "lock")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            } else if let reason = context.permissions[.decide]?.reason {
                                Text(reason).foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        ContentUnavailableView("지원자를 선택하세요", systemImage: "doc.text.magnifyingglass")
                    }
                }.matchingPanel()
            }
        }
    }

    private func filter(_ title: String, values: [String], value: Binding<String>,
                        label: @escaping (String) -> String) -> some View {
        Picker(title, selection: value) {
            Text("전체 " + title).tag("")
            ForEach(Array(Set(values)).sorted(), id: \.self) { Text(label($0)).tag($0) }
        }.labelsHidden().accessibilityLabel(title)
    }

    private func decision(_ row: ApplicantRow, approved: Bool) {
        context.request(approved ? "합격 처리할까요?" : "불합격 처리할까요?",
                        row.applicant.display + " · 발표 전 판정은 최종 결과가 아니에요.",
                        .decision(applicationId: row.applicationId, approved: approved))
    }
}

private func reviewStatus(_ raw: String) -> String {
    raw == "SUBMITTED" ? "대기" : MatchingLabel.status(raw)
}

private struct ReviewDistribution: View {
    let rows: [ApplicantRow]

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value8) {
            HStack {
                ForEach(["SUBMITTED", "APPROVED", "REJECTED"], id: \.self) { state in
                    Text(reviewStatus(state) + " " + String(rows.filter { $0.status == state }.count))
                        .foregroundStyle(color(state))
                }
                Text("전체 " + String(rows.count) + "명")
            }.umcTypography(.headlineBold)
            if !rows.isEmpty {
                Canvas { graphics, size in
                    var offset = 0.0
                    for state in ["SUBMITTED", "APPROVED", "REJECTED"] {
                        let count = rows.filter { $0.status == state }.count
                        let width = size.width * Double(count) / Double(rows.count)
                        graphics.fill(Path(CGRect(x: offset, y: 0, width: width, height: size.height)),
                                      with: .color(color(state)))
                        offset += width
                    }
                }
                .frame(height: 8)
                .clipShape(Capsule())
                .accessibilityHidden(true)
            }
        }
    }

    private func color(_ status: String) -> Color {
        switch status {
        case "APPROVED": UMCColor.Semantic.textBrandDefault
        case "REJECTED": UMCColor.Primitives.red500
        default: UMCColor.Primitives.yellow600
        }
    }
}

struct ProjectTeamView: View {
    let context: ProjectContext
    @State private var memberId = ""
    @State private var part = "PLAN"
    @State private var memberStatus = "COMPLETED"
    @State private var reason = ""

    private var canManageRegularMembers: Bool {
        guard let permission = context.permissions[.unassign] else { return false }
        // Outside the matching period, the server still distinguishes staff from other members.
        return permission.allowed
            || permission.reasonCode == "PROJECT_MANUAL_MATCHING_NOT_ALLOWED_IN_PERIOD"
    }

    private var canEditTeam: Bool {
        context.allows(.add) && ["DRAFT", "PENDING_REVIEW", "IN_PROGRESS"].contains(context.status ?? "")
    }

    var body: some View {
        OperationsLoad(key: context.project.id, load: {
            try await context.service.team(projectId: context.project.id)
        }) { team in
            HStack(alignment: .top, spacing: UMCSpacing.value16) {
                VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                    Text("함께 만드는 팀").umcTypography(.title2Bold)
                    if let owner = team.productOwner { Text("담당 PM · " + owner.display) }
                    ForEach(team.coProductOwners, id: \.memberId) { member in
                        row(member, part: "보조 PM")
                    }
                    ForEach(team.partGroups, id: \.part) { group in
                        ForEach(group.members, id: \.memberId) { member in
                            row(member, part: MatchingLabel.part(group.part))
                        }
                    }
                    Divider()
                    ForEach(context.project.partQuotas, id: \.part) { MatchingQuotaView(quota: $0) }
                }.matchingPanel()
                VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                    Text("팀원 관리").umcTypography(.title3Bold)
                    if canEditTeam {
                        TextField("추가할 회원 ID", text: $memberId)
                            .umcInputField()
                        Picker("파트", selection: $part) {
                            ForEach(["PLAN"] + (canManageRegularMembers ? OperationsPart.selectable : []), id: \.self) {
                                Text(MatchingLabel.part($0)).tag($0)
                            }
                        }
                        Button("팀원 추가") {
                            context.request("팀원을 추가할까요?", "회원 " + memberId + " · " + MatchingLabel.part(part),
                                            .add(memberId: memberId, part: part))
                        }.disabled((Int64(memberId) ?? 0) <= 0)
                    }
                    if canEditTeam {
                        Picker("변경할 상태", selection: $memberStatus) {
                            Text("활동 완료").tag("COMPLETED")
                            Text("자진 이탈").tag("WITHDRAWN")
                            Text("활동 중단").tag("DISMISSED")
                        }
                        TextField("상태 변경 사유", text: $reason)
                            .umcInputField()
                    }
                    if !canEditTeam {
                        Text("팀원 정보를 조회할 수 있어요.").foregroundStyle(.secondary)
                    }
                }.matchingPanel()
            }
        }
    }

    private func row(_ member: OperationsPerson, part: String) -> some View {
        let canEditMember = canEditTeam && (part == "보조 PM" || canManageRegularMembers)
        return HStack {
            Text(member.display)
            MatchingBadge(text: part)
            Spacer()
            Menu("관리") {
                if context.allows(.transfer), part == "보조 PM" {
                    Button("소유권 양도") {
                        context.request("프로젝트 소유권을 양도할까요?", member.display,
                                        .transfer(memberId: member.memberId))
                    }
                }
                if canEditMember {
                    Button("팀원 상태 변경") {
                        context.request("팀원 상태를 변경할까요?", member.display + " · " + reason,
                                        .changeStatus(memberId: member.memberId, status: memberStatus, reason: reason))
                    }.disabled(reason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || reason.count > 255)
                }
                if canEditMember && context.allows(.remove) {
                    Button("팀원 제거", role: .destructive) {
                        context.request("팀원을 제거할까요?", member.display, .remove(memberId: member.memberId))
                    }
                }
            }.disabled(!(context.allows(.transfer) && part == "보조 PM") && !canEditMember)
        }
    }
}
