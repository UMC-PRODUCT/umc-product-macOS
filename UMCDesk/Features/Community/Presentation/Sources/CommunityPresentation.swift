//
//  CommunityPresentation.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 10/6/26.
//

import AppKit
import CommunityDomain
import CoreDesignSystem
import SwiftUI

public struct CommunityThreadsView: View {
    private let accountID: String
    private let repository: any CommunityThreadRepository
    private let conversations: any ThreadConversationRepository
    private let management: any ThreadManagementRepository
    private let defaults: UserDefaults

    public init(
        accountID: String, repository: any CommunityThreadRepository,
        conversations: any ThreadConversationRepository, management: any ThreadManagementRepository,
        defaults: UserDefaults = .standard
    ) {
        self.accountID = accountID
        self.repository = repository
        self.conversations = conversations
        self.management = management
        self.defaults = defaults
    }

    public var body: some View {
        ThreadBrowser(accountID: accountID, repository: repository,
                      conversations: conversations, management: management, defaults: defaults)
            .id(accountID)
    }
}

private struct ThreadBrowser: View {
    let accountID: String
    let repository: any CommunityThreadRepository
    let conversations: any ThreadConversationRepository
    let management: any ThreadManagementRepository
    let defaults: UserDefaults

    @FocusState private var resultsFocused: Bool
    @State private var query = ""
    @State private var filter = "all"
    @State private var threads: [CommunityThread] = []
    @State private var next: String?
    @State private var selection: String?
    @State private var reload = 0
    @State private var loading = false
    @State private var failure: String?
    @State private var creating = false
    @State private var loadedSearch: [String]?
    @State private var pendingSelection: [String]?

    private var search: [String] { [query, filter] }

    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                HStack {
                    Text("스레드").umcTypography(.title1Bold)
                    Spacer()
                    Button("새 스레드", systemImage: "plus") { creating = true }
                        .labelStyle(.iconOnly)
                }
                ThreadSearchField(query: $query, selectResult: selectFirst)
                    .frame(height: 28)
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
                    if query.isEmpty && threads.contains(where: \.isPinned) {
                        Section("고정") { rows(threads.filter(\.isPinned)) }
                        Section("전체") { rows(threads.filter { !$0.isPinned }) }
                    } else {
                        rows(threads)
                    }
                }
                .frame(minHeight: 0, maxHeight: .infinity)
                .focused($resultsFocused)
                .accessibilityLabel("스레드 검색 결과")
                if let next {
                    Button("더 보기") { Task { await load(offset: next) } }.disabled(loading)
                }
            }
            .padding(UMCSpacing.value16)
            .frame(minWidth: 220, idealWidth: 344, maxWidth: 400,
                   minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            if let item = threads.first(where: { $0.id == selection }) {
                ThreadDestination(accountID: accountID, thread: item, detached: false,
                                  repository: repository, conversations: conversations,
                                  management: management, defaults: defaults)
                    .id(item.id)
            } else {
                ContentUnavailableView(threads.isEmpty && !loading && failure == nil
                    ? "표시할 스레드가 없어요" : "스레드를 선택하세요",
                    systemImage: "bubble.left.and.bubble.right")
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            }
        }
        .communitySplitContent()
        .task(id: search + [String(reload)]) {
            if loadedSearch != search {
                threads = []
                selection = nil
                next = nil
            }
            await load(offset: nil)
        }
        .onReceive(NotificationCenter.default.publisher(for: .threadBrowserChanged)) { notice in
            guard let key = notice.object as? ThreadWindowKey, key.accountID == accountID else { return }
            if notice.userInfo?["exit"] as? Bool == true && selection == key.threadID {
                selection = nil
            }
            reload += 1
        }
        .sheet(isPresented: $creating) {
            ThreadComposer(repository: repository) { item in
                filter = "all"
                query = ""
                threads.removeAll { $0.id == item.id }
                threads.insert(item, at: 0)
                loadedSearch = search
                selection = item.id
                creating = false
                reload += 1
            }
        }
    }

    private func rows(_ items: [CommunityThread]) -> some View {
        ForEach(items) { item in
            HStack(alignment: .top) {
                Text(item.icon).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title).font(.headline)
                    if item.membershipState == "KICKED" {
                        Text("내보내짐 · 확인 필요").font(.caption)
                    } else if let description = item.description, !description.isEmpty {
                        Text(description).lineLimit(2).font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if item.isPinned { Image(systemName: "pin.fill").accessibilityLabel("고정됨") }
                if item.unread != "0" {
                    Text(item.unread).accessibilityLabel("안 읽은 메시지 " + item.unread)
                }
            }.padding(.vertical, 4).tag(item.id)
        }
    }

    private func selectFirst() {
        guard loadedSearch == search && !loading else { pendingSelection = search; return }
        guard let id = threads.first?.id else { return }
        selection = id
        resultsFocused = true
    }

    @MainActor private func load(offset: String?) async {
        let expected = search
        let generation = reload
        loading = true
        failure = nil
        defer {
            if !Task.isCancelled, expected == search, generation == reload { loading = false }
        }
        do {
            if !query.isEmpty, offset == nil { try await Task.sleep(for: .milliseconds(200)) }
            let page = try await repository.threads(query: String(query.unicodeScalars.prefix(80)),
                                                    filter: filter, offset: offset)
            guard !Task.isCancelled, expected == search, generation == reload else { return }
            let previous = offset == nil ? [] : threads
            var ids = Set(previous.map(\.id))
            threads = previous + page.values.filter { ids.insert($0.id).inserted }
            next = page.cursor
            loadedSearch = expected
            if pendingSelection == expected, let first = threads.first {
                selection = first.id
                resultsFocused = true
            }
            pendingSelection = nil
        } catch {
            if !Task.isCancelled, expected == search, generation == reload {
                failure = error.localizedDescription
            }
        }
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

extension View {
    /// A native split pane next to the app rail can extend beneath the unified window toolbar.
    func communitySplitContent() -> some View {
        frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity,
              alignment: .topLeading)
            .padding(.top, UMCSpacing.value16)
    }
}
