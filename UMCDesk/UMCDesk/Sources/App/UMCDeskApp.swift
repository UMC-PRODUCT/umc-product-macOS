//
//  UMCDeskApp.swift
//  UMCDesk
//
//  Created by euijjang97 on 10/6/26.
//

import SwiftUI
import AuthPresentation
import CoreUIComponents

@main
struct UMCDeskApp: App {
    private let dependencies = AppDependencies()

    var body: some Scene {
        WindowGroup("UMC Desk") {
            AuthView()
                .toggleStyle(UMCCheckboxStyle())
                .frame(minWidth: 1040, minHeight: 720)
        }
        .defaultSize(width: 1440, height: 960)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}
