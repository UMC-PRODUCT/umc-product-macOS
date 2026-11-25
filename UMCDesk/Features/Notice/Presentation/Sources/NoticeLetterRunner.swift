//  NoticeLetterRunner.swift
//  NoticePresentation
//
//  Created by euijjang97 on 11/25/26.

import CoreDesignSystem
import CoreUIComponents
import SwiftUI
import UMCFoundation

enum NoticeConnectionFailure {
    static func matches(_ error: any Error) -> Bool {
        if let error = error as? URLError {
            return [.cannotFindHost, .cannotConnectToHost, .dnsLookupFailed,
                    .networkConnectionLost, .notConnectedToInternet, .timedOut].contains(error.code)
        }
        switch error as? UMCFoundation.NetworkError {
        case .noNetwork, .timeout: return true
        case .requestFailed(let status, _): return status == 408 || (500...599).contains(status)
        default: return false
        }
    }
}

/// Fixed playfield units keep the artwork and collision bounds aligned as the pane resizes.
struct LetterRun {
    enum Phase { case ready, running, finished }
    private(set) var phase = Phase.ready
    private(set) var score = 0
    private(set) var obstacle = 270.0
    private(set) var height = 0.0
    private var velocity = 0.0

    static let letterX = 38.0
    static let letterWidth = 25.0
    static let bottleWidth = 14.0
    static let bottleHeight = 18.0

    mutating func jump() {
        if phase == .finished { self = Self() }
        phase = .running
        if height == 0 { velocity = 210 }
    }

    mutating func step() {
        guard phase == .running else { return }
        let dt = 1.0 / 30
        height = max(0, height + velocity * dt)
        velocity = height > 0 ? velocity - 560 * dt : 0
        obstacle -= (127 + Double(min(score, 12)) * 3) * dt
        if obstacle < Self.letterX + Self.letterWidth,
           obstacle + Self.bottleWidth > Self.letterX, height < Self.bottleHeight {
            phase = .finished
        } else if obstacle < -Self.bottleWidth {
            score += 1
            obstacle = 300
        }
    }
}

struct NoticeLetterRunner: View {
    @State private var run = LetterRun()
    @Environment(\.appearsActive) private var active
    @Environment(\.scenePhase) private var scene

    private var instruction: String {
        switch run.phase {
        case .ready: AppLocalization.string("클릭 또는 스페이스로 시작")
        case .running: AppLocalization.string("클릭 또는 스페이스로 점프")
        case .finished: AppLocalization.string("부딪혔어요 · 다시 한 판")
        }
    }

    var body: some View {
        let title = AppLocalization.string("편지 배달")
        let score = AppLocalization.string("\(run.score)점")
        UMCFocusableButton(
            title, identifier: "notice.connection.runner", cornerRadius: 12,
            accessibilityValue: score + ", " + instruction, action: { run.jump() }
        ) { _ in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(title).umcTypography(.headlineBold)
                    Spacer()
                    Text(score).monospacedDigit()
                }
                Canvas { context, size in
                    let scale = size.width / 300
                    context.scaleBy(x: scale, y: scale)
                    let floor = size.height / scale - 2
                    context.fill(Path(CGRect(x: 0, y: floor, width: 300, height: 1)),
                                 with: .foreground)
                    let paper = CGRect(x: LetterRun.letterX, y: floor - 17 - run.height,
                                       width: LetterRun.letterWidth, height: 17)
                    context.fill(Path(roundedRect: paper, cornerRadius: 3),
                                 with: .color(UMCColor.Semantic.textBrandDefault))
                    var fold = Path()
                    fold.move(to: CGPoint(x: paper.minX + 2, y: paper.minY + 3))
                    fold.addLine(to: CGPoint(x: paper.midX, y: paper.midY + 1))
                    fold.addLine(to: CGPoint(x: paper.maxX - 2, y: paper.minY + 3))
                    context.stroke(fold, with: .color(UMCColor.Custom.backgroundSurface),
                                   lineWidth: 1.5)
                    let bottle = CGRect(x: run.obstacle, y: floor - 13,
                                        width: LetterRun.bottleWidth, height: 13)
                    context.fill(Path(roundedRect: bottle, cornerRadius: 3), with: .foreground)
                    context.fill(Path(CGRect(x: bottle.minX + 3, y: floor - LetterRun.bottleHeight,
                                             width: bottle.width - 6, height: 6)), with: .foreground)
                }
                .frame(height: 72)
                Text(instruction).umcTypography(.captionRegular).foregroundStyle(.secondary)
            }
            .padding(12)
            .background(UMCColor.Custom.backgroundSurface, in: .rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(UMCColor.Semantic.borderNeutralWeak200)
            }
            .contentShape(.rect)
        }
        .frame(maxWidth: 324)
        .task(id: active && scene == .active && run.phase == .running) {
            guard active, scene == .active, run.phase == .running else { return }
            while !Task.isCancelled && run.phase == .running {
                do { try await Task.sleep(for: .seconds(1.0 / 30)) } catch { return }
                guard active, scene == .active else { return }
                run.step()
            }
        }
    }
}
