//
//  ProjectWorkspaceDetail.swift
//  ProjectWorkspacePresentation
//
//  Created by euijjang97 on 11/23/26.
//

import CoreUIComponents
import CoreDesignSystem
import Foundation
import ProjectWorkspaceDomain
import SwiftUI

private enum WorkFilter: String, CaseIterable, Identifiable {
    case mine = "내 작업"
    case all = "전체"
    case done = "완료"

    var id: Self { self }

    var toolTitle: String {
        switch self {
        case .mine: "내 작업"
        case .all: "전체 작업"
        case .done: "완료한 작업"
        }
    }
}

enum WorkspaceSheet: Identifiable {
    case addTodo, connections, team, todo(UUID), github(WorkspaceGitHubItem)

    var id: String {
        switch self {
        case .addTodo: "add"
        case .connections: "connections"
        case .team: "team"
        case .todo(let id): id.uuidString
        case .github(let item): "github-" + item.id
        }
    }
}

struct ProjectWorkspaceDetail: View {
    let project: WorkspaceProject
    let loadGitHub: WorkspaceGitHubLoader?
    let teamContent: ((String) -> AnyView)?
    let membershipFailed: Bool
    let refreshMembership: () -> Void
    let close: () -> Void
    @AppStorage private var data: Data
    @State private var filter = WorkFilter.mine
    @Binding private var sheet: WorkspaceSheet?
    @State private var showsDeleteConfirmation = false
    @State private var refreshID: UUID?
    @State private var githubError = false
    @State private var storageError = false

    init(project: WorkspaceProject, accountID: String, sheet: Binding<WorkspaceSheet?>,
         loadGitHub: WorkspaceGitHubLoader?,
         teamContent: ((String) -> AnyView)?, membershipFailed: Bool, refreshMembership: @escaping () -> Void,
         close: @escaping () -> Void) {
        _sheet = sheet
        self.project = project
        self.loadGitHub = loadGitHub
        self.teamContent = teamContent
        self.membershipFailed = membershipFailed
        self.refreshMembership = refreshMembership
        self.close = close
        _data = AppStorage(wrappedValue: Data(), WorkspaceRecord.key(
            accountID: accountID, projectID: project.id
        ))
    }

    private func readRecord() throws -> WorkspaceRecord {
        if data.isEmpty { return WorkspaceRecord() }
        return try JSONDecoder().decode(WorkspaceRecord.self, from: data)
    }

    // MARK: - Body

    var body: some View {
        let record = try? readRecord()
        ScrollView {
            VStack(alignment: .leading, spacing: UMCSpacing.value24) {
                Button("프로젝트 목록", systemImage: "chevron.left", action: close)
                if let record {
                    ViewThatFits(in: .horizontal) {
                        HStack { title; Spacer(); actions }
                        VStack(alignment: .leading) { title; actions }
                    }
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: UMCSpacing.value24) {
                            workList(record).frame(minWidth: 400)
                            resourcePanel(record).frame(width: 238)
                        }
                        VStack(alignment: .leading, spacing: UMCSpacing.value24) {
                            workList(record)
                            resourcePanel(record)
                        }
                    }
                } else {
                    ContentUnavailableView("개인 기록을 읽을 수 없어요",
                                           systemImage: "exclamationmark.triangle",
                                           description: Text("프로젝트 도구에서 개인 기록을 초기화할 수 있습니다."))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(UMCSpacing.value32)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if membershipFailed {
                HStack {
                    Text("참여 상태를 다시 확인하지 못했어요.")
                    Button("다시 시도", action: refreshMembership)
                }
            }
        }
        .umcTabTools("프로젝트 도구") { dismiss in
            if record != nil {
                Button("한 줄 할 일 추가", systemImage: "plus") {
                    dismiss()
                    sheet = .addTodo
                }.buttonStyle(UMCToolPrimaryButtonStyle())
                Divider()
                UMCToolGroupHeading("작업 보기")
                ForEach(WorkFilter.allCases) { choice in
                    Button {
                        filter = choice
                    } label: {
                        HStack {
                            Text(choice.toolTitle)
                            Spacer()
                            if filter == choice { Image(systemName: "checkmark") }
                        }
                    }
                    .accessibilityAddTraits(filter == choice ? .isSelected : [])
                }
                Divider()
                UMCToolGroupHeading("연결과 팀")
                Button("GitHub · Figma 연결 관리", systemImage: "link") {
                    dismiss()
                    sheet = .connections
                }
                if teamContent != nil, !membershipFailed {
                    Button("매칭 팀 구성 보기", systemImage: "person.2") {
                        dismiss()
                        sheet = .team
                    }
                }
                Divider()
            }
            Button("참여 상태 새로고침", systemImage: "arrow.clockwise") {
                dismiss()
                refreshMembership()
            }
            if !data.isEmpty {
                Divider()
                Button("개인 기록 삭제", systemImage: "trash", role: .destructive) {
                    dismiss()
                    showsDeleteConfirmation = true
                }
            }
        }
        .onAppear { _ = change { $0.lastOpened = Date() } }
        .sheet(item: $sheet) { destination in
            sheetContent(destination, record: record ?? WorkspaceRecord())
                .padding(UMCSpacing.value24)
                .frame(minWidth: 340, idealWidth: 420)
        }
        .task(id: refreshID) {
            guard refreshID != nil, let repo = record?.link(for: .github), let loadGitHub else {
                return
            }
            do {
                let items = try await loadGitHub(repo)
                try Task.checkCancellation()
                _ = change {
                    guard $0.link(for: .github) == repo else { return }
                    $0.githubItems = items
                    $0.githubUpdatedAt = Date()
                }
            } catch {
                if !Task.isCancelled { githubError = true }
            }
            if !Task.isCancelled { refreshID = nil }
        }
        .alert("이 프로젝트의 개인 기록을 삭제할까요?", isPresented: $showsDeleteConfirmation) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                refreshID = nil
                data = Data()
                close()
            }
        } message: {
            Text("이 Mac에 저장한 할 일과 연결 자료를 삭제합니다. 매칭 팀은 유지됩니다.")
        }
        .alert("개인 기록을 저장하지 못했어요", isPresented: $storageError) {
            Button("확인") {}
        }
    }

    private var title: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value4) {
            Text(project.name).umcTypography(.largeTitle3Bold)
            Text("매칭 연결").umcTypography(.headlineRegular).foregroundStyle(.secondary)
        }
    }

    private var actions: some View {
        HStack {
            Button("연결 관리") { sheet = .connections }
            Button("할 일", systemImage: "plus") { sheet = .addTodo }
                .buttonStyle(.borderedProminent)
                .tint(UMCColor.Semantic.textBrandDefault)
        }.controlSize(.large)
    }

    private func workList(_ record: WorkspaceRecord) -> some View {
        let todos = record.todos.filter { filter == .all || $0.completed == (filter == .done) }
        let imported = record.githubItems ?? []
        let github = imported.filter { filter == .all || (filter == .done && $0.completed) }
        return VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            Picker("작업 보기", selection: $filter) {
                ForEach(WorkFilter.allCases) { choice in
                    Text("\(choice.rawValue) \(count(choice, record: record))").tag(choice)
                }
            }.pickerStyle(.segmented).labelsHidden()
            VStack(alignment: .leading, spacing: 0) {
                Text("최근 업데이트").umcTypography(.bodyRegular).foregroundStyle(.secondary)
                    .padding(UMCSpacing.value12)
                Divider()
                if todos.isEmpty && github.isEmpty {
                    ContentUnavailableView("표시할 작업이 없습니다", systemImage: "checklist",
                                           description: Text("할 일을 추가하거나 연결 자료를 확인하세요."))
                }
                ForEach(todos) { todo in
                    workButton(title: todo.title, subtitle: "내가 추가한 할 일",
                               status: todo.completed ? "완료" : "할 일",
                               symbol: todo.completed ? "checkmark.circle" : "circle") {
                        sheet = .todo(todo.id)
                    }
                }
                ForEach(github) { item in
                    workButton(title: item.title, subtitle: githubLabel(item),
                               status: item.completed ? "닫힘" : "열림",
                               symbol: item.isPullRequest ? "arrow.triangle.branch" : "number") {
                        sheet = .github(item)
                    }
                }
            }.workspaceCard()
            if record.link(for: .github) != nil {
                Text("GitHub 작업의 상태는 원본에서 변경할 수 있어요.")
                    .umcTypography(.bodyRegular).foregroundStyle(.secondary)
            }
        }
    }

    private func count(_ choice: WorkFilter, record: WorkspaceRecord) -> Int {
        let imported = record.githubItems ?? []
        switch choice {
        case .mine: return record.todos.filter { !$0.completed }.count
        case .all: return record.todos.count + imported.count
        case .done:
            return record.todos.filter(\.completed).count + imported.filter(\.completed).count
        }
    }

    private func workButton(title: String, subtitle: String, status: String, symbol: String,
                            action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: UMCSpacing.value12) {
                Image(systemName: symbol).foregroundStyle(UMCColor.Semantic.textBrandDefault)
                VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                    Text(title).umcTypography(.headlineBold)
                    Text(subtitle).umcTypography(.bodyRegular).foregroundStyle(.secondary)
                }
                Spacer()
                Text(status).umcTypography(.bodyRegular)
            }.padding(UMCSpacing.value16).contentShape(.rect)
        }.buttonStyle(.plain)
    }

    private func resourcePanel(_ record: WorkspaceRecord) -> some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            Text("자료 바로가기").umcTypography(.title4Bold)
            ForEach(WorkspaceResource.allCases) { resource in
                if let url = record.link(for: resource) {
                    Link(destination: url) {
                        Label(resource == .github ? "저장소 열기" : "디자인 열기",
                              systemImage: "arrow.up.right.square")
                    }
                } else {
                    Button("\(resource.rawValue) 연결") { sheet = .connections }
                }
            }
            if record.link(for: .github) != nil && loadGitHub != nil {
                Divider()
                Button(refreshID == nil ? "공개 작업 불러오기" : "불러오는 중…") {
                    githubError = false
                    filter = .all
                    refreshID = UUID()
                }.disabled(refreshID != nil)
                if githubError {
                    Text("GitHub를 불러오지 못했어요. 공개 저장소인지 확인하고 다시 시도하세요.")
                        .foregroundStyle(.secondary)
                }
                if let updated = record.githubUpdatedAt {
                    Text("최근 작업 30개까지 · \(updated.formatted())")
                        .umcTypography(.bodyRegular).foregroundStyle(.secondary)
                }
            }
            if teamContent != nil, !membershipFailed {
                Divider()
                Button("매칭 팀 구성 보기", systemImage: "person.2") { sheet = .team }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(UMCSpacing.value16).workspaceCard()
    }

    @ViewBuilder
    private func sheetContent(
        _ destination: WorkspaceSheet, record: WorkspaceRecord
    ) -> some View {
        switch destination {
        case .team:
            if !membershipFailed {
                teamContent?(project.id)
            } else {
                Button("닫기") { sheet = nil }
            }
        case .addTodo:
            WorkspaceTodoForm { input in
                if change({ $0.addTodo(input) }) { filter = .mine; sheet = nil }
            }
        case .connections:
            WorkspaceConnectionsForm(record: record) { original, resources in
                let switched = resources[WorkspaceResource.github.rawValue] !=
                    original[WorkspaceResource.github.rawValue]
                if change({ $0.updateLinks(original: original, edited: resources) }) {
                    if switched { refreshID = nil; githubError = false }
                    sheet = nil
                }
            }
        case .todo(let id):
            if let todo = record.todos.first(where: { $0.id == id }) {
                VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                    Text(todo.title).umcTypography(.title1Bold).textSelection(.enabled)
                    Text("내가 추가한 할 일 · \(todo.createdAt.formatted())")
                    HStack {
                        Button("닫기") { sheet = nil }.keyboardShortcut(.cancelAction)
                        Button(todo.completed ? "다시 할 일로" : "완료하기") {
                            if change({
                                if let index = $0.todos.firstIndex(where: { $0.id == id }) {
                                    $0.todos[index].completed = !todo.completed
                                }
                            }) { sheet = nil }
                        }.keyboardShortcut(.defaultAction)
                    }
                }
            } else {
                Button("목록으로 돌아가기") { sheet = nil }
            }
        case .github(let item):
            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                Text(item.title).umcTypography(.title1Bold)
                Text(githubLabel(item)).foregroundStyle(.secondary)
                if !item.summary.isEmpty {
                    ScrollView { Text(item.summary).textSelection(.enabled) }.frame(maxHeight: 220)
                }
                if let repo = record.link(for: .github) {
                    Link("GitHub에서 열기", destination: repo
                        .appending(path: item.isPullRequest ? "pull" : "issues")
                        .appending(path: item.id))
                }
                Button("닫기") { sheet = nil }.keyboardShortcut(.cancelAction)
            }
        }
    }

    private func githubLabel(_ item: WorkspaceGitHubItem) -> String {
        "GitHub \(item.isPullRequest ? "PR" : "이슈") #\(item.id)"
    }

    private func change(_ update: (inout WorkspaceRecord) -> Void) -> Bool {
        do {
            var record = try readRecord()
            update(&record)
            data = try JSONEncoder().encode(record)
            return true
        } catch {
            storageError = true
            return false
        }
    }
}
