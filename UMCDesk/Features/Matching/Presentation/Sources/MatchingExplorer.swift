//
//  MatchingExplorer.swift
//  MatchingPresentation
//
//  Created by euijjang97 on 11/22/26.
//

import AppKit
import CoreDesignSystem
import CoreUIComponents
import MatchingDomain
import SwiftUI
import UMCFoundation

@MainActor
@Observable
final class MatchingExplorerState {
    struct Filters: Equatable {
        var keyword = ""
        var part: String?
        var quotaStatus: String?
        var schoolId: String?
    }

    struct Query: Equatable {
        let chapterId: String?
        let filters: Filters
        let page: Int
        let attempt: Int
    }

    var loadedQuery: Query?
    var returnProjectId: String?
    var listOrigin: CGPoint?
    var filters = Filters()
    var page = 0
    var attempt = 0
    var projects = MatchingRequest<MatchingProjectPage>()
}

struct MatchingExplorer: View {
    let repository: any MatchingUseCase
    let gisuId: String
    let chapterId: String?
    let schools: [MatchingFilterOption]
    let select: (MatchingProject) -> Void

    @Bindable var state: MatchingExplorerState

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value24) {
            HStack {
                UMCSearchField(
                    AppLocalization.string("프로젝트 이름 검색"), text: $state.filters.keyword,
                    accessibilityHint: AppLocalization.string("프로젝트 이름을 입력해 검색하세요.")
                )
                .frame(maxWidth: 220)
                MatchingFilterPickers(state: state, schools: schools)
                Spacer()
            }
            .labelsHidden()
            .fixedSize(horizontal: false, vertical: true)
            MatchingRequestView(request: state.projects, retry: { state.attempt += 1 }) { result in
                if result.content.isEmpty {
                    ContentUnavailableView("프로젝트가 없어요", systemImage: "magnifyingglass",
                        description: Text("다른 검색어나 모집 조건을 선택해 보세요."))
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 315, maximum: 460), spacing: UMCSpacing.value24)],
                              alignment: .leading, spacing: UMCSpacing.value24) {
                        ForEach(result.content, id: \.id) { project in
                            MatchingProjectCard(
                                project: project, restoresFocus: state.returnProjectId == project.id,
                                listOrigin: state.listOrigin,
                                didRestore: {
                                    state.returnProjectId = nil
                                }, open: { origin in
                                    state.listOrigin = origin
                                    select(project)
                                }
                            )
                        }
                    }
                }
                HStack {
                    let start = state.page * 3 + 1
                    let end = state.page * 3 + result.content.count
                    if let count = result.totalElements, end >= start {
                        Text("\(start)–\(end) / \(count)개 프로젝트").umcTypography(.bodyRegular)
                    } else {
                        Text("\(state.page + 1)페이지").umcTypography(.bodyRegular)
                    }
                    Spacer()
                    if state.page > 0 {
                        Button("이전 페이지") { state.page -= 1 }
                            .buttonStyle(MatchingActionStyle(appearance: .secondary))
                    }
                    Button("다음 페이지") { state.page += 1 }
                        .buttonStyle(MatchingActionStyle(appearance: .secondary))
                        .disabled(!result.hasNext)
                }
            }
        }
        .onChange(of: state.filters) { state.page = 0 }
        .onChange(of: chapterId) { state.page = 0 }
        .task(id: MatchingExplorerState.Query(chapterId: chapterId, filters: state.filters, page: state.page, attempt: state.attempt)) {
            let query = MatchingExplorerState.Query(chapterId: chapterId, filters: state.filters,
                                                    page: state.page, attempt: state.attempt)
            if state.loadedQuery == query, case .loaded = state.projects.phase { return }
            await state.projects.load {
                if !state.filters.keyword.isEmpty { try await Task.sleep(for: .milliseconds(250)) }
                return try await repository.projects(
                    gisuId: gisuId, keyword: state.filters.keyword.isEmpty ? nil : state.filters.keyword,
                    page: state.page, part: state.filters.part, quotaStatus: state.filters.quotaStatus,
                    schoolId: state.filters.schoolId, chapterId: chapterId
                )
            }
            if !Task.isCancelled { state.loadedQuery = query }
        }
    }
}

struct MatchingFilterPickers: View {
    @Bindable var state: MatchingExplorerState
    let schools: [MatchingFilterOption]

    var body: some View {
        Picker("학교", selection: $state.filters.schoolId) {
            Text("학교 전체").tag(String?.none)
            ForEach(schools) { Text($0.name).tag(Optional($0.id)) }
        }
        .accessibilityLabel("학교 필터")
        Picker("파트", selection: $state.filters.part) {
            Text("파트 전체").tag(String?.none)
            ForEach(["DESIGN", "MOBILE_PRODUCT_ENGINEER", "WEB_PRODUCT_ENGINEER",
                     "WEB", "IOS", "ANDROID", "NODEJS", "SPRINGBOOT"], id: \.self) {
                Text(MatchingLabel.part($0)).tag(Optional($0))
            }
        }
        .accessibilityLabel("파트 필터")
        Picker("모집 상태", selection: $state.filters.quotaStatus) {
            Text("모집 상태 전체").tag(String?.none)
            Text("모집 중").tag(Optional("RECRUITING"))
            Text("모집 완료").tag(Optional("COMPLETED"))
        }
        .accessibilityLabel("모집 상태 필터")
    }
}

struct MatchingProjectCard: View {
    let project: MatchingProject
    let restoresFocus: Bool
    let listOrigin: CGPoint?
    let didRestore: () -> Void
    let open: (CGPoint?) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            if let imageURL = MatchingLabel.webURL(project.thumbnailImageUrl) {
                AsyncImage(url: imageURL) { image in
                    image.resizable().scaledToFill()
                } placeholder: { Color.clear }
                .frame(maxWidth: .infinity).frame(height: 90).clipped()
                .accessibilityHidden(true)
            }
            HStack {
                Text(project.name).umcTypography(.title2Bold)
                if let status = project.partQuotaStatus {
                    MatchingBadge(text: MatchingLabel.status(status))
                }
            }
            if let description = project.description { Text(description).umcTypography(.headlineRegular) }
            ViewThatFits(in: .horizontal) {
                HStack { quotas }
                VStack(alignment: .leading) { quotas }
            }
            Divider()
            HStack {
                Text(ownerName).umcTypography(.bodyRegular).foregroundStyle(.secondary)
                Spacer()
                ProjectPostingButton(restoresFocus: restoresFocus, listOrigin: listOrigin,
                                     didRestore: didRestore, open: open)
                    .fixedSize()
            }
        }
        .matchingPanel()
    }

    private var quotas: some View {
        ForEach(project.partQuotas, id: \.part) { MatchingQuotaView(quota: $0) }
    }

    private var ownerName: String {
        [project.productOwner?.nickname ?? project.productOwner?.name, project.productOwner?.schoolName]
            .compactMap { $0 }.joined(separator: " · ")
    }
}

struct MatchingApplicationRoute: Identifiable {
    let id: String
    let projectId: String
    let projectName: String
    let roundId: String?
    let isDraft: Bool
}

private struct ProjectPostingButton: NSViewRepresentable {
    let restoresFocus: Bool
    let listOrigin: CGPoint?
    let didRestore: () -> Void
    let open: (CGPoint?) -> Void

    final class PostingButton: NSButton {
        var open: ((CGPoint?) -> Void)?
        var listOrigin: CGPoint?
        var didRestore: (() -> Void)?
        var restoresFocus = false
        override var acceptsFirstResponder: Bool { true }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            restoreIfNeeded()
        }

        func restoreIfNeeded() {
            guard restoresFocus, window != nil else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self, restoresFocus, let window, window.makeFirstResponder(self)
                else { return }
                restoresFocus = false
                if let origin = listOrigin, let scroll = enclosingScrollView {
                    window.contentView?.layoutSubtreeIfNeeded()
                    let clip = scroll.contentView
                    let target = clip.constrainBoundsRect(CGRect(origin: origin, size: clip.bounds.size))
                    clip.scroll(to: target.origin)
                    scroll.reflectScrolledClipView(clip)
                }
                didRestore?()
            }
        }

        @objc func openPosting() { open?(enclosingScrollView?.contentView.bounds.origin) }

        override func keyDown(with event: NSEvent) {
            if [36, 76].contains(event.keyCode), event.modifierFlags.intersection([.command, .option, .control, .shift]).isEmpty {
                performClick(nil)
            } else {
                super.keyDown(with: event)
            }
        }
    }

    func makeNSView(context: Context) -> PostingButton {
        let button = PostingButton(title: "공고 보기 →", target: nil, action: nil)
        button.bezelStyle = .rounded
        button.target = button
        button.action = #selector(PostingButton.openPosting)
        button.setAccessibilityLabel("공고 보기")
        return button
    }

    func updateNSView(_ button: PostingButton, context: Context) {
        button.listOrigin = listOrigin
        button.open = open
        button.didRestore = didRestore
        button.restoresFocus = restoresFocus
        button.restoreIfNeeded()
    }
}

struct MatchingProjectDetail<Tabs: View>: View {
    let summary: MatchingProject
    let repository: any MatchingUseCase
    let gisuId: String
    let applicantParts: [String]
    @State private var eligibleRounds = MatchingRequest<[MatchingRound]>()
    let openApplications: () -> Void
    let back: () -> Void
    @ViewBuilder let tabs: () -> Tabs

    @State private var detail = MatchingRequest<MatchingProject>()
    @State private var permission = MatchingRequest<MatchingCapability>()
    @State private var attempt = 0
    @State private var startTask: Task<Void, Never>?
    @State private var isStarting = false
    @State private var failure: String?
    @State private var route: MatchingApplicationRoute?
    @State private var viewingTeam = false
    @State private var canReadTeam = false
    @State private var chosenRoundId: String?

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value24) {
            HStack {
                VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                    Text(summary.name).umcTypography(.largeTitle3Bold).accessibilityAddTraits(.isHeader)
                    if let summaryLine = descriptionLines.first {
                        Text(String(summaryLine)).umcTypography(.headlineRegular).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Button("목록으로", action: back)
                    .buttonStyle(MatchingActionStyle(appearance: .text))
                if case .loaded(let access) = permission.phase, access.allowed,
                   case .loaded = eligibleRounds.phase {
                    TimelineView(.periodic(from: .now, by: 15)) { tick in
                        let open = rounds.filter { $0.isOpen(at: tick.date) }
                        let selected = open.count == 1 ? open[0] : open.first { $0.id == chosenRoundId }
                        Button(isStarting ? "지원서 확인 중" : "지원서 작성") {
                            if let selected {
                                startTask = Task { await begin(project: displayedProject, roundId: selected.id) }
                            }
                        }
                        .disabled(isStarting || selected == nil)
                        .buttonStyle(MatchingActionStyle(appearance: .primary))
                    }
                }
            }
            tabs()
            Divider()
            MatchingRequestView(request: detail, retry: { attempt += 1 }) { project in
                MatchingColumns {
                VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                    if let image = MatchingLabel.webURL(project.thumbnailImageUrl) {
                        AsyncImage(url: image) { phase in
                            if let image = phase.image {
                                image.resizable().scaledToFit().frame(maxHeight: 180)
                                    .accessibilityHidden(true)
                            }
                        }
                    }
                    if descriptionLines.count > 1 {
                        Text(descriptionLines.dropFirst().joined(separator: "\n")).umcTypography(.headlineRegular)
                        Divider()
                    }
                    Text("프로젝트를 더 알아보세요").umcTypography(.title1Bold)
                    if let url = MatchingLabel.webURL(project.externalLink) {
                        Link("소개 자료 열기", destination: url).umcTypography(.headlineBold)
                    }
                    Divider()
                    if let owner = project.productOwner {
                        Text([owner.nickname ?? owner.name, owner.schoolName, "기획"]
                            .compactMap { $0 }.joined(separator: " · "))
                    }
                    if canReadTeam {
                        Button("팀 구성 보기") { viewingTeam = true }
                            .buttonStyle(MatchingActionStyle(appearance: .text))
                    }
                }
                .matchingPanel()
                VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                    if case .loaded(let access) = permission.phase, access.allowed {
                        MatchingBadge(text: "지원 가능한 프로젝트")
                    }
                    Text("함께할 자리").umcTypography(.title2Bold)
                    ForEach(project.partQuotas, id: \.part) { MatchingQuotaView(quota: $0) }
                    Divider()
                    TimelineView(.periodic(from: .now, by: 15)) { tick in
                        applicationAction(project, at: tick.date)
                    }
                    if let failure { Text(failure).foregroundStyle(UMCColor.Semantic.textError) }
                }
                .matchingPanel()
                }
            }
        }
        .task(id: attempt) {
            await detail.load { try await repository.project(id: summary.id) }
            await permission.load { try await repository.applicationCapability(projectId: summary.id) }
            if case .loaded(let capability) = permission.phase, capability.allowed {
                await eligibleRounds.load {
                    guard let chapter = try await repository.matchingChapterId(gisuId: gisuId)
                    else { return [] }
                    return try await repository.rounds(chapterId: chapter).filter { round in
                        round.isEligible(chapterId: chapter, parts: applicantParts)
                    }
                }
            }
            let access = try? await repository.permissions(projectId: summary.id)
            if !Task.isCancelled { canReadTeam = access?[.team]?.allowed == true }
        }
        .onDisappear { startTask?.cancel() }
        .sheet(item: $route) { route in
            MatchingApplicationEditor(repository: repository, route: route, rounds: rounds,
                                      onChange: openApplications)
        }
        .sheet(isPresented: $viewingTeam) {
            MatchingTeamSheet(repository: repository, projectId: summary.id)
        }
    }

    private var rounds: [MatchingRound] {
        if case .loaded(let rounds) = eligibleRounds.phase { return rounds }
        return []
    }

    private var descriptionLines: [Substring] {
        displayedProject.description?.split(separator: "\n") ?? []
    }

    private var displayedProject: MatchingProject {
        if case .loaded(let project) = detail.phase { return project }
        return summary
    }

    @ViewBuilder private func applicationAction(_ project: MatchingProject, at now: Date) -> some View {
        let open = rounds.filter { $0.isOpen(at: now) }
        MatchingRequestView(request: permission, retry: { attempt += 1 }) { capability in
            if !capability.allowed {
                Text(capability.reason ?? "이 프로젝트에 지원할 수 없어요.").foregroundStyle(.secondary)
            } else if case .loading = eligibleRounds.phase {
                ProgressView("지원 가능한 차수 확인 중")
            } else if case .failed(let failure) = eligibleRounds.phase {
                Text(failure).foregroundStyle(UMCColor.Semantic.textError)
                Button("일정 다시 불러오기") { attempt += 1 }
            } else if !open.isEmpty {
                let roundId = open.count == 1 ? open[0].id
                    : open.first(where: { $0.id == chosenRoundId })?.id
                if open.count > 1 {
                    Picker("지원 차수", selection: Binding(
                        get: { roundId }, set: { chosenRoundId = $0 }
                    )) {
                        Text("차수 선택").tag(String?.none)
                        ForEach(open, id: \.id) { Text($0.name).tag(Optional($0.id)) }
                    }
                } else { Text(open[0].name).umcTypography(.headlineBold) }
                if let round = open.first(where: { $0.id == roundId }) {
                    Text("지원 마감  " + MatchingLabel.time(round.endsAt))
                    if let deadline = round.decisionDeadline {
                        Text("판정 마감  " + MatchingLabel.time(deadline))
                    }
                    if let publish = round.resultPublishAt {
                        Text("결과 공개 예정  " + MatchingLabel.time(publish))
                    }
                }
            } else {
                Text(capability.reason ?? "현재 지원 가능한 차수가 없어요.").foregroundStyle(.secondary)
            }
        }
    }

    @MainActor private func begin(project: MatchingProject, roundId: String) async {
        guard !isStarting else { return }
        isStarting = true
        failure = nil
        defer { isStarting = false }
        do {
            let drafts = try await repository.myApplications(gisuId: gisuId, drafts: true)
            try Task.checkCancellation()
            let existing = drafts.first { $0.projectId == project.id && $0.matchingRound?.id == roundId }
            let applicationId: String
            if let existingId = existing?.applicationId { applicationId = existingId }
            else {
                applicationId = try await repository.createApplication(
                    projectId: project.id, roundId: roundId
                )
            }
            try Task.checkCancellation()
            route = .init(id: applicationId, projectId: project.id, projectName: project.name,
                          roundId: roundId, isDraft: true)
        } catch { failure = error.localizedDescription }
    }
}

private struct MatchingTeamSheet: View {
    let repository: any MatchingUseCase
    let projectId: String
    @State private var team = MatchingRequest<OperationsTeam>()
    @State private var attempt = 0

    var body: some View {
        MatchingTeamPanel {
            MatchingRequestView(request: team, retry: { attempt += 1 }) { value in
                MatchingRosterList(team: value)
            }
        }
        .task(id: attempt) { await team.load { try await repository.team(projectId: projectId) } }
    }
}

struct MatchingTeamPanel<Content: View>: View {
    @Environment(\.dismiss) private var dismiss
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            HStack {
                Text("팀 구성").umcTypography(.title1Bold).accessibilityAddTraits(.isHeader)
                Spacer()
                Button("닫기") { dismiss() }.keyboardShortcut(.cancelAction)
            }
            ScrollView { content() }
        }
        .padding(UMCSpacing.value24).frame(width: 450, height: 480)
    }
}

struct MatchingRosterList: View {
    let team: OperationsTeam

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            if let owner = team.productOwner { person(owner, role: "담당 PM") }
            ForEach(team.coProductOwners, id: \.memberId) { person($0, role: "보조 PM") }
            ForEach(team.partGroups, id: \.part) { group in
                ForEach(group.members, id: \.memberId) {
                    person($0, role: MatchingLabel.part(group.part))
                }
            }
        }.matchingPanel()
    }

    private func person(_ value: OperationsPerson, role: String) -> some View {
        LabeledContent(role, value: [value.nickname ?? value.name, value.schoolName]
            .compactMap { $0 }.joined(separator: " · "))
    }
}
