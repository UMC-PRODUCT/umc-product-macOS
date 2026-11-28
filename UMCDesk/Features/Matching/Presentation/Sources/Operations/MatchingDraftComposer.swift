//
//  MatchingDraftComposer.swift
//  MatchingPresentation
//
//  Created by euijjang97 on 11/22/26.
//

import CoreDesignSystem
import CoreUIComponents
import MatchingDomain
import SwiftUI
import UMCFoundation

struct MatchingDraftComposer: View {
    let service: any MatchingUseCase
    let gisuId: String
    let canCreateOwn: Bool
    let canChooseOther: Bool
    let open: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var chooseOwner = false
    @State private var owner: OperationsPerson?
    @State private var keyword = ""
    @State private var query = ""
    @State private var page = 0
    @State private var creating = false
    @State private var failure: String?

    private var needsOwner: Bool { canChooseOther && (!canCreateOwn || chooseOwner) }

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            Text("프로젝트 만들기").umcTypography(.title1Bold)
            OperationsLoad(key: gisuId, load: { try await service.latestDraft(gisuId: gisuId) }) { draft in
                if let draft {
                    HStack {
                        Text(draft.name ?? "제목 없는 초안")
                        Spacer()
                        Button("기존 초안 이어쓰기") { open(draft.id) }
                    }.matchingPanel()
                }
            }
            if canCreateOwn && canChooseOther {
                Picker("새 초안 담당 PM", selection: $chooseOwner) {
                    Text("본인").tag(false)
                    Text("다른 PM 선택").tag(true)
                }.pickerStyle(.segmented)
            }
            if needsOwner {
                HStack {
                    UMCSearchField(
                        AppLocalization.string("PM 이름 또는 닉네임"), text: $keyword
                    )
                        .onSubmit { search() }
                    Button("검색") { search() }
                }
                OperationsLoad(key: [gisuId, query, String(page)], load: {
                    try await service.pmCandidates(gisuId: gisuId, keyword: query, page: page)
                }) { result in
                    if result.people.isEmpty { Text("선택할 수 있는 PM이 없어요.") }
                    ScrollView {
                        VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                            ForEach(result.people, id: \.memberId) { person in
                                Button {
                                    owner = person
                                } label: {
                                    Label([person.nickname, person.name, person.schoolName]
                                        .compactMap { $0 }.joined(separator: " · "), systemImage:
                                        owner?.memberId == person.memberId ? "checkmark.circle.fill" : "circle")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }.buttonStyle(.plain)
                            }
                        }
                    }.frame(maxHeight: 180)
                    HStack {
                        Button("이전") { owner = nil; page -= 1 }.disabled(page < 1)
                        Button("다음") { owner = nil; page += 1 }.disabled(!result.hasNext)
                    }
                }
            }
            if let failure { Label(failure, systemImage: "exclamationmark.circle") }
            HStack {
                Spacer()
                Button("취소") { dismiss() }
                Button("새 초안 만들기") { create() }
                    .buttonStyle(.borderedProminent)
                    .disabled(needsOwner ? owner == nil : !canCreateOwn)
            }
        }
        .disabled(creating)
        .interactiveDismissDisabled(creating)
        .overlay { if creating { ProgressView() } }
        .padding(UMCSpacing.value24)
        .frame(width: 460)
    }

    private func search() {
        owner = nil
        page = 0
        query = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func create() {
        guard !creating, (needsOwner ? owner != nil : canCreateOwn) else { return }
        creating = true
        failure = nil
        Task {
            defer { creating = false }
            do {
                let id = try await service.createProjectDraft(
                    gisuId: gisuId, productOwnerMemberId: needsOwner ? owner?.memberId : nil
                )
                open(id)
            } catch { failure = error.localizedDescription }
        }
    }
}
