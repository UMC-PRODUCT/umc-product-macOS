//
//  CommunityPresentation.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 10/6/26.
//

import CommunityDomain
import CoreDesignSystem
import SwiftUI

public struct CommunityThreadsView: View {
    private let repository: any CommunityThreadRepository
    @State private var query = ""
    @State private var filter = "all"
    @State private var threads: [CommunityThread] = []
    @State private var next: String?
    @State private var selection: String?
    @State private var reload = 0
    @State private var loading = false
    @State private var failure: String?
    @State private var creating = false

    public init(repository: any CommunityThreadRepository) { self.repository = repository }

    public var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                HStack {
                    Text("스레드").umcTypography(.title1Bold)
                    Spacer()
                    Button("새 스레드", systemImage: "plus") { creating = true }
                        .labelStyle(.iconOnly)
                }
                TextField("스레드 검색", text: $query)
                Picker("스레드 필터", selection: $filter) {
                    Text("전체").tag("all")
                    Text("읽지 않음").tag("unread")
                    Text("스터디").tag("STUDY")
                    Text("질문").tag("QNA")
                    Text("프로젝트").tag("PROJECT")
                    Text("자유").tag("FREE")
                }
                if let failure {
                    Text(failure).foregroundStyle(.secondary)
                    Button("다시 시도") { reload += 1 }
                }
                if loading { ProgressView().controlSize(.small) }
                List(selection: $selection) {
                    ForEach(threads) { item in
                        HStack {
                            Text(item.icon).accessibilityHidden(true)
                            Text(item.title)
                            Spacer()
                            if item.isPinned { Image(systemName: "pin.fill").accessibilityLabel("고정됨") }
                            if item.unread != "0" { Text(item.unread).accessibilityLabel("안 읽은 메시지 " + item.unread) }
                        }.tag(item.id)
                    }
                }
                if let next {
                    Button("더 보기") { Task { await load(offset: next) } }.disabled(loading)
                }
            }
            .padding(UMCSpacing.value16)
            .frame(minWidth: 230, idealWidth: 290, maxWidth: 400)
            if let item = threads.first(where: { $0.id == selection }) {
                ThreadHistory(repository: repository, thread: item) { updated in
                    if let index = threads.firstIndex(where: { $0.id == updated.id }) {
                        threads[index] = updated
                    }
                }.id(item.id)
            } else {
                ContentUnavailableView(threads.isEmpty && !loading && failure == nil
                    ? "표시할 스레드가 없어요" : "스레드를 선택하세요", systemImage: "bubble.left.and.bubble.right")
            }
        }
        .task(id: [query, filter, String(reload)]) {
            threads = []
            selection = nil
            next = nil
            await load(offset: nil)
        }
        .sheet(isPresented: $creating) {
            ThreadComposer(repository: repository) { item in
                threads.insert(item, at: 0)
                selection = item.id
                creating = false
            }
        }
    }

    @MainActor private func load(offset: String?) async {
        let expectedQuery = query
        let expectedFilter = filter
        loading = true
        failure = nil
        defer { if !Task.isCancelled, query == expectedQuery, filter == expectedFilter { loading = false } }
        do {
            if !query.isEmpty { try await Task.sleep(for: .milliseconds(250)) }
            let page = try await repository.threads(query: String(query.unicodeScalars.prefix(80)),
                                                    filter: filter, offset: offset)
            guard !Task.isCancelled, query == expectedQuery, filter == expectedFilter else { return }
            var ids = Set(threads.map(\.id))
            threads += page.values.filter { ids.insert($0.id).inserted }
            next = page.cursor
        } catch {
            if !Task.isCancelled, query == expectedQuery, filter == expectedFilter {
                failure = error.localizedDescription
            }
        }
    }
}

private struct ThreadHistory: View {
    let repository: any CommunityThreadRepository
    let thread: CommunityThread
    let update: (CommunityThread) -> Void
    @State private var messages: [ThreadMessage] = []
    @State private var cursor: String?
    @State private var busy = false
    @State private var failure: String?
    @State private var retry = 0

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            HStack {
                Text(thread.icon + " " + thread.title).umcTypography(.title1Bold)
                Spacer()
                if thread.isJoined && thread.membershipState == "ACTIVE" {
                    Menu("스레드 설정", systemImage: "ellipsis.circle") {
                        Button(thread.isPinned ? "고정 해제" : "스레드 고정") { change(.pin, !thread.isPinned) }
                        Button(thread.isMuted ? "알림 켜기" : "알림 끄기") { change(.mute, !thread.isMuted) }
                    }.fixedSize().disabled(busy)
                }
            }
            if let description = thread.description, !description.isEmpty { Text(description) }
            Divider()
            if thread.membershipState == "KICKED" {
                ContentUnavailableView("이 스레드에서 내보내졌어요", systemImage: "person.crop.circle.badge.minus")
            } else if !thread.isJoined {
                ContentUnavailableView("참여자만 대화를 볼 수 있어요", systemImage: "lock")
            } else {
                if let failure {
                    Text(failure)
                    Button("다시 불러오기") { retry += 1 }
                }
                if busy { ProgressView().controlSize(.small) }
                if let cursor { Button("이전 메시지") { Task { await history(before: cursor) } }.disabled(busy) }
                List(messages) { message in
                    VStack(alignment: .leading) {
                        if !message.author.isEmpty { Text(message.author).font(.headline) }
                        Text(message.text).textSelection(.enabled)
                    }
                }
            }
            Spacer(minLength: 0)
        }
        .padding(UMCSpacing.value24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .task(id: retry) {
            if thread.isJoined, thread.membershipState == "ACTIVE" { await history(before: nil) }
        }
    }

    private func change(_ preference: ThreadPreference, _ enabled: Bool) {
        guard !busy else { return }
        busy = true
        Task { @MainActor in
            defer { busy = false }
            do { update(try await repository.update(preference, enabled: enabled, id: thread.id)) }
            catch { failure = error.localizedDescription }
        }
    }

    @MainActor private func history(before: String?) async {
        busy = true
        failure = nil
        defer { if !Task.isCancelled { busy = false } }
        do {
            let page = try await repository.messages(id: thread.id, before: before)
            try Task.checkCancellation()
            if before == nil { messages = [] }
            var ids = Set(messages.map(\.id))
            let older = page.values.filter { ids.insert($0.id).inserted }
            messages.insert(contentsOf: older, at: 0)
            cursor = page.cursor
        } catch { if !Task.isCancelled { failure = error.localizedDescription } }
    }
}

private struct ThreadComposer: View {
    let repository: any CommunityThreadRepository
    let created: (CommunityThread) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var description = ""
    @State private var icon = "💬"
    @State private var category = "FREE"
    @State private var failure: String?
    @State private var saving = false

    var body: some View {
        Form {
            Text("새 스레드").umcTypography(.title1Bold)
            TextField("이름", text: $title)
            TextField("설명", text: $description, axis: .vertical)
            TextField("아이콘", text: $icon)
            Picker("카테고리", selection: $category) {
                Text("자유").tag("FREE")
                Text("스터디").tag("STUDY")
                Text("질문").tag("QNA")
                Text("프로젝트").tag("PROJECT")
            }
            if let failure { Text(failure).foregroundStyle(.secondary) }
            HStack {
                Spacer()
                Button("취소") { dismiss() }.keyboardShortcut(.cancelAction)
                Button("만들기") { create() }.keyboardShortcut(.defaultAction)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                              || title.unicodeScalars.count > 80 || description.unicodeScalars.count > 500
                              || icon.count != 1 || icon.unicodeScalars.count > 32)
            }
        }.padding(UMCSpacing.value24).frame(width: 420).disabled(saving)
         .interactiveDismissDisabled(saving)
    }

    private func create() {
        guard !saving else { return }
        saving = true
        Task { @MainActor in
            defer { saving = false }
            do {
                let value = try await repository.create(title: title, description: description,
                                                        category: category, icon: icon)
                created(value)
            } catch { failure = error.localizedDescription }
        }
    }
}
