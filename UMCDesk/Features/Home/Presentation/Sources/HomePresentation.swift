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
private final class HomeViewModel {
    var profile: HomeProfile?
    var schedule: Loadable<String?> = .idle
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

    private func result(_ read: () async throws -> String?) async -> Result<String?, Error> {
        do { return .success(try await read()) } catch { return .failure(error) }
    }

    private func state(_ result: Result<String?, Error>) -> Loadable<String?> {
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
                    VStack(alignment: .leading, spacing: 28) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(model.profile.map { "안녕, " + $0.nickname + "." } ?? "나만의 공간")
                                    .umcTypography(.largeTitle3Bold)
                                Text(Date.now, format: .dateTime.month().day().weekday(.wide))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("새로고침", systemImage: "arrow.clockwise") { reload = UUID() }
                                .labelStyle(.iconOnly)
                        }
                        workSummary
                        Divider()
                        HStack {
                            Text("잠깐, 한 판?").umcTypography(.title2Bold)
                            Spacer()
                            Button(showsArcade ? "게임 접기" : "게임 선택") {
                                showsArcade.toggle()
                            }
                        }
                        if showsArcade { arcade }
                    }
                    .padding(UMCSpacing.value32)
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

    private var workSummary: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            if case .loaded(nil) = model.schedule {
                HStack {
                    Text("오늘 남은 일정이 없어요").foregroundStyle(.secondary)
                    Spacer()
                    navigationButton("일정 보기", destination: .activity)
                }
                if case .loaded(.some) = model.project {
                    projectEntry(primary: true)
                    noticeEntry(primary: false)
                } else {
                    noticeEntry(primary: true)
                    projectEntry(primary: false)
                }
            } else {
                entry(
                    "오늘 일정", symbol: "calendar", state: model.schedule,
                    empty: "오늘 남은 일정이 없어요", action: "일정 보기",
                    destination: .activity, primary: true)
                noticeEntry(primary: false)
                projectEntry(primary: false)
            }
        }
    }

    private func projectEntry(primary: Bool) -> some View {
        entry(
            "이어서 작업", symbol: "folder", state: model.project,
            empty: "관리하는 프로젝트가 없어요", action: "프로젝트 보기",
            destination: .project, primary: primary)
    }

    private func noticeEntry(primary: Bool) -> some View {
        entry(
            "공지", symbol: "megaphone", state: model.notice,
            empty: "확인할 새 소식이 없어요", action: "공지 보기",
            destination: .notice, primary: primary)
    }

    private func entry(
        _ title: String, symbol: String, state: Loadable<String?>, empty: String,
        action: String, destination: HomeDestination, primary: Bool
    ) -> some View {
        HStack(alignment: .center, spacing: UMCSpacing.value16) {
            VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                Label(title, systemImage: symbol)
                    .umcTypography(.headlineBold)
                    .foregroundStyle(primary ? UMCColor.Semantic.textBrandDefault : .secondary)
                switch state {
                case .idle, .loading:
                    ProgressView().controlSize(.small).accessibilityLabel(title + " 불러오는 중")
                case .loaded(let value):
                    Text(value ?? empty)
                        .umcTypography(primary && value != nil ? .title1Bold : .headlineRegular)
                        .fixedSize(horizontal: false, vertical: true)
                case .failed:
                    Text("불러오지 못했어요").foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: UMCSpacing.value8)
            navigationButton(action, destination: destination)
        }
        .padding(.horizontal, UMCSpacing.value20)
        .padding(.vertical, primary ? UMCSpacing.value20 : UMCSpacing.value8)
        .background {
            if primary {
                RoundedRectangle(cornerRadius: UMCRadius.value12)
                    .fill(UMCColor.Custom.backgroundSurfaceGreyWeaker)
            }
        }
        .accessibilityElement(children: .contain)
    }

    @ViewBuilder
    private func navigationButton(_ title: String, destination: HomeDestination) -> some View {
        if let onOpen {
            Button(title) { onOpen(destination) }
                .fixedSize()
        }
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
