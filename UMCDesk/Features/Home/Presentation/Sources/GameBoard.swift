//  GameBoard.swift
//  HomePresentation
//
//  Created by euijjang97 on 11/23/26.
//

import CoreDesignSystem
import HomeDomain
import SwiftUI

extension MiniGame {
    var title: String {
        switch self {
        case .jump: "블록 점프"
        case .bricks: "벽돌 깨기"
        case .tower: "타이밍 탑 쌓기"
        }
    }

    var summary: String {
        switch self {
        case .jump: "블록을 넘으며 오래 버티기"
        case .bricks: "공을 튕겨 벽돌을 전부 없애기"
        case .tower: "움직이는 블록을 맞춰 20층 쌓기"
        }
    }

    var controls: String { self == .bricks ? "마우스 / ← →" : "Space / 클릭" }
}

struct GameBoard: View {
    let round: MiniGameRound
    var preview = false

    var body: some View {
        Canvas { context, size in
            let scaleX = size.width / 100
            let scaleY = size.height / 60
            func block(_ rect: CGRect, color: Color) {
                let frame = CGRect(
                    x: rect.minX * scaleX, y: rect.minY * scaleY,
                    width: rect.width * scaleX, height: rect.height * scaleY)
                context.fill(Path(roundedRect: frame, cornerRadius: 2), with: .color(color))
            }
            let brand = UMCColor.Semantic.surfaceBrandInverse
            switch round.game {
            case .jump:
                block(CGRect(x: 0, y: 53, width: 100, height: 1), color: .secondary)
                block(CGRect(x: 18, y: 45 - round.player, width: 6, height: 8), color: brand)
                block(
                    CGRect(x: preview ? 70 : round.obstacle, y: 46, width: 5, height: 7),
                    color: .secondary)
            case .bricks:
                for index in round.bricks {
                    block(MiniGameRound.brickRect(index), color: index < 8 ? .secondary : brand)
                }
                block(CGRect(x: round.paddle - 12, y: 55, width: 24, height: 2), color: .primary)
                block(
                    CGRect(x: round.ball.x - 1, y: round.ball.y - 1, width: 2, height: 2),
                    color: brand)
            case .tower:
                if preview {
                    for layer in 0..<5 {
                        block(
                            CGRect(
                                x: 25 + layer * 3, y: 50 - layer * 8,
                                width: 45 - layer * 3, height: 6), color: brand)
                    }
                } else {
                    for layer in round.layers {
                        block(
                            CGRect(
                                x: layer.minX, y: 57 - layer.minY * 2.6,
                                width: layer.width, height: 2.5), color: brand)
                    }
                    block(
                        CGRect(
                            x: round.movingX, y: 57 - Double(round.layers.count) * 2.6,
                            width: round.layers.last?.width ?? 40, height: 2.5),
                        color: .primary)
                }
            }
        }
        .background(UMCColor.Custom.backgroundSurface)
        .accessibilityHidden(true)
    }
}

struct GameSessionView: View {
    @State private var round: MiniGameRound
    @State private var paused = false
    @State private var startingStage: Int
    let records: GameRecords
    @Environment(\.scenePhase) private var scenePhase
    @FocusState private var focused: Bool
    let record: (MiniGame, Int) -> Void
    let close: () -> Void

    init(
        game: MiniGame, records: GameRecords, record: @escaping (MiniGame, Int) -> Void,
        close: @escaping () -> Void
    ) {
        _round = State(initialValue: MiniGameRound(game: game))
        self.records = records
        _startingStage = State(initialValue: Self.stage(records.totals[game.rawValue, default: 0]))
        self.record = record
        self.close = close
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Button("홈으로", systemImage: "chevron.left", action: close)
                Spacer()
                Text("\(round.score)점").monospacedDigit()
            }
            Text("잠깐 쉬어가는 시간").umcTypography(.largeTitle3Bold)
            Text(round.game.title).umcTypography(.title2Bold)
            Text(round.game.summary + " · " + round.game.controls).foregroundStyle(.secondary)
            GameBoard(round: round)
                .frame(maxWidth: .infinity, maxHeight: 420)
                .overlay {
                    if round.finished || paused {
                        Text(paused ? "일시 정지" : resultTitle)
                            .umcTypography(.largeTitle3Bold).padding().background(
                                .regularMaterial, in: Capsule())
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    if !paused { round.act() }
                    focused = true
                }
                .overlay {
                    if round.game == .bricks {
                        PaddleTrackingView { position in
                            if !paused { round.movePaddle(to: position) }
                        }
                    }
                }
            HStack {
                if round.finished {
                    Button("다시 한 판") {
                        startingStage = Self.stage(records.totals[round.game.rawValue, default: 0])
                        round = MiniGameRound(game: round.game)
                        focused = true
                    }
                } else {
                    Button(paused ? "계속하기" : "일시 정지") {
                        paused.toggle()
                        focused = true
                    }
                }
                Spacer()
                let id = round.game.rawValue
                Text("최고 기록 \(records.best[id, default: 0])점")
                Text("누적 점수 \(records.totals[id, default: 0])점")
                Text("\(Self.stage(records.totals[id, default: 0])) / 3 단계")
            }
            if !records.recent.isEmpty {
                Text("최근 플레이").umcTypography(.headlineBold)
                Text(records.recent.joined(separator: "   /   ")).foregroundStyle(.secondary)
            }
        }
        .padding(32).focusable().focused($focused).focusEffectDisabled()
        .onAppear { focused = true }
        .onExitCommand {
            if round.finished {
                close()
            } else {
                paused = false
                round.end()
            }
        }
        .onKeyPress(.space) {
            if !paused { round.act() }
            return .handled
        }
        .onKeyPress(.leftArrow) { move(-5) }
        .onKeyPress(.rightArrow) { move(5) }
        .onChange(of: round.finished) { _, ended in if ended { record(round.game, round.score) } }
        .onChange(of: scenePhase) { _, phase in if phase != .active { paused = true } }
        .task(id: !paused && !round.finished) {
            guard !paused, !round.finished else { return }
            let clock = ContinuousClock()
            var last = clock.now
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(16)) } catch { break }
                let now = clock.now
                let elapsed = last.duration(to: now).components
                last = now
                if !paused && !round.finished {
                    round.advance(
                        seconds: Double(elapsed.seconds) + Double(elapsed.attoseconds) / 1e18)
                }
            }
        }
    }

    private var resultTitle: String {
        let stage = Self.stage(records.totals[round.game.rawValue, default: 0])
        if stage > startingStage { return "\(stage)단계 클리어!" }
        return round.cleared ? "클리어!" : "한 판 끝!"
    }

    private static func stage(_ total: Int) -> Int {
        [500, 1500, 3000].filter { total >= $0 }.count
    }

    private func move(_ offset: Double) -> KeyPress.Result {
        guard round.game == .bricks, !paused else { return .ignored }
        round.movePaddle(to: round.paddle + offset)
        return .handled
    }
}

private struct PaddleTrackingView: NSViewRepresentable {
    let move: (Double) -> Void
    func makeNSView(context: Context) -> TrackingSurface { TrackingSurface() }
    func updateNSView(_ view: TrackingSurface, context: Context) { view.move = move }

    final class TrackingSurface: NSView {
        var move: ((Double) -> Void)?
        private var tracking: NSTrackingArea?

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            if let tracking { removeTrackingArea(tracking) }
            let area = NSTrackingArea(
                rect: .zero,
                options: [
                    .mouseMoved, .activeInKeyWindow,
                    .inVisibleRect,
                ], owner: self)
            addTrackingArea(area)
            tracking = area
        }

        override func mouseMoved(with event: NSEvent) {
            guard bounds.width > 0 else { return }
            move?(convert(event.locationInWindow, from: nil).x * 100 / bounds.width)
        }
    }
}
