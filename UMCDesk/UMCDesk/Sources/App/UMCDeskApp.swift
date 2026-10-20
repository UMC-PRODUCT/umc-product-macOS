//
//  UMCDeskApp.swift
//  UMCDesk
//
//  Created by euijjang97 on 10/6/26.
//

import SwiftUI
import AppKit
import AuthPresentation
import CoreDesignSystem
import CoreUIComponents
import SettingsDomain
import SettingsPresentation

@main
struct UMCDeskApp: App {
    @NSApplicationDelegateAdaptor(AppLifecycleDelegate.self) private var lifecycle
    private let dependencies = AppDependencies()

    var body: some Scene {
        @Bindable var preferences = dependencies.settingsPreferences

        WindowGroup("UMC Desk", id: "main") {
            AppRootView(dependencies: dependencies)
                .toggleStyle(UMCCheckboxStyle())
                .preferredColorScheme(preferences.theme.colorScheme)
                .environment(\.umcBodyTextScale, preferences.bodyTextSize.scale)
                .frame(minWidth: 1040, minHeight: 720)
                .onAppear { lifecycle.preferences = preferences }
        }
        .defaultSize(width: 1440, height: 960)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        .commands { AppSettingsCommands(dependencies: dependencies) }

        Settings {
            SettingsSceneView(dependencies: dependencies)
                .toggleStyle(UMCCheckboxStyle())
                .preferredColorScheme(preferences.theme.colorScheme)
                .environment(\.umcBodyTextScale, preferences.bodyTextSize.scale)
                .frame(minWidth: 1040, minHeight: 720)
        }
        .defaultSize(width: 1440, height: 960)
        .windowStyle(.hiddenTitleBar)

        MenuBarExtra(
            "UMC Desk", systemImage: "square.grid.2x2", isInserted: $preferences.showsMenuBar
        ) {
            AppMenuBarContent(dependencies: dependencies)
        }
    }
}

private struct AppRootView: View {
    let dependencies: AppDependencies
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Group {
            if dependencies.navigation.showsSettings {
                SettingsView(viewModel: dependencies.settingsViewModel)
            } else {
                AuthView()
                    .toolbar {
                        ToolbarItem(placement: .automatic) {
                            Button("설정", systemImage: "gearshape") {
                                dependencies.settingsViewModel.showSettings()
                                openSettings()
                            }
                            .help("설정 열기 (⌘,)")
                        }
                    }
            }
        }
        .onAppear { configureLoginAction() }
    }

    private func configureLoginAction() {
        dependencies.settingsViewModel.onOpenLogin = {
            dependencies.navigation.showsSettings = false
            openWindow(id: "main")
            NSApplication.shared.activate()
        }
    }
}

private struct SettingsSceneView: View {
    let dependencies: AppDependencies
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        SettingsView(viewModel: dependencies.settingsViewModel)
            .background(SettingsWindowChrome())
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            .onAppear {
                dependencies.settingsViewModel.showSettings()
                dependencies.settingsViewModel.onOpenLogin = {
                    dependencies.navigation.showsSettings = false
                    openWindow(id: "main")
                    NSApplication.shared.activate()
                }
            }
    }
}

private struct SettingsWindowChrome: NSViewRepresentable {
    func makeNSView(context: Context) -> SettingsChromeView { SettingsChromeView() }
    func updateNSView(_ view: SettingsChromeView, context: Context) { view.configureWindow() }
}

private final class SettingsChromeView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configureWindow()
    }

    func configureWindow() {
        guard let window else { return }
        // Settings scenes retain their native title bar despite SwiftUI's window style.
        window.styleMask.insert(.fullSizeContentView)
        window.toolbar = nil
        window.titlebarSeparatorStyle = .none
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
    }
}

private struct AppMenuBarContent: View {
    let dependencies: AppDependencies
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Button("UMC Desk 열기") {
            openWindow(id: "main")
            NSApplication.shared.activate()
        }
        Button("마이페이지") {
            dependencies.settingsViewModel.showProfile()
            dependencies.navigation.showsSettings = true
            openWindow(id: "main")
            NSApplication.shared.activate()
        }
        Button("설정…") {
            dependencies.settingsViewModel.showSettings()
            openSettings()
        }
        Divider()
        Button("UMC Desk 종료", role: .destructive) { NSApplication.shared.terminate(nil) }
    }
}

private struct AppSettingsCommands: Commands {
    let dependencies: AppDependencies
    @Environment(\.openSettings) private var openSettings

    var body: some Commands {
        CommandGroup(replacing: .appSettings) {
            Button("설정…") {
                dependencies.settingsViewModel.showSettings()
                openSettings()
            }
            .keyboardShortcut(",", modifiers: .command)
        }
    }
}

@MainActor
final class AppLifecycleDelegate: NSObject, NSApplicationDelegate {
    var preferences: SettingsPreferences?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        !(preferences?.showsMenuBar ?? true)
    }
}

private extension SettingsTheme {
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
