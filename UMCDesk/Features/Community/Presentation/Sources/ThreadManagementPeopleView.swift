//
//  ThreadManagementPeopleView.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import CoreDesignSystem
import CoreUIComponents
import SwiftUI
import UMCFoundation

enum ThreadManagementPeopleMode { case members, invite, transfer }

struct ThreadManagementPeopleView: View {
    let threadID: String
    let detail: ThreadManagementDetail
    let mode: ThreadManagementPeopleMode
    let repository: any ThreadManagementRepository
    @Binding var saving: Bool
    let onChanged: () -> Void
    let onFinished: () -> Void

    @State var model = ThreadManagementPeopleModel()
    @State private var query = ""
    @State private var revision = 0
    @State private var confirming: ThreadManagementOperation?
    @State private var destination: ThreadManagementDestination?

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
            if let completion = model.completion {
                Label {
                    Text(completion).umcTypography(.headlineRegular)
                } icon: {
                    Image(systemName: "checkmark").foregroundStyle(UMCColor.Semantic.textSuccess)
                }
                .padding(.horizontal, UMCSpacing.value16)
                .padding(.vertical, UMCSpacing.value12)
                .background(UMCColor.Custom.backgroundSurfaceGreyWeaker,
                            in: .rect(cornerRadius: UMCRadius.value12))
                .accessibilityElement(children: .combine)
            }
            if mode == .members, detail.canManage {
                HStack {
                    Text(model.selecting ? "내보낼 참여자를 선택하세요."
                         : "개설자와 관리자는 참여자를 초대하거나 내보낼 수 있어요.")
                    Spacer()
                    Button(model.selecting ? "선택 취소" : "선택") {
                        model.toggleSelectionMode()
                    }
                    if !model.selecting {
                        Button("참여자 초대", systemImage: "person.badge.plus") {
                            destination = .invite
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            UMCSearchField(AppLocalization.string("이름 또는 닉네임 검색"), text: $query)
            if !model.selection.isEmpty && mode != .members {
                HStack {
                    Text("\(model.selection.count)명 선택").umcTypography(.headlineBold)
                    Button("선택 해제") { model.selection = [:] }
                    Spacer()
                    selectionActions
                }
            }
            if mode == .invite && !model.selection.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(selected, id: \.memberId) { person in
                            Button(person.name, systemImage: "xmark.circle") {
                                model.selection.removeValue(forKey: person.memberId)
                            }
                            .accessibilityLabel(person.name + " 선택 해제")
                        }
                    }
                }
            }
            if let failure = model.failure {
                Text(failure).foregroundStyle(UMCColor.Semantic.iconError)
                Button("다시 시도") { revision += 1 }
            }
            if model.loading { ProgressView().controlSize(.small) }
            ScrollView {
                LazyVStack(spacing: mode == .members ? UMCSpacing.value20 : UMCSpacing.value8) {
                    ForEach(model.rows, id: \.memberId) { person in row(person) }
                    if model.rows.isEmpty && !model.loading && model.failure == nil {
                        Text(query.isEmpty ? "표시할 회원이 없어요." : "검색 결과가 없어요.")
                    }
                    if let cursor = model.cursor {
                        Button("더 보기") { Task { await load(offset: cursor) } }
                            .disabled(model.loading)
                    }
                }
            }
            .frame(minHeight: 140, idealHeight: mode == .members ? 390 : 260,
                   maxHeight: mode == .members ? .infinity : 340)
            if mode == .members && model.selecting {
                HStack(spacing: UMCSpacing.value12) {
                    Text("\(model.selection.count)명 선택").umcTypography(.headlineBold)
                    selectionActions
                }
            }
            if mode == .invite, let operationError = model.operationError {
                Text(operationError).foregroundStyle(UMCColor.Semantic.iconError)
            }
            HStack {
                Text("참여자는 최대 \(detail.maxMembers)명까지 함께할 수 있어요.")
                    .umcTypography(.bodyRegular).foregroundStyle(.secondary)
                Spacer()
                if mode == .invite {
                    Button("\(model.selection.count)명 초대") { invite() }
                        .buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
                        .disabled(model.selection.isEmpty)
                }
            }
        }
        .disabled(saving)
        .task(id: [query, String(revision)]) { await load(offset: nil) }
        .sheet(item: $destination) { page in
            ThreadManagementView(threadID: threadID, destination: page, repository: repository,
                                 onChanged: { onChanged(); revision += 1 }, onExit: onFinished)
        }
        .sheet(isPresented: $model.showsFailure) {
            let mayRetry = detail.canManage &&
                (model.lastAction == .kick || detail.myRole == .owner)
            ThreadManagementFailureSheet(model: model, saving: saving, mayRetry: mayRetry) {
                guard let operation = model.lastAction else { return }
                run(operation, retry: true)
            }
        }
        .alert(item: $confirming) { operation in
            Alert(title: Text("\(model.selection.count)명에게 \(operation.rawValue)를 적용할까요?"),
                  message: Text(selected.map(\.name).joined(separator: ", ")),
                  primaryButton: .destructive(Text(operation.rawValue)) {
                      run(operation, selected)
                  },
                  secondaryButton: .cancel(Text("취소")))
        }
    }

    private var selected: [ThreadManagementPerson] {
        model.selection.values.sorted { $0.memberId < $1.memberId }
    }

    @ViewBuilder private var selectionActions: some View {
        if mode == .transfer {
            Button("개설자 위임") { confirming = .transfer }
        } else if mode == .members {
            Button("\(model.selection.count)명 내보내기", role: .destructive) { confirming = .kick }
                .buttonStyle(ThreadManagementDestructiveButtonStyle())
                .disabled(model.selection.isEmpty)
            if detail.myRole == .owner {
                Menu("역할 변경") {
                    Button("관리자 지정") { confirming = .promote }
                        .disabled(selected.contains { $0.role != .member })
                    Button("관리자 해제") { confirming = .demote }
                        .disabled(selected.contains { $0.role != .admin })
                    Button("개설자 위임") { confirming = .transfer }
                        .disabled(model.selection.count != 1)
                }
                .disabled(model.selection.isEmpty)
            }
        }
    }

    private func row(_ person: ThreadManagementPerson) -> some View {
        let choosing = mode == .transfer || (mode == .members && model.selecting)
        return HStack(spacing: UMCSpacing.value12) {
            if choosing || mode == .invite {
                let checked = Binding(
                    get: { model.selection[person.memberId] != nil },
                    set: { enabled in
                        if enabled && mode == .transfer { model.selection.removeAll() }
                        model.selection[person.memberId] = enabled ? person : nil
                    })
                Toggle(isOn: checked) { EmptyView() }
                    .toggleStyle(UMCCheckboxStyle())
                    .accessibilityRepresentation {
                        Toggle(person.name, isOn: checked).toggleStyle(.checkbox)
                    }
                    .disabled(!canSelect(person) || (mode == .invite && !checked.wrappedValue
                              && model.selection.count >= remainingCapacity))
            }
            Text(String(person.name.prefix(1)))
                .umcTypography(.headlineBold)
                .foregroundStyle(UMCColor.Primitives.violet600)
                .frame(width: 40, height: 40)
                .background(UMCColor.Primitives.violet50, in: .rect(cornerRadius: 12))
                .accessibilityHidden(true)
            VStack(alignment: .leading) {
                let name = person.name + (person.memberId == model.currentID ? " (나)" : "")
                if choosing {
                    Text(name).umcTypography(.headlineBold).accessibilityHidden(true)
                } else {
                    Button(name) { destination = .profile(memberID: person.memberId) }
                        .buttonStyle(.plain).umcTypography(.headlineBold)
                }
                Text([person.generation.map { $0 + "기" }, person.part].compactMap { $0 }
                    .joined(separator: " · ")).foregroundStyle(.secondary)
            }
            if let role = person.role {
                Text(role.label).umcTypography(.bodyRegular).padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(UMCColor.Semantic.fillNeutralWeak75, in: Capsule())
            }
            Spacer()
            if mode == .members && !model.selecting {
                if canSelect(person) {
                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: UMCSpacing.value12) {
                            memberActions(person)
                        }
                        .fixedSize()
                        Menu {
                            memberActions(person)
                        } label: { Label("참여자 옵션", systemImage: "ellipsis") }
                        .labelStyle(.iconOnly)
                    }
                }
            }
        }
        .padding(UMCSpacing.value12)
        .frame(minHeight: mode == .members ? 74 : 54)
        .background(UMCColor.Semantic.fillNeutralWeaker50, in: .rect(cornerRadius: 12))
    }

    @ViewBuilder private func memberActions(_ person: ThreadManagementPerson) -> some View {
        if detail.myRole == .owner {
            Menu("역할 변경") {
                if person.role == .member {
                    singleAction("관리자 지정", .promote, person)
                } else {
                    singleAction("관리자 해제", .demote, person)
                }
            }
            singleAction("개설자 위임", .transfer, person)
        }
        singleAction("내보내기", .kick, person)
    }

    private func singleAction(_ title: String, _ operation: ThreadManagementOperation,
                              _ person: ThreadManagementPerson) -> some View {
        Button(title) {
            model.selection = [person.memberId: person]
            confirming = operation
        }
    }

    private var remainingCapacity: Int {
        min(99, max(0, (Int(detail.maxMembers) ?? 0) - (Int(detail.memberCount) ?? 0)))
    }

    private func canSelect(_ person: ThreadManagementPerson) -> Bool {
        if mode == .invite { return true }
        return detail.canManage && model.currentID != nil && person.memberId != model.currentID &&
            person.state == "ACTIVE" && person.role != nil && person.role != .owner
    }

    private func load(offset: String?) async {
        await model.load(threadID: threadID, mode: mode, query: query, offset: offset,
                         needsIdentity: detail.canManage, repository: repository)
    }

    private func invite() {
        guard !saving, !model.selection.isEmpty else { return }
        let ids = selected.map(\.memberId)
        saving = true
        model.operationError = nil
        Task {
            defer { saving = false }
            do {
                try await repository.apply(.invite(ids), threadID: threadID)
                onChanged()
                onFinished()
            } catch { model.operationError = error.localizedDescription }
        }
    }

    private func run(_ operation: ThreadManagementOperation,
                     _ targets: [ThreadManagementPerson] = [], retry: Bool = false) {
        guard !saving, retry || !targets.isEmpty, detail.canManage,
              operation == .kick || detail.myRole == .owner else { return }
        saving = true
        Task {
            defer { saving = false }
            let changed: Bool
            if retry {
                changed = await model.retryFailures(repository: repository, threadID: threadID)
            } else {
                changed = await model.apply(operation, targets: targets,
                                            repository: repository, threadID: threadID)
            }
            if changed {
                onChanged()
                if operation == .transfer { onFinished(); return }
            }
            revision += 1
        }
    }
}

extension ThreadManagementRole {
    var label: String {
        switch self {
        case .owner: "개설자"
        case .admin: "관리자"
        case .member: "참여자"
        }
    }
}

struct ThreadManagementFailureSheet: View {
    let model: ThreadManagementPeopleModel
    let saving: Bool
    var mayRetry = true
    let retry: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            Text(model.lastAction == .kick
                 ? "\(model.failed.count)명을 내보내지 못했어요"
                 : "\(model.failed.count)명의 역할을 변경하지 못했어요")
                .umcTypography(.title2Bold)
            Text("실패한 참여자만 다시 시도할 수 있어요.")
                .foregroundStyle(.secondary)
            ScrollView {
                VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                    ForEach(model.succeeded, id: \.memberId) { resultRow($0, failed: false) }
                    ForEach(model.failed, id: \.memberId) { resultRow($0, failed: true) }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: min(220, CGFloat(model.failed.count + model.succeeded.count) * 38))
            HStack {
                Spacer()
                Button("닫기") { model.showsFailure = false }
                    .keyboardShortcut(.cancelAction)
                Button("실패한 \(model.failed.count)명 재시도", role: .destructive, action: retry)
                    .buttonStyle(ThreadManagementDestructiveButtonStyle())
                    .disabled(!mayRetry)
            }
        }
        .padding(UMCSpacing.value24)
        .frame(width: 472, alignment: .leading)
        .background(UMCColor.Custom.backgroundSurfaceGreyWeaker)
        .disabled(saving)
        .interactiveDismissDisabled(saving)
    }

    private func resultRow(_ person: ThreadManagementPerson, failed: Bool) -> some View {
        HStack(spacing: UMCSpacing.value8) {
            Text(person.name).umcTypography(.headlineBold)
            if let role = person.role {
                Text(role.label).foregroundStyle(.secondary)
            }
            Text((model.lastAction?.rawValue ?? "") + (failed ? " 실패" : " 완료"))
                .foregroundStyle(failed ? UMCColor.Semantic.textError
                                  : UMCColor.Semantic.textSuccess)
        }
        .padding(.horizontal, UMCSpacing.value12)
        .frame(minHeight: 30, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct ThreadManagementDestructiveButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .umcTypography(.headlineBold)
            .foregroundStyle(UMCColor.Semantic.textError)
            .padding(.horizontal, UMCSpacing.value16)
            .frame(minHeight: 36)
            .background(configuration.isPressed ? UMCColor.Semantic.fillNeutralWeak75 : .clear,
                        in: .rect(cornerRadius: UMCRadius.value8))
            .overlay {
                RoundedRectangle(cornerRadius: UMCRadius.value8)
                    .strokeBorder(UMCColor.Semantic.borderErrorWeak200)
            }
            .contentShape(.rect)
            .opacity(isEnabled ? 1 : 0.5)
    }
}
