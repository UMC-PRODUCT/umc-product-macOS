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
    @State private var feedback = ""
    @State private var editing: SupportDraft?

    init(
        fixture: SupportFixture, initialDraft: SupportDraft? = nil, scene: SupportScene = .home,
        back: @escaping () -> Void
    ) {
        self.fixture = fixture
        self.back = back
        let selected =
            initialDraft
            ?? fixture.drafts.first { draft in
                switch scene {
                case .faqDraft: draft.status == "초안"
                case .faqArchived: draft.archived
                case .faqEditing: draft.status == "수정 중"
                default: draft.published != nil
                }
            }
        _filter = State(initialValue: selected?.published != nil ? "발행" : selected?.status ?? "초안")
        _editing = State(initialValue: selected)
    }

    var body: some View {
        HStack {
            Button("문의 관리로", action: back).keyboardShortcut(.cancelAction)
            Spacer()
            Button("FAQ 작성") {
                filter = "초안"
                editing = SupportDraft(
                    article: SupportArticle(
                        id: UUID().uuidString, question: "", answer: ""
                    ))
            }
        }
        Text("FAQ 관리").inquiryFont(28, weight: .bold).accessibilityAddTraits(.isHeader)
        Text("문의에서 반복되는 질문을 공개용 답변으로 정리하고 검증하세요.")
        if !feedback.isEmpty { Text(feedback) }
        Picker(
            "공개 상태",
            selection: Binding(
                get: { filter },
                set: {
                    filter = $0
                    editing = nil
                })
        ) {
            ForEach(["초안", "발행", "보관"], id: \.self) { Text($0).tag($0) }
        }.pickerStyle(.segmented).fixedSize()
        HStack(alignment: .top, spacing: 24) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("대표 질문").inquiryFont(18, weight: .bold)
                    ForEach(
                        fixture.drafts.filter {
                            ($0.published != nil ? "발행" : $0.status) == filter
                        }
                    ) { draft in
                        Button {
                            editing = draft
                        } label: {
                            VStack(alignment: .leading) {
                                Text(draft.article.question)
                                Text(draft.status).inquiryFont(13)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }.padding(20)
            }.supportCard(padding: 0).frame(width: 330)
            if let draft = editing {
                SupportFAQEditor(
                    draft: draft, current: fixture.drafts.first { $0.id == draft.id },
                    close: { editing = nil }
                ) { result, action in
                    let latest = fixture.apply(action, draft: result)
                    filter = latest.published != nil ? "발행" : latest.status
                    editing = latest
                    switch action {
                    case .save:
                        feedback = latest.published == nil ? "초안을 저장했어요." : "수정 중 · 기존 발행본 공개"
                    case .publish: feedback = "검증한 답변을 발행했어요."
                    case .archive: feedback = "답변을 보관했어요."
                    }
                }.id(draft.id)
            } else {
                ContentUnavailableView("편집할 FAQ를 선택하세요", systemImage: "list.bullet")
            }
        }

    }
}

private struct SupportFAQEditor: View {
    @State var draft: SupportDraft
    let current: SupportDraft?
    let close: () -> Void
    let save: (SupportDraft, SupportFixture.FAQAction) -> Void
    @State private var verified = false

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            Text("FAQ 편집").inquiryFont(20, weight: .bold).accessibilityAddTraits(.isHeader)
            if current?.published != nil {
                Text("기존 발행본 공개")
            } else if current?.archived == true {
                Text("보관 · 비공개")
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("공개용 질문")
                TextField("공개용 질문", text: $draft.article.question)
                    .textFieldStyle(.plain).inquiryFont(18).padding(16)
                    .background(
                        UMCColor.Custom.backgroundSurfaceGreyWeak, in: .rect(cornerRadius: 10))
                if draft.article.id == "attendance" { Text("별칭 · 출석 오류, 출석 정정, 결석 표시") }
                Text("공개용 답변")
                TextEditor(text: $draft.article.answer)
                    .accessibilityLabel("공개용 답변").scrollContentBackground(.hidden)
                    .inquiryFont(16).padding(16).frame(minHeight: 124, maxHeight: 184)
                    .background(
                        UMCColor.Custom.backgroundSurfaceGreyWeak, in: .rect(cornerRadius: 10))
                Text("UMC 서비스 사용자 · " + draft.article.category)
                Text("종료일 · 지정 안 함    검증 조직 · UMC PRODUCT")
                Toggle("예시 답변 검증 완료", isOn: $verified)
                    .toggleStyle(UMCCheckboxStyle())
            }
            Spacer()
            HStack {
                Button("취소") { close() }.keyboardShortcut(.cancelAction)
                if current?.published != nil {
                    Button("보관") {
                        save(draft, .archive)
                    }
                }
                Spacer()
                Button("초안 저장") {
                    save(draft, .save)
                }
                .disabled(!draft.isValid)
                Button("검증 후 발행") {
                    save(draft, .publish)
                }
                .disabled(!verified || !draft.isValid)
                .keyboardShortcut(.defaultAction)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).supportCard()
        .onChange(of: draft.article) { verified = false }
    }
}
