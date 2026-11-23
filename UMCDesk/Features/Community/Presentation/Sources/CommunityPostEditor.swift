//
//  CommunityPostEditor.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import CoreDesignSystem
import SwiftUI

struct CommunityPostEditor: View {
    let existing: CommunityPost?
    let repository: any CommunityPostRepository
    let saved: (CommunityPost) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title: String
    @State private var content: String
    @State private var category: CommunityPostCategory
    @State private var location: String
    @State private var meetAt: Date
    @State private var capacity: String
    @State private var link: String
    @State private var busy = false
    @State private var awaitingConfirmation = false
    @State private var failure: String?
    @State private var operation: Task<Void, Never>?

    init(
        existing: CommunityPost?, repository: any CommunityPostRepository,
        saved: @escaping (CommunityPost) -> Void
    ) {
        self.existing = existing
        self.repository = repository
        self.saved = saved
        _title = State(initialValue: existing?.title ?? "")
        _content = State(initialValue: existing?.content ?? "")
        _category = State(initialValue: existing.flatMap { .init(rawValue: $0.category) } ?? .free)
        _location = State(initialValue: existing?.meeting?.location ?? "")
        _meetAt = State(
            initialValue: existing?.meeting.flatMap { CommunityPostDate.parse($0.meetAt) }
                ?? Date())
        _capacity = State(initialValue: existing?.meeting?.maxParticipants ?? "2")
        _link = State(initialValue: existing?.meeting?.openChatUrl ?? "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(existing == nil ? "새 게시글" : "게시글 수정").umcTypography(.title1Bold)
            Form {
                Picker("카테고리", selection: $category) {
                    ForEach(
                        CommunityPostCategory.allCases.filter {
                            guard let existing else { return true }
                            return ($0 == .lightning) == (existing.category == "LIGHTNING")
                        }, id: \.self
                    ) { Text($0.label).tag($0) }
                }
                TextField("제목", text: $title)
                TextField("본문", text: $content, axis: .vertical).lineLimit(3...10)
                if category == .lightning {
                    DatePicker("모임 일시", selection: $meetAt)
                    TextField("모임 장소", text: $location)
                    TextField("최대 인원", text: $capacity)
                    TextField("오픈 채팅 주소", text: $link)
                }
            }
            .disabled(awaitingConfirmation)
            if let failure { Text(failure).foregroundStyle(.secondary) }
            HStack {
                Spacer()
                Button("취소") { dismiss() }.keyboardShortcut(.cancelAction)
                Button(awaitingConfirmation ? "등록 결과 확인" : "저장") { save() }.keyboardShortcut(.defaultAction)
                    .disabled(!valid)
            }
        }
        .padding(24).frame(minWidth: 360, idealWidth: 520)
        .disabled(busy).interactiveDismissDisabled(busy)
        .onDisappear { operation?.cancel() }
    }

    private var valid: Bool {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return false }
        guard category == .lightning else { return true }
        guard let count = Int32(capacity), count > 0, let url = URL(string: link),
            ["https", "http"].contains(url.scheme), url.host != nil
        else { return false }
        return !location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func save() {
        guard !busy, valid else { return }
        busy = true
        operation = Task { @MainActor in
            defer { busy = false }
            do {
                let meeting: CommunityPostMeeting? =
                    category == .lightning
                    ? .init(
                        meetAt: meetAt.ISO8601Format(), location: location,
                        maxParticipants: capacity, openChatUrl: link) : nil
                let result = try await repository.save(
                    id: existing?.id, title: title,
                    content: content, category: category, meeting: meeting)
                try Task.checkCancellation()
                saved(result)
            } catch {
                if !Task.isCancelled {
                    awaitingConfirmation = error as? CommunityPostWriteFailure == .unconfirmed
                    failure = error.localizedDescription
                }
            }
        }
    }
}
