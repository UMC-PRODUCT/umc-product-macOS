//  HomePresentation.swift
//  HomePresentation
//
//  Created by euijjang97 on 11/23/26.
//

import CoreDesignSystem
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
    @State private var showsArcade = false
    @State private var selectedGame: MiniGame?
    @State private var reload = UUID()
    @State private var records = GameRecords()
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    @State private var wideHero = false
    @State private var narrowPage = false
    private var paper: DeskPaper { DeskPaper(dark: scheme == .dark) }
    private let defaults: UserDefaults
    private let memberID: String?
    private let onOpen: ((HomeDestination) -> Void)?

    public init(
        repository: any HomeRepository, memberID: String? = nil,
        defaults: UserDefaults = .standard,
        onOpen: ((HomeDestination) -> Void)? = nil
    ) {
        _model = State(initialValue: HomeViewModel(repository))
        self.defaults = defaults
        self.memberID = memberID
        self.onOpen = onOpen
    }

    var recordStore: HomeGameRecordStore {
        HomeGameRecordStore(defaults: defaults, memberID: memberID ?? model.profile?.id)
    }

    public var body: some View {
        Group {
            if let selectedGame {
                GameSessionView(
                    game: selectedGame, records: records, record: save,
                    close: { self.selectedGame = nil })
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: UMCSpacing.value24) {
                        homeHeader
                        workSummary
                        arcadeHeader
                        if showsArcade { arcade }
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
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(selectedGame == nil ? paper.background : UMCColor.Custom.backgroundSurface)
        .tint(UMCColor.Semantic.textBrandDefault)
        .task(id: reload) { await model.load() }
        .onChange(of: recordStore, initial: true) { _, store in
            records = store.load()
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

    private var panelSurface: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(paper.panel)
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(.primary.opacity(contrast == .increased ? 0.55 : 0.13))
            }
            .shadow(color: .black.opacity(0.07), radius: 3, y: 2)
    }

    private var arcadeHeader: some View {
        HStack(spacing: UMCSpacing.value16) {
            Image("desk-scene", bundle: .module)
                .resizable().aspectRatio(contentMode: .fit)
                .frame(maxWidth: narrowPage ? 110 : 215)
                .clipShape(.rect(cornerRadius: 9))
                .accessibilityHidden(true)
            GameBoard(round: MiniGameRound(game: .jump), preview: true, surface: paper.panel)
                .aspectRatio(100.0 / 60, contentMode: .fit)
                .frame(width: 48, height: 48)
                .accessibilityHidden(true)
            Text("잠깐, 한 판?").umcTypography(.title2Bold)
            Spacer(minLength: 0)
            Button {
                showsArcade.toggle()
            } label: {
                HStack(spacing: UMCSpacing.value4) {
                    Text(showsArcade ? "게임 접기" : "게임 선택")
                    Image(systemName: showsArcade ? "chevron.up" : "chevron.down")
                }
                .umcTypography(.headlineBold)
                .foregroundStyle(paper.buttonText)
                .padding(.horizontal, UMCSpacing.value12)
                .frame(minHeight: 32)
                .background(paper.button, in: .rect(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(showsArcade ? "게임 접기" : "게임 선택")
            .accessibilityValue(showsArcade ? "펼침" : "접힘")
        }
        .padding(.horizontal, UMCSpacing.value16)
        .padding(.vertical, UMCSpacing.value12)
        .frame(minHeight: 76)
        .background { panelSurface }
    }

    private var arcade: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            HStack(alignment: .top, spacing: UMCSpacing.value16) {
                ForEach(MiniGame.allCases) { game in gameCard(game) }
            }
            Text("나의 기록").umcTypography(.headlineBold)
            HStack(alignment: .top, spacing: 20) {
                ForEach(MiniGame.allCases) { game in
                    let total = records.totals[game.rawValue, default: 0]
                    let goal = [500, 1500, 3000].first { $0 > total }
                    VStack(alignment: .leading) {
                        Text("\(game.title) · 누적 \(total)점").umcTypography(
                            .headlineBold)
                        ProgressView(
                            value: Double(min(total, goal ?? 3000)),
                            total: Double(goal ?? 3000))
                        Text(goal.map { "다음 목표 \($0)점" } ?? "3단계 달성")
                            .umcTypography(.calloutRegular).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            VStack(alignment: .leading, spacing: 8) {
                Text("최근 플레이").umcTypography(.headlineBold)
                Text(
                    records.recent.isEmpty
                        ? "아직 플레이 기록이 없어요"
                        : records.recent.joined(separator: "   /   ")
                )
                .foregroundStyle(.secondary)
            }
        }
    }

    private func gameCard(_ game: MiniGame) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(game.title).umcTypography(.headlineBold)
            Text(game.summary).umcTypography(.calloutRegular).foregroundStyle(.secondary)
            GameBoard(round: MiniGameRound(game: game), preview: true)
                .frame(height: 64).clipShape(.rect(cornerRadius: 8))
            Text("\(game.controls) · 최고 \(records.best[game.rawValue, default: 0])점")
                .umcTypography(.calloutRegular).foregroundStyle(.secondary)
            Button {
                selectedGame = game
            } label: {
                Text("한 판 하기").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent).accessibilityLabel(game.title + " 한 판 하기")
        }
        .padding(18)
        .background(UMCColor.Custom.backgroundSurfaceGreyWeaker, in: .rect(cornerRadius: 12))
    }

    private func save(_ game: MiniGame, score: Int) {
        let id = game.rawValue
        records.best[id] = max(score, records.best[id, default: 0])
        records.totals[id, default: 0] += score
        records.recent = Array((["\(game.title) \(score)점"] + records.recent).prefix(3))
        recordStore.save(records)
    }
}
