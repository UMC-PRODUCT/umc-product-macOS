//
//  SupportInquiryPreview.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/23/26.
//

#if DEBUG
import CoreDesignSystem
import SwiftUI

struct SupportInquiryPreview: View {
    @Bindable var fixture: SupportFixture
    @State private var selectedID: UUID?
    @State private var composing = false
    @State private var managingFAQ = false

    private var selectedTicket: Binding<SupportTicket>? {
        $fixture.tickets.first { $0.wrappedValue.id == selectedID }
    }

    var body: some View {
        if managingFAQ {
            SupportFAQPreview(fixture: fixture) { managingFAQ = false }
        } else if let ticket = selectedTicket {
            SupportTicketDetail(ticket: ticket) { selectedID = nil }
                .id(ticket.wrappedValue.id)
        } else {
            HStack {
                Text("문의 관리").umcTypography(.title2Bold).accessibilityAddTraits(.isHeader)
                Spacer()
                Button("FAQ 관리") { managingFAQ = true }
                Button("새 문의 작성") { composing = true }.buttonStyle(.borderedProminent)
            }
            Table(fixture.tickets) {
                TableColumn("문의") { ticket in
                    Button(ticket.subject) { selectedID = ticket.id }
                        .buttonStyle(.link)
                }
                TableColumn("받는 팀") { Text($0.team.rawValue) }
                TableColumn("상태") { Text($0.status.rawValue) }
            }
            .sheet(isPresented: $composing) {
                SupportComposePreview { subject, content, team in
                    selectedID = fixture.create(subject: subject, content: content, team: team)
                    composing = false
                }
            }
        }
    }
}

private struct SupportComposePreview: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subject = ""
    @State private var content = ""
    @State private var team: SupportTeam?
    let submit: (String, String, SupportTeam) -> Void

    private var isValid: Bool {
        team != nil && !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            Text("문의 작성").umcTypography(.title2Bold).accessibilityAddTraits(.isHeader)
            Text("예시 문의는 이 창에만 저장돼요.").foregroundStyle(.secondary)
            Form {
                Picker("받는 팀", selection: $team) {
                    Text("받는 팀 선택").tag(Optional<SupportTeam>.none)
                    ForEach(SupportTeam.allCases, id: \.self) { team in
                        Text(team.rawValue).tag(Optional(team))
                    }
                }
                TextField("제목", text: $subject)
                TextField("문의 내용", text: $content, axis: .vertical)
                    .lineLimit(3...6)
            }
            HStack {
                Spacer()
                Button("취소") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("예시 문의 등록") {
                    if let team { submit(subject, content, team) }
                }
                .disabled(!isValid)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(UMCSpacing.value24)
        .frame(width: 460)
    }
}

private struct SupportTicketDetail: View {
    @Binding var ticket: SupportTicket
    let back: () -> Void
    @State private var message = ""

    var body: some View {
        HStack {
            Button("문의 관리로", action: back).keyboardShortcut(.cancelAction)
            Spacer()
            Text(ticket.status.rawValue).umcTypography(.headlineRegular)
            Button(ticket.status == .closed ? "다시 진행" : "문의 종료") {
                ticket.status = ticket.status == .closed ? .active : .closed
            }
        }
        ScrollView {
            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                Text(ticket.subject).umcTypography(.title2Bold).accessibilityAddTraits(.isHeader)
                Text(ticket.content).textSelection(.enabled)
                GroupBox("운영 정보") {
                    Form {
                        Picker("받는 팀", selection: $ticket.team) {
                            ForEach(SupportTeam.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        Picker("담당자", selection: $ticket.assignee) {
                            Text("미배정").tag("미배정")
                            Text("예시 담당자").tag("예시 담당자")
                        }
                        Picker("라벨", selection: $ticket.label) {
                            ForEach(["미분류", "화면 오류", "이용 방법"], id: \.self) { Text($0).tag($0) }
                        }
                    }
                    .padding(UMCSpacing.value12)
                }
                ForEach(ticket.replies) { Text($0.text).textSelection(.enabled) }
                if ticket.status != .closed {
                    HStack {
                        TextField("예시 답변", text: $message).onSubmit { send() }
                        Button("답변 추가", action: send)
                            .disabled(
                                message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func send() {
        ticket.reply(message)
        message = ""
    }
}
#endif
