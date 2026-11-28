//
//  SupportTicketDetail.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/23/26.
//

import CoreDesignSystem
import SwiftUI

struct SupportTicketDetail: View {
    @Binding var ticket: SupportTicket
    var scene = SupportScene.home
    @State private var editingAssignee = false
    let isOperator: Bool
    var articles: [SupportArticle] = []
    let back: () -> Void
    @State private var editingLabel = false
    @State private var initialLabels: [String] = []
    @State private var pendingLabels: [String] = []
    @State private var message = ""
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
            HStack {
                Text(ticket.subject).umcTypography(.title2Bold).accessibilityAddTraits(.isHeader)
                Spacer()
                Button(isOperator ? "문의 관리로" : "내 문의로", action: back)
                    .keyboardShortcut(.cancelAction)
            }
            HStack {
                Text(ticket.status.rawValue)
                    .padding(.horizontal, UMCSpacing.value16).padding(.vertical, UMCSpacing.value4)
                    .background(UMCColor.Semantic.surfaceBrandWeak, in: .capsule)
                Text("받는 팀 · " + ticket.team.rawValue)
                if isOperator {
                    Spacer()
                    Button(ticket.status == .closed ? "다시 진행" : "문의 종료") {
                        ticket.status = ticket.status == .closed ? .active : .closed
                    }
                }
            }
            HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                ScrollViewReader { scroll in
                    ScrollView {
                        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                            bubble(ticket.content, author: .requester, date: ticket.createdAt)
                            if ticket.status == .received && !ticket.replies.contains(where: { $0.author == .agent }) {
                                Text("문의가 접수됐어요. 이 대화에서 답변을 확인할 수 있어요.")
                                    .inquiryFont(13).foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
                            }
                            if let file = ticket.attachmentName { Label(file, systemImage: "paperclip") }
                            if let reference = ticket.reference { Text("참고한 답변 · " + reference.question) }
                            ForEach(ticket.replies) { reply in
                                bubble(reply.text, author: reply.author, date: reply.sentAt)
                                    .id(reply.id)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .onChange(of: ticket.replies.last?.id, initial: true) { _, id in
                        if let id { scroll.scrollTo(id, anchor: .bottom) }
                    }
                }
                if isOperator && ticket.status == .closed {
                    Label("종료된 문의예요. 이전 대화를 읽을 수 있어요.", systemImage: "lock")
                        .foregroundStyle(.secondary)
                } else {
                    HStack {
                        TextField(isOperator ? "문의자에게 답변" : "담당자에게 메시지 보내기", text: $message)
                            .textFieldStyle(.plain)
                            .accessibilityIdentifier("support.reply")
                            .focused($inputFocused)
                            .onSubmit { send() }
                            .onExitCommand(perform: back)
                        Button(action: send) {
                            Label("보내기", systemImage: "arrow.up").labelStyle(.iconOnly)
                        }
                        .buttonBorderShape(.circle)
                        .accessibilityIdentifier("support.send")
                        .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    .padding(16).frame(minHeight: 104)
                    .background(UMCColor.Custom.backgroundSurface,
                                in: .rect(cornerRadius: UMCRadius.value12))
                    if ticket.status == .closed {
                        Text("메시지를 보내면 문의가 다시 열려요")
                            .umcTypography(.footnoteRegular)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(UMCSpacing.value16)
            .background(UMCColor.Custom.backgroundSurfaceGreyWeak,
                        in: .rect(cornerRadius: UMCRadius.value16))
            if isOperator { operations.frame(width: 360) }
            }
        }
        .onAppear {
            inputFocused = ticket.status != .closed
            editingAssignee = scene == .assignee
            if scene == .labels { initialLabels = ticket.labels; pendingLabels = ticket.labels; editingLabel = true }
        }
    }

    private func bubble(_ text: String, author: SupportTicket.Author, date: Date) -> some View {
        let own = isOperator ? author == .agent : author == .requester
        let time = date.formatted(date: .omitted, time: .shortened)
        let surface = own
            ? UMCColor.Semantic.surfaceBrandMedium : UMCColor.Custom.backgroundSurface
        return HStack(alignment: .top, spacing: 12) {
            if !own {
                Text(isOperator ? "유" : "운").frame(width: 32, height: 32)
                    .background(UMCColor.Semantic.surfaceBrandWeak, in: .circle)
            }
            VStack(alignment: own ? .trailing : .leading, spacing: UMCSpacing.value4) {
            Text("\(own ? "나" : author.rawValue) · \(time)")
                .umcTypography(.footnoteRegular)
                .foregroundStyle(.secondary)
            Text(text).inquiryFont(14).textSelection(.enabled)
                .padding(14)
                .background(surface, in: .rect(cornerRadius: UMCRadius.value12))
        }
        .frame(maxWidth: 660, alignment: own ? .trailing : .leading)
        }
        .frame(maxWidth: .infinity, alignment: own ? .trailing : .leading)
        .accessibilityElement(children: .combine)
    }

    private var operations: some View {
        GroupBox("처리 정보") {
            VStack(alignment: .leading, spacing: 12) {
                Picker("받는 팀", selection: $ticket.team) {
                    ForEach(SupportTeam.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                Button(ticket.assignee + " ▾") { editingAssignee.toggle(); editingLabel = false }
                    .overlay(alignment: .topTrailing) {
                        if editingAssignee {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("담당자 선택")
                                ForEach(["이지원", "예시 담당자", "미배정"], id: \.self) { name in
                                    Button(name) { ticket.assignee = name; editingAssignee = false }
                                }
                            }.frame(width: 180).supportCard(padding: 16).offset(y: 36)
                        }
                    }.zIndex(editingAssignee ? 2 : 0)
                Button("내가 맡기") { ticket.assignee = "예시 담당자" }
                Button("라벨 · " + ticket.label) {
                    initialLabels = ticket.labels
                    pendingLabels = ticket.labels
                    editingLabel = true
                }
                .overlay(alignment: .topTrailing) {
                    if editingLabel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("라벨 편집").umcTypography(.headlineBold)
                        ForEach(["출석 오류", "정보 확인", "기능 요청", "로그인"], id: \.self) { name in
                            Button {
                                if pendingLabels.contains(name) { pendingLabels.removeAll { $0 == name } }
                                else { pendingLabels.append(name) }
                            } label: {
                                Label(name, systemImage: pendingLabels.contains(name)
                                      ? "checkmark.square.fill" : "square")
                            }.accessibilityAddTraits(pendingLabels.contains(name) ? .isSelected : [])
                        }
                        HStack {
                            Button("취소") { editingLabel = false }.keyboardShortcut(.cancelAction)
                            Button("적용") { ticket.applyLabels(original: initialLabels, selected: pendingLabels); editingLabel = false }
                        }
                    }.frame(width: 220).supportCard(padding: 20).offset(y: 36)
                    }
                }.zIndex(editingLabel ? 2 : 0)
                Picker("대표 질문 연결", selection: $ticket.linkedQuestion) {
                    Text("미분류").tag(String?.none)
                    ForEach(articles) { Text($0.question).tag(Optional($0.id)) }
                }
                Text("처리 이력").umcTypography(.headlineBold)
                Text("문의 접수 · 담당자 미배정")
                ForEach(ticket.history) { event in
                    Text(event.time.formatted(date: .omitted, time: .shortened)
                         + " · " + event.actor + " · " + event.message)
                }
            }
            .padding(UMCSpacing.value12)
        }
    }

    private func send() {
        guard ticket.reply(message, from: isOperator ? .agent : .requester) else { return }
        message = ""
        inputFocused = true
    }
}
