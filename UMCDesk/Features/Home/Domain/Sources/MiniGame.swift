//  MiniGame.swift
//  HomeDomain
//
//  Created by euijjang97 on 11/23/26.
//

import CoreGraphics
import Foundation

public enum MiniGame: String, CaseIterable, Identifiable, Sendable {
    case jump, bricks, tower
    public var id: Self { self }
}

/// The board uses a fixed logical coordinate system, independent of window size.
public struct MiniGameRound {
    public let game: MiniGame
    public private(set) var score = 0
    public private(set) var finished = false
    public private(set) var cleared = false
    public private(set) var player = 0.0
    public private(set) var obstacle = 96.0
    public private(set) var paddle = 50.0
    public private(set) var ball = CGPoint(x: 50, y: 45)
    public private(set) var bricks = Set(0..<24)
    public private(set) var layers = [CGRect(x: 30, y: 0, width: 40, height: 1)]
    public private(set) var movingX = 0.0
    private var speedY = 0.0
    private var ballSpeed = CGPoint(x: 26, y: -37)
    private var towerDirection = 1.0

    public init(game: MiniGame) { self.game = game }

    public mutating func end() { finished = true }

    public mutating func movePaddle(to position: Double) {
        paddle = min(88, max(12, position))
    }

    public mutating func act() {
        guard !finished else { return }
        switch game {
        case .jump:
            if player == 0 { speedY = 62 }
        case .bricks:
            break
        case .tower:
            guard let last = layers.last else { return }
            let left = max(movingX, last.minX)
            let right = min(movingX + last.width, last.maxX)
            guard left < right else {
                finished = true
                return
            }
            layers.append(CGRect(x: left, y: Double(layers.count), width: right - left, height: 1))
            score += 50
            movingX = towerDirection > 0 ? 100 - (right - left) : 0
            towerDirection *= -1
            cleared = layers.count == 21
            finished = cleared
        }
    }

    public mutating func advance(seconds: Double) {
        guard !finished, seconds > 0 else { return }
        let step = min(seconds, 0.05)
        switch game {
        case .jump:
            player = max(0, player + speedY * step)
            speedY = player > 0 ? speedY - 150 * step : 0
            obstacle -= (39 + Double(min(score / 50, 10))) * step
            if obstacle < 24, obstacle + 5 > 18, player < 7 { finished = true }
            if obstacle < -5 {
                score += 50
                obstacle = 100
                cleared = score >= 1500
                finished = cleared
            }
        case .tower:
            let limit = 100 - (layers.last?.width ?? 40)
            movingX += towerDirection * (30 + Double(layers.count)) * step
            if movingX <= 0 || movingX >= limit {
                movingX = min(limit, max(0, movingX))
                towerDirection = movingX == 0 ? 1 : -1
            }
        case .bricks:
            advanceBall(step)
        }
    }

    public static func brickRect(_ index: Int) -> CGRect {
        CGRect(
            x: 3 + Double(index % 8) * 12, y: 6 + Double(index / 8) * 6,
            width: 10.8, height: 4.2)
    }

    private mutating func advanceBall(_ step: Double) {
        let prior = ball
        ball.x += ballSpeed.x * step
        ball.y += ballSpeed.y * step
        if ball.x < 1 || ball.x > 99 {
            ballSpeed.x *= -1
            ball.x = min(99, max(1, ball.x))
        }
        if ball.y < 1 {
            ballSpeed.y = abs(ballSpeed.y)
            ball.y = 1
        }
        if prior.y < 55, ball.y >= 55, abs(ball.x - paddle) <= 13 {
            ballSpeed.y = -abs(ballSpeed.y)
            ballSpeed.x = 3 * (ball.x - paddle)
            ball.y = 54.9
        }
        if let hit = bricks.sorted().first(where: {
            Self.brickRect($0).insetBy(dx: -0.8, dy: -0.8).contains(ball)
        }) {
            bricks.remove(hit)
            ballSpeed.y *= -1
            score += 50
            cleared = bricks.isEmpty
        }
        finished = cleared || ball.y > 60
    }
}
