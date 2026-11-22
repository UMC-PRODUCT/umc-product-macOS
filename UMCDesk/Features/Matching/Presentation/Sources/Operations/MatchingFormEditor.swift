//
//  MatchingFormEditor.swift
//  MatchingPresentation
//
//  Created by euijjang97 on 11/22/26.
//

import CoreDesignSystem
import MatchingDomain
import SwiftUI

struct MatchingFormEditor: View {
    let context: ProjectContext
    @State private var draft: EditableMatchingForm
    @State private var selection = 0

    init(context: ProjectContext, form: EditableMatchingForm) {
        self.context = context
        _draft = State(initialValue: form)
    }

    private var canEdit: Bool {
        context.allows(context.project.applicationFormId == nil ? .formCreate : .formEdit)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            if !canEdit {
                Label(context.permissions[.formEdit]?.reason ?? "지원 폼을 읽기만 할 수 있어요.", systemImage: "lock")
            }
            HStack(alignment: .top, spacing: UMCSpacing.value16) {
                VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                    Text("지원 폼 구조").umcTypography(.title3Bold)
                    ForEach(draft.sections.indices, id: \.self) { index in
                        Button {
                            selection = index
                        } label: {
                            Label(draft.sections[index].title, systemImage: selection == index ? "folder.fill" : "folder")
                        }
                    }
                    if canEdit {
                        Button("섹션 추가", systemImage: "plus") {
                            draft.sections.append(.init(sectionId: nil, type: "COMMON", allowedParts: [],
                                title: "새 섹션", description: nil, orderNo: String(draft.sections.count), questions: []))
                            selection = draft.sections.count - 1
                        }
                    }
                }.matchingPanel().frame(maxWidth: 230)
                VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                    TextField("폼 제목", text: optionalText($draft.title))
                    TextField("폼 설명", text: optionalText($draft.description), axis: .vertical)
                    if draft.sections.indices.contains(selection) {
                        Divider()
                        sectionEditor($draft.sections[selection])
                        HStack {
                            Button("섹션 위로") { draft.sections.swapAt(selection, selection - 1); selection -= 1 }
                                .disabled(selection == 0)
                            Button("섹션 아래로") { draft.sections.swapAt(selection, selection + 1); selection += 1 }
                                .disabled(selection >= draft.sections.count - 1)
                            Button("섹션 삭제", role: .destructive) {
                                draft.sections.remove(at: selection)
                                selection = max(0, min(selection, draft.sections.count - 1))
                            }
                        }
                    }
                    if canEdit {
                        Button("폼 저장") {
                            context.request("지원 폼을 저장할까요?", context.project.name,
                                            .form(draft, confirmDeletion: false))
                        }.disabled(!valid)
                    }
                }.disabled(!canEdit).textFieldStyle(.roundedBorder).matchingPanel()
            }
        }
    }

    private var valid: Bool {
        (draft.title?.count ?? 0) <= 200 && (draft.description?.count ?? 0) <= 500 &&
        draft.sections.allSatisfy { section in
            !section.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            (section.type != "PART" || !(section.allowedParts ?? []).isEmpty) &&
            section.questions.allSatisfy { question in
                !question.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                question.options.allSatisfy { !$0.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            }
        }
    }

    private func sectionEditor(_ section: Binding<EditableSection>) -> some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
            TextField("섹션 제목", text: section.title)
            TextField("섹션 설명", text: optionalText(section.description))
            Picker("노출 대상", selection: section.type) {
                Text("공통").tag("COMMON")
                Text("파트").tag("PART")
            }
            if section.wrappedValue.type == "PART" {
                ForEach(Array(Set(OperationsPart.selectable + (section.wrappedValue.allowedParts ?? []))).sorted(), id: \.self) { part in
                    Toggle(MatchingLabel.part(part), isOn: .init(get: {
                        section.wrappedValue.allowedParts?.contains(part) == true
                    }, set: { enabled in
                        var parts = Set(section.wrappedValue.allowedParts ?? [])
                        if enabled { parts.insert(part) } else { parts.remove(part) }
                        section.wrappedValue.allowedParts = parts.sorted()
                    }))
                }
            }
            ForEach(section.wrappedValue.questions.indices, id: \.self) { index in
                QuestionEditor(question: section.questions[index])
                HStack {
                    Button("문항 위로") { section.wrappedValue.questions.swapAt(index, index - 1) }
                        .disabled(index == 0)
                    Button("문항 아래로") { section.wrappedValue.questions.swapAt(index, index + 1) }
                        .disabled(index == section.wrappedValue.questions.count - 1)
                    Button("문항 삭제") { section.wrappedValue.questions.remove(at: index) }
                }
            }
            Button("문항 추가") {
                section.wrappedValue.questions.append(.init(questionId: nil, type: "SHORT_TEXT",
                    title: "새 문항", description: nil, isRequired: false, orderNo: "0", options: []))
            }
        }
    }
}

private struct QuestionEditor: View {
    @Binding var question: EditableQuestion
    private let choices = ["RADIO", "CHECKBOX", "DROPDOWN"]

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value8) {
            Divider()
            TextField("문항 제목", text: $question.title)
            TextField("문항 설명", text: optionalText($question.description))
            Picker("답변 유형", selection: $question.type) {
                Text("단답형").tag("SHORT_TEXT")
                Text("장문형").tag("LONG_TEXT")
                Text("단일 선택").tag("RADIO")
                Text("복수 선택").tag("CHECKBOX")
                Text("드롭다운").tag("DROPDOWN")
                Text("파일").tag("FILE")
                Text("포트폴리오").tag("PORTFOLIO")
                if question.type == "SCHEDULE" { Text("일정").tag("SCHEDULE") }
            }
            .onChange(of: question.type) { _, type in
                if !choices.contains(type) { question.options = [] }
            }
            Toggle("필수 응답", isOn: $question.isRequired)
            if choices.contains(question.type) {
                ForEach(question.options.indices, id: \.self) { index in
                    HStack {
                        TextField("선택지", text: $question.options[index].content)
                        Toggle("기타", isOn: $question.options[index].isOther)
                        Button("위로") { question.options.swapAt(index, index - 1) }.disabled(index == 0)
                        Button("삭제") { question.options.remove(at: index) }
                    }
                }
                Button("선택지 추가") {
                    question.options.append(.init(optionId: nil, content: "", orderNo: "0", isOther: false))
                }
            }
        }
    }
}

private func optionalText(_ source: Binding<String?>) -> Binding<String> {
    .init(get: { source.wrappedValue ?? "" }, set: { source.wrappedValue = $0 })
}
