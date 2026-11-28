//  HomePresentation.swift
//  HomePresentation
//
//  Created by euijjang97 on 11/23/26.
//

import CoreDesignSystem
import CoreUIComponents
import HomeDomain
import SwiftUI
import UMCFoundation

public enum HomeDestination {
    case activity, notice, project
}

@MainActor @Observable
final class HomeViewModel {
    var profile: HomeProfile?
    var schedule: Loadable<HomeSchedule?> = .idle
    var notice: Loadable<String?> = .idle
    var project: Loadable<String?> = .idle
    let repository: any HomeRepository

    init(_ repository: any HomeRepository) { self.repository = repository }

    enum Focus: Equatable { case schedule, project, notice, empty }

    var focus: Focus {
        guard case .loaded(nil) = schedule else { return .schedule }
        switch project {
        case .loaded(.some): return .project
        case .loaded(nil):
            switch notice {
            case .loaded(.some): return .notice
            case .loaded(nil): return .empty
            default: return .schedule
            }
        default: return .schedule
        }
    }

    func load() async {
        schedule = refreshing(schedule)
        notice = refreshing(notice)
        project = refreshing(project)
        async let identity: Void = loadProfile()
        async let schedules: Void = read(repository.schedule) { self.schedule = $0 }
        async let notices: Void = read(repository.notice) { self.notice = $0 }
        async let projects: Void = read(repository.project) { self.project = $0 }
        _ = await (identity, schedules, notices, projects)
    }

    private func loadProfile() async {
        if let value = try? await repository.profile(), !Task.isCancelled { profile = value }
    }

    private func refreshing<Value>(_ state: Loadable<Value>) -> Loadable<Value> {
        if case .loaded = state { return state }
        return .loading
    }

    private func read<Value: Sendable>(
        _ read: @Sendable () async throws -> Value,
        apply: @MainActor (Loadable<Value>) -> Void
    ) async {
        let result: Loadable<Value>
        do { result = .loaded(try await read()) } catch { result = .failed(error) }
        if !Task.isCancelled { apply(result) }
    }

}

public struct HomeView: View {
    @State private var model: HomeViewModel
    @State private var dockOwner: DockRecordStore?
    @State private var dockRecords = DockRecords()
    @FocusState private var dockFocused: Bool
    private let recordStore: DockRecordStore
    @State private var reload = UUID()
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var wideHero = false
    @State private var narrowPage = false
    private var paper: DeskPaper { DeskPaper(dark: scheme == .dark) }
    private let onOpen: ((HomeDestination) -> Void)?

    public init(
        repository: any HomeRepository, memberID: String? = nil,
        defaults: UserDefaults = .standard,
        onOpen: ((HomeDestination) -> Void)? = nil
    ) {
        _model = State(initialValue: HomeViewModel(repository))
        recordStore = DockRecordStore(defaults: defaults, memberID: memberID)
        self.onOpen = onOpen
    }

    public var body: some View {
        Group {
            if let dockOwner, dockOwner == recordStore {
                DockSessionView(record: { score in
                    guard self.dockOwner == recordStore else { return }
                    dockRecords = dockOwner.record(score)
                }, close: {
                    self.dockOwner = nil
                    Task { @MainActor in dockFocused = true }
                })
            } else {
                home
            }
        }
        .umcTabTools(AppLocalization.string("홈 도구")) { dismiss in
            if let onOpen {
                if schedule != nil {
                    Button(AppLocalization.string("일정 보기"), systemImage: "calendar") {
                        dismiss()
                        onOpen(.activity)
                    }
                }
                if case .loaded(.some) = model.notice {
                    Button(AppLocalization.string("공지 보기"), systemImage: "megaphone") {
                        dismiss()
                        onOpen(.notice)
                    }
                }
                if case .loaded(.some) = model.project {
                    Button(AppLocalization.string("프로젝트 보기"), systemImage: "folder") {
                        dismiss()
                        onOpen(.project)
                    }
                }
            }
            Button(AppLocalization.string("새로고침"), systemImage: "arrow.clockwise") {
                dismiss()
                reload = UUID()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(paper.background)
        .tint(UMCColor.Semantic.textBrandDefault)
        .task(id: reload) { await model.load() }
        .onChange(of: recordStore, initial: true) { _, store in
            if dockOwner != store { dockOwner = nil }
            dockRecords = store.load()
        }
    }

    private var home: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UMCSpacing.value24) {
                homeHeader
                workSummary
                dockCard
            }
            .frame(maxWidth: 1120)
            .padding(narrowPage ? UMCSpacing.value20 : UMCSpacing.value32)
            .frame(maxWidth: .infinity)
            .transformEnvironment(\.umcFontDesign) { design in
                if design == nil { design = .default }
            }
        }
        .onGeometryChange(for: Bool.self) { $0.size.width < 684 } action: {
            narrowPage = $0
        }
    }

    private var homeHeader: some View {
        HStack {
            Text(model.profile.map { "안녕, " + $0.nickname + "." } ?? "나만의 공간")
                .umcTypography(.largeTitle2Bold)
            Spacer()
            Button {
                reload = UUID()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 19, weight: .medium))
                    .frame(width: 32, height: 32).contentShape(.rect)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("새로고침")
            .help("새로고침")
        }
    }

    private var workSummary: some View {
        DeskCardLayout {
            hero
            if model.focus != .notice && model.focus != .empty {
                companion("공지", state: model.notice, destination: .notice)
            }
            if model.focus != .project && model.focus != .empty {
                companion("프로젝트", state: model.project, destination: .project)
            }
        }
    }

    private var heroTitle: String {
        switch model.focus {
        case .empty: return "표시할 일정, 프로젝트, 공지가 없어요"
        case .project: if case .loaded(let title?) = model.project { return title }
        case .notice: if case .loaded(let title?) = model.notice { return title }
        case .schedule:
            switch model.schedule {
            case .loaded(let item?): return item.name
            case .loaded(nil): return "오늘 남은 일정이 없어요"
            case .failed: return "일정을 불러오지 못했어요"
            case .idle, .loading: return ""
            }
        }
        return ""
    }

    private var schedule: HomeSchedule? {
        if case .loaded(let item) = model.schedule { return item }
        return nil
    }

    private var hero: some View {
        let showArt = wideHero && heroTitle.count <= 80
        return HStack {
            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                if model.focus == .schedule && heroTitle.isEmpty {
                    placeholders
                } else {
                    VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                        Text(schedule?.startsAt ?? .now,
                             format: .dateTime.month().day().weekday(.wide))
                            .umcTypography(.title4Regular)
                            .foregroundStyle(paper.muted)
                        Rectangle().fill(paper.muted.opacity(0.38))
                            .frame(maxWidth: 230).frame(height: 1)
                            .padding(.bottom, UMCSpacing.value4)
                        Text(heroTitle).umcTypography(.largeTitle1Bold)
                            .fixedSize(horizontal: false, vertical: true)
                        if let schedule {
                            Text(schedule.startsAt, format: .dateTime.hour().minute())
                                .umcTypography(.title2Regular)
                        }
                    }
                    .accessibilityElement(children: .combine)
                }
                if let onOpen, model.focus != .empty {
                    let action: (String, HomeDestination) = switch model.focus {
                    case .project: ("프로젝트 보기", .project)
                    case .notice: ("공지 보기", .notice)
                    case .schedule, .empty: ("일정 보기", .activity)
                    }
                    Button { onOpen(action.1) } label: {
                        Text(action.0).umcTypography(.headlineBold)
                            .padding(.horizontal, UMCSpacing.value16)
                            .frame(minHeight: 32)
                            .foregroundStyle(paper.buttonText)
                            .background(paper.button, in: .rect(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    .accessibilityHint(model.focus == .schedule ? "활동 탭으로 이동" : "해당 탭으로 이동")
                }
            }
            Spacer(minLength: showArt ? 188 : 0)
        }
        .foregroundStyle(paper.ink)
        .padding(UMCSpacing.value32)
        .frame(maxWidth: .infinity, minHeight: 272, maxHeight: .infinity, alignment: .leading)
        .background { DeskPaperSurface(paper: paper, showsCalendar: showArt) }
        .onGeometryChange(for: Bool.self) { $0.size.width >= 536 } action: { wideHero = $0 }
        .accessibilityElement(children: .contain)
    }

    private var placeholders: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            ForEach([90, 210, 70], id: \.self) { width in
                RoundedRectangle(cornerRadius: 4).fill(paper.muted.opacity(0.18))
                    .frame(maxWidth: CGFloat(width)).frame(height: width == 210 ? 36 : 18)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("일정을 불러오는 중")
    }

    @ViewBuilder
    private func companion(
        _ title: String, state: Loadable<String?>, destination: HomeDestination
    ) -> some View {
        let content = switch state {
        case .loaded(let value): value ?? (destination == .notice ? "표시할 공지가 없어요" : "표시할 프로젝트가 없어요")
        case .failed: destination == .notice ? "공지를 불러오지 못했어요" : "프로젝트를 불러오지 못했어요"
        case .idle, .loading: "불러오는 중"
        }
        let card = VStack(alignment: .leading, spacing: UMCSpacing.value8) {
            HStack(spacing: UMCSpacing.value8) {
                Capsule().fill(paper.muted).frame(width: 3, height: 14)
                Text(title).umcTypography(.headlineBold)
            }
            .foregroundStyle(paper.muted)
            Text(content).umcTypography(.title3Bold)
                .fixedSize(horizontal: false, vertical: true)
            if onOpen != nil {
                Divider().accessibilityHidden(true)
                HStack {
                    Text(title + " 보기").umcTypography(.headlineRegular)
                    Spacer()
                    Image(systemName: "chevron.right")
                }
                .foregroundStyle(paper.muted)
            }
        }
        .padding(UMCSpacing.value20)
        .frame(maxWidth: .infinity, minHeight: 120, maxHeight: .infinity, alignment: .leading)
        .background { panelSurface }
        .contentShape(.rect(cornerRadius: 14))
        if let onOpen {
            Button { onOpen(destination) } label: { card }
                .buttonStyle(.plain)
                .accessibilityLabel(title + ", " + content)
                .accessibilityHint(title + " 탭으로 이동")
        } else {
            card.accessibilityElement(children: .combine)
        }
    }

    private var dockCard: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value8) {
            Label("소인이 찍겠습니다!", systemImage: "ferry.fill").umcTypography(.title2Bold)
            Text("꾹이의 접지부두 · 소인기 세 면 펼치기").umcTypography(.headlineRegular)
            Text("WASD 이동 · ← → 회전 · F 소인").umcTypography(.calloutRegular)
            Text("최고 \(dockRecords.best)점 · 누적 \(dockRecords.total)점")
            if !dockRecords.recent.isEmpty {
                Text("최근 플레이 · " + dockRecords.recent.map { "\($0)점" }.joined(separator: " / "))
            }
            Button("한 판 하기") { dockOwner = recordStore }
                .buttonStyle(.borderedProminent)
                .focused($dockFocused)
                .accessibilityLabel("소인이 찍겠습니다! 한 판 하기")
        }
        .padding(UMCSpacing.value20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background { panelSurface }
    }

    private var panelSurface: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(paper.panel)
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.primary.opacity(contrast == .increased ? 0.55 : 0.13))
            }
            .shadow(color: .black.opacity(0.07), radius: 3, y: 2)
    }
}
