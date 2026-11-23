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
    let onCheckList: (String, String) -> Void
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
    private var publishedID: String? { publication.noticeID }
    @State private var uploaded: [URL: String] = [:]
    @State private var imagesAttached = false
    @State private var linksAttached = false

    init(
        repository: any NoticeRepository, gisu: String, tab: String,
        onAccessDenied: @escaping () -> Void,
        onCheckList: @escaping (String, String) -> Void,
        onPublished: @escaping (String) -> Void
    ) {
        self.repository = repository
        self.gisu = gisu
        self.onAccessDenied = onAccessDenied
        self.onCheckList = onCheckList
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
                    Picker("수신 대상", selection: $draft.noticeTab) {
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
                        .lineLimit(2...6).disabled(linksAttached)
                    Button("사진 선택", systemImage: "photo.on.rectangle") { importing = true }
                        .disabled(imagesAttached)
                    ForEach(files, id: \.self) { file in
                        HStack {
                            Text(file.lastPathComponent)
                            Spacer()
                            Button("제거") { files.removeAll { $0 == file } }.disabled(
                                imagesAttached)
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
            .disabled(busy || publication.needsListCheck || publication.needsPollCheck)
            if let error { Text(error).foregroundStyle(.red).textSelection(.enabled) }
            HStack {
                Button(publishedID == nil ? "취소" : "게시된 공지 열기") {
                    if let publishedID { onPublished(publishedID) } else { dismiss() }
                }.keyboardShortcut(.cancelAction).disabled(busy)
                Spacer()
                if busy { ProgressView().controlSize(.small) }
                if publication.needsListCheck {
                    Button("목록에서 게시 결과 확인") { onCheckList(draft.title, draft.noticeTab) }
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
                    .disabled((!valid && !publication.needsPollCheck) || busy)
                }
            }
        }
        .padding(24)
        .frame(minWidth: 460, idealWidth: 560, minHeight: 400, idealHeight: 600)
        .task {
            do { organization = try await repository.organization(gisu: gisu) } catch {
                self.error = error.localizedDescription
            }
        }
        .onDisappear { publishingTask?.cancel() }
        .interactiveDismissDisabled(busy || publishedID != nil)
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
        Picker("범위", selection: $scope) {
            Text("전체").tag("all")
            if draft.noticeTab == "CHALLENGER", organization?.chapters.isEmpty == false {
                Text("지부").tag("chapter")
            }
            if draft.noticeTab != "CENTRAL_MEMBER", organization?.schools.isEmpty == false {
                Text("학교").tag("school")
            }
        }
        .onChange(of: draft.noticeTab) { _, tab in
            scope = "all"
            if tab == "SCHOOL_CORE" { draft.parts.removeAll() }
        }
        .onChange(of: scope) { _, value in
            draft.chapterId = value == "chapter" ? organization?.chapters.first?.chapterId : nil
            draft.schoolId = value == "school" ? organization?.schools.first?.schoolId : nil
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

    private func publish() async {
        guard valid || publication.needsPollCheck, !busy else { return }
        busy = true
        error = nil
        defer { busy = false }
        do {
            guard try await repository.canCompose(gisu: gisu) else {
                throw NoticeRequestFailure.accessDenied
            }
            let id = try await publication.publish {
                try await repository.create(draft, gisu: gisu)
            }
            for file in files where uploaded[file] == nil {
                uploaded[file] = try await repository.uploadImage(file: file)
            }
            if !files.isEmpty && !imagesAttached {
                try await repository.replaceImages(files.compactMap { uploaded[$0] }, id: id)
                imagesAttached = true
            }
            if !links.isEmpty && !linksAttached {
                try await repository.replaceLinks(links, id: id)
                linksAttached = true
            }
            if usingPoll {
                try await publication.publishPoll {
                    try await repository.addPoll(poll, id: id)
                } check: {
                    guard let result = try await repository.detail(id: id).vote else {
                        return .absent
                    }
                    let matches =
                        result.title == poll.title
                        && result.options.map(\.content) == poll.options
                        && result.isAnonymous == poll.isAnonymous
                        && result.allowMultipleChoice == poll.allowMultipleChoice
                        && (try? Date(result.endsAtExclusive, strategy: .iso8601))
                            == (try? Date(poll.endsAt.ISO8601Format(), strategy: .iso8601))
                    return matches ? .matching : .different
                }
            }
            try Task.checkCancellation()
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
