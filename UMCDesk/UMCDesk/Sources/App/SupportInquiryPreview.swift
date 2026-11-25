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
    let showAnswers: () -> Void
    @State private var status: SupportInquiryStatus?
    @State private var onlyUnassigned = false

    init(fixture: SupportFixture, isOperator: Bool = false, initialTicket: UUID? = nil,
         showAnswers: @escaping () -> Void) {
        self.fixture = fixture
        self.isOperator = isOperator
        self.showAnswers = showAnswers
        _selectedID = State(initialValue: initialTicket)
    }

    private var tickets: [SupportTicket] {
        guard isOperator else { return fixture.myTickets }
        return fixture.tickets.filter { ticket in
            (status == nil || status == ticket.status)
                && (!onlyUnassigned || ticket.assignee == "미배정")
        }
    }
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
                Text(isOperator ? "접수된 문의" : "내 문의 현황")
                    .umcTypography(.title2Bold).accessibilityAddTraits(.isHeader)
                Spacer()
                if isOperator {
                    Button("FAQ 관리") { managingFAQ = true }
                } else if !fixture.myTickets.isEmpty {
                    Button("새 문의 작성") { composing = true }.buttonStyle(.borderedProminent)
                }
            }
            Group {
                if !isOperator && fixture.myTickets.isEmpty {
                    ContentUnavailableView {
                        Text("아직 등록한 문의가 없어요").umcTypography(.title2Bold)
                    } description: {
                        Text("많이 묻는 질문에서 먼저 답을 찾거나 문의를 남겨주세요.")
                    } actions: {
                        HStack {
                            Button("답변 찾아보기", action: showAnswers)
                            Button("문의하기") { composing = true }.buttonStyle(.borderedProminent)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay {
                        RoundedRectangle(cornerRadius: UMCRadius.value12)
                            .strokeBorder(UMCColor.Semantic.borderNeutralWeak200)
                            .allowsHitTesting(false)
                    }
                } else {
                    if isOperator {
                        HStack {
                            Picker("상태", selection: $status) {
                                Text("상태 전체").tag(SupportInquiryStatus?.none)
                                ForEach(SupportInquiryStatus.allCases, id: \.self) {
                                    Text($0.rawValue).tag(Optional($0))
                                }
                            }
                            .fixedSize()
                            Toggle("미배정", isOn: $onlyUnassigned)
                            Spacer()
                            Text("\(tickets.count)건").monospacedDigit()
                        }
                    }
                    ticketTable
                }
            }
            .sheet(isPresented: $composing) {
                SupportComposePreview { subject, content, team in
                    selectedID = fixture.create(subject: subject, content: content, team: team)
                    composing = false
                }
            }
        }
    }

    private var ticketTable: some View {
        Table(tickets, selection: $highlightedID) {
            TableColumn("문의") { ticket in
                Button(ticket.subject) { selectedID = ticket.id }
                    .buttonStyle(.link)
            }
            if isOperator {
                TableColumn("담당자") { Text($0.assignee) }
                TableColumn("라벨") { Text($0.label) }
                TableColumn("받는 팀") { Text($0.team.rawValue) }
            }
            TableColumn("상태") { Text($0.status.rawValue) }
            TableColumn("접수일") {
                Text($0.createdAt, format: .dateTime.month().day()).monospacedDigit()
            }
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
    }
}

struct SupportComposePreview: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subject = ""
    @State private var content = ""
    @State private var team = SupportTeam.product
    let submit: (String, String, SupportTeam) -> Void

    private var isValid: Bool {
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            Text("문의 작성").umcTypography(.title2Bold).accessibilityAddTraits(.isHeader)
            Text("예시 문의는 이 창에만 저장돼요.").foregroundStyle(.secondary)
            Form {
                Picker("받는 팀", selection: $team) {
                    ForEach(SupportTeam.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                TextField("제목", text: $subject)
                TextField("문의 내용", text: $content, axis: .vertical)
                    .lineLimit(3...6)
            }
            HStack {
                Spacer()
                Button("취소") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("예시 문의 등록") {
                    submit(subject, content, team)
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
