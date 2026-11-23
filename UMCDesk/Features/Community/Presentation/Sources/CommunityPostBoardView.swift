//
//  CommunityPostBoardView.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import CommunityDomain
import CoreDesignSystem
import SwiftUI

public struct CommunityPostBoardView: View {
    private let accountID: String
    private let repository: any CommunityPostRepository

    public init(accountID: String, repository: any CommunityPostRepository) {
        self.accountID = accountID
        self.repository = repository
    }

    public var body: some View {
        Board(accountID: accountID, repository: repository).id(accountID)
    }
}

private struct Board: View {
    let accountID: String
    let repository: any CommunityPostRepository
    @State private var query = ""
    @State private var scope = CommunityPostScope.all
    @State private var category: CommunityPostCategory?
    @State private var rows: [CommunityPost] = []
    @State private var selected: String?
    @State private var next: String?
    @State private var failure: String?
    @State private var loading = true
    @State private var creating = false
    @State private var reload = 0
    @State private var pendingSearch: [String]?
    @State private var loadedRequest: [String]?
    @FocusState private var resultsFocused: Bool

    private var keyword: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }
    private var request: [String] { [keyword, scope.rawValue, category?.rawValue ?? ""] }
    private var version: [String] { request + [String(reload)] }

    var body: some View {
        HSplitView {
            VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                HStack {
                    Text("커뮤니티").umcTypography(.title1Bold)
                    Spacer()
                    Button("새 글", systemImage: "square.and.pencil") { creating = true }
                }
                TextField("제목·본문 검색", text: $query)
                    .accessibilityLabel("게시글 검색")
                    .onSubmit(selectResult)
                if keyword.isEmpty {
                    Picker("게시글 범위", selection: $scope) {
                        ForEach(CommunityPostScope.allCases, id: \.self) { scope in
                            Text(scope.label).tag(scope)
                        }
                    }
                    if scope == .all {
                        Picker("카테고리", selection: $category) {
                            Text("전체").tag(nil as CommunityPostCategory?)
                            ForEach(CommunityPostCategory.allCases, id: \.self) {
                                Text($0.label).tag(Optional($0))
                            }
                        }
                    }
                } else {
                    Text("전체 게시글 검색 결과").font(.caption).foregroundStyle(.secondary)
                }
                if let failure {
                    Text(failure)
                    Button("목록 다시 불러오기") { reload += 1 }
                }
                if loading { ProgressView("게시글 불러오는 중").controlSize(.small) }
                List(rows, selection: $selected) { row in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(CommunityPostCategory(rawValue: row.category)?.label ?? row.category)
                            .font(.caption).foregroundStyle(UMCColor.Semantic.textBrandDefault)
                        Text(row.title).font(.headline).lineLimit(2)
                        Text(row.content).lineLimit(1).foregroundStyle(.secondary)
                        HStack {
                            Text(row.author ?? "게시글")
                            Spacer()
                            Label(row.likeCount, systemImage: "heart")
                            Label(row.commentCount, systemImage: "bubble.right")
                        }.font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 6).tag(row.id)
                        .accessibilityElement(children: .combine)
                }
                .frame(minHeight: 0, maxHeight: .infinity)
                .overlay {
                    if !loading && rows.isEmpty && failure == nil {
                        ContentUnavailableView(
                            keyword.isEmpty ? "게시글이 없어요" : "검색 결과가 없어요",
                            systemImage: "text.bubble")
                    }
                }
                .focused($resultsFocused).accessibilityLabel("게시글 목록")
                if let next {
                    Button("더 보기") { Task { await load(page: next) } }.disabled(loading)
                }
            }
            .padding(UMCSpacing.value16)
            .frame(minWidth: 220, idealWidth: 320, maxWidth: 420,
                   minHeight: 0, maxHeight: .infinity, alignment: .topLeading)
            if let selected {
                CommunityPostDetailView(id: selected, accountID: accountID, repository: repository)
                {
                    deleted in
                    if deleted { self.selected = nil }
                    reload += 1
                }.id(selected)
                    .onExitCommand { resultsFocused = true }
            } else {
                ContentUnavailableView("게시글을 선택하세요", systemImage: "text.bubble")
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            }
        }
        .communitySplitContent()
        .background(UMCColor.Custom.backgroundDefault)
        .task(id: version) {
            if loadedRequest != request {
                selected = nil
                rows = []
                next = nil
            }
            await load(page: "0")
        }
        .sheet(isPresented: $creating, onDismiss: { resultsFocused = true }) {
            CommunityPostEditor(existing: nil, repository: repository) { created in
                query = ""
                scope = .all
                category = nil
                loadedRequest = request
                rows.insert(created, at: 0)
                selected = created.id
                creating = false
                reload += 1
            }
        }
    }

    private func selectResult() {
        guard loadedRequest == request && !loading else {
            pendingSearch = request
            return
        }
        if let first = rows.first {
            selected = first.id
            resultsFocused = true
        }
    }

    @MainActor private func load(page: String) async {
        let expected = version
        loading = true
        failure = nil
        defer { if !Task.isCancelled && expected == version { loading = false } }
        do {
            if !keyword.isEmpty && page == "0" { try await Task.sleep(for: .milliseconds(200)) }
            let result = try await repository.posts(
                scope: scope, category: category,
                keyword: keyword, page: page)
            guard !Task.isCancelled, expected == version else { return }
            let previous = page == "0" ? [] : rows
            var ids = Set(previous.map(\.id))
            rows = previous + result.values.filter { ids.insert($0.id).inserted }
            next = result.cursor
            loadedRequest = request
            if pendingSearch == request, let first = rows.first {
                selected = first.id
                resultsFocused = true
            }
            pendingSearch = nil
        } catch {
            if !Task.isCancelled && expected == version { failure = error.localizedDescription }
        }
    }
}

extension CommunityPostCategory {
    var label: String {
        switch self {
        case .free: "자유"
        case .question: "질문"
        case .information: "정보"
        case .habit: "취미"
        case .lightning: "번개"
        }
    }
}

extension CommunityPostScope {
    fileprivate var label: String {
        switch self {
        case .all: "전체 게시글"
        case .my: "내가 쓴 글"
        case .commented: "댓글 단 글"
        case .scrapped: "스크랩한 글"
        }
    }
}
