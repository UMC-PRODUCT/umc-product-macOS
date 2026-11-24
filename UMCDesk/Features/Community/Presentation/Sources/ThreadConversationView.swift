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
    @FocusState private var composerFocused: Bool

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
                        HStack(spacing: 8) {
                            Rectangle().fill(.separator).frame(width: 32, height: 1)
                            Text(date, format: .dateTime.month().day().weekday())
                                .font(.caption).fixedSize()
                            Rectangle().fill(.separator).frame(width: 32, height: 1)
                        }
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                    }
                    row(message)
                }
                ForEach(model.outgoing) { item in
                    outgoingRow(item)
                }
            }
            .padding(.horizontal, UMCSpacing.value24)
            .padding(.vertical, UMCSpacing.value16)
        }
        .frame(minHeight: 0, maxHeight: .infinity)
        .defaultScrollAnchor(.bottom, for: .initialOffset)
        .scrollEdgeEffectStyle(.soft, for: .bottom)
        .safeAreaBar(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
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
            MessageDetails(own: own, canAct: active && !message.isHidden,
                           sent: own && !message.isHidden, date: date(message.createdAt),
                           reactionsEnabled: !model.busy,
                           react: { react($0, message: message) }) {
                if !own && !message.author.isEmpty {
                    Text(message.author).font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 6) {
                    if let reply = message.replyID {
                        let original = model.messages.first { $0.id == reply && !$0.isHidden }
                        Label(original?.text ?? "메시지에 답장", systemImage: "arrowshape.turn.up.left")
                            .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    }
                    if !message.text.isEmpty { Text(message.text).textSelection(.enabled) }
                    if !message.files.isEmpty { attachments(message.files) }
                }
                .modifier(MessageBubble(own: own))
                if !message.isHidden && !message.reactions.isEmpty {
                    ViewThatFits(in: .horizontal) {
                        reactionStrip(message)
                        ScrollView(.horizontal) { reactionStrip(message) }
                            .defaultScrollAnchor(own ? .trailing : .leading, for: .initialOffset)
                    }
                }
            } actions: { dismiss in
                messageCommands(message, own: own, dismiss: dismiss)
            }
            if !own { Spacer(minLength: 32) }
        }
    }

    @ViewBuilder
    private func messageCommands(
        _ message: ThreadConversationMessage, own: Bool, dismiss: @escaping () -> Void
    ) -> some View {
        Button("답장") {
            dismiss()
            model.selectReply(message.id)
        }
        if own {
            Button("수정") {
                dismiss()
                editText = message.text
                editing = message
            }
            Button("삭제", role: .destructive) {
                dismiss()
                deleting = message
            }
        } else if management != nil {
            Button("메시지 신고", systemImage: "flag", role: .destructive) {
                dismiss()
                reporting = message
            }
        }
    }

    private func reactionStrip(_ message: ThreadConversationMessage) -> some View {
        HStack(spacing: 5) {
            ForEach(message.reactions, id: \.emoji) { reaction in
                Button {
                    react(reaction.emoji, message: message)
                } label: {
                    HStack(spacing: 3) {
                        Text(reaction.emoji).font(.caption)
                        Text(reaction.count).font(.caption2.weight(.medium)).monospacedDigit()
                    }
                    .padding(.horizontal, 7)
                    .frame(minHeight: 21)
                    .foregroundStyle(reaction.reactedByMe
                        ? UMCColor.Semantic.textBrandStrong : UMCColor.Semantic.textNeutralDefault)
                    .modifier(ConversationGlass(shape: Capsule(), branded: reaction.reactedByMe,
                                                interactive: true))
                    .overlay {
                        if reaction.reactedByMe {
                            Capsule().strokeBorder(UMCColor.Semantic.borderPrimaryStrong500,
                                                   lineWidth: 1)
                                .allowsHitTesting(false)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("\(reaction.emoji) 반응 \(reaction.count)개")
                .accessibilityAddTraits(reaction.reactedByMe ? .isSelected : [])
                .disabled(!active || model.busy)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    private func outgoingRow(_ item: ThreadConversationModel.Outgoing) -> some View {
        VStack(alignment: .trailing, spacing: 5) {
            VStack(alignment: .leading, spacing: 6) {
                if !item.content.isEmpty { Text(item.content) }
                if !item.files.isEmpty { Text("사진 \(item.files.count)장") }
            }
            .modifier(MessageBubble(own: true))
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
                .focused($composerFocused)
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
        .modifier(ComposerPanel(focused: composerFocused))
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
                .textFieldStyle(.plain)
                .font(.system(size: 15))
                .lineLimit(1...6)
                .focused($composerFocused)
                .padding(.horizontal, 4)
                .frame(minHeight: 34, alignment: .topLeading)
                .background {
                    Color.clear.contentShape(Rectangle())
                        .onTapGesture { composerFocused = true }
                }
            HStack(spacing: 6) {
                Button { picking = true } label: {
                    Label("사진 첨부", systemImage: "plus").frame(width: 28, height: 28)
                }
                .disabled(!model.draftIsOutgoing && model.attachments.count >= 4)
                .help("사진 첨부")
                Button { mentioning = true } label: {
                    Label("참여자 멘션", systemImage: "at").frame(width: 28, height: 28)
                }
                .help("참여자 멘션")
                .popover(isPresented: $mentioning) {
                    ConversationMentions(model: model) { person in
                        model.mention(person)
                        mentioning = false
                    }
                }
                Spacer()
                if model.composerText.unicodeScalars.count > 1_800 {
                    Text("\(model.composerText.unicodeScalars.count) / 2,000").font(.caption)
                }
                if model.busy { ProgressView().controlSize(.small) }
                Button(action: requestSend) {
                    Label("메시지 전송", systemImage: "arrow.up")
                        .font(.body.weight(.semibold))
                        .frame(width: 32, height: 32)
                        .foregroundStyle(UMCColor.Semantic.textInverse)
                        .background(model.canSend && !model.draftIsOutgoing
                            ? UMCColor.Semantic.textNeutralDefault
                            : UMCColor.Semantic.textDisabled, in: Circle())
                        .contentShape(Circle())
                }
                .disabled(!model.canSend || model.draftIsOutgoing)
                .keyboardShortcut(.return, modifiers: .command)
                .help("메시지 전송 (⌘↩)")
            }
            .buttonStyle(.plain)
            .labelStyle(.iconOnly)
        }
        .disabled(model.busy || !model.loaded)
        .modifier(ComposerPanel(focused: composerFocused))
    }

    private func requestSend() {
        if model.attachments.isEmpty { model.send() } else { confirmingPhotos = true }
    }
}

private struct MessageDetails<Bubble: View, Actions: View>: View {
    let own: Bool
    let canAct: Bool
    let sent: Bool
    let date: Date?
    let reactionsEnabled: Bool
    let react: (String) -> Void
    @ViewBuilder let bubble: () -> Bubble
    @ViewBuilder let actions: (@escaping () -> Void) -> Actions

    private let emojiChoices = ["👍", "❤️", "🔥", "🎉", "👀"]
    @State private var showingActions = false
    @State private var hovering = false
    @FocusState private var menuFocused: Bool
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOver

    var body: some View {
        VStack(alignment: own ? .trailing : .leading, spacing: 4) {
            bubble()
            HStack(spacing: 5) {
                if own && canAct { actionButton }
                if let date {
                    if sent {
                        Image(systemName: "checkmark").accessibilityLabel("전송 완료")
                            .help("전송 완료")
                    }
                    Text(date, format: .dateTime.hour().minute())
                }
                if !own && canAct { actionButton }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .onHover { hovering = $0 }
        .contextMenu {
            if canAct {
                Menu("반응 추가", systemImage: "face.smiling") {
                    ForEach(emojiChoices, id: \.self) { emoji in
                        Button(emoji) { react(emoji) }
                    }
                }
                .disabled(!reactionsEnabled)
                Divider()
                actions({})
            }
        }
    }

    private var actionButton: some View {
        Button {
            showingActions.toggle()
        } label: {
            Image(systemName: "face.smiling")
                .foregroundStyle(hovering || menuFocused || voiceOver || showingActions
                    ? Color.secondary : Color.clear)
                .frame(width: 24, height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focused($menuFocused)
        .accessibilityLabel("메시지 반응 및 동작")
        .help("반응 추가 및 메시지 동작")
        .popover(isPresented: $showingActions) { actionPopover }
    }

    private var actionPopover: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 3) {
                ForEach(emojiChoices, id: \.self) { emoji in
                    Button {
                        showingActions = false
                        react(emoji)
                    } label: {
                        Text(emoji).font(.system(size: 21))
                            .frame(width: 32, height: 32)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("\(emoji) 반응")
                    .disabled(!reactionsEnabled)
                }
            }
            Divider()
            HStack(spacing: 14) {
                actions { showingActions = false }
            }
            .buttonStyle(.borderless)
            .controlSize(.small)
            .padding(.horizontal, 5)
        }
        .padding(10)
        .fixedSize()
    }
}

private struct ComposerPanel: ViewModifier {
    let focused: Bool
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        content
            .padding(.horizontal, 14)
            .padding(.top, 16)
            .padding(.bottom, 10)
            .modifier(ConversationGlass(shape: shape))
            .overlay {
                if focused {
                    shape.strokeBorder(UMCColor.Semantic.borderPrimaryStrong500,
                                       lineWidth: contrast == .increased ? 2 : 1)
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: 840)
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity)
    }
}

private struct MessageBubble: ViewModifier {
    let own: Bool

    func body(content: Content) -> some View {
        let shape = UnevenRoundedRectangle(
            topLeadingRadius: 17, bottomLeadingRadius: own ? 17 : 6,
            bottomTrailingRadius: own ? 6 : 17, topTrailingRadius: 17)
        content
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .foregroundStyle(UMCColor.Semantic.textNeutralDefault)
            .modifier(ConversationGlass(shape: shape, branded: own))
    }
}

private struct ConversationGlass<Surface: InsettableShape>: ViewModifier {
    let shape: Surface
    var branded = false
    var interactive = false

    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        if reduceTransparency || contrast == .increased {
            content
                .background(branded ? UMCColor.Semantic.surfaceBrandMedium
                    : UMCColor.Custom.backgroundSurfaceGreyWeaker, in: shape)
                .overlay {
                    shape.strokeBorder(branded ? UMCColor.Semantic.borderPrimaryStrong500
                        : UMCColor.Semantic.borderNeutralStronger600)
                        .allowsHitTesting(false)
                }
        } else {
            content.glassEffect(
                .regular.tint(branded ? UMCColor.Semantic.fillPrimaryMedium100 : nil)
                    .interactive(interactive), in: shape)
        }
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
