//  DockRoundTests.swift
//  HomeDomainTests
//
//  Created by euijjang97 on 11/25/26.
//

import Foundation
import Testing

@testable import HomeDomain

private func tick(_ round: inout DockRound, frames: Int) {
    for _ in 0..<frames { round.advance(1 / 60) }
}

private func aim(_ round: inout DockRound, at target: SIMD2<Double>) {
    let delta = target - round.position
    round.turn(atan2(delta.x, -delta.y) - round.heading)
}

@Test func dockStartsOnlyAfterStampImpact() {
    var round = DockRound()
    round.stamp()
    tick(&round, frames: 5)
    #expect(round.phase == .reception)
    tick(&round, frames: 9)
    #expect(round.phase == .first)
}

@Test(arguments: DockRound.Seal.allCases)
func deliversNineSpiritsAndThreeFaces(seal: DockRound.Seal) {
    var round = DockRound()
    round.stamp()
    var chose = false
    for _ in 0..<9_000 where round.phase != .won && round.phase != .lost {
        if round.phase == .choice {
            tick(&round, frames: 600)
            #expect(round.health > 0)
            round.choose(seal)
            chose = true
        }
        if let first = round.spirits.first {
            aim(&round, at: first.position)
            round.stamp()
        } else if round.phase == .boss {
            if abs(round.position.x - round.safeX) > 0.2 {
                round.turn(-round.heading)
                round.move(strafe: round.position.x < round.safeX ? 1 : -1,
                           forward: 0, seconds: 1 / 60)
            }
            if round.exposed { aim(&round, at: DockRound.bossPosition); round.stamp() }
        }
        tick(&round, frames: 1)
    }
    #expect(chose)
    #expect(round.phase == .won)
    #expect(round.score == 750)
    tick(&round, frames: 300)
    #expect(round.score == 750)
}

@Test func threeUnavoidedWarningsEndDelivery() {
    var round = DockRound()
    round.stamp()
    tick(&round, frames: 1000)
    #expect(round.phase == .lost)
    #expect(round.health == 0)
    #expect(round.score == 0)
}
