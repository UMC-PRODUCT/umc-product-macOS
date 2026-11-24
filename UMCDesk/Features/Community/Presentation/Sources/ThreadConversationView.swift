//
//  ThreadConversationView.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import CoreDesignSystem
import ImageIO
import SwiftUI
import UniformTypeIdentifiers

public struct ThreadConversationView: View {
    private let thread: CommunityThread
    private let accountID: String
    private let repository: any ThreadConversationRepository

    private let management: (any ThreadManagementRepository)?
    private let defaults: UserDefaults

    public init(
        thread: CommunityThread, accountID: String,
        repository: any ThreadConversationRepository, management: (any ThreadManagementRepository)? = nil,
        defaults: UserDefaults = .standard
    ) {
        self.thread = thread
        self.accountID = accountID
        self.repository = repository
        self.management = management
        self.defaults = defaults
    }

    public var body: some View {
        if thread.membershipState == "KICKED" || accountID.isEmpty {
            ContentUnavailableView("대화 접근이 종료됐어요", systemImage: "lock")
        } else if !thread.isJoined || thread.membershipState != "ACTIVE" {
            ContentUnavailableView("참여자만 대화를 볼 수 있어요", systemImage: "lock")
        } else {
            ConversationTimeline(thread: thread, accountID: accountID, repository: repository,
                                 management: management, defaults: defaults)
                .id(ObjectIdentifier(defaults))
                .id([accountID, thread.id, thread.membershipState ?? "", String(thread.isJoined)])
        }
    }
}

private struct ConversationTimeline: View {
    let thread: CommunityThread
    @State private var model: ThreadConversationModel
    @State private var picking = false
    @State private var mentioning = false
    @State private var confirmingPhotos = false
    let management: (any ThreadManagementRepository)?
    @State private var reporting: ThreadConversationMessage?
    @State private var editing: ThreadConversationMessage?
    @State private var deleting: ThreadConversationMessage?
    @State private var preview: ThreadConversationFile?
    @State private var editText = ""

    init(thread: CommunityThread, accountID: String, repository: any ThreadConversationRepository,
         management: (any ThreadManagementRepository)?, defaults: UserDefaults) {
        self.management = management
        self.thread = thread
        _model = State(
            initialValue: ThreadConversationModel(
                threadID: thread.id,
                accountID: accountID,
                repository: repository, defaults: defaults))
    }

    private var active: Bool { thread.isJoined && thread.membershipState == "ACTIVE" }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: UMCSpacing.value12) {
                    if !model.messages.isEmpty { summaryPanel }
                    if model.cursor != nil {
                        Button("이전 메시지") { Task { await model.refresh(older: true) } }
                    }
                    if model.loaded && model.messages.isEmpty && model.outgoing.isEmpty {
                        ContentUnavailableView("아직 메시지가 없어요", systemImage: "bubble.left")
                    } else if !model.loaded && model.failure == nil {
                        ProgressView("대화를 불러오는 중")
                    }
                    ForEach(Array(model.messages.enumerated()), id: \.element.id) {
                        offset, message in
                        if let date = date(message.createdAt),
                            offset == 0 || !sameDay(date, model.messages[offset - 1].createdAt)
                        {
                            HStack {
                                Rectangle().frame(height: 1)
                                Text(date, format: .dateTime.month().day().weekday())
                                    .font(.caption).fixedSize()
                                Rectangle().frame(height: 1)
                            }.foregroundStyle(.secondary)
                        }
                        row(message)
                    }
                    ForEach(model.outgoing) { item in
                        outgoingRow(item)
                    }
                }.padding(UMCSpacing.value24)
            }
            .frame(minHeight: 0, maxHeight: .infinity)
            .defaultScrollAnchor(.bottom, for: .initialOffset)
            if let failure = model.failure {
                HStack {
                    Text(failure).font(.callout)
                    Spacer()
                    if model.canRetry {
                        Button("다시 시도") { model.retry() }.disabled(model.busy || model.cooldown)
                    }
                    Button("닫기", systemImage: "xmark") { model.failure = nil }.labelStyle(
                        .iconOnly)
                }.padding(.horizontal, UMCSpacing.value24)
            }
            if active {
                Group {
                    if let editing { editComposer(editing) } else { composer }
                }.fixedSize(horizontal: false, vertical: true)
            } else {
                Text("참여자만 메시지를 보낼 수 있어요.").padding()
            }
        }
        .frame(minHeight: 0, maxHeight: .infinity, alignment: .top)
        .background(UMCColor.Custom.backgroundDefault)
        .task { await model.observe(active: active) }
        .onDisappear { model.stop() }
        .fileImporter(
            isPresented: $picking, allowedContentTypes: [.jpeg, .png, .gif, .webP],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls): model.attach(urls)
            case .failure(let error):
                if (error as NSError).code != NSUserCancelledError {
                    model.failure = error.localizedDescription
                }
            }
        }
        .sheet(isPresented: $confirmingPhotos) {
            VStack(alignment: .leading, spacing: 16) {
                Text("사진 \(model.attachments.count)장을 보낼까요?").umcTypography(.title1Bold)
                HStack {
                    ForEach(model.attachments) { file in
                        AttachmentThumbnail(file: file)
                    }
                }
                HStack {
                    Spacer()
                    Button("취소") { confirmingPhotos = false }.keyboardShortcut(.cancelAction)
                    Button("사진 보내기") {
                        confirmingPhotos = false
                        model.send()
                    }.keyboardShortcut(.defaultAction)
                }
            }.padding(24)
        }
        .confirmationDialog(
            "메시지를 삭제할까요?",
            isPresented: Binding(
                get: { deleting != nil }, set: { if !$0 { deleting = nil } }), presenting: deleting
        ) { message in
            Button("삭제", role: .destructive) { model.perform(.delete(message: message.id)) }
        }
        .sheet(item: $reporting) { message in
            if let management {
                ThreadReportSheet(target: .message(message.id), repository: management)
            }
        }
        .sheet(item: $preview) { file in
            VStack {
                HStack {
                    Text(file.name)
                    Spacer()
                    Button("닫기") { preview = nil }.keyboardShortcut(.cancelAction)
                }
                image(file)
            }.padding(24).frame(minWidth: 400, minHeight: 300)
        }
        .onChange(of: model.messages) { _, messages in
            if let reporting, !messages.contains(where: { $0.id == reporting.id && !$0.isHidden }) {
                self.reporting = nil
            }
            if let preview, !messages.contains(where: { $0.files.contains(preview) }) {
                self.preview = nil
            }
            if let editing, !messages.contains(where: { $0.id == editing.id && !$0.isHidden }) {
                self.editing = nil
            }
        }
    }

    private var summaryPanel: some View {
        ThreadSummaryPanel(model: model, unread: thread.unread)
    }

    private func row(_ message: ThreadConversationMessage) -> some View {
        let own = message.authorID == model.accountID
        return HStack(alignment: .top, spacing: 10) {
            if own { Spacer(minLength: 32) }
            if !own && !message.isHidden {
                Text(String(message.author.prefix(1)))
                    .frame(width: 32, height: 32)
                    .background(UMCColor.Semantic.surfaceBrandMedium, in: .rect(cornerRadius: 10))
                    .accessibilityHidden(true)
            }
            VStack(alignment: own ? .trailing : .leading, spacing: 5) {
                if !own && !message.author.isEmpty { Text(message.author).font(.caption) }
                VStack(alignment: .leading, spacing: 6) {
                    if let reply = message.replyID {
                        let original = model.messages.first { $0.id == reply && !$0.isHidden }
                        Label(original?.text ?? "메시지에 답장", systemImage: "arrowshape.turn.up.left")
                            .font(.caption).lineLimit(2)
                    }
                    if !message.text.isEmpty { Text(message.text).textSelection(.enabled) }
                    if !message.files.isEmpty {
                        attachments(message.files)
                    }
                }.padding(14)
                    .background(
                        own
                            ? UMCColor.Semantic.surfaceBrandMedium
                            : UMCColor.Custom.backgroundSurfaceGreyWeaker,
                        in: .rect(cornerRadius: 14))
                if !message.isHidden {
                    HStack(spacing: 4) {
                        ForEach(message.reactions, id: \.emoji) { reaction in
                            Button("\(reaction.emoji) \(reaction.count)") {
                                react(reaction.emoji, message: message)
                            }.tint(reaction.reactedByMe ? Color.accentColor : nil)
                                .disabled(!active || model.busy)
                        }
                        if active {
                            Menu("반응 추가", systemImage: "face.smiling") {
                                ForEach(["👍", "❤️", "🔥", "🎉", "👀"], id: \.self) { emoji in
                                    Button(emoji) { react(emoji, message: message) }
                                }
                                Button("답장") { model.selectReply(message.id) }
                            }.labelStyle(.iconOnly).fixedSize().disabled(model.busy)
                            if !own, management != nil {
                                Menu("메시지 더보기", systemImage: "ellipsis") {
                                    reportButton(message)
                                }.labelStyle(.iconOnly).fixedSize()
                            }
                        }
                    }
                }
                if let date = date(message.createdAt) {
                    HStack(spacing: 4) {
                        Text(date, format: .dateTime.hour().minute())
                        if own && !message.isHidden { Text("· 전송 완료") }
                    }.font(.caption).foregroundStyle(.secondary)
                }
            }.contextMenu {
                if active && !message.isHidden {
                    Button("답장") { model.selectReply(message.id) }
                    if own {
                        Button("수정") {
                            editText = message.text
                            editing = message
                        }
                        Button("삭제", role: .destructive) { deleting = message }
                    } else if management != nil {
                        reportButton(message)
                    }
                }
            }
            if !own { Spacer(minLength: 32) }
        }
    }

    private func outgoingRow(_ item: ThreadConversationModel.Outgoing) -> some View {
        VStack(alignment: .trailing, spacing: 5) {
            VStack(alignment: .leading, spacing: 6) {
                if !item.content.isEmpty { Text(item.content) }
                if !item.files.isEmpty { Text("사진 \(item.files.count)장") }
            }
            .padding(14)
            .background(UMCColor.Semantic.surfaceBrandMedium, in: .rect(cornerRadius: 14))
            if let failure = item.failure {
                ViewThatFits(in: .horizontal) {
                    HStack { failedDelivery(item, reason: failure) }
                    VStack(alignment: .trailing) { failedDelivery(item, reason: failure) }
                }
            } else {
                HStack(spacing: 4) {
                    ProgressView().controlSize(.mini)
                    Text(item.createdAt, format: .dateTime.hour().minute())
                    Text("· 전송 중")
                }.font(.caption)
            }
        }.frame(maxWidth: .infinity, alignment: .trailing)
    }

    @ViewBuilder private func failedDelivery(
        _ item: ThreadConversationModel.Outgoing, reason: String
    ) -> some View {
        Label("전송 실패", systemImage: "exclamationmark.circle")
            .foregroundStyle(.red).help(reason).accessibilityHint(reason)
        if item.retryable {
            Button("다시 보내기") { model.retryOutgoing(item.id) }
                .disabled(model.busy || model.cooldown || !model.loaded)
        }
    }

    private func attachments(_ files: [ThreadConversationFile]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            if files.count > 1 { Text("사진 \(files.count)장").font(.caption) }
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 58), spacing: 4)], spacing: 4) {
                ForEach(files) { file in
                    Button { preview = file } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            image(file).frame(maxWidth: .infinity).frame(height: 58)
                            Text(file.name).lineLimit(1).font(.caption2)
                        }
                    }.buttonStyle(.plain)
                }
            }.frame(maxWidth: files.count == 1 ? 156 : 300)
        }
    }

    private func reportButton(_ message: ThreadConversationMessage) -> some View {
        Button("메시지 신고", systemImage: "flag", role: .destructive) { reporting = message }
    }

    private func date(_ value: String?) -> Date? {
        guard let value else { return nil }
        return (try? Date(value, strategy: .iso8601))
            ?? (try? Date(
                value, strategy: Date.ISO8601FormatStyle(includingFractionalSeconds: true)))
    }

    private func sameDay(_ date: Date, _ other: String?) -> Bool {
        guard let previous = self.date(other) else { return false }
        return Calendar.current.isDate(date, inSameDayAs: previous)
    }

    private func image(_ file: ThreadConversationFile) -> some View {
        AsyncImage(url: file.url) { phase in
            if let image = phase.image {
                image.resizable().scaledToFit()
            } else {
                Label("사진", systemImage: "photo")
            }
        }
    }

    private func react(_ emoji: String, message: ThreadConversationMessage) {
        let already = message.reactions.first { $0.emoji == emoji }?.reactedByMe ?? false
        model.perform(.react(message: message.id, emoji: emoji, adding: !already))
    }

    private func editComposer(_ message: ThreadConversationMessage) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("메시지 수정 중", systemImage: "pencil").font(.headline)
            Text(message.text).lineLimit(1).font(.caption).foregroundStyle(.secondary)
            TextField("메시지", text: $editText, axis: .vertical)
                .textFieldStyle(.plain).lineLimit(1...6)
            HStack {
                Spacer()
                Button("취소") { editing = nil }.keyboardShortcut(.cancelAction)
                Button("저장") {
                    model.perform(.edit(message: message.id, content: editText))
                    editing = nil
                }
                .keyboardShortcut(.return, modifiers: .command)
                .disabled(!model.loaded || model.busy || model.cooldown ||
                    editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
                    editText.unicodeScalars.count > 2_000)
            }
        }
        .padding(16)
        .background(UMCColor.Custom.backgroundSurfaceGreyWeaker, in: .rect(cornerRadius: 14))
        .padding(.horizontal, 24).padding(.vertical, 12)
    }

    private var composer: some View {
        @Bindable var model = model
        return VStack(alignment: .leading, spacing: 8) {
            if !model.draftIsOutgoing, let reply = model.reply {
                HStack {
                    Label(
                        model.messages.first { $0.id == reply && !$0.isHidden }?.text ?? "답장",
                        systemImage: "arrowshape.turn.up.left"
                    ).lineLimit(1)
                    Button("답장 취소") { model.selectReply(nil) }
                }
            }
            ForEach(model.draftIsOutgoing ? [] : model.attachments) { file in
                Button("첨부 해제 · \(file.name)", systemImage: "xmark.circle") {
                    model.removeFile(file.id)
                }
            }
            TextField("메시지 보내기…", text: $model.composerText, axis: .vertical)
                .textFieldStyle(.plain).lineLimit(1...6)
            HStack {
                Button("사진 첨부", systemImage: "plus") { picking = true }
                    .disabled(!model.draftIsOutgoing && model.attachments.count >= 4)
                Button("참여자 멘션", systemImage: "at") { mentioning = true }
                    .popover(isPresented: $mentioning) {
                        ConversationMentions(model: model) { person in
                            model.mention(person)
                            mentioning = false
                        }
                    }
                Spacer()
                if model.composerText.unicodeScalars.count > 1_800 {
                    Text("\(model.text.unicodeScalars.count) / 2,000").font(.caption)
                }
                if model.busy { ProgressView().controlSize(.small) }
                Button("메시지 전송", systemImage: "arrow.up.circle.fill") { requestSend() }
                    .disabled(!model.canSend || model.draftIsOutgoing).keyboardShortcut(.return, modifiers: .command)
            }.labelStyle(.iconOnly)
        }.disabled(model.busy || !model.loaded)
            .padding(16).background(
                UMCColor.Custom.backgroundSurfaceGreyWeaker,
                in: .rect(cornerRadius: 14)
            )
            .padding(.horizontal, 24).padding(.vertical, 12)
    }

    private func requestSend() {
        if model.attachments.isEmpty { model.send() } else { confirmingPhotos = true }
    }
}

private struct ConversationMentions: View {
    let model: ThreadConversationModel
    let choose: (ThreadManagementPerson) -> Void
    @State private var query = ""
    @State private var people: [ThreadManagementPerson] = []
    @State private var failure: String?

    var body: some View {
        VStack(alignment: .leading) {
            TextField("참여자 검색", text: $query)
            if let failure { Text(failure) }
            List(people, id: \.memberId) { person in
                Button(person.name) { choose(person) }
            }
        }.padding().frame(width: 260, height: 260)
            .task(id: query) {
                people = []
                failure = nil
                do {
                    try await Task.sleep(for: .milliseconds(200))
                    let result = try await model.members(query: query)
                    try Task.checkCancellation()
                    people = result
                } catch {
                    if !Task.isCancelled { failure = error.localizedDescription }
                }
            }
    }
}

private struct AttachmentThumbnail: View {
    let file: ThreadConversationModel.Attachment
    @State private var thumbnail: CGImage?

    var body: some View {
        VStack(alignment: .leading) {
            Group {
                if let thumbnail {
                    Image(decorative: thumbnail, scale: 1).resizable().scaledToFit()
                } else {
                    Image(systemName: "photo")
                }
            }.frame(width: 78, height: 65)
            Text(file.name).font(.caption).lineLimit(1).frame(width: 78)
        }
        .task(id: file.id) {
            guard let source = CGImageSourceCreateWithURL(file.localURL as CFURL, nil) else {
                return
            }
            let options: [CFString: Any] = [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 180,
            ]
            thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        }
    }
}
