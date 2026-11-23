//
//  ThreadManagementProfileView.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import CoreUIComponents
import CoreDesignSystem
import SwiftUI

struct ThreadManagementProfileView: View {
    @Environment(\.dismiss) private var dismiss
    let memberID: String
    let repository: any ThreadManagementRepository
    @State private var profile: ThreadManagementProfile?
    @State private var failure: String?
    @State private var revision = 0

    @State private var isOtherMember = false
    @State private var blocked: Bool?
    @State private var blockFailure: String?
    @State private var reporting = false
    @State private var confirmingBlock = false
    @State private var changingBlock = false
    @State private var statusRevision = 0

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            HStack {
                Text("회원 프로필").umcTypography(.title1Bold)
                Spacer()
                if isOtherMember, profile != nil {
                    Menu("더보기") {
                        Button(blocked == true ? "차단 해제" : "사용자 차단",
                               systemImage: "lock", role: .destructive) {
                            confirmingBlock = true
                        }.disabled(blocked == nil || changingBlock)
                        Button("사용자 신고", systemImage: "flag", role: .destructive) {
                            reporting = true
                        }
                    }.fixedSize().disabled(changingBlock)
                }
                Button("닫기", systemImage: "xmark") { dismiss() }
                    .labelStyle(.iconOnly).buttonStyle(.plain)
                    .keyboardShortcut(.cancelAction).disabled(changingBlock)
            }
            if let profile {
                ScrollView {
                    VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                        HStack(spacing: UMCSpacing.value12) {
                            AsyncImage(url: publicURL(profile.profileImageLink)) { phase in
                                if let image = phase.image {
                                    image.resizable().scaledToFill()
                                } else {
                                    Text(String(profile.name.prefix(1))).umcTypography(.title2Bold)
                                }
                            }
                            .frame(width: 56, height: 56)
                            .background(UMCColor.Semantic.fillNeutralWeak75).clipShape(Circle())
                            VStack(alignment: .leading) {
                                Text([profile.name, profile.nickname].compactMap { $0 }
                                    .joined(separator: " / ")).umcTypography(.title3Bold)
                                if let school = profile.schoolName { Text(school) }
                            }
                        }
                        if blocked == true { Text("차단한 사용자").font(.callout) }
                        if let blockFailure {
                            Text(blockFailure).foregroundStyle(UMCColor.Semantic.textError)
                            Button("차단 상태 다시 확인") { statusRevision += 1 }
                        }
                        Divider()
                        Text("활동 이력").umcTypography(.headlineBold)
                        if profile.challengerRecords.isEmpty { Text("활동 이력이 없어요.") }
                        ForEach(profile.challengerRecords.indices, id: \.self) { index in
                            let record = profile.challengerRecords[index]
                            Text([record.gisu.map { $0 + "기" }, record.part].compactMap { $0 }
                                .joined(separator: " · "))
                        }
                        Text("연락처·외부 링크").umcTypography(.headlineBold)
                        linkRow("이메일", nil)
                        linkRow("GitHub", profile.profile?.github)
                        linkRow("LinkedIn", profile.profile?.linkedIn)
                        linkRow("Blog", profile.profile?.blog)
                        linkRow("Instagram", profile.profile?.instagram)
                        linkRow("개인 사이트", profile.profile?.personal)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(minHeight: 240, idealHeight: 440, maxHeight: 500)
            } else if let failure {
                Text(failure).foregroundStyle(UMCColor.Semantic.iconError)
                Button("다시 시도") { revision += 1 }
            } else { ProgressView() }
        }
        .interactiveDismissDisabled(changingBlock)
        .sheet(isPresented: $reporting) {
            ThreadReportSheet(target: .member(memberID), repository: repository)
        }
        .confirmationDialog(blocked == true ? "차단을 해제할까요?" : "이 사용자를 차단할까요?",
                            isPresented: $confirmingBlock) {
            Button(blocked == true ? "차단 해제" : "차단", role: .destructive) {
                guard let blocked, !changingBlock else { return }
                changingBlock = true
                Task { await updateBlock(to: !blocked) }
            }
            Button("취소", role: .cancel) {}
        }
        .task(id: statusRevision) {
            blocked = nil
            blockFailure = nil
            do {
                let actor = try await repository.currentMemberID()
                try Task.checkCancellation()
                isOtherMember = actor != memberID
                if isOtherMember { try await refreshBlock() }
            } catch {
                if !Task.isCancelled { blockFailure = error.localizedDescription }
            }
        }
        .task(id: revision) {
            failure = nil
            do {
                let result = try await repository.profile(memberID: memberID)
                try Task.checkCancellation()
                profile = result
            } catch {
                if !Task.isCancelled { failure = error.localizedDescription }
            }
        }
    }

    private func refreshBlock() async throws {
        let result = try await repository.isBlocked(memberID: memberID)
        try Task.checkCancellation()
        blocked = result
    }

    private func updateBlock(to desired: Bool) async {
        defer { changingBlock = false }
        blocked = nil
        blockFailure = nil
        do {
            try await repository.setBlocked(desired, memberID: memberID)
        } catch {
            blockFailure = error.localizedDescription
        }
        do {
            try await refreshBlock()
        } catch {
            blockFailure = "차단 상태를 확인하지 못했어요. " + error.localizedDescription
        }
    }

    private func linkRow(_ title: String, _ value: String?) -> some View {
        LabeledContent(title) {
            if let value, let url = publicURL(value) {
                Link(value, destination: url).lineLimit(1)
            } else if let value, !value.isEmpty {
                Text(value).textSelection(.enabled)
            } else {
                Text("비공개 항목이에요.").foregroundStyle(.secondary)
            }
        }
    }

    private func publicURL(_ value: String?) -> URL? {
        guard let value, let url = URL(string: value), let scheme = url.scheme?.lowercased(),
              ["https", "http"].contains(scheme), url.host != nil else { return nil }
        return url
    }
}

struct ThreadReportSheet: View {
    @Environment(\.dismiss) private var dismiss
    let target: ThreadReportTarget
    let repository: any ThreadManagementRepository
    @State private var reasons: [ThreadReportReason] = []
    @State private var detail = ""
    @State private var confirming = false
    @State private var submitting = false
    @State private var receipt: String?
    @State private var failure: String?

    private var valid: Bool {
        !reasons.isEmpty && (!target.isMember ||
            (!detail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                && detail.utf16.count <= 500))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            if let receipt {
                Text("신고가 접수됐어요").umcTypography(.title2Bold)
                Text("접수한 신고 내용을 확인할게요.")
                Text("접수 번호 " + receipt).font(.caption).textSelection(.enabled)
                HStack {
                    Spacer()
                    Button("확인") { dismiss() }.keyboardShortcut(.defaultAction)
                }
            } else {
                Text(target.isMember ? "사용자 신고" : "메시지 신고").umcTypography(.title2Bold)
                Text(confirming ? "선택한 내용으로 신고할까요?" : "신고 사유를 선택해 주세요.")
                if confirming {
                    Text(reasons.map(label).joined(separator: " · "))
                    if target.isMember { Text(detail).lineLimit(1...6) }
                } else {
                    ForEach(target.reasons, id: \.self) { reason in
                        Toggle(isOn: selection(reason)) {
                            Text(label(reason))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .environment(\.layoutDirection, .leftToRight)
                        }
                        .toggleStyle(UMCCheckboxStyle())
                        .environment(\.layoutDirection, .rightToLeft)
                        .padding(.horizontal, UMCSpacing.value12)
                        .padding(.vertical, UMCSpacing.value8)
                        .background(UMCColor.Custom.backgroundSurfaceGreyWeaker,
                                    in: .rect(cornerRadius: 8))
                    }
                    if target.isMember {
                        TextField("상세 신고 내용 (필수)", text: $detail, axis: .vertical)
                            .lineLimit(2...5)
                        Text("\(detail.utf16.count) / 500").font(.caption)
                    }
                }
                if let failure { Text(failure).foregroundStyle(UMCColor.Semantic.textError) }
                HStack {
                    if submitting { ProgressView().controlSize(.small) }
                    Spacer()
                    Button(confirming ? "뒤로" : "취소") {
                        if confirming { confirming = false; failure = nil } else { dismiss() }
                    }.keyboardShortcut(.cancelAction).disabled(submitting)
                    Button(confirming ? "접수하기" : "신고하기") {
                        if confirming { submit() } else { confirming = true }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(UMCColor.Semantic.textError)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!valid || submitting)
                }
            }
        }
        .padding(UMCSpacing.value24)
        .frame(width: 520, alignment: .leading)
        .background(UMCColor.Custom.backgroundDefault)
        .interactiveDismissDisabled(submitting)
    }

    private func selection(_ reason: ThreadReportReason) -> Binding<Bool> {
        Binding(get: { reasons.contains(reason) }, set: { selected in
            reasons.removeAll { $0 == reason }
            if selected { reasons.append(reason) }
        })
    }

    private func label(_ reason: ThreadReportReason) -> String {
        switch reason {
        case .spam: target.isMember ? "스팸·광고 활동" : "스팸/광고"
        case .abuse: "욕설/비방"
        case .inappropriate: "부적절한 콘텐츠"
        case .privacy: "개인정보 노출"
        case .harassment: "괴롭힘·지속적인 불쾌 행위"
        case .impersonation: "사칭·허위 프로필"
        case .other: "기타"
        }
    }

    private func submit() {
        guard valid, !submitting else { return }
        submitting = true
        failure = nil
        Task {
            defer { submitting = false }
            do {
                receipt = try await repository.report(target, reasons: reasons, detail: detail)
            } catch {
                failure = error.localizedDescription
            }
        }
    }
}
