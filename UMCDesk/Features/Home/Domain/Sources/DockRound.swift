//  DockRound.swift
//  HomeDomain
//
//  Created by euijjang97 on 11/25/26.
//

import Foundation
import simd

/// The dock lies on an x/z plane. North is negative z and the reception desk faces north.
public struct DockRound {
    public enum Phase { case reception, first, choice, second, boss, won, lost }
    public enum Seal: String, CaseIterable, Sendable {
        case pair = "겹우표", echo = "메아리인", slide = "여백접기"
        public var action: String {
            switch self {
            case .pair: "나란히 찍기"
            case .echo: "한 박자 뒤 다시 찍기"
            case .slide: "Space로 내 자리 비우기"
            }
        }
    }
    public struct Spirit: Identifiable {
        public let id: Int
        public fileprivate(set) var position: SIMD2<Double>
        public var folds: Int
        public let kite: Bool
    }
    public private(set) var phase = Phase.reception
    public private(set) var position = SIMD2<Double>(0, 8)
    public private(set) var heading = 0.0
    public private(set) var health = 3
    public private(set) var spirits: [Spirit] = []
    public private(set) var seal: Seal?
    public private(set) var opened = 0
    public private(set) var faces = 3
    public private(set) var beat = 0.0
    public private(set) var warningPoint = SIMD2<Double>.zero
    public private(set) var slideWait = 0.0
    public private(set) var stampTime = 0.0
    public private(set) var hit = false
    public private(set) var hasWarning = false
    public var exposed: Bool { phase == .boss && beat > 2.5 && (faces != 1 || finalSweep) }
    public var score: Int { opened * 50 + (phase == .won ? 300 : 0) }
    public var playing: Bool { [.reception, .first, .second, .boss].contains(phase) }
    public var direction: SIMD2<Double> { .init(sin(heading), -cos(heading)) }
    public var safeX: Double { laneCenter(at: position.y) }
    public var slope: Double { faces == 2 || (faces == 1 && !finalSweep) ? -0.14 : 0.14 }
    public func laneCenter(at z: Double) -> Double { (slope < 0 ? -3.0 : 3.0) + slope * z }
    public private(set) var attacker: Int?
    public private(set) var finalSweep = false
    public var incomingGate: String? {
        guard let next = queue.first else { return nil }
        return next.0 < 0 ? "서쪽 봉투문" : "동쪽 우표문"
    }
    public static let bossPosition = SIMD2<Double>(0, -10)
    private var group = 0
    private var serial = 0
    private var attackIndex = 0
    private var jumpStart = SIMD2<Double>.zero
    private var guardTime = 0.0
    private var nextSpawn = 0.0
    private var queue: [(Double, Double, Bool)] = []
    public private(set) var impactPoint = SIMD2<Double>.zero
    public private(set) var echoPoint: SIMD2<Double>?
    private var echoWait = 0.0
    private var pendingImpact = false
    private var lastMove = SIMD2<Double>(0, -1)

    public init() {}

    public mutating func turn(_ angle: Double) {
        heading = (heading + angle).truncatingRemainder(dividingBy: 2 * .pi)
    }

    public mutating func move(strafe: Double, forward: Double, seconds: Double) {
        let delta = SIMD2(-direction.y, direction.x) * strafe + direction * forward
        guard playing, simd_length_squared(delta) > 0 else { return }
        lastMove = simd_normalize(delta)
        walk(lastMove * min(seconds, 0.05) * 4.5)
    }

    private mutating func walk(_ delta: SIMD2<Double>) {
        func clear(_ p: SIMD2<Double>) -> Bool {
            abs(p.x) <= 7.4 && p.y <= 9.8 && p.y >= (seal == nil ? -3.8 : -10.7)
                && !(abs(p.x) < 1.5 && abs(p.y - 1) < 1.2)
        }
        let side = position + SIMD2(delta.x, 0)
        if clear(side) { position = side }
        let ahead = position + SIMD2(0, delta.y)
        if clear(ahead) { position = ahead }
    }

    public mutating func slide() {
        guard playing, seal == .slide, slideWait == 0 else { return }
        for _ in 0..<12 { walk(lastMove * 0.2) }
        slideWait = 3
    }

    public mutating func stamp() {
        guard playing, stampTime == 0 else { return }
        stampTime = 0.38
        pendingImpact = true
        hit = false
    }

    public mutating func choose(_ choice: Seal) {
        guard phase == .choice else { return }
        seal = choice
        phase = .second
        wave()
    }

    private mutating func wave() {
        if phase == .first {
            queue = [(-3, -1, false), (-2, -2, false), (3, -3, true)]
        } else {
            let x = group == 0 ? -2.0 : 3.0
            queue = [(x - 0.8, -6, false), (x + 0.8, -6, false), (x, -8, true)]
        }
        beat = 0
        nextSpawn = 0.7
        hasWarning = false
    }

    public mutating func advance(_ seconds: Double) {
        guard playing else { return }
        let step = min(max(0, seconds), 0.05)
        slideWait = max(0, slideWait - step)
        guardTime = max(0, guardTime - step)
        stampTime = max(0, stampTime - step)
        if pendingImpact, stampTime <= 0.22 {
            pendingImpact = false
            impact()
        }
        guard playing, phase != .reception else { return }
        if let point = echoPoint {
            echoWait -= step
            if echoWait <= 0 {
                echoPoint = nil
                if let index = spirits.firstIndex(where: { simd_distance($0.position, point) < 1 }) {
                    unfold(index)
                }
            }
        }
        if !queue.isEmpty {
            nextSpawn -= step
            if nextSpawn <= 0 {
                let (x, z, kite) = queue.removeFirst()
                serial += 1
                var entry = SIMD2(x, z)
                if simd_distance(entry, position) < 2.4 { entry.x = position.x < 0 ? 5 : -5 }
                spirits.append(.init(id: serial, position: entry, folds: kite ? 2 : 1,
                                     kite: kite))
                nextSpawn = phase == .second ? 0.28 : 1.1
            }
        }
        if phase != .boss, spirits.isEmpty, queue.isEmpty {
            echoPoint = nil
            if phase == .first { phase = .choice }
            else if group == 0 { group = 1; wave() }
            else { phase = .boss; beat = 0 }
            hasWarning = false
            return
        }
        let prior = beat
        beat += step
        if prior < 0.9, beat >= 0.9 {
            warningPoint = position
            if phase != .boss, !spirits.isEmpty {
                let spirit = spirits[attackIndex % spirits.count]
                attacker = spirit.id
                jumpStart = spirit.position
                attackIndex += 1
            }
            hasWarning = true
        }
        if phase != .boss, beat > 1.9, beat <= 2.55,
           let index = spirits.firstIndex(where: { $0.id == attacker && !$0.kite }) {
            let t = min(1, (beat - 1.9) / 0.6)
            spirits[index].position = jumpStart + (warningPoint - jumpStart) * t
        }
        if prior < 2.5, beat >= 2.5 {
            let danger = phase == .boss
                ? abs(position.x - safeX) > 2.1
                : simd_distance(position, warningPoint) < 1.65
            if danger, guardTime == 0, phase == .boss || spirits.contains(where: { $0.id == attacker }) { health -= 1; guardTime = 1 }
            hasWarning = false
            if health == 0 { phase = .lost }
            if phase == .boss && faces == 1 && !finalSweep {
                finalSweep = true
                beat = 0
            }
        }
        if beat >= (phase == .boss ? 6 : 4.4) { beat = 0 }
    }

    private mutating func unfold(_ index: Int) {
        spirits[index].folds -= 1
        if spirits[index].folds == 0 { spirits.remove(at: index); opened += 1 }
    }

    private func aim(_ target: SIMD2<Double>, radius: Double) -> Bool {
        let delta = target - position
        let ahead = simd_dot(direction, delta)
        return ahead > 0 && abs(direction.x * delta.y - direction.y * delta.x) < radius
    }

    private mutating func impact() {
        impactPoint = position + direction * 3
        if phase == .reception {
            guard aim(.init(0, 5), radius: 1.6) else { return }
            phase = .first
            hit = true
            wave()
        } else if phase == .boss {
            guard exposed, aim(Self.bossPosition, radius: 2) else { return }
            impactPoint = Self.bossPosition - direction * 0.9
            faces -= 1
            hit = true
            beat = 0
            if faces == 0 { phase = .won }
        } else {
            let targets = spirits.filter { aim($0.position, radius: seal == .pair ? 1.7 : 0.95) }
                .sorted { simd_distance($0.position, position) < simd_distance($1.position, position) }
            for target in targets.prefix(seal == .pair ? 2 : 1) {
                guard let index = spirits.firstIndex(where: { $0.id == target.id }) else { continue }
                hit = true
                impactPoint = target.position - direction * 0.3
                unfold(index)
                if seal == .echo { echoPoint = target.position; echoWait = 0.48 }
            }
        }
    }
}
