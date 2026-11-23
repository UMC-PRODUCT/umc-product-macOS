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
    var isOperator = false
    @FocusState private var tableFocused: Bool
    @State private var highlightedID: UUID?
    @State private var selectedID: UUID?
    @State private var composing = false
    @State private var managingFAQ = false

    private var selectedTicket: Binding<SupportTicket>? {
        $fixture.tickets.first {
            $0.wrappedValue.id == selectedID
                && (isOperator || $0.wrappedValue.belongsToCurrentUser)
        }
    }

    var body: some View {
        if isOperator && managingFAQ {
            SupportFAQPreview(fixture: fixture) { managingFAQ = false }
        } else if let ticket = selectedTicket {
            SupportTicketDetail(ticket: ticket, isOperator: isOperator) {
                highlightedID = selectedID
                selectedID = nil
            }
            .id(ticket.wrappedValue.id)
        } else {
            HStack {
                Text(isOperator ? "문의 관리" : "내 문의 현황")
                    .umcTypography(.title2Bold).accessibilityAddTraits(.isHeader)
                Spacer()
                if isOperator {
                    Button("FAQ 관리") { managingFAQ = true }
                } else {
                    Button("새 문의 작성") { composing = true }.buttonStyle(.borderedProminent)
                }
            }
            Table(isOperator ? fixture.tickets : fixture.myTickets, selection: $highlightedID) {
                TableColumn("문의") { ticket in
                    Button(ticket.subject) { selectedID = ticket.id }
                        .buttonStyle(.link)
                }
                if isOperator { TableColumn("받는 팀") { Text($0.team.rawValue) } }
                TableColumn("상태") { Text($0.status.rawValue) }
            }
            .focused($tableFocused)
            .onAppear { tableFocused = true }
            .contextMenu(forSelectionType: UUID.self) { _ in } primaryAction: { ids in
                selectedID = ids.first
            }
            .onKeyPress(.return) {
                guard let highlightedID else { return .ignored }
                selectedID = highlightedID
                return .handled
            }
            .sheet(isPresented: $composing) {
                SupportComposePreview { subject, content in
                    selectedID = fixture.create(subject: subject, content: content, team: .product)
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
    let submit: (String, String) -> Void

    private var isValid: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            Text("문의 작성").umcTypography(.title2Bold).accessibilityAddTraits(.isHeader)
            Text("예시 문의는 이 창에만 저장돼요.").foregroundStyle(.secondary)
            Form {
                TextField("제목", text: $subject)
                TextField("문의 내용", text: $content, axis: .vertical)
                    .lineLimit(3...6)
            }
            HStack {
                Spacer()
                Button("취소") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("예시 문의 등록") {
                    submit(subject, content)
                }
                .disabled(!isValid)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(UMCSpacing.value24)
        .frame(width: 460)
    }
}

#endif
