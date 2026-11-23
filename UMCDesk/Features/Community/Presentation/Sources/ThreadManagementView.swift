//
//  ThreadManagementView.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import CoreDesignSystem
import SwiftUI

public enum ThreadManagementDestination: Hashable, Identifiable {
    case members, invite, edit, leave, delete, acknowledgeKick
    case profile(memberID: String)
    public var id: Self { self }

    var title: String {
        switch self {
        case .members: "참여자"
        case .invite: "참여자 초대"
        case .edit: "스레드 편집"
        case .leave: "스레드 나가기"
        case .delete: "스레드 삭제"
        case .acknowledgeKick: "이 스레드에서 내보내졌어요"
        case .profile: "공개 프로필"
        }
    }
}

public struct ThreadManagementView: View {
    @Environment(\.dismiss) private var dismiss
    let threadID: String
    let destination: ThreadManagementDestination
    let repository: any ThreadManagementRepository
    let onChanged: () -> Void
    let onExit: () -> Void

    @State private var detail: ThreadManagementDetail?
    @State private var failure: String?
    @State private var loading = true
    @State private var saving = false
    @State private var version = 0
    @State private var title = ""
    @State private var introduction = ""

    public init(threadID: String, destination: ThreadManagementDestination,
                repository: any ThreadManagementRepository,
                onChanged: @escaping () -> Void, onExit: @escaping () -> Void) {
        self.threadID = threadID
        self.destination = destination
        self.repository = repository
        self.onChanged = onChanged
        self.onExit = onExit
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            HStack {
                Text(destination.title).umcTypography(.title1Bold)
                if destination == .members, let detail {
                    Text(detail.memberCount + "명").padding(.horizontal, 8)
                        .background(UMCColor.Semantic.fillNeutralWeak75, in: Capsule())
                }
                Spacer()
                Group {
                    if destination == .members {
                        Button("대화로 돌아가기") { dismiss() }
                    } else {
                        Button("닫기", systemImage: "xmark") { dismiss() }
                            .labelStyle(.iconOnly).buttonStyle(.plain)
                    }
                }
                .keyboardShortcut(.cancelAction)
                .disabled(saving)
            }
            if let failure {
                Text(failure).foregroundStyle(UMCColor.Semantic.iconError)
                if detail == nil, destination != .acknowledgeKick {
                    Button("다시 시도") { version += 1 }
                }
            }
            if case let .profile(memberID) = destination {
                ThreadManagementProfileView(memberID: memberID, repository: repository)
            } else if destination == .acknowledgeKick {
                Text("확인하면 이 스레드가 목록에서 사라져요.")
                terminalButton("확인", action: .acknowledgeKick)
            } else if loading {
                ProgressView()
            } else if let detail {
                content(detail)
            }
        }
        .padding(destination == .members ? UMCSpacing.value32 : 28)
        .frame(minWidth: 460, idealWidth: destination == .members ? 780 : 620,
               maxWidth: .infinity, alignment: .leading)
        .tint(UMCColor.Semantic.textBrandDefault)
        .background(UMCColor.Custom.backgroundDefault)
        .interactiveDismissDisabled(saving)
        .task(id: version) { await load() }
    }

    @ViewBuilder private func content(_ detail: ThreadManagementDetail) -> some View {
        switch destination {
        case .members, .invite:
            if destination == .members || detail.canManage {
                people(detail, mode: destination == .members ? .members : .invite)
            } else {
                accessDenied
            }
        case .edit:
            if detail.canManage { editor } else { accessDenied }
        case .delete:
            if detail.canManage {
                Text("스레드를 삭제할까요?").umcTypography(.title3Bold)
                Text("모든 참여자가 이 스레드에 접근할 수 없게 돼요.")
                terminalButton("삭제", action: .delete)
            } else { accessDenied }
        case .leave:
            if detail.membershipState != "ACTIVE" { accessDenied }
            else if detail.myRole == .owner {
                Text("나가기 전에 개설자를 위임해 주세요.").umcTypography(.headlineBold)
                if detail.memberCount == "1" {
                    Text("다른 참여자를 초대해 위임하거나 스레드를 삭제할 수 있어요.")
                } else {
                    people(detail, mode: .transfer)
                }
            } else {
                Text("이 스레드에서 나갈까요?")
                terminalButton("나가기", action: .leave)
            }
        case .acknowledgeKick, .profile: EmptyView()
        }
    }

    private func people(_ detail: ThreadManagementDetail, mode: ThreadManagementPeopleMode)
        -> some View {
        ThreadManagementPeopleView(threadID: threadID, detail: detail, mode: mode,
            repository: repository, saving: $saving, onChanged: {
                onChanged()
                Task {
                    if let updated = try? await repository.detail(threadID: threadID) {
                        self.detail = updated
                    }
                }
            }) {
                if mode == .invite { dismiss() } else { version += 1 }
            }
    }

    private var accessDenied: some View {
        Label("이 작업을 수행할 권한이 없어요.", systemImage: "lock")
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
            Text("스레드의 제목과 소개를 수정하세요.").foregroundStyle(.secondary)
            LabeledContent("제목") { Text("\(title.unicodeScalars.count) / 80") }
            TextField("제목", text: $title)
                .managementInput(minHeight: 48)
            LabeledContent("소개") { Text("\(introduction.unicodeScalars.count) / 500") }
            TextField("소개", text: $introduction, axis: .vertical)
                .lineLimit(3...6).managementInput(minHeight: 90)
            HStack {
                Spacer()
                Button("취소") { dismiss() }
                Button("변경 저장") {
                    let changedTitle = title != detail?.title ? title : nil
                    let changedIntro = introduction == (detail?.description ?? "")
                        ? nil : introduction
                    submit(.edit(title: changedTitle, description: changedIntro), exit: false)
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                .disabled(!canSave)
            }
        }
        .textFieldStyle(.plain)
        .disabled(saving)
    }

    private var canSave: Bool {
        guard let detail else { return false }
        return !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            title.unicodeScalars.count <= 80 && introduction.unicodeScalars.count <= 500 &&
            (title != detail.title || introduction != (detail.description ?? ""))
    }

    private func terminalButton(_ label: String, action: ThreadManagementAction) -> some View {
        HStack {
            Spacer()
            Button("취소") { dismiss() }
            Button(label, role: destination == .acknowledgeKick ? nil : .destructive) {
                submit(action, exit: true)
            }
            .buttonStyle(.borderedProminent)
        }
        .disabled(saving)
    }

    private func load() async {
        switch destination {
        case .profile, .acknowledgeKick: return
        default: break
        }
        loading = true
        failure = nil
        do {
            let value = try await repository.detail(threadID: threadID)
            try Task.checkCancellation()
            detail = value
            title = value.title
            introduction = value.description ?? ""
        } catch {
            guard !Task.isCancelled else { return }
            detail = nil
            failure = error.localizedDescription
        }
        loading = false
    }

    private func submit(_ action: ThreadManagementAction, exit: Bool) {
        guard !saving else { return }
        saving = true
        failure = nil
        Task {
            defer { saving = false }
            do {
                try await repository.apply(action, threadID: threadID)
                dismiss()
                if exit { onExit() } else { onChanged() }
            } catch { failure = error.localizedDescription }
        }
    }
}

extension ThreadManagementDetail {
    var canManage: Bool {
        membershipState == "ACTIVE" && (myRole == .owner || myRole == .admin)
    }
}


private extension View {
    func managementInput(minHeight: CGFloat) -> some View {
        self.padding(.horizontal, UMCSpacing.value12)
            .frame(minHeight: minHeight, alignment: .leading)
            .background(UMCColor.Semantic.surfaceNeutralWeak, in: .rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(UMCColor.Semantic.borderNeutralWeak200)
                    .allowsHitTesting(false)
            }
    }
}
