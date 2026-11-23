//
//  Routing.swift
//  CoreRouting
//
//  Created by euijjang97 on 10/6/26.
//

import Foundation

public enum DeskWindow {
    public static let updates = "updates"
    public static let support = "support"
}

public enum DeskSection: String, CaseIterable, Sendable {
    case home, notice, activity, threads, projects

    public var title: String {
        switch self {
        case .home: "홈"
        case .notice: "공지"
        case .activity: "활동"
        case .threads: "스레드"
        case .projects: "프로젝트"
        }
    }

    public var symbol: String {
        switch self {
        case .home: "house"
        case .notice: "megaphone"
        case .activity: "calendar.badge.checkmark"
        case .threads: "bubble.left"
        case .projects: "square.grid.2x2"
        }
    }
}
