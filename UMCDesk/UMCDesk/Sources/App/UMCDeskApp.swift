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
    #if DEBUG || UMC_PRERELEASE
    @State private var typographyPreview = UMCTypographyPreview()
    #endif

    var body: some Scene {
        @Bindable var preferences = dependencies.settingsPreferences
        #if DEBUG || UMC_PRERELEASE
        @Bindable var previewPreferences = dependencies.previewSettingsViewModel.preferences
        #endif

        WindowGroup("UMC Desk", id: "main") {
            AppRootView(dependencies: dependencies)
                .toggleStyle(UMCCheckboxStyle())
                .preferredColorScheme(preferences.theme.colorScheme)
                .environment(\.umcBodyTextScale, preferences.bodyTextSize.scale)
                .frame(minWidth: 1040, minHeight: 720)
                #if DEBUG || UMC_PRERELEASE
                .environment(\.umcTypographyPreview, typographyPreview)
                #endif
                .onAppear { lifecycle.preferences = preferences }
        }
        .defaultSize(width: 1440, height: 960)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))
        .commands {
            AppSettingsCommands(dependencies: dependencies)
            #if DEBUG || UMC_PRERELEASE
            AuthPreviewCommands()
            #endif
        }

        Settings {
            SettingsSceneView(dependencies: dependencies)
                .toggleStyle(UMCCheckboxStyle())
                .preferredColorScheme(preferences.theme.colorScheme)
                .environment(\.umcBodyTextScale, preferences.bodyTextSize.scale)
                .frame(minWidth: 1040, minHeight: 720)
                #if DEBUG || UMC_PRERELEASE
                .environment(\.umcTypographyPreview, typographyPreview)
                #endif
        }
        .defaultSize(width: 1440, height: 960)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))

        #if DEBUG || UMC_PRERELEASE
        Window("마이페이지·설정 프리뷰", id: "settings-design-preview") {
            SettingsView(viewModel: dependencies.previewSettingsViewModel)
                .toggleStyle(UMCCheckboxStyle())
                .preferredColorScheme(previewPreferences.theme.colorScheme)
                .environment(\.umcBodyTextScale, previewPreferences.bodyTextSize.scale)
                .environment(\.umcTypographyPreview, typographyPreview)
                .frame(minWidth: 1040, minHeight: 720)
        }
        .defaultSize(width: 1440, height: 960)
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unifiedCompact(showsTitle: false))

        Window("타이포그래피 조절", id: "typography-preview") {
            AppTypographyPreviewControls(settings: $typographyPreview)
        }
        .windowResizability(.contentSize)
        #endif

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

    var body: some View {
        Group {
            if dependencies.navigation.showsSettings {
                SettingsView(viewModel: dependencies.settingsViewModel)
            } else {
                AuthView()
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
            .background(SettingsWindowToolbar())
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

private struct SettingsWindowToolbar: NSViewRepresentable {
    func makeNSView(context: Context) -> SettingsToolbarView { SettingsToolbarView() }
    func updateNSView(_ view: SettingsToolbarView, context: Context) { view.configureWindow() }
}

private final class SettingsToolbarView: NSView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        configureWindow()
    }

    func configureWindow() {
        // The Settings scene overrides its SwiftUI toolbar style with preference-window chrome.
        window?.toolbarStyle = .unifiedCompact
        window?.titleVisibility = .hidden
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
    #if DEBUG || UMC_PRERELEASE
    @Environment(\.openWindow) private var openWindow
    #endif

    var body: some Commands {
        @Bindable var preferences = dependencies.settingsPreferences

        CommandGroup(replacing: .appSettings) {
            Button("설정…") {
                dependencies.settingsViewModel.showSettings()
                openSettings()
            }
            .keyboardShortcut(",", modifiers: .command)
        }
        #if DEBUG || UMC_PRERELEASE
        CommandGroup(after: .sidebar) {
            Button("마이페이지 프리뷰…") {
                SettingsDesignPreview.prepareViewModel(
                    dependencies.previewSettingsViewModel, page: .myPage
                )
                openWindow(id: "settings-design-preview")
            }
            Button("설정 프리뷰…") {
                SettingsDesignPreview.prepareViewModel(
                    dependencies.previewSettingsViewModel, page: .general
                )
                openWindow(id: "settings-design-preview")
            }
            Divider()
            Picker("화면 모드", selection: $preferences.theme) {
                Text("시스템 설정").tag(SettingsTheme.system)
                Text("라이트").tag(SettingsTheme.light)
                Text("다크").tag(SettingsTheme.dark)
            }
            Button("타이포그래피 조절…") { openWindow(id: "typography-preview") }
        }
        #endif
    }
}

@MainActor
final class AppLifecycleDelegate: NSObject, NSApplicationDelegate {
    var preferences: SettingsPreferences?

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        preferences?.windowCloseBehavior == .quit
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
