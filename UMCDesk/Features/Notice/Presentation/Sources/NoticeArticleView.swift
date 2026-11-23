//  NoticeArticleView.swift
//  NoticePresentation
//
//  Created by euijjang97 on 11/23/26.

import CoreDesignSystem
import NoticeDomain
import SwiftUI
import UniformTypeIdentifiers

struct NoticeArticleView: View {
    let repository: any NoticeRepository
    let id: String
    let confirmed: Bool
    let onBack: () -> Void
    let onChanged: () -> Void
    let onRead: () -> Void
    @State private var entry: NoticeEntry?
    @State private var selection: Set<String> = []
    @State private var permissions: Set<String> = []
    @State private var editSheet = false
    @State private var deletePrompt = false
    @State private var showReaders = false
    @State private var photo: NoticeAttachment?
    @State private var busy = false
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            HStack {
                Text("공지 / " + (entry?.mustRead == true ? "고정" : "상세")).foregroundStyle(.secondary)
                Spacer()
                if permissions.contains("CHECK") {
                    Button("읽음 현황") { showReaders = true }
                }
                if permissions.contains("EDIT") {
                    Button("수정") { editSheet = true }
                }
                if permissions.contains("DELETE") {
                    Button("삭제", role: .destructive) { deletePrompt = true }
                }
            }
            if let error {
                HStack {
                    Text(error).foregroundStyle(.secondary)
                    Button("다시 불러오기") {
                        Task { await perform { try await reloadWithPermissions() } }
                    }
                }
            }
            if let entry {
                ScrollView {
                    VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                        Text(entry.audienceLabel).foregroundStyle(.secondary)
                        Text(entry.title).umcTypography(.largeTitle2Bold)
                        Label(entry.metadata, systemImage: "person.crop.circle")
                            .foregroundStyle(.secondary)
                        Divider()
                        Text(
                            (try? AttributedString(
                                markdown: entry.content,
                                options: .init(
                                    interpretedSyntax: .inlineOnlyPreservingWhitespace)))
                                ?? AttributedString(entry.content)
                        )
                        .umcTypography(.bodyRegular).textSelection(.enabled)
                        .environment(
                            \.openURL,
                            OpenURLAction { url in
                                noticeWebURL(url.absoluteString) == nil
                                    ? .discarded : .systemAction
                            })
                        if let images = entry.images, !images.isEmpty {
                            GroupBox("사진 \(images.count)") {
                                ScrollView(.horizontal) {
                                    HStack {
                                        ForEach(images) { image in
                                            Button {
                                                photo = image
                                            } label: {
                                                AsyncImage(url: noticeWebURL(image.url)) { image in
                                                    image.resizable().scaledToFill()
                                                } placeholder: {
                                                    Image(systemName: "photo")
                                                }
                                                .frame(width: 160, height: 110)
                                                .clipShape(.rect(cornerRadius: UMCRadius.value8))
                                            }
                                            .accessibilityLabel("첨부 사진 크게 보기")
                                        }
                                    }
                                }
                            }
                        }
                        if let vote = entry.vote { poll(vote) }
                        ForEach(entry.links ?? []) { link in
                            if let url = noticeWebURL(link.url) {
                                Link(destination: url) { Label(link.url, systemImage: "link") }
                            }
                        }
                        Button(confirmed ? "읽음 확인 완료" : "읽음 확인", systemImage: "checkmark.circle") {
                            Task {
                                await perform {
                                    try await repository.confirmRead(id: id)
                                    onRead()
                                }
                            }
                        }
                        .disabled(confirmed || busy)
                    }
                    .frame(maxWidth: 980, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else if busy {
                ProgressView()
            }
            Spacer(minLength: 0)
        }
        .padding(UMCSpacing.value32)
        .task { await perform { try await reloadWithPermissions() } }
        .confirmationDialog("이 공지를 삭제할까요?", isPresented: $deletePrompt) {
            Button("공지 삭제", role: .destructive) {
                Task {
                    await perform {
                        try await repository.delete(id: id)
                        onChanged()
                        onBack()
                    }
                }
            }
        }
        .sheet(
            isPresented: $editSheet,
            onDismiss: {
                onChanged()
                Task { await perform { try await reload() } }
            }
        ) {
            if let entry {
                NoticeEditView(repository: repository, entry: entry) {
                    editSheet = false
                }
            }
        }
        .sheet(isPresented: $showReaders) { NoticeReadersView(repository: repository, id: id) }
        .sheet(item: $photo) { photo in
            VStack {
                AsyncImage(url: noticeWebURL(photo.url)) { phase in
                    if let image = phase.image {
                        image.resizable().scaledToFit()
                    } else if phase.error != nil {
                        Text("사진을 불러올 수 없습니다.")
                    } else {
                        ProgressView()
                    }
                }
                Button("닫기") { self.photo = nil }.keyboardShortcut(.cancelAction)
            }
            .padding().frame(minWidth: 450, minHeight: 320)
        }
    }

    private func poll(_ vote: NoticeVote) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                Text(vote.title).umcTypography(.headlineBold)
                Text(
                    [
                        vote.allowMultipleChoice ? "복수 선택" : "단일 선택",
                        vote.isAnonymous ? "익명" : "기명", "참여 \(vote.totalParticipants)명",
                        "마감 \(vote.endsAtExclusive.prefix(10))",
                    ].joined(separator: " · ")
                )
                .foregroundStyle(.secondary)
                ForEach(vote.options, id: \.optionId) { option in
                    Toggle(
                        "\(option.content) (\(option.voteCount)표)",
                        isOn: Binding {
                            selection.contains(option.optionId)
                        } set: { enabled in
                            if enabled {
                                if !vote.allowMultipleChoice { selection.removeAll() }
                                selection.insert(option.optionId)
                            } else {
                                selection.remove(option.optionId)
                            }
                        }
                    )
                    .disabled(vote.status != "OPEN" || busy)
                }
                let previous = Set(vote.mySelectedOptionIds)
                Button(selection.isEmpty && !previous.isEmpty ? "투표 취소" : "투표 제출") {
                    Task {
                        await perform {
                            try await repository.vote(
                                options: selection.sorted(),
                                replacing: !previous.isEmpty, id: id)
                            entry = nil
                            try await reload()
                        }
                    }
                }
                .disabled(vote.status != "OPEN" || busy || previous == selection)
            }.frame(maxWidth: .infinity, alignment: .leading).padding(8)
        } label: {
            Label(vote.status == "OPEN" ? "진행 중인 투표" : "투표", systemImage: "chart.bar")
        }
    }

    private func reloadWithPermissions() async throws {
        try await reload()
        permissions = try await repository.permissions(id: id)
    }

    private func reload() async throws {
        let detail = try await repository.detail(id: id)
        entry = detail
        selection = Set(detail.vote?.mySelectedOptionIds ?? [])
    }

    private func perform(_ operation: () async throws -> Void) async {
        guard !busy else { return }
        busy = true
        error = nil
        defer { busy = false }
        do { try await operation() } catch {
            if !Task.isCancelled { self.error = error.localizedDescription }
        }
    }
}

private struct NoticeReadersView: View {
    @Environment(\.dismiss) private var dismiss
    let repository: any NoticeRepository
    let id: String
    @State private var counts: NoticeReadCounts?
    @State private var rows: [NoticeReader] = []
    @State private var targets: Set<String> = []
    @State private var confirmReminder = false
    @State private var reminderSent = false
    @State private var status = "READ"
    @State private var cursor: String?
    @State private var busy = false
    @State private var error: String?
    @State private var requestID = UUID()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("읽음 현황").umcTypography(.title2Bold)
            if let counts {
                Text(
                    [
                        "전체 \(counts.totalCount)명", "읽음 \(counts.readCount)명",
                        "안 읽음 \(counts.unreadCount)명",
                    ].joined(separator: " · "))
            }
            Picker("상태", selection: $status) {
                Text("읽음").tag("READ")
                Text("안 읽음").tag("UNREAD")
            }.pickerStyle(.segmented)
            List(rows, id: \.challengerId) { row in
                let name = [row.name, row.schoolName].compactMap { $0 }.joined(separator: " · ")
                if status == "UNREAD" {
                    Toggle(
                        name,
                        isOn: Binding {
                            targets.contains(row.challengerId)
                        } set: { selected in
                            if selected {
                                targets.insert(row.challengerId)
                            } else {
                                targets.remove(row.challengerId)
                            }
                            reminderSent = false
                        })
                } else {
                    Text(name)
                }
            }
            if busy { ProgressView() }
            if let error {
                Text(error)
                Button("다시 시도") { Task { await load(after: cursor) } }
            } else if let cursor {
                Button("더 보기") { Task { await load(after: cursor) } }.disabled(busy)
            }
            if status == "UNREAD" {
                Button("선택한 대상에게 리마인드 발송") { confirmReminder = true }
                    .disabled(targets.isEmpty || busy)
                if reminderSent { Text("리마인드를 발송했습니다.") }
            }
            Button("닫기") { dismiss() }.keyboardShortcut(.cancelAction)
        }
        .padding(24).frame(minWidth: 360, minHeight: 340)
        .task(id: status) {
            targets = []
            reminderSent = false
            await load(after: nil)
        }
        .confirmationDialog("선택한 대상에게 알림을 보낼까요?", isPresented: $confirmReminder) {
            Button("발송") {
                Task {
                    busy = true
                    defer { busy = false }
                    do {
                        try await repository.remind(id: id, challengers: targets.sorted())
                        targets.removeAll()
                        reminderSent = true
                    } catch { self.error = error.localizedDescription }
                }
            }
        }
    }

    private func load(after next: String?) async {
        let token = UUID()
        requestID = token
        busy = true
        error = nil
        if next == nil {
            rows = []
            cursor = nil
        }
        defer { if requestID == token { busy = false } }
        do {
            if counts == nil { counts = try await repository.readCounts(id: id) }
            let page = try await repository.readers(id: id, status: status, cursor: next)
            guard requestID == token, !Task.isCancelled else { return }
            rows += page.content
            cursor = page.hasNext ? page.nextCursor : nil
        } catch {
            if requestID == token, !Task.isCancelled { self.error = error.localizedDescription }
        }
    }
}

private struct NoticeEditView: View {
    @Environment(\.dismiss) private var dismiss
    let repository: any NoticeRepository
    let entry: NoticeEntry
    let saved: () -> Void
    @State private var title: String
    @State private var content: String
    @State private var pinned: Bool
    @State private var linksText: String
    @State private var images: [NoticeAttachment]
    @State private var addedFiles: [URL] = []
    @State private var uploaded: [URL: String] = [:]
    @State private var importing = false
    @State private var removePoll = false
    @State private var busy = false
    @State private var failure: String?

    init(repository: any NoticeRepository, entry: NoticeEntry, saved: @escaping () -> Void) {
        self.repository = repository
        self.entry = entry
        self.saved = saved
        _title = State(initialValue: entry.title)
        _content = State(initialValue: entry.content)
        _pinned = State(initialValue: entry.mustRead)
        _images = State(initialValue: entry.images ?? [])
        _linksText = State(initialValue: (entry.links ?? []).map(\.url).joined(separator: "\n"))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("공지 수정").umcTypography(.title2Bold)
            Form {
                Section("공지 내용") {
                    TextField("제목", text: $title)
                    TextField("본문", text: $content, axis: .vertical).lineLimit(3...10)
                    Toggle("필독 공지로 고정", isOn: $pinned)
                }
                Section("첨부") {
                    TextField("링크 (한 줄에 하나)", text: $linksText, axis: .vertical)
                    ForEach(images) { image in
                        HStack {
                            Text("사진 " + image.id)
                            Spacer()
                            Button("제거") { images.removeAll { $0.id == image.id } }
                        }
                    }
                    ForEach(addedFiles, id: \.self) { file in
                        HStack {
                            Text(file.lastPathComponent)
                            Spacer()
                            Button("제거") { addedFiles.removeAll { $0 == file } }
                        }
                    }
                    Button("사진 추가") { importing = true }
                }
                if let vote = entry.vote {
                    Section("투표") { Toggle("‘" + vote.title + "’ 투표 삭제", isOn: $removePoll) }
                }
            }.formStyle(.grouped)
            if let failure { Text(failure) }
            HStack {
                Button("취소") { dismiss() }.keyboardShortcut(.cancelAction)
                Spacer()
                Button("저장") {
                    Task {
                        guard !busy else { return }
                        busy = true
                        defer { busy = false }
                        do {
                            try await save()
                            saved()
                        } catch { failure = error.localizedDescription }
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(
                    title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        || title.count > 255 || content.count > 3000
                        || !links.allSatisfy { noticeWebURL($0) != nil })
            }
        }.disabled(busy).interactiveDismissDisabled(busy)
            .padding(24).frame(minWidth: 420, minHeight: 450)
            .fileImporter(
                isPresented: $importing, allowedContentTypes: [.jpeg, .png, .webP, .gif, .heic],
                allowsMultipleSelection: true
            ) { result in
                if case .success(let urls) = result {
                    addedFiles += urls.filter { !addedFiles.contains($0) }
                }
            }
    }

    private var links: [String] {
        linksText.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    private func save() async throws {
        if entry.title != title || entry.content != content || entry.mustRead != pinned {
            try await repository.edit(id: entry.id, title: title, content: content, pinned: pinned)
        }
        if links != (entry.links ?? []).map(\.url) {
            try await repository.replaceLinks(links, id: entry.id)
        }
        if images.count != (entry.images?.count ?? 0) || !addedFiles.isEmpty {
            let retained = try images.map { image in
                guard let id = image.fileId else { throw URLError(.cannotParseResponse) }
                return id
            }
            for file in addedFiles where uploaded[file] == nil {
                uploaded[file] = try await repository.uploadImage(file: file)
            }
            try await repository.replaceImages(
                retained + addedFiles.compactMap { uploaded[$0] },
                id: entry.id)
        }
        if removePoll { try await repository.removePoll(id: entry.id) }
    }
}
