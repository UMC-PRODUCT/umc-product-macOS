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
    let onDirty: (Bool) -> Void
    @State private var filter = "발행"
    @Environment(\.umcBodyTextScale) private var scale
    @State private var command = SupportCommand()
    @State private var showEditor = false
    @State private var verified = false
    @State private var pending: (() -> Void)?
    @State private var feedback = ""
    @State private var editing: SupportDraft?

    init(
        fixture: SupportFixture, initialDraft: SupportDraft? = nil, scene: SupportScene = .home,
        onDirty: @escaping (Bool) -> Void = { _ in }, back: @escaping () -> Void
    ) {
        self.onDirty = onDirty
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
        _editing = State(initialValue: selected.flatMap { Self.savedInput(for: $0, in: fixture) })
        _verified = State(
            initialValue: selected?.published != nil && selected?.published == selected?.article)
        _showEditor = State(
            initialValue: initialDraft != nil
                || [.faqDraft, .faqEditing, .faqArchived].contains(scene))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("FAQ 관리").inquiryFont(28, weight: .bold).accessibilityAddTraits(.isHeader)
                Button("문의 관리로") { leave { back() } }
                if !feedback.isEmpty { Text(feedback) }
                SupportCommandStatus(
                    command: command, transport: fixture.transport, scope: editing?.id ?? "",
                    isOperator: true)
                SupportActionRow {
                    ForEach(["초안", "발행", "보관"], id: \.self) { name in
                        Button((name == filter ? "✓ " : "") + name) {
                            leave {
                                filter = name
                                select(records.first, open: false)
                            }
                        }.accessibilityAddTraits(name == filter ? .isSelected : [])
                    }
                    if filter == "초안" {
                        Button("FAQ 작성") {
                            leave {
                                select(
                                    SupportDraft(
                                        article: SupportArticle(
                                            id: UUID().uuidString, question: "", answer: "",
                                            category: "기타")), open: true)
                            }
                        }
                    }
                }
                ViewThatFits(in: .horizontal) {
                    SupportPanelLayout(
                        scale: scale, firstMinimum: 252, secondMinimum: 520, fraction: 330 / 1258
                    ) {
                        list
                        editor
                    }.frame(minWidth: 772 * scale + 24)
                    VStack(alignment: .leading, spacing: 12) {
                        if showEditor && editing != nil {
                            Button("대표 질문 목록으로") {
                                leave {
                                    select(
                                        editing.flatMap { draft in
                                            fixture.drafts.first { $0.id == draft.id }
                                        }, open: false)
                                }
                            }
                            editor
                        } else {
                            list
                        }
                    }
                }
            }
        }.onChange(of: hasEdits, initial: true) { onDirty(hasEdits) }.onDisappear {
            onDirty(false)
        }
        .alert(
            "FAQ 편집을 취소할까요?",
            isPresented: Binding(get: { pending != nil }, set: { if !$0 { pending = nil } })
        ) {
            Button("계속 편집", role: .cancel) { pending = nil }
            Button("편집 취소", role: .destructive) {
                let action = pending
                pending = nil
                action?()
            }
        }
    }

    private static func savedInput(for draft: SupportDraft, in fixture: SupportFixture)
        -> SupportDraft
    {
        fixture.transport.pendingFAQs.first { key, _ in
            key.scope == draft.id && fixture.transport.state(key)?.acknowledged == false
        }?.value ?? draft
    }

    private var records: [SupportDraft] {
        var records = fixture.drafts.filter { ($0.published != nil ? "발행" : $0.status) == filter }
        if filter == "초안" {
            for draft in fixture.transport.pendingFAQs.values
            where !fixture.drafts.contains(where: { $0.id == draft.id })
                && !records.contains(where: { $0.id == draft.id })
            {
                records.append(draft)
            }
        }
        return records
    }

    private var list: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("대표 질문").inquiryFont(20, weight: .bold).accessibilityAddTraits(.isHeader)
            ForEach(records) { record in
                Button {
                    leave { select(record, open: true) }
                } label: {
                    VStack(alignment: .leading) {
                        Text(record.article.question).inquiryFont(16, weight: .medium)
                        Text(record.status).inquiryFont(13)
                    }.fixedSize(horizontal: false, vertical: true).padding(12).frame(
                        maxWidth: .infinity, alignment: .leading
                    )
                    .background(
                        record.id == editing?.id
                            ? UMCColor.Semantic.surfaceBrandWeak : Color.clear,
                        in: .rect(cornerRadius: 8))
                }.buttonStyle(.plain).accessibilityAddTraits(
                    record.id == editing?.id ? .isSelected : [])
            }
        }.frame(maxWidth: .infinity, alignment: .leading).supportCard()
    }

    @ViewBuilder private var editor: some View {
        if let binding = Binding($editing) {
            let current = fixture.drafts.first { $0.id == binding.wrappedValue.id }
            SupportFAQEditor(
                draft: binding, current: current, verified: $verified,
                cancel: {
                    leave { select(current, open: false) }
                }
            ) { draft, action in
                let name =
                    switch action {
                    case .save: "초안 저장"
                    case .publish: "FAQ 발행"
                    case .archive: "FAQ 보관"
                    }
                let transport = fixture.transport
                let key = SupportPreviewTransport.Key(
                    scope: draft.id, action: name, isOperator: true)
                guard !transport.blocked(key) else { return }
                transport.pendingFAQs[key] = draft
                command.run(name, scope: draft.id, transport: transport, isOperator: true) { _ in
                    guard action == .archive || draft.isValid else { return false }
                    _ = fixture.apply(action, draft: draft)
                    return true
                } success: { _ in
                    transport.pendingFAQs[key] = nil
                    guard editing?.id == draft.id,
                        let latest = fixture.drafts.first(where: { $0.id == draft.id })
                    else { return }
                    filter = latest.published != nil ? "발행" : latest.status
                    if editing?.article == draft.article { select(latest, open: true) }
                    feedback = name + "을 완료했어요."
                }
            }.id(binding.wrappedValue.id)
        } else {
            Text("편집할 FAQ를 선택하세요.").frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func select(_ draft: SupportDraft?, open: Bool) {
        editing = draft.map { Self.savedInput(for: $0, in: fixture) }
        showEditor = open
        verified = draft?.published != nil && draft?.published == draft?.article
    }

    private var hasEdits: Bool {
        guard let editing else { return false }
        if let current = fixture.drafts.first(where: { $0.id == editing.id }) {
            return current.article != editing.article
        }
        return !editing.article.question.isEmpty || !editing.article.answer.isEmpty
    }

    private func leave(_ action: @escaping () -> Void) {
        guard !command.isSending else { return }
        if hasEdits {
            pending = action
            return
        }
        action()
    }
}

private struct SupportFAQEditor: View {
    @Binding var draft: SupportDraft
    let current: SupportDraft?
    @Binding var verified: Bool
    let cancel: () -> Void
    let save: (SupportDraft, SupportFixture.FAQAction) -> Void
    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            if current?.published != nil {
                Text("수정 중 · 기존 발행본 공개").inquiryFont(13, weight: .medium).padding(8).background(
                    UMCColor.Semantic.surfaceBrandWeak, in: .rect(cornerRadius: 8))
            } else if current?.archived == true {
                Text("보관 · 비공개")
            }
            VStack(alignment: .leading, spacing: 12) {
                Text("공개용 질문").inquiryFont(13)
                TextField("공개용 질문", text: $draft.article.question, axis: .vertical)
                    .textFieldStyle(.plain)
                    .inquiryFont(16, weight: .medium)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(minHeight: 27, alignment: .leading).padding(16)
                    .background(
                        UMCColor.Custom.backgroundSurfaceGreyWeak, in: .rect(cornerRadius: 10))
                if draft.article.id == "attendance" { Text("별칭 · 출석 오류, 출석 정정, 결석 표시") }
                Text("공개용 답변").inquiryFont(13)
                TextEditor(text: $draft.article.answer)
                    .accessibilityLabel("공개용 답변").scrollContentBackground(.hidden)
                    .inquiryFont(16).padding(16).frame(minHeight: 124, maxHeight: 184)
                    .background(
                        UMCColor.Custom.backgroundSurfaceGreyWeak, in: .rect(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 12) {
                    Picker("적용 대상", selection: $draft.article.audience) {
                        ForEach(["UMC 서비스 사용자", "UMC 운영진"], id: \.self) { Text($0) }
                    }
                    Picker("카테고리", selection: $draft.article.category) {
                        ForEach(["기타", "출석·과제", "계정·로그인", "알림", "활동 증명", "프로젝트·매칭"], id: \.self) {
                            Text($0)
                        }
                    }
                }

                Text("종료일 · 지정 안 함    검증 조직 · UMC PRODUCT")
                Toggle("검증 확인 · 개인정보 없음 / 적용 범위 확인 / 답변 정확성 확인", isOn: $verified)
                    .toggleStyle(UMCCheckboxStyle())
                Text(
                    current?.published != nil
                        ? "검증 전까지 기존 발행본이 공개돼요."
                        : (current?.archived == true
                            ? "보관한 답변은 공개·추천·순위에서 제외돼요." : "초안은 검증 후 발행하기 전까지 공개되지 않아요.")
                ).inquiryFont(13)
            }
            Spacer()
            SupportActionRow {
                Button("편집 취소", action: cancel)
                Button("초안 저장") {
                    save(draft, .save)
                }
                .disabled(!draft.isValid)
                Button("검증 후 발행") {
                    save(draft, .publish)
                }
                .buttonStyle(SupportActionStyle(prominent: true))
                .disabled(!verified || !draft.isValid)
                .keyboardShortcut(.defaultAction)
                if current?.published != nil {
                    Button("보관") { save(draft, .archive) }.accessibilityLabel("선택한 FAQ 보관")
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading).supportCard()

        .onChange(of: draft.article) { verified = false }
    }
}
