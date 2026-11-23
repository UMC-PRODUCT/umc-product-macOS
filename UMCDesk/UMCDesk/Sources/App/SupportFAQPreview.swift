//
//  SupportFAQPreview.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/23/26.
//

#if DEBUG
import CoreDesignSystem
import CoreUIComponents
import SwiftUI

struct SupportFAQPreview: View {
    @Bindable var fixture: SupportFixture
    let back: () -> Void
    @State private var editing: SupportDraft?

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
        Table(fixture.drafts) {
            TableColumn("대표 질문") { draft in
                Button(draft.article.question) { editing = draft }.buttonStyle(.link)
            }
            TableColumn("상태") { Text($0.status) }
        }
        .sheet(item: $editing) { draft in
            SupportFAQEditor(draft: draft) { result in
                if let index = fixture.drafts.firstIndex(where: { $0.id == result.id }) {
                    fixture.drafts[index] = result
                } else {
                    fixture.drafts.append(result)
                }
                editing = nil
            }
        }
    }
}

private struct SupportFAQEditor: View {
    @Environment(\.dismiss) private var dismiss
    @State var draft: SupportDraft
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
                Button("취소") { dismiss() }.keyboardShortcut(.cancelAction)
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
        .frame(width: 500)
        .onChange(of: draft.article) { verified = false }
    }
}
#endif
