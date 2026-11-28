//
//  WorkspaceForms.swift
//  ProjectWorkspacePresentation
//
//  Created by euijjang97 on 11/23/26.
//

import CoreDesignSystem
import ProjectWorkspaceDomain
import CoreUIComponents
import SwiftUI

struct WorkspaceTodoForm: View {
    let save: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @FocusState private var editing: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            Text("할 일 추가").umcTypography(.title1Bold)
            Text("한 줄이면 충분해요. 이 프로젝트에 내 할 일로 저장됩니다.")
                .foregroundStyle(.secondary)
            TextField("할 일", text: $title)
                .focused($editing)
                .focusEffectDisabled()
                .umcInputField(isFocused: editing)
            HStack {
                Spacer()
                Button("취소") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("추가") { save(title) }.keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }.onAppear { editing = true }
    }
}

struct WorkspaceConnectionsForm: View {
    let save: ([String: String], [String: String]) -> Void
    @State private var original: [String: String]
    @Environment(\.dismiss) private var dismiss
    @State private var links: [String: String]
    @State private var submitted = false

    init(record: WorkspaceRecord, save: @escaping ([String: String], [String: String]) -> Void) {
        _original = State(initialValue: record.resources)
        _links = State(initialValue: record.resources)
        self.save = save
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            Text("연결 관리").umcTypography(.title1Bold)
            ForEach(WorkspaceResource.allCases) { resource in
                let invalid = submitted && !valid(resource)
                VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                    Text(resource.rawValue).umcTypography(.headlineBold)
                    TextField(resource == .github ? "GitHub 저장소 링크" : "Figma 파일 링크",
                              text: Binding(
                                get: { links[resource.rawValue] ?? "" },
                                set: { links[resource.rawValue] = $0 }
                              ))
                    .umcInputField(isInvalid: invalid)
                    if invalid {
                        Text(resource == .github ? "GitHub 저장소 주소를 확인하세요." :
                                "Figma 파일 링크를 확인하세요.")
                            .foregroundStyle(UMCColor.Semantic.iconError)
                    }
                }
            }
            Text("이 Mac에서 내 계정으로만 사용합니다. 비공개 자료는 원본에서 로그인해 열 수 있습니다.")
                .umcTypography(.bodyRegular).foregroundStyle(.secondary)
            HStack {
                Spacer()
                Button("취소") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("저장") {
                    submitted = true
                    guard WorkspaceResource.allCases.allSatisfy(valid) else { return }
                    var resources: [String: String] = [:]
                    for resource in WorkspaceResource.allCases {
                        resources[resource.rawValue] = resource.validatedURL(
                            links[resource.rawValue] ?? ""
                        )?.absoluteString
                    }
                    save(original, resources)
                }.keyboardShortcut(.defaultAction)
            }
        }
    }

    private func valid(_ resource: WorkspaceResource) -> Bool {
        let value = links[resource.rawValue] ?? ""
        let input = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return input.isEmpty || resource.validatedURL(input) != nil
    }
}
