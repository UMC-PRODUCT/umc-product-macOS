//
//  WindowNavigation.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 11/25/26.
//

import CoreRouting
import SwiftUI

enum WindowLocation: Equatable {
    case section(DeskSection)
    case settings(SettingsPage)
    case matching
    case feature(WindowDetail)
}

struct WindowVisit: Equatable {
    let location: WindowLocation
    var detail: WindowDetail?
}

struct WindowHistory {
    private var visits: [WindowVisit] = []
    private var index = 0

    var current: WindowVisit? { visits.isEmpty ? nil : visits[index] }
    var canGoBack: Bool { index > 0 }
    var canGoForward: Bool { index + 1 < visits.count }

    mutating func visit(_ destination: WindowVisit) {
        guard current != destination else { return }
        if canGoForward { visits.removeSubrange((index + 1)...) }
        visits.append(destination)
        index = visits.count - 1
    }

    mutating func back() -> WindowVisit? {
        guard canGoBack else { return nil }
        index -= 1
        return current
    }

    mutating func forward() -> WindowVisit? {
        guard canGoForward else { return nil }
        index += 1
        return current
    }
}

/// Feature routers supply the key needed to reopen a specific matching or project page.
struct WindowFeatureNavigation: Sendable {
    let location: WindowDetail?
    let restore: @MainActor (WindowDetail) -> Void
}

extension EnvironmentValues {
    @Entry var windowFeatureRouter: WindowFeatureNavigation?
}

public extension View {
    func windowFeatureNavigation<Route: Equatable & Sendable>(
        location: Route?, restore: @escaping @MainActor (Route) -> Void
    ) -> some View {
        let router = WindowFeatureNavigation(location: location.map(WindowDetail.init)) {
            if let route = $0.route(as: Route.self) { restore(route) }
        }
        return environment(\.windowFeatureRouter, router)
    }
}
