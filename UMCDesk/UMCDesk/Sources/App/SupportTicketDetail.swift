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
    let isOperator: Bool
    let back: () -> Void
    @State private var editingLabel = false
    @State private var pendingLabel = ""
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
                            if ticket.status == .received && !ticket.replies.contains(where: { $0.author == .agent }) {
                                Label("답변 대기 · 담당자가 문의를 확인하고 있어요.", systemImage: "clock")
                            }
                            bubble(ticket.content, author: .requester, date: ticket.createdAt)
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
                    .padding(UMCSpacing.value16)
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
        .onAppear { inputFocused = ticket.status != .closed }
    }

    private func bubble(_ text: String, author: SupportTicket.Author, date: Date) -> some View {
        let own = isOperator ? author == .agent : author == .requester
        let time = date.formatted(date: .omitted, time: .shortened)
        let surface = own
            ? UMCColor.Semantic.surfaceBrandMedium : UMCColor.Custom.backgroundSurface
        return VStack(alignment: own ? .trailing : .leading, spacing: UMCSpacing.value4) {
            Text("\(own ? "나" : author.rawValue) · \(time)")
                .umcTypography(.footnoteRegular)
                .foregroundStyle(.secondary)
            Text(text).textSelection(.enabled)
                .padding(UMCSpacing.value12)
                .background(surface, in: .rect(cornerRadius: UMCRadius.value12))
        }
        .frame(maxWidth: 580, alignment: own ? .trailing : .leading)
        .frame(maxWidth: .infinity, alignment: own ? .trailing : .leading)
        .accessibilityElement(children: .combine)
    }

    private var operations: some View {
        GroupBox("운영 정보") {
            Form {
                Picker("받는 팀", selection: $ticket.team) {
                    ForEach(SupportTeam.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                Picker("담당자", selection: $ticket.assignee) {
                    Text("미배정").tag("미배정")
                    Text("예시 담당자").tag("예시 담당자")
                }
                Button("라벨 · " + ticket.label) {
                    pendingLabel = ticket.label
                    editingLabel = true
                }
                .popover(isPresented: $editingLabel) {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("라벨 편집", selection: $pendingLabel) {
                            ForEach(["미분류", "화면 오류", "출석 오류", "정보 확인", "기능 요청", "이용 방법"],
                                    id: \.self) { Text($0).tag($0) }
                        }.pickerStyle(.radioGroup)
                        HStack {
                            Button("취소") { editingLabel = false }.keyboardShortcut(.cancelAction)
                            Button("적용") { ticket.label = pendingLabel; editingLabel = false }
                        }
                    }.padding(20)
                }
            }
            .padding(UMCSpacing.value12)
        }
    }

    private func send() {
        ticket.reply(message, from: isOperator ? .agent : .requester)
        message = ""
        inputFocused = true
    }
}
