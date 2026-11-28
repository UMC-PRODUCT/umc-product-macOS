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
    let fixture: SupportFixture
    @Environment(\.umcBodyTextScale) private var scale
    @State private var expanded = false
    @State private var command = SupportCommand()
    @State private var inputRequest = 0
    @FocusState private var operatorFocus: String?
    var scene = SupportScene.home
    @State private var editingAssignee = false
    let isOperator: Bool
    var articles: [SupportArticle] = []
    let back: () -> Void
    @State private var editingLabel = false
    @State private var initialLabels: [String] = []
    @State private var pendingLabels: [String] = []
    @State private var replyDraft = SupportPreviewTransport.ReplyDraft()

    private var scope: String { ticket.id.uuidString }
    private var replyKey: SupportPreviewTransport.Key {
        .init(scope: scope, action: "답변 보내기", isOperator: isOperator)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
            if hasOpenMenu { header }
            if isOperator {
                ViewThatFits(in: .horizontal) {
                    SupportWidePanels(split: SupportPanelLayout(scale: scale)) {
                        conversation(compact: false)
                        processingPanel
                    }.frame(minWidth: 900 * scale + 24)
                    if hasOpenMenu { processingPanel } else { conversation(compact: true) }
                }
            } else {
                conversation(compact: false)
            }
        }.onExitCommand { closeInnermost() }
            .onChange(of: editingAssignee) {
                if !editingAssignee && !editingLabel { operatorFocus = "담당자" }
            }
            .onChange(of: editingLabel) {
                if !editingLabel && !editingAssignee { operatorFocus = "라벨" }
            }
            .onChange(of: ticket.status) {
                if ticket.status == .closed {
                    editingAssignee = false
                    editingLabel = false
                }
            }
            .onChange(of: replyDraft.request.flatMap { fixture.transport.receipts[$0] }) {
                if let request = replyDraft.request,
                    replyDraft.acknowledge(request, receipt: fixture.transport.receipts[request])
                {
                    inputRequest += 1
                }
            }
            .onAppear {
                if let request = fixture.transport.requests[replyKey],
                    let input = fixture.transport.pendingReplies[replyKey],
                    fixture.transport.receipts[request]?.acknowledged == false
                {
                    replyDraft = .init(input: input, request: request)
                }
                expanded = [.assignee, .labels, .labelsChanged].contains(scene)
                inputRequest = ticket.status == .closed ? 0 : 1
                editingAssignee = scene == .assignee
                if [.labels, .labelsChanged].contains(scene) {
                    initialLabels = ticket.labels
                    pendingLabels = scene == .labelsChanged ? ["기능 요청"] : ticket.labels
                    editingLabel = true
                }
            }
    }

    @ViewBuilder private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(isOperator ? (ticket.operatorTitle ?? ticket.subject) : ticket.subject)
                    .fixedSize(horizontal: false, vertical: true).inquiryFont(28, weight: .bold)
                    .accessibilityAddTraits(.isHeader)
                Text(
                    isOperator
                        ? "김유엠 · UMC 서비스 · "
                            + timestamp(ticket.createdAt)
                            + " 접수" : ticket.category + " · UMC 서비스"
                ).inquiryFont(14)
            }
            Spacer()
            Button(isOperator ? "문의 관리로" : "내 문의로", action: back)
                .onExitCommand { closeInnermost() }
        }
        HStack {
            Text(ticket.status.rawValue)
                .padding(.horizontal, UMCSpacing.value16).padding(.vertical, UMCSpacing.value4)
                .background(UMCColor.Semantic.surfaceBrandWeak, in: .capsule)
            Text("받는 팀 · " + ticket.visibleTeam)
            if isOperator && ticket.status != .closed {
                Spacer()
                Button("문의 종료") {
                    change("상태 변경", payload: ["종료"]) { $0.changeStatus(.closed, by: .agent) }
                }
            }
        }
        SupportCommandStatus(
            command: command, transport: fixture.transport, scope: scope, isOperator: isOperator)
    }

    private func conversation(compact: Bool) -> some View {
        SupportReadingArea {
            VStack(alignment: .leading, spacing: 20) {
                if !hasOpenMenu { header }
                if compact && isOperator {
                    DisclosureGroup("처리 정보", isExpanded: $expanded) { operations }
                }
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
                        Label("문의가 접수됐어요. 이 대화에서 답변을 확인할 수 있어요.", systemImage: "clock")
                            .inquiryFont(13).foregroundStyle(
                                UMCColor.Semantic.textNeutralMedium600)
                    }
                    if let reference = ticket.reference {
                        Divider()
                        Text("참고한 답변 · " + reference.question).inquiryFont(14)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

            }.frame(maxWidth: .infinity, alignment: .leading)
        } actions: {
            if isOperator && ticket.status == .closed {
                Label("종료된 문의예요. 이전 대화를 읽을 수 있어요.", systemImage: "lock")
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    SupportInputField(
                        isOperator ? "문의자에게 답변" : "UMC PRODUCT 담당자에게 메시지 보내기",
                        identifier: "support.reply", text: $replyDraft.input.text, focusRequest: inputRequest,
                        submit: send, escape: closeInnermost
                    )
                    .frame(minHeight: 28 * scale).padding(12)
                    .background(
                        UMCColor.Custom.backgroundSurfaceWhite, in: .rect(cornerRadius: 12))
                    HStack {
                        Button {
                            replyDraft.input.attachment.toggle()
                        } label: {
                            Label(
                                replyDraft.input.attachment ? "오류 화면.png 제거" : "예시 파일 첨부", systemImage: "paperclip")
                        }
                        Spacer()
                        Button("보내기", action: send).accessibilityIdentifier("support.send")
                            .disabled(
                                replyDraft.input.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                    || fixture.transport.blocked(replyKey))
                    }
                    if ticket.status == .closed {
                        Label("메시지를 보내면 문의가 다시 열려요", systemImage: "lock.open").inquiryFont(13)
                    }
                }
            }
        }.padding(16).background(
            UMCColor.Custom.backgroundSurfaceGreyWeak, in: .rect(cornerRadius: 16))
    }

    private func closeInnermost() {
        if editingAssignee {
            editingAssignee = false
            operatorFocus = "담당자"
        } else if editingLabel {
            editingLabel = false
            operatorFocus = "라벨"
        } else {
            back()
        }
    }

    private func change(
        _ name: String, payload: [String], apply: @escaping (inout SupportTicket) -> Void
    ) {
        let id = ticket.id
        command.run(
            name, scope: scope, transport: fixture.transport, isOperator: true, payload: payload
        ) { _ in
            fixture.modifyOpenTicket(id, change: apply)
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
                    .accessibilityHidden(true)
            }
            VStack(alignment: own ? .trailing : .leading, spacing: UMCSpacing.value4) {
                Text("\(own ? "나" : (isOperator ? "김유엠" : "이지원 · UMC PRODUCT 담당자")) · \(time)")
                    .inquiryFont(13)
                    .foregroundStyle(.secondary)
                SupportSelectableText(text).inquiryFont(14)
                    .padding(14)
                    .background(surface, in: .rect(cornerRadius: UMCRadius.value12))
            }
            .frame(maxWidth: 660 * scale, alignment: own ? .trailing : .leading)
        }
        .padding(own ? .leading : .trailing, own ? 44 : 0)
        .frame(maxWidth: .infinity, alignment: own ? .trailing : .leading)
        .accessibilityElement(children: .contain)
    }

    private var hasOpenMenu: Bool { editingAssignee || editingLabel }

    @ViewBuilder private var processingPanel: some View {
        if hasOpenMenu {
            SupportFieldMenuPlacement {
                VStack(alignment: .leading, spacing: 12) {
                    processingHeading
                    if editingLabel {
                        assigneeField
                        processingLabels
                    }
                }.accessibilityHidden(true).allowsHitTesting(false)
                if editingLabel { labelField } else { assigneeField }
                VStack(alignment: .leading, spacing: 12) {
                    if !editingLabel {
                        processingLabels
                        labelField
                    }
                    processingHistory
                }.accessibilityHidden(true).allowsHitTesting(false)
                ViewThatFits(in: .vertical) {
                    fieldMenu.fixedSize(horizontal: false, vertical: true)
                    ScrollView { fieldMenu }
                }.frame(maxWidth: 312)
            }.background(UMCColor.Custom.backgroundSurfaceWhite, in: .rect(cornerRadius: 16))
                .clipped()
                .task(id: editingLabel) {
                    await Task.yield()
                    operatorFocus =
                        "선택 " + (editingLabel ? pendingLabels.first ?? "출석 오류" : ticket.assignee)
                }
        } else {
            ScrollView { operations }
        }
    }

    @ViewBuilder private var processingHeading: some View {
        Text("처리 정보").inquiryFont(18, weight: .bold)
        Menu("담당 팀 · " + ticket.visibleTeam) {
            ForEach(SupportTeam.allCases, id: \.self) { team in
                Button(team.rawValue) {
                    change("담당 팀 변경", payload: [team.rawValue]) { $0.team = team }
                }
            }
        }
        Text("담당자").inquiryFont(13)
    }
    private var assigneeField: some View {
        Button {
            editingAssignee.toggle()
            editingLabel = false
        } label: {
            Text(ticket.assignee + " ▾").frame(maxWidth: .infinity, minHeight: 44)
        }
        .focused($operatorFocus, equals: "담당자")
    }
    @ViewBuilder private var processingLabels: some View {
        Button("내가 맡기") { change("담당자 변경", payload: ["이지원"]) { $0.assignee = "이지원" } }
        Text("라벨 · PRODUCT 내부용").inquiryFont(13)
        HStack {
            ForEach(ticket.labels, id: \.self) {
                Text($0).padding(6).background(
                    UMCColor.Semantic.surfaceBrandWeak, in: .rect(cornerRadius: 6))
            }
        }
    }
    private var labelField: some View {
        Button {
            editingAssignee = false
            initialLabels = ticket.labels
            pendingLabels = ticket.labels
            editingLabel = true
        } label: {
            Text("라벨 편집").frame(maxWidth: .infinity)
        }
        .focused($operatorFocus, equals: "라벨")
    }

    @ViewBuilder private var fieldMenu: some View {
        if editingAssignee {
            VStack(alignment: .leading, spacing: 8) {
                Text("담당자 선택")
                Text("문의 관리 권한이 있는 UMC PRODUCT 구성원").inquiryFont(13)
                ForEach(["이지원", "김지원", "미배정"], id: \.self) { name in
                    Button(name == "미배정" ? "배정 해제" : name) {
                        change("담당자 변경", payload: [name]) { $0.assignee = name }
                        editingAssignee = false
                    }.focused($operatorFocus, equals: "선택 " + name)
                }
                Button {
                    editingAssignee = false
                } label: {
                    Text("취소").frame(maxWidth: .infinity)
                }.buttonStyle(.plain).keyboardShortcut(.cancelAction)
            }.frame(maxWidth: 280, alignment: .topLeading).supportCard(
                padding: 16
            )
        } else {
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
                    }.focused($operatorFocus, equals: "선택 " + name).accessibilityAddTraits(
                        pendingLabels.contains(name) ? .isSelected : [])
                }
                Button("적용") {
                    let before = initialLabels
                    let after = pendingLabels
                    change("라벨 적용", payload: before + ["→"] + after) {
                        $0.applyLabels(original: before, selected: after)
                    }
                    editingLabel = false
                }
                Text("라벨은 UMC PRODUCT 내부에서만 보여요.").inquiryFont(13)
                Button {
                    editingLabel = false
                } label: {
                    Text("취소").frame(maxWidth: .infinity)
                }.buttonStyle(.plain).keyboardShortcut(.cancelAction)
            }.frame(maxWidth: 272, alignment: .topLeading).supportCard(
                padding: 20
            )
        }
    }
    private var operations: some View {
        VStack(alignment: .leading, spacing: 12) {
            processingHeading
            assigneeField
            processingLabels
            labelField
            processingHistory
            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading).supportCard().disabled(
            ticket.status == .closed)
    }

    @ViewBuilder private var processingHistory: some View {
        Text("대표 질문").inquiryFont(13)
        Text(articles.first { $0.id == ticket.linkedQuestion }?.question ?? "미분류").inquiryFont(
            14)
        Menu("대표 질문 연결") {
            Button("미분류") { change("대표 질문 연결", payload: []) { $0.linkedQuestion = nil } }
            ForEach(articles) { article in
                Button(article.question) {
                    change("대표 질문 연결", payload: [article.id]) { $0.linkedQuestion = article.id }
                }
            }
        }.fixedSize()
        Text("담당자 변경 이력").inquiryFont(13, weight: .medium)
        Text("14:20 문의 접수 · 담당자 미배정")
        ForEach(ticket.history) { event in
            Text(
                event.time.formatted(date: .omitted, time: .shortened)
                    + " · " + event.actor + " · " + event.message)
        }
    }

    private func send() {
        let id = ticket.id
        let input = replyDraft.input
        let text = input.text
        let file = input.attachment
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !fixture.transport.blocked(replyKey) else { return }
        let request = command.run(
            "답변 보내기", scope: scope, transport: fixture.transport, isOperator: isOperator,
            attachment: file, payload: [text, file ? "첨부" : ""], reply: input
        ) { includeFile in
            guard let index = fixture.tickets.firstIndex(where: { $0.id == id }) else {
                return false
            }
            return fixture.tickets[index].reply(
                text, from: isOperator ? .agent : .requester,
                attachment: file && includeFile ? "오류 화면.png" : nil)
        }
        if let request { replyDraft.request = request }
    }
}
