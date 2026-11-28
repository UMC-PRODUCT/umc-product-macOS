//
//  SupportTicketDetail.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/23/26.
//

import CoreDesignSystem
import SwiftUI

struct SupportTicketDetail: View {
    @Environment(\.colorScheme) private var colorScheme
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
    @State private var attachment = false
    @FocusState private var inputFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isOperator ? (ticket.operatorTitle ?? ticket.subject) : ticket.subject)
                        .inquiryFont(28, weight: .bold).accessibilityAddTraits(.isHeader)
                    Text(
                        isOperator
                            ? "김유엠 · UMC 서비스 · "
                                + timestamp(ticket.createdAt)
                                + " 접수" : ticket.category + " · UMC 서비스"
                    ).inquiryFont(14)
                }
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
                        ticket.changeStatus(
                            ticket.status == .closed ? .active : .closed, by: .agent)
                    }
                }
            }
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                    ScrollViewReader { scroll in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 20) {
                                bubble(ticket.content, author: .requester, date: ticket.createdAt)
                                if let file = ticket.attachmentName {
                                    Label(file, systemImage: "paperclip")
                                }
                                ForEach(ticket.replies) { reply in
                                    bubble(
                                        reply.text
                                            + (reply.attachment.map { "\n첨부 · " + $0 } ?? ""),
                                        author: reply.author, date: reply.sentAt
                                    )
                                    .id(reply.id)
                                }
                                if !isOperator && ticket.status == .received
                                    && !ticket.replies.contains(where: { $0.author == .agent })
                                {
                                    Text("문의가 접수됐어요. 이 대화에서 답변을 확인할 수 있어요.")
                                        .inquiryFont(13).foregroundStyle(
                                            UMCColor.Semantic.textNeutralMedium600)
                                }
                                if let reference = ticket.reference {
                                    Divider()
                                    Text("참고한 답변 · " + reference.question).inquiryFont(14)
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
                        VStack(alignment: .leading, spacing: 10) {
                            TextField(
                                isOperator ? "문의자에게 답변" : "UMC PRODUCT 담당자에게 메시지 보내기",
                                text: $message
                            )
                            .textFieldStyle(.plain)
                            .accessibilityIdentifier("support.reply")
                            .focused($inputFocused)
                            .onSubmit { send() }
                            .onExitCommand(perform: back)
                            HStack {
                                Button {
                                    attachment.toggle()
                                } label: {
                                    Label(
                                        attachment ? "오류 화면.png 제거" : "예시 파일 첨부",
                                        systemImage: attachment ? "paperclip" : "plus"
                                    )
                                    .labelStyle(.iconOnly)
                                }
                                if attachment { Text("오류 화면.png").inquiryFont(13) }
                                Spacer()
                                Button(action: send) {
                                    Label("보내기", systemImage: "arrow.up").labelStyle(.iconOnly)
                                }
                                .buttonBorderShape(.circle)
                                .accessibilityIdentifier("support.send")
                                .disabled(
                                    message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                )
                            }
                        }
                        .padding(16).frame(minHeight: 104)
                        .background(
                            UMCColor.Custom.backgroundSurface,
                            in: .rect(cornerRadius: UMCRadius.value12))
                        if ticket.status != .closed {
                            Text(
                                isOperator
                                    ? "첫 답변을 보내면 진행 중으로 바뀌어요. 종료 후 새 메시지로 다시 열 수 있어요."
                                    : "UMC PRODUCT 담당자에게 메시지를 보내세요."
                            ).inquiryFont(13)
                        } else {
                            Text("메시지를 보내면 문의가 다시 열려요")
                                .inquiryFont(13)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(24)
                .background(
                    colorScheme == .dark
                        ? UMCColor.Semantic.fillNeutralStrong200
                        : UMCColor.Custom.backgroundSurfaceGreyWeak,
                    in: .rect(cornerRadius: UMCRadius.value16))
                if isOperator { operations.frame(width: 360) }
            }
        }
        .onAppear {
            inputFocused = ticket.status != .closed
            editingAssignee = scene == .assignee
            if [.labels, .labelsChanged].contains(scene) {
                initialLabels = ticket.labels
                pendingLabels = scene == .labelsChanged ? ["기능 요청"] : ticket.labels
                editingLabel = true
            }
        }
    }

    private func timestamp(_ date: Date) -> String {
        let time = Calendar.current.dateComponents([.hour, .minute], from: date)
        return String(format: "%02d:%02d", time.hour ?? 0, time.minute ?? 0)
    }

    private func bubble(_ text: String, author: SupportTicket.Author, date: Date) -> some View {
        let own = isOperator ? author == .agent : author == .requester
        let time = timestamp(date)
        let surface =
            own
            ? UMCColor.Semantic.surfaceBrandMedium : UMCColor.Custom.backgroundSurface
        return HStack(alignment: .top, spacing: 12) {
            if !own {
                Text(isOperator ? "유" : "운").frame(width: 32, height: 32)
                    .background(UMCColor.Semantic.surfaceBrandWeak, in: .circle)
            }
            VStack(alignment: own ? .trailing : .leading, spacing: UMCSpacing.value4) {
                Text("\(own ? "나" : (isOperator ? "김유엠" : "이지원 · UMC PRODUCT 담당자")) · \(time)")
                    .inquiryFont(13)
                    .foregroundStyle(.secondary)
                Text(text).inquiryFont(15).textSelection(.enabled)
                    .padding(14)
                    .background(surface, in: .rect(cornerRadius: UMCRadius.value12))
            }
            .frame(maxWidth: 660, alignment: own ? .trailing : .leading)
        }
        .frame(maxWidth: .infinity, alignment: own ? .trailing : .leading)
        .accessibilityElement(children: .combine)
    }

    private var operations: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("처리 정보").inquiryFont(18, weight: .bold)
            Text("담당자").inquiryFont(13)
            Button {
                editingAssignee.toggle()
                editingLabel = false
            } label: {
                Text(ticket.assignee + " ▾").frame(maxWidth: .infinity, minHeight: 44)
            }
            .overlay(alignment: .topTrailing) {
                if editingAssignee {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("담당자 선택")
                        Text("문의 관리 권한이 있는 UMC PRODUCT 구성원").inquiryFont(13)
                        ForEach(["이지원", "김지원", "미배정"], id: \.self) { name in
                            Button(name == "미배정" ? "배정 해제" : name) {
                                ticket.assignee = name
                                editingAssignee = false
                            }
                        }
                        Button {
                            editingAssignee = false
                        } label: {
                            Text("취소").frame(maxWidth: .infinity)
                        }.buttonStyle(.plain).keyboardShortcut(.cancelAction)
                    }.frame(width: 280, height: 261, alignment: .topLeading).supportCard(
                        padding: 16
                    )
                    .fixedSize(
                        horizontal: false, vertical: true
                    ).offset(y: 44)
                }
            }.zIndex(editingAssignee ? 2 : 0)
            Button("내가 맡기") { ticket.assignee = "이지원" }
            Text("라벨 · PRODUCT 내부용").inquiryFont(13)
            HStack {
                ForEach(ticket.labels, id: \.self) {
                    Text($0).padding(6).background(
                        UMCColor.Semantic.surfaceBrandWeak, in: .rect(cornerRadius: 6))
                }
            }
            Button("라벨 편집") {
                editingAssignee = false
                initialLabels = ticket.labels
                pendingLabels = ticket.labels
                editingLabel = true
            }
            .overlay(alignment: .topLeading) {
                if editingLabel {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("라벨 선택 · 복수 선택 가능").inquiryFont(14, weight: .bold)
                        ForEach(["출석 오류", "정보 확인", "기능 요청"], id: \.self) { name in
                            Button {
                                if pendingLabels.contains(name) {
                                    pendingLabels.removeAll { $0 == name }
                                } else {
                                    pendingLabels.append(name)
                                }
                            } label: {
                                HStack {
                                    Text(name)
                                    Spacer()
                                    if pendingLabels.contains(name) {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }.accessibilityAddTraits(
                                pendingLabels.contains(name) ? .isSelected : [])
                        }
                        Button("적용") {
                            ticket.applyLabels(original: initialLabels, selected: pendingLabels)
                            editingLabel = false
                        }
                        Text("라벨은 UMC PRODUCT 내부에서만 보여요.").inquiryFont(13)
                        Button {
                            editingLabel = false
                        } label: {
                            Text("취소").frame(maxWidth: .infinity)
                        }.buttonStyle(.plain).keyboardShortcut(.cancelAction)
                    }.frame(width: 272, height: 273, alignment: .topLeading).supportCard(
                        padding: 20
                    )
                    .fixedSize(
                        horizontal: false, vertical: true
                    ).offset(y: 44)
                }
            }.zIndex(editingLabel ? 2 : 0)
            Text("대표 질문").inquiryFont(13)
            Text(articles.first { $0.id == ticket.linkedQuestion }?.question ?? "미분류").inquiryFont(
                14)
            Menu("대표 질문 연결") {
                Button("미분류") { ticket.linkedQuestion = nil }
                ForEach(articles) { article in
                    Button(article.question) { ticket.linkedQuestion = article.id }
                }
            }.fixedSize()
            Text("담당자 변경 이력").inquiryFont(13, weight: .medium)
            Text("14:20 문의 접수 · 담당자 미배정")
            ForEach(ticket.history) { event in
                Text(
                    event.time.formatted(date: .omitted, time: .shortened)
                        + " · " + event.actor + " · " + event.message)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading).supportCard()
    }

    private func send() {
        guard
            ticket.reply(
                message, from: isOperator ? .agent : .requester,
                attachment: attachment ? "오류 화면.png" : nil)
        else { return }
        message = ""
        attachment = false
        inputFocused = true
    }
}
