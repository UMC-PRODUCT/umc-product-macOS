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
        preferences.bodyTextSize = size.width == 1040 ? .extraLarge : .standard
        for id in ["757:12600", "807:13303", "903:3596", "903:14091", "903:14321", "906:3869",
            "activity_roles", "776:17026"] {
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

    @Test("The role preview includes every supported activity badge without changing the default")
    func activityRolesPreview() throws {
        let preferences = SettingsPreferences(defaults: UserDefaults(suiteName:
            "SettingsRolePreviewTests.\(UUID().uuidString)")!)
        let model = try #require(SettingsDesignPreview.makeViewModel(id: "activity_roles",
            preferences: preferences))
        let activities = try #require(model.profile).activities
        let roles = activities.flatMap(\.roles)
        #expect(activities.count == 12)
        #expect(Set(activities.map(\.part)) == Set([
            "PLAN", "DESIGN", "WEB", "ANDROID", "IOS", "NODEJS", "SPRINGBOOT", "ADMIN",
            "WEB_PRODUCT_ENGINEER", "MOBILE_PRODUCT_ENGINEER",
        ]))
        #expect(Set(roles) == Set([
            "SCHOOL_PRESIDENT", "SCHOOL_VICE_PRESIDENT", "SCHOOL_PART_LEADER", "SCHOOL_ETC_ADMIN",
            "CENTRAL_PRESIDENT", "CENTRAL_VICE_PRESIDENT", "CENTRAL_OPERATING_TEAM_MEMBER",
            "CENTRAL_EDUCATION_TEAM_MEMBER", "CHAPTER_PRESIDENT", "SUPER_ADMIN", "PRODUCT",
            "CHALLENGER",
        ]))
        let original = try #require(SettingsDesignPreview.makeViewModel(id: "757:12600",
            preferences: preferences))
        #expect(original.profile?.activities.map(\.part) == ["PLAN", "PLAN"])
        #expect(original.profile?.activities.flatMap(\.roles) == [
            "SCHOOL_PRESIDENT", "SUPER_ADMIN", "PRODUCT",
        ])
    }

    @Test("Usage preview statistics and heatmap describe the same twelve weeks")
    func usagePreviewIsConsistent() {
        let days = SettingsUsagePreview.days
        #expect(days.count == 84)
        #expect(Set(days.map(\.date)).count == 84)
        #expect(SettingsUsagePreview.weeks.count == 12)
        #expect(SettingsUsagePreview.weeks.allSatisfy { $0.days.count == 7 })
        #expect(SettingsUsagePreview.calendar.component(.weekday, from: days[0].date) == 2)
        #expect(SettingsUsagePreview.totalMinutes == 3615)
        #expect(SettingsUsagePreview.totalDuration == "60시간 15분")
        #expect(SettingsUsagePreview.activeDays == 63)
        #expect(SettingsUsagePreview.currentStreak == 1)
    }

    @Test("Every Figma state has an isolated preview with the expected dialog")
    func designStatesAreReachable() throws {
        let preferences = SettingsPreferences(defaults: UserDefaults(suiteName:
            "SettingsPreviewTests.\(UUID().uuidString)")!)
        #expect(SettingsDesignPreview.ids.count == 21)
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
