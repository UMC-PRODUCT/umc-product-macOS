//
//  MatchingPresentation.swift
//  MatchingPresentation
//
//  Created by euijjang97 on 11/22/26.
//

import CoreDesignSystem
import MatchingDomain
import SwiftUI

public enum MatchingDestination: Hashable, Sendable {
    case explore, applications, schedule, status, management

    var heading: String {
        switch self {
        case .applications: "내 지원 현황"
        case .schedule: "차수 운영 타임라인"
        default: title
        }
    }

    var title: String {
        switch self {
        case .explore: "프로젝트 탐색"
        case .applications: "내 지원"
        case .schedule: "전체 일정"
        case .status: "매칭 현황"
        case .management: "내 프로젝트"
        }
    }
}

@MainActor
@Observable
final class MatchingRequest<Value> {
    enum Phase { case loading, loaded(Value), failed(String) }
    private(set) var phase: Phase = .loading
    private var generation = 0

    func load(_ operation: () async throws -> Value) async {
        generation += 1
        let current = generation
        phase = .loading
        do {
            let result = try await operation()
            guard !Task.isCancelled, current == generation else { return }
            phase = .loaded(result)
        } catch {
            guard !Task.isCancelled, current == generation else { return }
            phase = .failed(error.localizedDescription)
        }
    }
}

struct MatchingRequestView<Value, Content: View>: View {
    let request: MatchingRequest<Value>
    let retry: () -> Void
    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        switch request.phase {
        case .loading:
            ProgressView().frame(maxWidth: .infinity).padding()
        case .failed(let message):
            ContentUnavailableView {
                Label("불러올 수 없어요", systemImage: "exclamationmark.circle")
            } description: { Text(message) } actions: { Button("다시 시도", action: retry) }
        case .loaded(let value):
            content(value)
        }
    }
}

public struct MatchingView: View {
    private let repository: any MatchingUseCase
    private let gisuId: String
    private let applicantParts: [String]
    private let memberId: String?
    private let onOpenProject: ((String) -> Void)?
    @State private var explorer = MatchingExplorerState()
    @State private var position = ScrollPosition()
    @State private var destination: MatchingDestination
    @State private var organization = MatchingRequest<MatchingOrganization>()
    @State private var rounds = MatchingRequest<[MatchingRound]>()
    @State private var organizationAttempt = 0
    @State private var roundAttempt = 0
    @State private var chapterId: String?
    @State private var hasChosenChapter = false
    @State private var editingSchedule = false
    @State private var authorizedChapter: String?
    @State private var selectedProject: MatchingProject?
    @State private var draftId: String?
    @State private var creating = false
    @State private var canChooseOtherPM = false

    private var canCreateOwnDraft: Bool { applicantParts.contains("PLAN") }
    @State private var previous: [Location] = []
    @State private var following: [Location] = []

    private struct Location: Equatable {
        let destination: MatchingDestination
        var project: MatchingProject?
        var draftId: String?
    }

    public init(
        repository: any MatchingUseCase, gisuId: String,
        initialDestination: MatchingDestination = .explore, memberId: String? = nil,
        applicantParts: [String] = [], onOpenProject: ((String) -> Void)? = nil
    ) {
        self.repository = repository
        self.gisuId = gisuId
        self.applicantParts = applicantParts
        self.memberId = memberId
        self.onOpenProject = onOpenProject
        _destination = State(initialValue: initialDestination)
    }

    #if DEBUG
    init(repository: any MatchingUseCase, gisuId: String, previewProject: MatchingProject) {
        self.repository = repository
        self.gisuId = gisuId
        self.applicantParts = ["WEB"]
        self.memberId = nil
        self.onOpenProject = nil
        _destination = State(initialValue: .explore)
        _selectedProject = State(initialValue: previewProject)
    }
    #endif

    public var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: UMCSpacing.value24) {
                    if selectedProject == nil {
                        HStack {
                            Text(destination.heading)
                                .umcTypography(.largeTitle3Bold)
                                .accessibilityAddTraits(.isHeader)
                            Spacer()
                            matchingTools
                        }
                        matchingTabs
                        Divider()
                    }
                    bodyContent
                }
                .padding(.horizontal, UMCSpacing.value40)
                .padding(.vertical, UMCSpacing.value24)
            }
            .scrollPosition($position)
        }
        .toolbar {
            if selectedProject != nil {
                ToolbarItem(placement: .primaryAction) { matchingTools }
            }
            ToolbarItemGroup(placement: .navigation) {
                Button("뒤로", systemImage: "chevron.left") {
                    guard let target = previous.popLast() else { return }
                    following.append(current)
                    restore(target)
                }
                .disabled(previous.isEmpty)
                Button("앞으로", systemImage: "chevron.right") {
                    guard let target = following.popLast() else { return }
                    previous.append(current)
                    restore(target)
                }
                .disabled(following.isEmpty)
            }
        }
        .sheet(isPresented: $creating) {
            MatchingDraftComposer(service: repository, gisuId: gisuId,
                                  canCreateOwn: canCreateOwnDraft, canChooseOther: canChooseOtherPM) { id in
                creating = false
                go(.init(destination: .management, draftId: id))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundStyle(UMCColor.Semantic.textNeutralDefault)
        .tint(UMCColor.Semantic.textBrandDefault)
        .background(UMCColor.Custom.backgroundDefault)
        .task(id: gisuId) {
            let candidates = try? await repository.pmCandidates(gisuId: gisuId, keyword: nil, page: 0)
            if !Task.isCancelled { canChooseOtherPM = candidates != nil }
        }
        .task(id: organizationAttempt) {
            await organization.load { try await repository.organization(gisuId: gisuId) }
            guard case .loaded(let value) = organization.phase, chapterId == nil,
                  !hasChosenChapter else { return }
            if value.chapters.count == 1 {
                chapterId = value.chapters.first?.id
            } else if !value.chapters.isEmpty {
                let personal = try? await repository.matchingChapterId(gisuId: gisuId)
                guard !Task.isCancelled, !hasChosenChapter,
                      let personal, value.chapters.contains(where: { $0.id == personal }) else { return }
                chapterId = personal
            }
        }
        .task(id: RoundQuery(chapterId: chapterId, attempt: roundAttempt)) {
            authorizedChapter = nil
            guard let chapterId else { return }
            await rounds.load { try await repository.rounds(chapterId: chapterId) }
            if (try? await repository.canManageSchedule(chapterId: chapterId)) == true,
               !Task.isCancelled, self.chapterId == chapterId { authorizedChapter = chapterId }
        }
    }

    private var matchingTabs: some View {
        HStack(spacing: UMCSpacing.value8) {
            tab(.explore)
            tab(.applications)
            tab(.status)
            tab(.management)
            Spacer()
            if selectedProject == nil, destination == .explore, canCreateOwnDraft || canChooseOtherPM {
                Button("프로젝트 만들기") { creating = true }
                    .buttonStyle(MatchingActionStyle(appearance: .primary))
            }
        }
        .padding(UMCSpacing.value4)
        .background(UMCColor.Custom.backgroundSurfaceGreyWeaker,
                    in: .rect(cornerRadius: UMCRadius.value8))
    }

    private struct RoundQuery: Hashable {
        let chapterId: String?
        let attempt: Int
    }

    @ViewBuilder private var bodyContent: some View {
        if let selectedProject {
            MatchingProjectDetail(
                summary: selectedProject, repository: repository, gisuId: gisuId,
                applicantParts: applicantParts,
                openApplications: { navigate(.applications) },
                back: { navigate(.explore) },
                tabs: { matchingTabs }
            )
            .id(selectedProject.id)
        } else {
            switch destination {
            case .explore:
                scheduleSummary
                MatchingExplorer(repository: repository, gisuId: gisuId, chapterId: chapterId,
                                 schools: schools, select: {
                                     go(.init(destination: .explore, project: $0))
                                 }, state: explorer)
            case .applications:
                MatchingApplications(repository: repository, gisuId: gisuId, memberId: memberId, rounds: loadedRounds,
                                     onOpenProject: onOpenProject, explore: { navigate(.explore) })
            case .schedule:
                scheduleList
            case .management where draftId != nil:
                if let draftId {
                    ProjectOperationsView(service: repository, projectId: draftId, status: "DRAFT") {
                        navigate(.management)
                    }.id(draftId)
                }
            case .status, .management:
                chapterPicker
                MatchingOperationsView(section: destination == .status ? .statistics : .projects,
                                       service: repository, gisuId: gisuId, chapterId: chapterId,
                                       canCreateOwn: canCreateOwnDraft, canChooseOther: canChooseOtherPM,
                                       canReadAdjustment: chapterId != nil && authorizedChapter == chapterId)
            }
        }
    }

    private var matchingTools: some View {
        Menu {
            Button("전체 일정") { navigate(.schedule) }
            Button("내 지원") { navigate(.applications) }
            Button("내 프로젝트") { navigate(.management) }
        } label: {
            Label("매칭 도구", systemImage: "slider.horizontal.3")
        }
        .fixedSize()
    }

    private var schools: [MatchingFilterOption] {
        if case .loaded(let value) = organization.phase { return value.schools }
        return []
    }

    private var loadedRounds: [MatchingRound] {
        if case .loaded(let value) = rounds.phase {
            return value.filter { $0.chapterId == chapterId }
        }
        return []
    }

    private var chapterPicker: some View { chapterPicker(allowsAll: true) }

    @ViewBuilder private func chapterPicker(allowsAll: Bool) -> some View {
        MatchingRequestView(request: organization, retry: { organizationAttempt += 1 }) { org in
            if org.chapters.count > 1 {
                Picker("지부", selection: Binding(get: { chapterId }, set: { chosen in
                    hasChosenChapter = true
                    chapterId = chosen
                })) {
                    Text(allowsAll ? "전체 지부" : "지부 선택").tag(String?.none)
                    ForEach(org.chapters) { Text($0.name).tag(Optional($0.id)) }
                }
                .fixedSize()
            } else if org.chapters.isEmpty {
                Text("이 기수에 등록된 지부가 없어요.").foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder private var scheduleSummary: some View {
        chapterPicker
        if chapterId != nil {
            MatchingRequestView(request: rounds, retry: { roundAttempt += 1 }) { _ in
                let active = loadedRounds.first { $0.isOpen(at: .now) }
                let upcoming = loadedRounds.first { (MatchingLabel.date($0.startsAt) ?? .distantPast) > .now }
                if let round = active ?? upcoming ?? loadedRounds.last {
                    MatchingRoundCard(round: round, chapterName: selectedChapterName) { navigate(.schedule) }
                } else {
                    Label("등록된 매칭 일정이 없어요.", systemImage: "calendar")
                        .matchingPanel()
                }
            }
        } else if case .loaded(let org) = organization.phase, org.chapters.count > 1 {
            Label("지부를 선택하면 매칭 일정을 볼 수 있어요.", systemImage: "calendar")
                .matchingPanel(UMCColor.Semantic.surfaceBrandWeak)
        }
    }

    private var selectedChapterName: String? {
        guard case .loaded(let org) = organization.phase else { return nil }
        return org.chapters.first { $0.id == chapterId }?.name
    }

    @ViewBuilder private var scheduleList: some View {
        chapterPicker(allowsAll: false)
        if let chapterId {
            MatchingRequestView(request: rounds, retry: { roundAttempt += 1 }) { _ in
                if authorizedChapter == chapterId {
                    Button("지부 일정 관리") { editingSchedule = true }
                }
                ForEach(loadedRounds, id: \.id) { round in
                    MatchingRoundCard(round: round)
                    if round.autoDecisionExecutedAt != nil {
                        MatchingPublicationStatus(
                            round: round, repository: repository, gisuId: gisuId
                        )
                    }
                }
                if loadedRounds.isEmpty { Text("등록된 매칭 일정이 없어요.").matchingPanel() }
            }
            .sheet(isPresented: $editingSchedule) {
                MatchingScheduleEditor(repository: repository, chapterId: chapterId,
                                       rounds: loadedRounds, onSaved: { roundAttempt += 1 })
            }
        }
    }

    private func navigate(_ page: MatchingDestination) {
        go(Location(destination: page))
    }

    private var current: Location {
        Location(destination: destination, project: selectedProject, draftId: draftId)
    }

    private func go(_ target: Location) {
        guard current != target else { return }
        previous.append(current)
        following.removeAll()
        restore(target)
    }

    private func restore(_ target: Location) {
        if target.project != nil { position.scrollTo(edge: .top) }
        if let selectedProject, target.project == nil, target.destination == .explore {
            explorer.returnProjectId = selectedProject.id
        }
        selectedProject = target.project
        draftId = target.draftId
        destination = target.destination
    }

    private func tab(_ page: MatchingDestination) -> some View {
        let selected = page == destination || (page == .explore && destination == .schedule)
        return Button { navigate(page) } label: {
            Text(page.title)
                .umcTypography(selected ? .headlineBold : .headlineRegular)
                .foregroundStyle(selected ? UMCColor.Semantic.textBrandDefault : .secondary)
                .padding(.horizontal, UMCSpacing.value16)
                .padding(.vertical, UMCSpacing.value8)
                .background(selected ? UMCColor.Semantic.surfaceBrandMedium : .clear,
                            in: .rect(cornerRadius: UMCRadius.value8))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
