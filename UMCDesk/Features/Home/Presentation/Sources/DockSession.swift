//  DockSession.swift
//  HomePresentation
//
//  Created by euijjang97 on 11/25/26.
//

import AppKit
import HomeDomain
import SceneKit
import SwiftUI

@MainActor @Observable
final class DockSession {
    var round = DockRound()
    var started = false
    var paused = false
    var confirmingExit = false
    var keys: Set<UInt16> = []
    var sensitivity = 1.0
    var effects = 0.7
    var reduced = false
    var running: Bool { started && !paused && !confirmingExit && round.playing }
    func suspend() {
        keys.removeAll()
        if started && (round.playing || round.phase == .choice) { paused = true }
    }
}

struct DockSessionView: View {
    @State private var session = DockSession()
    @FocusState private var focus: String?
    @Environment(\.accessibilityReduceMotion) private var reduced
    let record: (Int) -> Void
    let close: () -> Void

    private var objective: String {
        switch session.round.phase {
        case .reception: "빈 봉투에 첫 소인을 찍으세요"
        case .first: "첫 파동 · 정령 세 장 펼치기"
        case .choice: "인장을 고르세요"
        case .second: "둘째 파동 · 북쪽 우편물 펼치기"
        case .boss: session.round.exposed ? "열린 봉투 면에 소인을 찍으세요" : "소인기 세 면 펼치기"
        case .won: "배달 완료"
        case .lost: "봉인 소진"
        }
    }

    var body: some View {
        ZStack {
            DockSurface(session: session)
            if session.running {
                VStack {
                    HStack {
                        Label(objective, systemImage: "envelope")
                        Spacer()
                        Text("봉인 \(session.round.health)/3 · \(session.round.score)점")
                    }
                    .padding(12).background(.black.opacity(0.88))
                    Spacer()
                    Text(session.round.seal == .pair ? "◎ ◎" : (session.round.hit ? "◉" : "◎"))
                        .font(.system(size: 23, weight: .bold))
                        .shadow(color: .black, radius: 1)
                    Spacer()
                    Text(caption).padding(9).background(.black.opacity(0.88), in: Capsule())
                }
                .padding(14).foregroundStyle(.white).allowsHitTesting(false)
            } else {
                VStack(alignment: .leading, spacing: 12) { panel }
                    .padding(24)
                    .frame(maxWidth: 410, alignment: .leading)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 15))
            }
        }
        .onChange(of: reduced, initial: true) { _, value in session.reduced = value }
        .onChange(of: session.round.phase) { _, phase in
            if phase == .won || phase == .lost { record(session.round.score); focus = "retry" }
            if phase == .choice { focus = DockRound.Seal.pair.rawValue }
        }
        .onChange(of: session.paused) { _, value in if value { focus = "resume" } }
        .onAppear { focus = "start" }
    }

    private var caption: String {
        let r = session.round
        if r.hasWarning {
            if r.phase == .boss { return r.safeX > 0 ? "⚠ 동쪽 통로로 이동 →" : "⚠ ← 서쪽 통로로 이동" }
            return "⚠ 발밑의 고리 밖으로 이동"
        }
        if r.phase == .boss { return "우편종지기 · 남은 면 \(r.faces)" }
        if let seal = r.seal { return "\(seal.rawValue) · \(seal.action) · Esc 일시 정지" }
        return "WASD 이동　← → 시점　F 소인　Esc 일시 정지"
    }

    @ViewBuilder private var panel: some View {
        if session.confirmingExit {
            Text("이번 배달을 끝낼까요?").font(.title.bold())
            Text("진행 중인 판의 점수는 저장되지 않아요.")
            Button("판 끝내기", action: close)
            Button("계속하기") { session.confirmingExit = false; session.paused = false }
        } else if session.paused {
            Text("일시 정지").font(.title.bold())
            Button("계속하기") { session.paused = false }.focused($focus, equals: "resume")
            Button("홈으로") { session.confirmingExit = true }
        } else if !session.started {
            Text("소인이 찍겠습니다!").font(.largeTitle.bold())
            Text("꾹이와 함께 접지부두의 마지막 우편물을 펼치세요.")
            Text("WASD 이동 · 마우스 또는 ← → 회전\n클릭 또는 F 소인 · Esc 일시 정지")
            Slider(value: $session.sensitivity, in: 0.3...2) { Text("시점 감도") }
            Slider(value: $session.effects, in: 0...1) { Text("효과음") }
            HStack {
                Button("배달 시작") { session.started = true }.focused($focus, equals: "start")
                Button("홈으로", action: close)
            }
        } else if session.round.phase == .choice {
            Text("인장을 고르세요").font(.title.bold())
            ForEach(DockRound.Seal.allCases, id: \.self) { seal in
                Button(seal.rawValue + " · " + seal.action) { session.round.choose(seal) }
                    .focused($focus, equals: seal.rawValue)
            }
            .onMoveCommand { direction in
                let seals = DockRound.Seal.allCases
                let index = seals.firstIndex { $0.rawValue == focus } ?? 0
                let delta = direction == .up || direction == .left ? 2 : 1
                focus = seals[(index + delta) % 3].rawValue
            }
        } else {
            Text(objective).font(.largeTitle.bold())
            Text("펼친 정령 \(session.round.opened) · \(session.round.seal?.rawValue ?? "기본 인장")")
            Text("배달 보너스 \(session.round.phase == .won ? 300 : 0) · 합계 \(session.round.score)점")
            HStack {
                Button("다시 한 판") {
                    session.round = DockRound()
                    session.started = false
                    focus = "start"
                }.focused($focus, equals: "retry")
                Button("홈으로", action: close)
            }
        }
    }
}

private struct DockSurface: NSViewRepresentable {
    let session: DockSession
    func makeNSView(context: Context) -> DockViewport { DockViewport(session) }
    func updateNSView(_ view: DockViewport, context: Context) { view.capture(session.running) }
    static func dismantleNSView(_ view: DockViewport, coordinator: ()) { view.stop() }
}

@MainActor
private final class DockViewport: SCNView {
    let session: DockSession
    let art = DockScenery()
    var link: CADisplayLink?
    var monitor: Any?
    var captured = false
    var previous = 0.0
    var elapsed = 0.0
    let tap = NSSound(named: "Pop")
    let bell = NSSound(named: "Glass")

    init(_ session: DockSession) {
        self.session = session
        super.init(frame: .zero, options: nil)
        scene = art.scene
        pointOfView = art.camera
        antialiasingMode = .multisampling2X
        preferredFramesPerSecond = 60
        art.draw(session.round, time: 0, reduced: session.reduced)
    }

    required init?(coder: NSCoder) { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let window else { stop(); return }
        guard link == nil else { return }
        for name in [NSWindow.didResignKeyNotification, NSWindow.willMiniaturizeNotification,
                     NSWindow.willCloseNotification] {
            NotificationCenter.default.addObserver(self, selector: #selector(interrupt),
                                                   name: name, object: window)
        }
        link = displayLink(target: self, selector: #selector(frameTick))
        link?.add(to: .main, forMode: .common)
        monitor = NSEvent.addLocalMonitorForEvents(
            matching: [.keyDown, .keyUp, .mouseMoved, .leftMouseDown, .leftMouseDragged]
        ) { [weak self] event in
            guard let self, event.window === self.window, self.captured,
                  !event.modifierFlags.contains(.command),
                  !event.modifierFlags.contains(.control) else { return event }
            switch event.type {
            case .mouseMoved, .leftMouseDragged:
                self.session.round.turn(event.deltaX * 0.004 * self.session.sensitivity)
            case .leftMouseDown:
                self.session.round.stamp()
            case .keyUp:
                self.session.keys.remove(event.keyCode)
            case .keyDown:
                switch event.keyCode {
                case 53: self.interrupt()
                case 3: if !event.isARepeat { self.session.round.stamp() }
                case 49: if !event.isARepeat { self.session.round.slide() }
                case 0, 1, 2, 13, 123, 124: self.session.keys.insert(event.keyCode)
                default: return event
                }
            default: return event
            }
            return nil
        }
    }

    @objc func interrupt() { session.suspend(); capture(false) }

    func capture(_ requested: Bool) {
        let enable = requested && window?.isKeyWindow == true
        guard enable != captured else { return }
        captured = enable
        previous = 0
        session.keys.removeAll()
        if enable {
            NSCursor.hide()
            CGAssociateMouseAndMouseCursorPosition(0)
        } else {
            CGAssociateMouseAndMouseCursorPosition(1)
            NSCursor.unhide()
        }
    }

    @objc func frameTick(_ link: CADisplayLink) {
        capture(session.running)
        let step = previous == 0 ? 0 : min(0.05, link.timestamp - previous)
        previous = link.timestamp
        if session.running && captured {
            func axis(_ positive: UInt16, _ negative: UInt16) -> Double {
                Double((session.keys.contains(positive) ? 1 : 0) - (session.keys.contains(negative) ? 1 : 0))
            }
            session.round.turn(axis(124, 123) * step * 1.9)
            session.round.move(strafe: axis(2, 0), forward: axis(13, 1), seconds: step)
            let wasHit = session.round.hit, wasWarned = session.round.hasWarning
            session.round.advance(step)
            if !wasHit && session.round.hit { sound(tap) }
            if !wasWarned && session.round.hasWarning { sound(bell) }
            if !session.running { capture(false) }
            elapsed += step
        } else if !session.started { elapsed += step }
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0
        art.draw(session.round, time: elapsed, reduced: session.reduced)
        SCNTransaction.commit()
    }

    private func sound(_ sample: NSSound?) {
        guard session.effects > 0 else { return }
        sample?.volume = Float(session.effects)
        sample?.play()
    }

    func stop() {
        capture(false)
        link?.invalidate()
        link = nil
        if let monitor { NSEvent.removeMonitor(monitor); self.monitor = nil }
        tap?.stop()
        bell?.stop()
        NotificationCenter.default.removeObserver(self)
    }
}
