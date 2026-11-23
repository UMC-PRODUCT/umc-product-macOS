//  MiniGameRoundTests.swift
//  HomeDomainTests
//
//  Created by euijjang97 on 11/23/26.
//

import Testing

@testable import HomeDomain

@Test func missedObstacleEndsRound() {
    var game = MiniGameRound(game: .jump)
    for _ in 0..<300 { game.advance(seconds: 1 / 60) }
    #expect(game.finished)
    #expect(!game.cleared)
}

@Test func jumpClearsFirstObstacle() {
    var game = MiniGameRound(game: .jump)
    while game.obstacle > 38 { game.advance(seconds: 1 / 60) }
    game.act()
    for _ in 0..<100 { game.advance(seconds: 1 / 60) }
    #expect(game.score >= 50)
    #expect(!game.finished)
}

@Test func towerTracksOverlapAndStopsOnMiss() {
    var game = MiniGameRound(game: .tower)
    game.act()
    #expect(game.score == 50)
    #expect(game.layers.last?.width == 10)
    game.act()
    #expect(game.finished)
}

@Test func paddleIsClampedAndBallRemovesBricks() {
    var game = MiniGameRound(game: .bricks)
    game.movePaddle(to: -50)
    #expect(game.paddle == 12)
    for _ in 0..<100 {
        game.movePaddle(to: game.ball.x)
        game.advance(seconds: 1 / 60)
    }
    #expect(game.bricks.count < 24)
}
