//  DockPerformanceHost.swift
//  UMCDesk QA
//
//  Created by euijjang97 on 11/25/26.
//

import Foundation
import HomeDomain
import HomePresentation
import SwiftUI

/// Standalone profiling entry point. Only the four home summary reads use local data.
private struct LocalSummary: HomeRepository {
    func profile() async throws -> HomeProfile { HomeProfile(id: "dock-qa", nickname: "꾹이") }
    func schedule() async throws -> HomeSchedule? { nil }
    func notice() async throws -> String? { nil }
    func project() async throws -> String? { nil }
}

@main
struct DockPerformanceHost: App {
    var body: some Scene {
        Window("접지부두 · Release 검수", id: "dock") {
            HomeView(repository: LocalSummary(), memberID: "dock-qa")
                .frame(minWidth: 720, minHeight: 520)
        }
        .defaultSize(width: 960, height: 620)
    }
}
