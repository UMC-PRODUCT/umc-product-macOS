//
//  ProjectWorkspacePresentation.swift
//  ProjectWorkspacePresentation
//
//  Created by euijjang97 on 10/6/26.
//

import CoreDesignSystem
import Foundation
import ProjectWorkspaceDomain
import SwiftUI

public struct ProjectWorkspaceView: View {
    private let accountID: String
    private let loadProjects: @Sendable () async throws -> [WorkspaceProject]
    private let loadGitHub: WorkspaceGitHubLoader?
    private let openMatching: (() -> Void)?

    public init(
        accountID: String,
        loadProjects: @escaping @Sendable () async throws -> [WorkspaceProject],
        loadGitHub: WorkspaceGitHubLoader? = nil,
        openMatching: (() -> Void)? = nil
    ) {
        self.accountID = accountID
        self.loadProjects = loadProjects
        self.loadGitHub = loadGitHub
        self.openMatching = openMatching
    }

    // MARK: - Body

    public var body: some View {
        WorkspaceDirectory(accountID: accountID, loadProjects: loadProjects,
                           loadGitHub: loadGitHub, openMatching: openMatching)
            .id(accountID)
    }
}

struct WorkspaceDirectory: View {
    let accountID: String
    let loadProjects: @Sendable () async throws -> [WorkspaceProject]
    let loadGitHub: WorkspaceGitHubLoader?
    let openMatching: (() -> Void)?

    @AppStorage private var recentProjectID: String
    @State private var directory: WorkspaceDirectoryModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.appearsActive) private var appearsActive

    init(
        accountID: String, loadProjects: @escaping @Sendable () async throws -> [WorkspaceProject],
        loadGitHub: WorkspaceGitHubLoader?, openMatching: (() -> Void)?,
        directory: WorkspaceDirectoryModel = WorkspaceDirectoryModel()
    ) {
        _directory = State(initialValue: directory)
        self.accountID = accountID
        self.loadProjects = loadProjects
        self.loadGitHub = loadGitHub
        self.openMatching = openMatching
        let key = "umc.project-workspace.recent." + Data(accountID.utf8).base64EncodedString()
        _recentProjectID = AppStorage(wrappedValue: "", key)
    }

    // MARK: - Body

    var body: some View {
        @Bindable var directory = directory
        let revision = directory.revision
        return Group {
            if let selected = directory.selected {
                VStack(spacing: 0) {
                    if directory.failed {
                        HStack {
                            Text("참여 상태를 다시 확인하지 못했어요.")
                            Button("다시 시도", action: directory.requestRefresh)
                        }
                    }
                    ProjectWorkspaceDetail(
                        project: selected, accountID: accountID, sheet: $directory.sheet,
                        loadGitHub: loadGitHub, openMatching: openMatching,
                        refreshMembership: directory.requestRefresh, close: directory.close
                    )
                    .id(selected.id)
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: UMCSpacing.value24) {
                        HStack {
                            Spacer()
                            WorkspaceTools(description: "참여 중인 프로젝트와 작업을 빠르게 찾으세요.") { dismiss in
                                Button("프로젝트 목록", action: dismiss)
                                if let openMatching {
                                    Button("매칭에서 찾기") {
                                        dismiss()
                                        openMatching()
                                    }
                                }
                                if let recent = directory.projects?.first(where: {
                                    $0.id == recentProjectID
                                }) {
                                    Button("이어서 작업 · \(recent.name)") {
                                        dismiss()
                                        directory.open(recent)
                                    }
                                }
                            }
                        }
                        ViewThatFits(in: .horizontal) {
                            HStack {
                                heading
                                Spacer()
                                matchingButton
                            }
                            VStack(alignment: .leading) { heading; matchingButton }
                        }
                        if directory.failed {
                            ContentUnavailableView {
                                Label("참여 프로젝트를 확인하지 못했어요", systemImage: "wifi.exclamationmark")
                            } actions: {
                                Button("다시 시도", action: directory.requestRefresh)
                            }
                        } else if directory.isOpening {
                            ProgressView("프로젝트 참여 상태 확인 중")
                        } else if let projects = directory.projects {
                            if projects.isEmpty {
                                ContentUnavailableView {
                                    Label("매칭에서 만난 팀과 바로 시작하세요", systemImage: "person.2")
                                } description: {
                                    Text("합류한 프로젝트는 이름과 소개를 다시 입력하지 않아도 됩니다.")
                                } actions: {
                                    if let openMatching {
                                        Button("매칭에서 프로젝트 찾기", action: openMatching)
                                    }
                                }
                            } else {
                                VStack(spacing: 0) {
                                    ForEach(projects) { project in
                                        WorkspaceDirectoryRow(
                                            project: project, accountID: accountID
                                        ) {
                                            directory.open(project)
                                        }
                                        if project.id != projects.last?.id { Divider() }
                                    }
                                }.workspaceCard()
                            }
                            Text("매칭은 팀 구성과 지원을, 프로젝트는 내 작업과 자료를 관리합니다.")
                                .umcTypography(.bodyRegular).foregroundStyle(.secondary)
                        } else {
                            ProgressView("참여 프로젝트 확인 중")
                        }
                    }
                    .padding(UMCSpacing.value32)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(UMCColor.Custom.backgroundDefault)
        .task(id: revision) {
            await directory.refresh(revision: revision, load: loadProjects)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { directory.requestRefresh() }
        }
        .onChange(of: appearsActive) { _, active in
            if active { directory.requestRefresh() }
        }
        .onChange(of: directory.selected?.id) { _, id in
            if let id { recentProjectID = id }
        }
    }

    private var heading: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value4) {
            Text("프로젝트").umcTypography(.largeTitle3Bold)
            Text("지금 작업하는 프로젝트를 한곳에서 열어 보세요.")
                .umcTypography(.headlineRegular).foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var matchingButton: some View {
        if let openMatching {
            Button("매칭에서 찾기", systemImage: "person.2", action: openMatching)
        }
    }
}

private struct WorkspaceDirectoryRow: View {
    let project: WorkspaceProject
    let select: () -> Void
    @AppStorage private var data: Data

    init(project: WorkspaceProject, accountID: String, select: @escaping () -> Void) {
        self.project = project
        self.select = select
        _data = AppStorage(wrappedValue: Data(), WorkspaceRecord.key(
            accountID: accountID, projectID: project.id
        ))
    }

    // MARK: - Body

    var body: some View {
        let record = try? JSONDecoder().decode(WorkspaceRecord.self, from: data)
        let resources = WorkspaceResource.allCases.filter { record?.link(for: $0) != nil }
        Button(action: select) {
            HStack(spacing: UMCSpacing.value16) {
                Image(systemName: "square.grid.2x2")
                    .foregroundStyle(UMCColor.Semantic.textBrandDefault)
                VStack(alignment: .leading) {
                    Text(project.name).umcTypography(.title4Bold)
                    Text("매칭 연결").umcTypography(.bodyRegular).foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing) {
                    Text(resources.isEmpty ? "연결 자료 없음" :
                            resources.map(\.rawValue).joined(separator: " · "))
                    if let date = record?.lastOpened {
                        Text(date, format: .relative(presentation: .named))
                    }
                }.umcTypography(.bodyRegular).foregroundStyle(.secondary)
                Image(systemName: "chevron.right")
            }
            .padding(UMCSpacing.value16)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityHint("프로젝트 작업과 자료 열기")
    }
}

extension View {
    func workspaceCard() -> some View {
        background(UMCColor.Custom.backgroundSurface,
                   in: RoundedRectangle(cornerRadius: UMCRadius.value12))
            .overlay {
                RoundedRectangle(cornerRadius: UMCRadius.value12)
                    .strokeBorder(UMCColor.Semantic.borderNeutralWeak200)
                    .allowsHitTesting(false)
            }
    }
}
