//
//  SupportFAQPreview.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/23/26.
//

import CoreDesignSystem
import CoreUIComponents
import SwiftUI

struct SupportFAQPreview: View {
    @Bindable var fixture: SupportFixture
    let back: () -> Void
    @State private var filter = "발행"
    @State private var editing: SupportDraft?

    init(fixture: SupportFixture, initialDraft: SupportDraft? = nil, back: @escaping () -> Void) {
        self.fixture = fixture
        self.back = back
        _editing = State(initialValue: initialDraft)
    }

    var body: some View {
        HStack {
            Button("문의 관리로", action: back).keyboardShortcut(.cancelAction)
            Spacer()
            Button("FAQ 작성") {
                editing = SupportDraft(article: SupportArticle(
                    id: UUID().uuidString, question: "", answer: ""
                ))
            }
        }
        Text("FAQ 관리").umcTypography(.title2Bold).accessibilityAddTraits(.isHeader)
        Picker("공개 상태", selection: $filter) {
            ForEach(["초안", "발행", "보관"], id: \.self) { Text($0).tag($0) }
        }.pickerStyle(.segmented).fixedSize().onChange(of: filter) { editing = nil }
        HStack(alignment: .top, spacing: 24) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("대표 질문").umcTypography(.headlineBold)
                    ForEach(fixture.drafts.filter { ($0.published != nil ? "발행" : $0.status) == filter }) { draft in
                        Button {
                            editing = draft
                        } label: {
                            VStack(alignment: .leading) {
                                Text(draft.article.question)
                                Text(draft.status).umcTypography(.captionRegular)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }.padding(20)
            }.frame(width: 330)
            if let draft = editing {
                SupportFAQEditor(draft: draft, close: { editing = nil }) { result in
                    if let index = fixture.drafts.firstIndex(where: { $0.id == result.id }) {
                        fixture.drafts[index] = result
                    } else {
                        fixture.drafts.append(result)
                    }
                    editing = nil
                }.id(draft.id)
            } else {
                ContentUnavailableView("편집할 FAQ를 선택하세요", systemImage: "list.bullet")
            }
        }

    }
}

private struct SupportFAQEditor: View {
    @State var draft: SupportDraft
    let close: () -> Void
    let save: (SupportDraft) -> Void
    @State private var verified = false

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            Text("FAQ 편집").umcTypography(.title2Bold).accessibilityAddTraits(.isHeader)
            Form {
                TextField("공개용 질문", text: $draft.article.question)
                TextField("공개용 답변", text: $draft.article.answer, axis: .vertical)
                    .lineLimit(3...6)
                Toggle("예시 답변 검증 완료", isOn: $verified)
                    .toggleStyle(UMCCheckboxStyle())
            }
            HStack {
                Button("취소") { close() }.keyboardShortcut(.cancelAction)
                if draft.published != nil {
                    Button("보관") {
                        draft.archive()
                        save(draft)
                    }
                }
                Spacer()
                Button("초안 저장") {
                    draft.archived = false
                    save(draft)
                }
                .disabled(!draft.isValid)
                Button("검증 후 발행") {
                    draft.publish()
                    save(draft)
                }
                .disabled(!verified || !draft.isValid)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(UMCSpacing.value24)
        .frame(maxWidth: .infinity)
        .onChange(of: draft.article) { verified = false }
    }
}
