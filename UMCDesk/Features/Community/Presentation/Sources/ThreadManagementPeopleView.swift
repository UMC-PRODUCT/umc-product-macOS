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

enum ThreadManagementPeopleMode { case members, invite, transfer }

struct ThreadManagementPeopleView: View {
    let threadID: String
    let detail: ThreadManagementDetail
    let mode: ThreadManagementPeopleMode
    let repository: any ThreadManagementRepository
    @Binding var saving: Bool
    let onChanged: () -> Void
    let onFinished: () -> Void

    @State private var model = ThreadManagementPeopleModel()
    @State private var selection: [String: ThreadManagementPerson] = [:]
    @State private var query = ""
    @State private var selecting = false
    @State private var revision = 0
    @State private var confirming: ThreadManagementOperation?
    @State private var destination: ThreadManagementDestination?

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
            if mode == .members, detail.canManage {
                HStack {
                    Text("개설자와 관리자는 참여자를 초대하거나 내보낼 수 있어요.")
                    Spacer()
                    Button(selecting ? "선택 취소" : "선택") {
                        selecting.toggle()
                        selection.removeAll()
                    }
                    Button("참여자 초대", systemImage: "person.badge.plus") {
                        destination = .invite
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            TextField("이름 또는 닉네임 검색", text: $query).textFieldStyle(.roundedBorder)
            if !selection.isEmpty && (mode != .members || selecting) {
                HStack {
                    Text("\(selection.count)명 선택").umcTypography(.headlineBold)
                    Button("선택 해제") { selection = [:] }
                    Spacer()
                    selectionActions
                }
            }
            if mode == .invite && !selection.isEmpty {
                ScrollView(.horizontal) {
                    HStack {
                        ForEach(selected, id: \.memberId) { person in
                            Button(person.name, systemImage: "xmark.circle") {
                                selection.removeValue(forKey: person.memberId)
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
            if let operationError = model.operationError {
                Text(operationError).foregroundStyle(UMCColor.Semantic.iconError)
            }
            if !model.succeeded.isEmpty || !model.failed.isEmpty {
                results
            }
            HStack {
                Text("참여자는 최대 \(detail.maxMembers)명까지 함께할 수 있어요.")
                    .umcTypography(.bodyRegular).foregroundStyle(.secondary)
                Spacer()
                if mode == .invite {
                    Button("\(selection.count)명 초대") { invite() }
                        .buttonStyle(.borderedProminent).keyboardShortcut(.defaultAction)
                        .disabled(selection.isEmpty)
                }
            }
        }
        .disabled(saving)
        .task(id: [query, String(revision)]) { await load(offset: nil) }
        .sheet(item: $destination) { page in
            ThreadManagementView(threadID: threadID, destination: page, repository: repository,
                                 onChanged: { onChanged(); revision += 1 }, onExit: onFinished)
        }
        .alert(item: $confirming) { operation in
            Alert(title: Text("\(selection.count)명에게 \(operation.rawValue)를 적용할까요?"),
                  message: Text(selected.map(\.name).joined(separator: ", ")),
                  primaryButton: .destructive(Text(operation.rawValue)) {
                      run(operation, selected)
                  },
                  secondaryButton: .cancel(Text("취소")))
        }
    }

    private var selected: [ThreadManagementPerson] {
        selection.values.sorted { $0.memberId < $1.memberId }
    }

    @ViewBuilder private var selectionActions: some View {
        if mode == .transfer {
            Button("개설자 위임") { confirming = .transfer }
        } else if mode == .members {
            Menu("일괄 작업") {
                if detail.myRole == .owner {
                    Button("관리자 지정") { confirming = .promote }
                        .disabled(selected.contains { $0.role != .member })
                    Button("관리자 해제") { confirming = .demote }
                        .disabled(selected.contains { $0.role != .admin })
                    Button("개설자 위임") { confirming = .transfer }
                        .disabled(selection.count != 1)
                }
                Button("내보내기", role: .destructive) { confirming = .kick }
            }
        }
    }

    private func row(_ person: ThreadManagementPerson) -> some View {
        HStack(spacing: UMCSpacing.value12) {
            if canSelect(person) && (mode != .members || selecting) {
                Toggle(person.name + " 선택", isOn: Binding(
                    get: { selection[person.memberId] != nil },
                    set: { enabled in
                        if enabled && mode == .transfer { selection.removeAll() }
                        selection[person.memberId] = enabled ? person : nil
                    }))
                    .toggleStyle(UMCCheckboxStyle()).labelsHidden()
                    .disabled(mode == .invite && selection[person.memberId] == nil &&
                              selection.count >= remainingCapacity)
            }
            Text(String(person.name.prefix(1)))
                .umcTypography(.headlineBold)
                .foregroundStyle(UMCColor.Primitives.violet600)
                .frame(width: 40, height: 40)
                .background(UMCColor.Primitives.violet50, in: .rect(cornerRadius: 12))
                .accessibilityHidden(true)
            VStack(alignment: .leading) {
                Button(person.name + (person.memberId == model.currentID ? " (나)" : "")) {
                    destination = .profile(memberID: person.memberId)
                }
                .buttonStyle(.plain).umcTypography(.headlineBold)
                Text([person.generation.map { $0 + "기" }, person.part].compactMap { $0 }
                    .joined(separator: " · ")).foregroundStyle(.secondary)
            }
            if let role = person.role {
                Text(role.label).umcTypography(.bodyRegular).padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(UMCColor.Semantic.fillNeutralWeak75, in: Capsule())
            }
            Spacer()
            if mode == .members && !selecting {
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
            selection = [person.memberId: person]
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

    @ViewBuilder private var results: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value4) {
            if let lastAction = model.lastAction {
                if !model.succeeded.isEmpty {
                    Text(lastAction.rawValue + " 완료 · " +
                         model.succeeded.map(\.name).joined(separator: ", "))
                }
                if !model.failed.isEmpty {
                    Text(lastAction.rawValue + " 실패 · " +
                         model.failed.map(\.name).joined(separator: ", "))
                    Button("실패한 참여자만 다시 시도") { run(lastAction, model.failed, retry: true) }
                }
            }
        }
        .umcTypography(.bodyRegular)
    }

    private func load(offset: String?) async {
        await model.load(threadID: threadID, mode: mode, query: query, offset: offset,
                         needsIdentity: detail.canManage, repository: repository)
    }

    private func invite() {
        guard !saving, !selection.isEmpty else { return }
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

    private func run(_ operation: ThreadManagementOperation, _ targets: [ThreadManagementPerson],
                     retry: Bool = false) {
        guard !saving, !targets.isEmpty else { return }
        saving = true
        Task {
            defer { saving = false }
            let changed = await model.apply(operation, targets: targets, retry: retry,
                                            repository: repository, threadID: threadID)
            for person in model.succeeded { selection.removeValue(forKey: person.memberId) }
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
