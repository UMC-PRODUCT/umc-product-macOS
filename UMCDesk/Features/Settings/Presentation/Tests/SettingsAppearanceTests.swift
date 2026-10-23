//
//  SettingsAppearanceTests.swift
//  SettingsPresentationTests
//
//  Created by euijjang97 on 10/20/26.
//

#if DEBUG
import AppKit
import SettingsDomain
import SwiftUI
import Testing
@testable import SettingsPresentation

@MainActor
struct SettingsAppearanceTests {
    @Test("Settings screens keep a scrollable content area in both appearances",
        arguments: [CGSize(width: 1040, height: 720), CGSize(width: 1440, height: 960)],
        [ColorScheme.light, .dark])
    func settingsWindowLayout(size: CGSize, scheme: ColorScheme) throws {
        let preferences = SettingsPreferences(defaults: UserDefaults(suiteName:
            "SettingsAppearanceTests.\(UUID().uuidString)")!)
        for id in ["757:12600", "807:13303", "903:3596", "903:14091", "903:14321", "906:3869"] {
            let model = try #require(SettingsDesignPreview.makeViewModel(id: id,
                preferences: preferences))
            let controller = NSHostingController(rootView: SettingsView(viewModel: model)
                .environment(\.colorScheme, scheme))
            let window = NSWindow(contentViewController: controller)
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.toolbarStyle = .unifiedCompact
            window.titleVisibility = .hidden
            let host = controller.view
            window.setContentSize(size)
            host.layoutSubtreeIfNeeded()
            window.displayIfNeeded()
            #expect(host.bounds.size == size)
            let toolbar = try #require(window.toolbar)
            #expect(toolbar.isVisible)
            #expect(window.toolbarStyle == .unifiedCompact)
            #expect(!toolbar.items.isEmpty)
            for button in [NSWindow.ButtonType.closeButton, .miniaturizeButton, .zoomButton] {
                #expect(window.standardWindowButton(button)?.isHidden == false)
            }
            let scrollViews = descendants(in: host, type: NSScrollView.self)
            let topInsets = scrollViews.map { scroll in
                let frame = host.convert(scroll.bounds, from: scroll)
                return host.isFlipped ? frame.minY : host.bounds.height - frame.maxY
            }
            // Native window chrome owns the top spacing; page content starts at the host's top.
            #expect(topInsets.contains { abs($0) < 0.5 }, "Scroll top insets: \(topInsets)")
            #expect(!descendants(in: host, type: NSScrollView.self).isEmpty)
            let fields = descendants(in: host, type: NSTextField.self).filter(\.isEditable)
            for field in fields {
                let frame = host.convert(field.bounds, from: field)
                #expect(frame.minX >= 0 && frame.maxX <= size.width + 1)
            }
            window.contentView = nil
        }
    }

    @Test("Every Figma state has an isolated preview with the expected dialog")
    func designStatesAreReachable() throws {
        let preferences = SettingsPreferences(defaults: UserDefaults(suiteName:
            "SettingsPreviewTests.\(UUID().uuidString)")!)
        #expect(SettingsDesignPreview.ids.count == 20)
        for id in SettingsDesignPreview.ids {
            let model = try #require(SettingsDesignPreview.makeViewModel(id: id,
                preferences: preferences))
            #expect(model.profile != nil)
            #expect(model.isDesignPreview)
        }
        let editing = try #require(SettingsDesignPreview.makeViewModel(id: "766:2895",
            preferences: preferences))
        #expect(editing.dialog == .editLinks)
        let registered = try #require(SettingsDesignPreview.makeViewModel(id: "771:15995",
            preferences: preferences))
        #expect(registered.codeStep == .complete)
        let empty = try #require(SettingsDesignPreview.makeViewModel(id: "765:15045",
            preferences: preferences))
        #expect(empty.profile?.activities.isEmpty == true)
        let noResults = try #require(SettingsDesignPreview.makeViewModel(id: "907:16571",
            preferences: preferences))
        #expect(noResults.visibleCategories.isEmpty)
    }

    private func descendants<Content: NSView>(in view: NSView, type: Content.Type) -> [Content] {
        view.subviews.flatMap { child in
            ((child as? Content).map { [$0] } ?? []) + descendants(in: child, type: type)
        }
    }
}
#endif
