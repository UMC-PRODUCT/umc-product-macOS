//  HomePresentation.swift
//  HomePresentation
//
//  Created by euijjang97 on 11/23/26.
//

import CoreDesignSystem
import HomeDomain
import SwiftUI
import UMCFoundation

fileprivate enum Constants {
    static let contentInset = UMCSpacing.value24
    static let maximumContentWidth: CGFloat = 1040
}

public enum HomeDestination {
    case activity, notice, project
}

@MainActor @Observable
private final class HomeViewModel {
    var profile: HomeProfile?
    var schedule: Loadable<HomeSchedule?> = .idle
    var notice: Loadable<String?> = .idle
    var project: Loadable<String?> = .idle
    let repository: any HomeRepository

    init(_ repository: any HomeRepository) { self.repository = repository }

    func load() async {
        schedule = .loading
        notice = .loading
        project = .loading
        async let identity = try? repository.profile()
        async let schedules = result { try await self.repository.schedule() }
        async let notices = result { try await self.repository.notice() }
        async let projects = result { try await self.repository.project() }
        let values = await (identity, schedules, notices, projects)
        guard !Task.isCancelled else { return }
        profile = values.0
        schedule = state(values.1)
        notice = state(values.2)
        project = state(values.3)
    }

    private func result<Value>(_ read: () async throws -> Value) async -> Result<Value, Error> {
        do { return .success(try await read()) } catch { return .failure(error) }
    }

    private func state<Value>(_ result: Result<Value, Error>) -> Loadable<Value> {
        switch result {
        case .success(let value): .loaded(value)
        case .failure(let error): .failed(error)
        }
    }
}

public struct HomeView: View {
    @State private var model: HomeViewModel
    @State private var showsArcade = false
    @State private var selectedGame: MiniGame?
    @State private var reload = UUID()
    @State private var records = GameRecords()
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
                        VStack(alignment: .leading, spacing: UMCSpacing.value24) {
                            homeHeader
                            workSummary
                            arcadeHeader.padding(.top, UMCSpacing.value8)
                        }
                        .padding(.horizontal, Constants.contentInset)
                        .transformEnvironment(\.umcFontDesign) { design in
                            if design == nil { design = .default }
                        }
                        if showsArcade { arcade }
                    }
                    .frame(maxWidth: Constants.maximumContentWidth)
                    .padding(UMCSpacing.value32)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(UMCColor.Custom.backgroundSurface)
        .tint(UMCColor.Semantic.textBrandDefault)
        .task(id: reload) { await model.load() }
        .onChange(of: recordStore, initial: true) { _, store in
            records = store.load()
        }
    }

    private var homeHeader: some View {
        HStack {
            Text(model.profile.map { "안녕, " + $0.nickname + "." } ?? "나만의 공간")
                .umcTypography(.title3Bold)
            Spacer()
            Button {
                reload = UUID()
            } label: {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 28, height: 28)
                    .contentShape(.rect)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("새로고침")
            .help("새로고침")
        }
    }

    private var workSummary: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            if case .loaded(nil) = model.schedule {
                HStack(spacing: UMCSpacing.value12) {
                    Text(Date.now, format: .dateTime.month().day().weekday(.wide))
                    Text("오늘 남은 일정이 없어요")
                    Spacer()
                    navigationLink("일정 보기", destination: .activity)
                }
                .umcTypography(.headlineRegular)
                .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)

                if case .loaded(.some) = model.project {
                    featured("이어서 작업", symbol: "folder", action: "프로젝트 보기",
                             destination: .project) {
                        summary(model.project, title: "이어서 작업",
                                empty: "관리하는 프로젝트가 없어요", style: .largeTitle3Bold)
                    }
                    noticeRow
                } else {
                    featured("공지", symbol: "megaphone", action: "공지 보기", destination: .notice) {
                        summary(model.notice, title: "공지",
                                empty: "확인할 새 소식이 없어요", style: .largeTitle3Bold)
                    }
                    projectRow
                }
            } else {
                featured("오늘 일정", symbol: "calendar", action: "일정 보기", destination: .activity) {
                    switch model.schedule {
                    case .loaded(let schedule?):
                        Text(schedule.name)
                            .umcTypography(.largeTitle3Bold)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(schedule.startsAt,
                             format: .dateTime.month().day().weekday().hour().minute())
                            .umcTypography(.headlineRegular)
                            .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
                    case .failed: Text("불러오지 못했어요")
                    case .idle, .loading:
                        ProgressView().controlSize(.small)
                            .accessibilityLabel("오늘 일정 불러오는 중")
                    case .loaded(nil): EmptyView()
                    }
                }
                noticeRow
                projectRow
            }
        }
    }

    private func featured<Content: View>(
        _ title: String, symbol: String, action: String, destination: HomeDestination,
        @ViewBuilder content: () -> Content
    ) -> some View {
        HStack(alignment: .top, spacing: UMCSpacing.value16) {
            VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                Label(title, systemImage: symbol)
                    .umcTypography(.headlineBold)
                    .foregroundStyle(UMCColor.Semantic.textBrandDefault)
                content()
            }
            .accessibilityElement(children: .contain)
            .accessibilitySortPriority(1)
            Spacer(minLength: 0)
            if let onOpen {
                Button(action) { onOpen(destination) }
                    .fixedSize()
                    .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, UMCSpacing.value24)
        .background {
            // 카드 표면만 넓혀 모든 행의 버튼이 같은 열에 남도록 한다.
            RoundedRectangle(cornerRadius: UMCRadius.value16)
                .fill(UMCColor.Custom.backgroundSurfaceGreyWeak)
                .padding(.horizontal, -Constants.contentInset)
        }
        .accessibilityElement(children: .contain)
    }

    private var noticeRow: some View {
        workRow("공지", symbol: "megaphone", state: model.notice,
                empty: "확인할 새 소식이 없어요", action: "공지 보기", destination: .notice)
    }

    private var projectRow: some View {
        workRow("이어서 작업", symbol: "folder", state: model.project,
                empty: "관리하는 프로젝트가 없어요", action: "프로젝트 보기", destination: .project)
    }

    private func workRow(
        _ title: String, symbol: String, state: Loadable<String?>,
        empty: String, action: String, destination: HomeDestination
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: UMCSpacing.value16) {
            Label(title, systemImage: symbol)
                .umcTypography(.headlineRegular)
                .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
                .frame(minWidth: 100, alignment: .leading)
            summary(state, title: title, empty: empty, style: .title4Bold)
            Spacer(minLength: 0)
            navigationLink(action, destination: destination)
        }
        .padding(.vertical, UMCSpacing.value8)
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func summary(
        _ state: Loadable<String?>, title: String, empty: String, style: UMCTypography
    ) -> some View {
        switch state {
        case .loaded(let value):
            Text(value ?? empty)
                .umcTypography(value == nil ? .headlineRegular : style)
                .fixedSize(horizontal: false, vertical: true)
        case .idle, .loading:
            ProgressView().controlSize(.small).accessibilityLabel(title + " 불러오는 중")
        case .failed: Text("불러오지 못했어요")
        }
    }

    @ViewBuilder
    private func navigationLink(_ title: String, destination: HomeDestination) -> some View {
        if let onOpen {
            Button {
                onOpen(destination)
            } label: {
                Text(title)
                    .frame(minHeight: UMCSpacing.value24)
                    .contentShape(.rect)
            }
            .buttonStyle(.borderless)
            .fixedSize()
        }
    }

    private var arcadeHeader: some View {
        HStack {
            Label("잠깐, 한 판?", systemImage: "gamecontroller")
                .umcTypography(.headlineRegular)
            Spacer()
            Button {
                showsArcade.toggle()
            } label: {
                HStack(spacing: UMCSpacing.value4) {
                    Text(showsArcade ? "게임 접기" : "게임 선택")
                    Image(systemName: showsArcade ? "chevron.up" : "chevron.down")
                        .imageScale(.small).accessibilityHidden(true)
                }
                .frame(minHeight: UMCSpacing.value24)
                .contentShape(.rect)
            }
            .buttonStyle(.borderless)
        }
        .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
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
