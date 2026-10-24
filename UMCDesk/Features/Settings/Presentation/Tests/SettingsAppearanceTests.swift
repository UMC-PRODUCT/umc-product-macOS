//
//  SettingsAppearanceTests.swift
//  SettingsPresentationTests
//
//  Created by euijjang97 on 10/20/26.
//

#if DEBUG
import AppKit
import CoreDesignSystem
import SettingsDomain
import SwiftUI
import Testing
@testable import SettingsPresentation

@MainActor
struct SettingsAppearanceTests {
    @Test("설치되지 않은 글꼴은 기본 글꼴로 복구한다")
    func missingFontFallsBack() {
        let suite = "missing-font.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set("FontThatDoesNotExist-123456", forKey: "settings.fontFamily")
        let preferences = SettingsPreferences(defaults: defaults)
        #expect(preferences.availableFontFamily == nil)
        #expect(preferences.font.design == nil)
        preferences.fontFamily = NSFontManager.shared.availableFontFamilies.first
        #expect(preferences.availableFontFamily == preferences.fontFamily)
    }

    @Test("Settings screens keep a scrollable content area in both appearances",
        arguments: [CGSize(width: 1040, height: 720), CGSize(width: 1440, height: 960)],
        [ColorScheme.light, .dark])
    func settingsWindowLayout(size: CGSize, scheme: ColorScheme) throws {
        let preferences = SettingsPreferences(defaults: UserDefaults(suiteName:
            "SettingsAppearanceTests.\(UUID().uuidString)")!)
        preferences.bodyTextSize = size.width == 1040 ? .extraLarge : .standard
        preferences.selectedColorThemeID = "midnight"
        preferences.font = .serif
        for id in ["757:12600", "807:13303", "903:3596", "903:14091", "903:14321", "906:3869",
            "activity_roles", "776:17026"] {
            let model = try #require(SettingsDesignPreview.makeViewModel(id: id,
                preferences: preferences))
            let controller = NSHostingController(rootView: SettingsView(viewModel: model)
                .environment(\.colorScheme, scheme)
                .environment(\.umcBodyTextScale, preferences.bodyTextSize.scale))
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

    @Test("준비 중인 알림 화면을 표시해도 저장된 켜짐과 꺼짐 설정이 보존된다",
        arguments: [true, false])
    func pendingNotificationsPreservePreferences(savedValue: Bool) throws {
        let suiteName = "SettingsPendingNotificationsTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }
        let preferences = SettingsPreferences(defaults: defaults)
        preferences.attendanceNotifications = savedValue
        preferences.noticeNotifications = !savedValue
        preferences.threadNotifications = savedValue
        preferences.showsNotificationContent = !savedValue
        let saved = defaults.dictionaryRepresentation() as NSDictionary
        let model = try #require(SettingsDesignPreview.makeViewModel(id: "903:14091",
            preferences: preferences))
        let controller = NSHostingController(rootView: SettingsNotificationsView(viewModel: model))
        let window = NSWindow(contentViewController: controller)
        defer { window.contentView = nil }
        window.setContentSize(CGSize(width: 800, height: 800))
        controller.view.layoutSubtreeIfNeeded()
        window.displayIfNeeded()
        #expect(defaults.dictionaryRepresentation() as NSDictionary == saved)
    }

    @Test("Compact profile forms fit their widths with large text and validation errors",
        arguments: [ColorScheme.light, .dark], [false, true])
    func compactProfileForms(scheme: ColorScheme, largeText: Bool) throws {
        let preferences = SettingsPreferences(defaults: UserDefaults(suiteName:
            "SettingsDialogTests.\(UUID().uuidString)")!)
        for id in ["766:2895", "770:14893", "771:15714", "771:15995"] {
            let model = try #require(SettingsDesignPreview.makeViewModel(id: id,
                preferences: preferences))
            let dialog = try #require(model.dialog)
            if largeText && dialog == .editLinks {
                for kind in SettingsLinkKind.allCases {
                    model.linkDraft[kind] = "https://example.com/a/very/long/profile/address"
                    model.linkErrors[kind] = "올바른 웹 주소를 입력해 주세요. "
                        + "로그인 정보가 포함된 주소는 사용할 수 없어요."
                }
            }
            let controller = NSHostingController(rootView:
                SettingsDialogContent(dialog: dialog, viewModel: model)
                    .environment(\.colorScheme, scheme)
                    .environment(\.umcBodyTextScale, largeText ? 1.32 : 1))
            let window = NSWindow(contentViewController: controller)
            let host = controller.view
            let size = host.fittingSize
            window.setContentSize(size)
            host.layoutSubtreeIfNeeded()
            window.displayIfNeeded()
            #expect(size.width == (dialog == .editLinks ? 560 : 440))
            #expect(size.height <= 680)
            let fields = descendants(in: host, type: NSTextField.self).filter(\.isEditable)
            #expect(fields.count == (dialog == .editLinks ? 5 : model.codeStep == .complete ? 0 : 1))
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
        #expect(noResults.searchResults.isEmpty)
    }

    @Test("Toolbar tooltips appear below the anchor without taking pointer input")
    func toolbarTooltipPanel() throws {
        let window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 400, height: 300),
            styleMask: [.titled], backing: .buffered, defer: false)
        let anchor = ToolbarTooltipAnchor.AnchorView(frame:
            NSRect(x: 40, y: 200, width: 40, height: 40))
        window.contentView?.addSubview(anchor)
        anchor.title = "뒤로"
        anchor.isPresented = true
        anchor.updateTooltip()
        defer {
            anchor.hideTooltip()
            window.contentView = nil
        }
        let panel = try #require(window.childWindows?.first as? NSPanel)
        let anchorFrame = window.convertToScreen(anchor.convert(anchor.bounds, to: nil))
        #expect(panel.frame.maxY < anchorFrame.minY)
        #expect(abs(panel.frame.midX - anchorFrame.midX) <= 0.5,
            "Panel: \(panel.frame), anchor: \(anchorFrame)")
        #expect(panel.ignoresMouseEvents)
        #expect(!panel.canBecomeKey)
        #expect(anchor.hitTest(.zero) == nil)
        anchor.isPresented = false
        anchor.updateTooltip()
        #expect(window.childWindows?.isEmpty != false)
        #expect(!panel.isVisible)
    }

    private func descendants<Content: NSView>(in view: NSView, type: Content.Type) -> [Content] {
        view.subviews.flatMap { child in
            ((child as? Content).map { [$0] } ?? []) + descendants(in: child, type: type)
        }
    }
}
#endif
