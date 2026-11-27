//  NoticeComposer.swift
//  NoticePresentation
//
//  Created by euijjang97 on 11/23/26.

import CoreDesignSystem
import NoticeDomain
import SwiftUI
import UniformTypeIdentifiers

struct NoticeComposer: View {
    @Environment(\.dismiss) private var dismiss
    let repository: any NoticeRepository
    let gisu: String
    let onAccessDenied: () -> Void
    let onPublished: (String) -> Void
    @State private var draft: NoticeDraft
    @State private var organization: NoticeOrganization?
    @State private var scope = "all"
    @State private var linksText = ""
    @State private var files: [URL] = []
    @State private var usingPoll = false
    @State private var poll = NoticePollDraft()
    @State private var importing = false
    @State private var busy = false
    @State private var error: String?
    @State private var publication = NoticePublication()
    @State private var publishingTask: Task<Void, Never>?
    @State private var restored = false
    @State private var confirmingNew = false
    @State private var discarding = false
    private var publishedID: String? { publication.noticeID }

    init(
        repository: any NoticeRepository, gisu: String, tab: String,
        onAccessDenied: @escaping () -> Void,
        onPublished: @escaping (String) -> Void
    ) {
        self.repository = repository
        self.gisu = gisu
        self.onAccessDenied = onAccessDenied
        self.onPublished = onPublished
        var value = NoticeDraft()
        value.noticeTab = tab
        _draft = State(initialValue: value)
    }

    private var links: [String] {
        linksText.split(whereSeparator: \.isNewline)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    }

    private var valid: Bool {
        (scope != "chapter" || draft.chapterId != nil)
            && (scope != "school" || draft.schoolId != nil)
            && !draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !draft.content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && draft.title.count <= 255 && draft.content.count <= 3000
            && links.allSatisfy { noticeWebURL($0) != nil }
            && (!usingPoll
                || (!poll.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    && poll.options.allSatisfy {
                        !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    } && poll.endsAt > .now))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("공지 작성").umcTypography(.title1Bold)
            Form {
                Section("공지 내용") {
                    TextField("제목", text: $draft.title)
                    TextField("본문", text: $draft.content, axis: .vertical).lineLimit(4...12)
                    Picker(
                        "수신 대상",
                        selection: Binding(
                            get: { draft.noticeTab },
                            set: { tab in
                                draft.noticeTab = tab
                                selectScope("all")
                                if tab == "SCHOOL_CORE" { draft.parts.removeAll() }
                            })
                    ) {
                        ForEach(noticeTabs, id: \.value) { item in Text(item.label).tag(item.value)
                        }
                    }
                    audience
                    if let generation = organization?.generation {
                        Text("\(generation)기 대상").foregroundStyle(.secondary)
                    } else {
                        Text("현재 활동 기수 대상").foregroundStyle(.secondary)
                    }
                    Toggle("필독 공지로 고정", isOn: $draft.mustRead)
                    Toggle("대상자에게 알림 발송", isOn: $draft.shouldNotify)
                }.disabled(publishedID != nil || publication.needsListCheck)
                Section("첨부") {
                    TextField("링크 (한 줄에 하나)", text: $linksText, axis: .vertical)
                        .lineLimit(2...6).disabled(publication.linksAttached)
                    Button("사진 선택", systemImage: "photo.on.rectangle") { importing = true }
                        .disabled(publication.imagesAttached)
                    ForEach(files, id: \.self) { file in
                        HStack {
                            Text(file.lastPathComponent)
                            Spacer()
                            Button("제거") { files.removeAll { $0 == file } }.disabled(
                                publication.imagesAttached)
                        }
                    }
                }
                Section("투표") {
                    Toggle("투표 추가", isOn: $usingPoll)
                    if usingPoll {
                        TextField("투표 제목", text: $poll.title)
                        ForEach(poll.options.indices, id: \.self) { index in
                            TextField("선택지 \(index + 1)", text: $poll.options[index])
                        }
                        HStack {
                            Button("선택지 추가") { poll.options.append("") }.disabled(
                                poll.options.count >= 5)
                            Button("마지막 선택지 제거") { poll.options.removeLast() }.disabled(
                                poll.options.count <= 2)
                        }
                        DatePicker("마감", selection: $poll.endsAt, in: Date.now...)
                        Toggle("익명 투표", isOn: $poll.isAnonymous)
                        Toggle("복수 선택 허용", isOn: $poll.allowMultipleChoice)
                    }
                }
            }
            .formStyle(.grouped)
            .disabled(
                !restored || busy || publication.needsListCheck || publication.needsPollCheck)
            if let error { Text(error).foregroundStyle(.red).textSelection(.enabled) }
            if publication.needsListCheck && !publication.candidates.isEmpty {
                Text("게시한 공지를 선택하면 준비한 첨부와 투표를 저장합니다.")
                ScrollView {
                    VStack(alignment: .leading) {
                        ForEach(publication.candidates) { candidate in
                            Button(
                                "이 공지로 계속 · #\(candidate.id) · \(candidate.title) · \(candidate.createdAt)"
                            ) {
                                recover(candidate.id)
                            }
                        }
                    }
                }.frame(maxHeight: 100).disabled(busy)
            }
            VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                if !restored {
                    Button("작성 상태 다시 열기") { Task { await openJournal() } }.disabled(busy)
                } else if publication.input != nil {
                    Button("이 작성 시도 버리기", role: .destructive) { discarding = true }.disabled(busy)
                }
                if publication.needsListCheck {
                    Button("별도 공지로 작성") { confirmingNew = true }.disabled(busy)
                }
            }
            Divider()
            HStack {
                Button(publishedID == nil ? "취소" : "게시된 공지 열기") {
                    if let publishedID {
                        onPublished(publishedID)
                    } else if publication.needsListCheck {
                        discarding = true
                    } else {
                        dismiss()
                    }
                }.keyboardShortcut(.cancelAction).disabled(busy)
                Spacer()
                if busy { ProgressView().controlSize(.small) }
                if publication.needsListCheck {
                    Button("게시 결과 확인") { recover(nil) }
                        .buttonStyle(.borderedProminent)
                        .keyboardShortcut(.defaultAction)
                        .disabled(busy)
                } else {
                    Button(
                        publication.needsPollCheck
                            ? "투표 등록 결과 확인" : (publishedID == nil ? "게시" : "첨부 저장 재시도")
                    ) {
                        guard publishingTask == nil else { return }
                        publishingTask = Task {
                            defer { publishingTask = nil }
                            await publish()
                        }
                    }
                    .keyboardShortcut(.defaultAction)
                    .buttonStyle(.borderedProminent)
                    .disabled(
                        !restored || publication.input.map { $0.gisu != gisu } == true
                            || (!valid && !publication.needsPollCheck) || busy)
                }
            }
        }
        .padding(24)
        .frame(minWidth: 460, idealWidth: 560, minHeight: 400, idealHeight: 600)
        .task {
            await openJournal()
            do { organization = try await repository.organization(gisu: gisu) } catch {
                self.error = error.localizedDescription
            }
        }
        .onDisappear { publishingTask?.cancel() }
        .interactiveDismissDisabled(busy || publishedID != nil || publication.needsListCheck)
        .confirmationDialog(
            "별도 공지로 작성할까요? 이미 게시됐다면 같은 공지와 알림이 중복될 수 있습니다.", isPresented: $confirmingNew
        ) {
            Button("별도 공지 작성") {
                do {
                    try publication.startSeparateNotice()
                    error = nil
                } catch { self.error = error.localizedDescription }
            }
        }
        .confirmationDialog("게시 결과 확인을 중단하고 작성 중인 첨부와 투표를 버릴까요?", isPresented: $discarding) {
            Button("초안 버리기", role: .destructive) {
                do {
                    try publication.finish()
                    dismiss()
                } catch { self.error = error.localizedDescription }
            }
        }
        .fileImporter(
            isPresented: $importing, allowedContentTypes: [.jpeg, .png, .webP, .gif, .heic],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                files += urls.filter { !files.contains($0) }
            case .failure(let failure):
                if (failure as NSError).code != NSUserCancelledError {
                    error = failure.localizedDescription
                }
            }
        }
    }

    @ViewBuilder
    private var audience: some View {
        Picker("범위", selection: Binding(get: { scope }, set: selectScope)) {
            Text("전체").tag("all")
            if draft.noticeTab == "CHALLENGER", organization?.chapters.isEmpty == false {
                Text("지부").tag("chapter")
            }
            if draft.noticeTab != "CENTRAL_MEMBER", organization?.schools.isEmpty == false {
                Text("학교").tag("school")
            }
        }
        if scope == "chapter", let organization {
            Picker("지부", selection: $draft.chapterId) {
                ForEach(organization.chapters, id: \.chapterId) { chapter in
                    Text(chapter.chapterName).tag(Optional(chapter.chapterId))
                }
            }
        }
        if scope == "school", let organization {
            Picker("학교", selection: $draft.schoolId) {
                ForEach(organization.schools, id: \.schoolId) { school in
                    Text(school.schoolName).tag(Optional(school.schoolId))
                }
            }
        }
        Menu(draft.parts.isEmpty ? "전체 파트" : "파트 \(draft.parts.count)개 선택") {
            ForEach(noticeParts, id: \.value) { item in
                Toggle(
                    item.label,
                    isOn: Binding {
                        draft.parts.contains(item.value)
                    } set: { enabled in
                        if enabled {
                            draft.parts.append(item.value)
                        } else {
                            draft.parts.removeAll { $0 == item.value }
                        }
                    })
            }
        }.disabled(draft.noticeTab == "SCHOOL_CORE")
    }

    private func selectScope(_ value: String) {
        scope = value
        draft.chapterId = value == "chapter" ? organization?.chapters.first?.chapterId : nil
        draft.schoolId = value == "school" ? organization?.schools.first?.schoolId : nil
    }

    private func openJournal() async {
        guard !busy, !restored else { return }
        busy = true
        defer { busy = false }
        do {
            let journal = try await repository.openPublicationJournal()
            try Task.checkCancellation()
            publication = try NoticePublication(journal: journal)
            if let saved = publication.input {
                draft = saved.draft
                scope =
                    draft.chapterId != nil ? "chapter" : (draft.schoolId != nil ? "school" : "all")
                files = saved.files
                linksText = saved.links.joined(separator: "\n")
                usingPoll = saved.poll != nil
                poll = saved.poll ?? NoticePollDraft()
                error =
                    saved.gisu == gisu
                    ? "이전 작성 시도를 복원했습니다. 게시 결과와 첨부를 확인해 주세요."
                    : "이전 기수의 작성 시도가 남아 있습니다. 새로 작성하려면 이 시도를 버려 주세요."
            } else {
                error = nil
            }
            restored = true
        } catch {
            if !Task.isCancelled { self.error = error.localizedDescription }
        }
    }

    private func recover(_ id: String?) {
        guard restored, publication.input?.gisu == gisu, publishingTask == nil else { return }
        busy = true
        error = nil
        publishingTask = Task {
            defer {
                busy = false
                publishingTask = nil
            }
            do {
                if let id {
                    try await publication.confirmCandidate(
                        id, draft: draft, gisu: gisu, repository: repository)
                    busy = false
                    await publish()
                } else {
                    try await publication.findCandidates(draft, gisu: gisu, repository: repository)
                    if publication.candidates.isEmpty { error = "일치하는 게시물이 없습니다. 잠시 후 다시 확인하세요." }
                }
            } catch NoticeRequestFailure.accessDenied {
                if !Task.isCancelled { onAccessDenied() }
            } catch {
                if !Task.isCancelled { self.error = error.localizedDescription }
            }
        }
    }

    private func publish() async {
        guard restored, publication.input.map({ $0.gisu == gisu }) != false,
            valid || publication.needsPollCheck, !busy
        else { return }
        busy = true
        error = nil
        defer { busy = false }
        do {
            guard try await repository.canCompose(gisu: gisu) else {
                throw NoticeRequestFailure.accessDenied
            }
            if let publishedID,
                !(try await repository.permissions(id: publishedID)).contains("EDIT")
            {
                throw NoticeRequestFailure.accessDenied
            }
            let saved = try publication.prepare(
                .init(
                    gisu: gisu, draft: draft, files: files, links: links,
                    poll: usingPoll ? poll : nil))
            files = saved.files
            let id = try await publication.submit(draft, gisu: gisu, repository: repository)
            try await publication.saveAttachments(
                files: files, links: links,
                poll: usingPoll ? poll : nil, repository: repository)
            try Task.checkCancellation()
            try publication.finish()
            onPublished(id)
        } catch NoticeRequestFailure.accessDenied {
            if !Task.isCancelled { onAccessDenied() }
        } catch {
            guard !Task.isCancelled else { return }
            let prefix = publishedID == nil ? "" : "본문을 게시했습니다. 첨부 저장을 확인해 주세요. "
            self.error = prefix + error.localizedDescription
        }
    }
}
