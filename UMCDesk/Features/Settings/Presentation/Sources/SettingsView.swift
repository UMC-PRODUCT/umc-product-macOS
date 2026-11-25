//
//  SettingsView.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/20/26.
//

import UMCFoundation
import AppKit
import CoreDesignSystem
import SettingsDomain
import CoreRouting
import CoreUIComponents
import SwiftUI

public struct SettingsView: View {
    // MARK: - Property

    @Environment(\.openWindow) private var openWindow
    @State private var viewModel: SettingsViewModel
    private let onSelectSection: ((DeskSection?) -> Void)?
    @State private var history = WindowHistory()
    @Environment(\.windowFeatureRouter) private var featureRouter
    private let section: DeskSection?
    private let matchingSelected: Bool
    private let onOpenMatching: (() -> Void)?
    private let featureContent: AnyView?
    @State private var pendingSearchResultID: String?
    @State private var showsSearchSuggestions = false
    @State private var hoveredRailItem: RailItem?
    private enum RailItem: Equatable {
        case section(DeskSection), matching, help, profile
    }

    @State private var railHelpFocus = UMCWindowButtonFocus()
    @State private var tabbedPastSearchResults = false
    @FocusState private var searchFocus: SearchFocus?

    private enum SearchFocus: Hashable {
        case field
        case recent(String)
        case recommended(String)
        case result(String)
    }

    @State private var showsProfileMenu = false
    @State private var hoveredProfileMenuItem: ProfileMenuFocus?
    @State private var showsProfileKeyboardFocus = false
    @FocusState private var profileMenuFocus: ProfileMenuFocus?
    @AccessibilityFocusState private var accessibleProfileMenuFocus: ProfileMenuFocus?

    private enum ProfileMenuFocus: Hashable {
        case trigger, myPage, settings, logout
    }
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var palette: SettingsAppearancePalette {
        .init(
            colors: colorScheme == .dark
                ? viewModel.preferences.selectedColorTheme.dark?.content
                :
            viewModel.preferences.selectedColorTheme.light?.content)
    }
    private var sidebarPalette: SettingsAppearancePalette {
        .init(
            colors: colorScheme == .dark
                ? viewModel.preferences.selectedColorTheme.dark?.sidebar
                :
            viewModel.preferences.selectedColorTheme.light?.sidebar)
    }

    private var sidebarChromeForeground: Color {
        UMCColor.Custom.backgroundTextWhite
    }

    fileprivate enum Constants {
        static let backTab = KeyEquivalent("\u{19}")
        static let railWidth: CGFloat = 44
        static let sidebarWidth: CGFloat = 271
        static let contentWidth: CGFloat = 760
    }

    public init(viewModel: SettingsViewModel, section: DeskSection? = nil,
                featureContent: AnyView? = nil, matchingSelected: Bool = false,
                onOpenMatching: (() -> Void)? = nil,
                onSelectSection: ((DeskSection?) -> Void)? = nil) {
        self.matchingSelected = matchingSelected
        self.onOpenMatching = onOpenMatching
        self.section = section
        self.featureContent = featureContent
        self.onSelectSection = onSelectSection
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: UMCSpacing.value4) {
            appRail
                .frame(width: Constants.railWidth)
                .environment(\.colorScheme, .light)
                .zIndex(1)
                .simultaneousGesture(TapGesture().onEnded { dismissSearchSuggestions() })
            HStack(spacing: 0) {
                if featureContent == nil, viewModel.page != .myPage {
                    settingsSidebar
                        .foregroundStyle(sidebarPalette.textNeutralDefault)
                        .tint(sidebarPalette.textBrandDefault)
                        .environment(\.settingsAppearancePalette, sidebarPalette)
                        .environment(\.colorScheme, sidebarPalette.colorScheme ?? colorScheme)
                        .zIndex(1)
                    Rectangle()
                        .fill(palette.borderNeutralWeak200)
                        .frame(width: 1)
                        .accessibilityHidden(true)
                }
                Group {
                    if let featureContent { featureContent }
                    else { pageContent }
                }
                    .environment(\.settingsAppearancePalette, palette)
                    .background(palette.backgroundDefault)
                    .environment(\.colorScheme, palette.colorScheme ?? colorScheme)
                    .simultaneousGesture(TapGesture().onEnded { dismissSearchSuggestions() })
                    .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(palette.backgroundDefault)
            .clipShape(.rect(cornerRadius: UMCRadius.value16))
            .overlay(alignment: .bottom) {
                ZStack {
                    if let toast = viewModel.toast {
                        toastView(toast)
                            .padding(UMCSpacing.value24)
                            .id(toast.id)
                            .transition(reduceMotion ? .opacity : .offset(y: 8).combined(
                                with: .opacity))
                    }
                }
                .animation(reduceMotion ? nil : .easeOut(duration: 0.22),
                    value: viewModel.toast?.id)
            }
        }
        .padding(.leading, UMCSpacing.value4)
        .padding([.bottom, .trailing], UMCSpacing.value12)
        .background(UMCColor.Custom.backgroundAppShell)
        .disabled(showsProfileMenu)
        .accessibilityHidden(true, isEnabled: showsProfileMenu)
        .overlay(alignment: .bottomLeading) {
            if showsProfileMenu {
                ZStack(alignment: .bottomLeading) {
                    Color.clear
                        .contentShape(.rect)
                        .onTapGesture { dismissProfileMenu() }
                        .accessibilityHidden(true)
                    profileMenu
                        .environment(\.colorScheme, palette.colorScheme ?? colorScheme)
                        .padding(.leading, Constants.railWidth + UMCSpacing.value12)
                        .padding(.bottom, UMCSpacing.value12 + UMCSpacing.value16)
                        .onAppear {
                            showsProfileKeyboardFocus = false
                            profileMenuFocus = .myPage
                            accessibleProfileMenuFocus = .myPage
                        }
                }
            }
        }
        .onExitCommand {
            if showsProfileMenu { dismissProfileMenu() }
            else { dismissSearchSuggestions() }
        }
        .defaultFocus($searchFocus, nil)
        .onChange(of: searchFocus) { _, focus in
            if focus == .field {
                // AppKit wraps back to search when the page has no eligible next key view.
                let event = NSApp.currentEvent
                let wrapped = tabbedPastSearchResults && event?.type != .leftMouseDown &&
                    event?.modifierFlags.contains(.shift) != true
                tabbedPastSearchResults = false
                if wrapped, railHelpFocus.focus() {
                    showsSearchSuggestions = false
                } else {
                    showsSearchSuggestions = true
                }
            } else if focus == nil { showsSearchSuggestions = false }
        }
        .onChange(of: viewModel.searchText) { _, _ in
            if searchFocus == .field { showsSearchSuggestions = true }
        }
        .onChange(of: showsProfileMenu) { _, isPresented in
            if !isPresented {
                profileMenuFocus = .trigger
                accessibleProfileMenuFocus = .trigger
            }
        }
        .environment(\.windowDetail, detailSelection)
        .onChange(of: location, initial: true) { _, destination in
            // Replaying an entry already moved the cursor, including its article selection.
            if history.current?.location != destination {
                history.visit(WindowVisit(location: destination))
            }
        }
        .toolbar { navigationToolbar }
        .toolbarBackground(UMCColor.Custom.backgroundAppShell, for: .windowToolbar)
        .toolbarBackgroundVisibility(.visible, for: .windowToolbar)
        .toolbarColorScheme(.dark, for: .windowToolbar)
        .foregroundStyle(palette.textNeutralDefault)
        .tint(palette.textBrandDefault)
        .sheet(item: $viewModel.dialog, onDismiss: viewModel.dismissDialog) { dialog in
            SettingsDialogContent(dialog: dialog, viewModel: viewModel)
                .environment(\.settingsAppearancePalette, palette)
                .environment(\.colorScheme, palette.colorScheme ?? colorScheme)
                .interactiveDismissDisabled(viewModel.isAccountBusy || viewModel.isClearingCache)
        }
        .environment(\.settingsThemeMode, colorScheme)
        .environment(\.settingsAppearancePalette, palette)
        .environment(\.umcFontDesign, viewModel.preferences.font.design)
        .environment(\.umcFontFamily, viewModel.preferences.availableFontFamily)
        .task { await viewModel.load() }
        .task(id: viewModel.toast?.id) {
            guard let toast = viewModel.toast, !viewModel.isDesignPreview else { return }
            try? await Task.sleep(for: .seconds(5))
            if !Task.isCancelled, viewModel.toast?.id == toast.id { viewModel.toast = nil }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await viewModel.refreshSystemStatus() } }
        }
        #if DEBUG || UMC_PRERELEASE
        .onAppear { showsProfileMenu = viewModel.previewShowsProfileMenu }
        #endif
    }

    private var appRail: some View {
        VStack(spacing: 0) {
            VStack(spacing: 0) {
                ForEach(DeskSection.allCases, id: \.self) { item in
                    let title = AppLocalization.string(String.LocalizationValue(item.title))
                    if let onSelectSection {
                        railButton(.section(item), title: title, symbol: item.symbol,
                                   selected: section == item) { onSelectSection(item) }
                    } else {
                        Image(systemName: item.symbol)
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(sidebarChromeForeground.opacity(0.75))
                            .frame(width: Constants.railWidth, height: Constants.railWidth)
                            .accessibilityLabel(AppLocalization.string("\(title), 준비 중"))
                            .accessibilityHint(AppLocalization.string("\(title) 화면은 아직 제공하지 않아요."))
                            .modifier(railHover(.section(item), title: title))
                    }
                }
                if let onOpenMatching {
                    railButton(.matching, title: AppLocalization.string("프로젝트 매칭"),
                               symbol: "person.2.badge.gearshape", selected: matchingSelected,
                               action: onOpenMatching)
                }
                SettingsHelpButton(foreground: sidebarChromeForeground, focusTarget: railHelpFocus) {
                    openWindow(id: DeskWindow.support)
                }
                .onKeyPress(keys: [.tab, Constants.backTab]) { press in
                    guard featureContent == nil, viewModel.page != .myPage else { return .ignored }
                    let backwards = press.modifiers.contains(.shift) || press.key == Constants.backTab
                    guard !backwards || !railHelpFocus.hasFollowingKeyView else { return .ignored }
                    tabbedPastSearchResults = false
                    showsSearchSuggestions = true
                    searchFocus = backwards ? searchFocusRows.last ?? .field : .field
                    return .handled
                }
                .modifier(railHover(.help, title: AppLocalization.string("도움말")))
            }
            Spacer(minLength: UMCSpacing.value24)
            Button { showsProfileMenu.toggle() } label: {
                SettingsAvatar(url: viewModel.profile?.profileImageURL, size: 32,
                    usesDesignImage: viewModel.isDesignPreview)
                    .frame(width: 44, height: 44)
                    .contentShape(.rect(cornerRadius: UMCRadius.value12))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(AppLocalization.string("프로필 메뉴"))
            .accessibilityHint(AppLocalization.string("마이페이지, 설정 및 계정 메뉴"))
            .focused($profileMenuFocus, equals: .trigger)
            .accessibilityFocused($accessibleProfileMenuFocus, equals: .trigger)
            .modifier(railHover(.profile, title: AppLocalization.string("프로필 메뉴")))
            .padding(.bottom, UMCSpacing.value16)
        }
    }

    private func railButton(
        _ item: RailItem, title: String, symbol: String, selected: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .foregroundStyle(sidebarChromeForeground)
                .frame(width: Constants.railWidth, height: Constants.railWidth)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .modifier(railHover(item, title: title, selected: selected))
    }

    private func railHover(_ item: RailItem, title: String, selected: Bool = false)
        -> some ViewModifier {
        let hovered = hoveredRailItem == item && !showsProfileMenu
        return RailHover(title: title, hovered: hovered, selected: selected) { inside in
            if inside {
                hoveredRailItem = item
            } else if hoveredRailItem == item {
                hoveredRailItem = nil
            }
        }
    }

    private var profileMenu: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value4) {
            if let profile = viewModel.profile {
                HStack(spacing: UMCSpacing.value8) {
                    SettingsAvatar(url: profile.profileImageURL, size: 24,
                        usesDesignImage: viewModel.isDesignPreview)
                    VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                        Text("\(profile.nickname) / \(profile.name)")
                            .umcTypography(.headlineBold)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        Text(profileMenuSummary(profile))
                            .umcTypography(.subheadlineRegular)
                            .foregroundStyle(palette.textNeutralWeak500)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .padding(.horizontal, UMCSpacing.value8)
                .padding(.vertical, UMCSpacing.value4)
                SettingsDivider()
            }
            VStack(spacing: UMCSpacing.value4) {
                profileMenuButton(
                    AppLocalization.string("마이페이지"), symbol: "person.crop.circle", focus: .myPage
                ) {
                    onSelectSection?(nil)
                    viewModel.showProfile()
                }
                profileMenuButton(
                    AppLocalization.string("설정"), symbol: "gearshape", focus: .settings
                ) {
                    onSelectSection?(nil)
                    viewModel.showSettings()
                }
            }
            if viewModel.profile != nil {
                SettingsDivider()
                profileMenuButton(
                    AppLocalization.string("로그아웃"), symbol: "rectangle.portrait.and.arrow.right",
                    focus: .logout) {
                    viewModel.dialogMessage = nil
                    viewModel.dialog = .logout
                }
            }
        }
        .padding(UMCSpacing.value8)
        .frame(width: 240)
        .foregroundStyle(palette.textNeutralStrong800)
        .background {
            RoundedRectangle(cornerRadius: UMCRadius.value12)
                .fill(palette.backgroundDefault)
                .shadow(color: .black.opacity(0.16), radius: 16, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: UMCRadius.value12)
                .strokeBorder(palette.borderNeutralWeak200)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(AppLocalization.string("프로필 메뉴"))
        .onKeyPress(keys: [.tab, .upArrow, .downArrow]) { _ in
            showsProfileKeyboardFocus = true
            hoveredProfileMenuItem = nil
            return .ignored
        }
    }

    private func dismissProfileMenu() {
        hoveredProfileMenuItem = nil
        showsProfileMenu = false
    }

    private func profileMenuSummary(_ profile: SettingsProfile) -> String {
        var values: [String] = []
        if let activity = profile.activities.first {
            values.append(AppLocalization.string("\(activity.generation)기"))
        }
        if let school = profile.schoolName { values.append(school) }
        if let activity = profile.activities.first { values += activity.roles.map(roleTitle) }
        return values.joined(separator: " · ")
    }

    private func profileMenuButton(
        _ title: String, symbol: String, focus: ProfileMenuFocus, action: @escaping () -> Void
    ) -> some View {
        Button {
            dismissProfileMenu()
            action()
        } label: {
            HStack(spacing: UMCSpacing.value8) {
                Image(systemName: symbol)
                    .font(.system(size: 14))
                    .frame(width: 16, height: 16)
                    .accessibilityHidden(true)
                Text(title)
                    .umcTypography(.headlineRegular)
            }
            .padding(.horizontal, UMCSpacing.value8)
            .padding(.vertical, UMCSpacing.value4)
            .frame(maxWidth: .infinity, minHeight: 28, alignment: .leading)
            .contentShape(.rect)
        }
        .buttonStyle(SettingsPlainButtonStyle(
            highlight: hoveredProfileMenuItem != nil || profileMenuFocus == focus ?
                palette.fillPrimaryWeakHoverPressed : .clear,
            cornerRadius: UMCRadius.value6,
            isFocused: profileMenuShowsKeyboardHighlight(
                keyboardNavigation: showsProfileKeyboardFocus,
                hasHoveredItem: hoveredProfileMenuItem != nil,
                isFocused: profileMenuFocus == focus)))
        .onHover { hovering in
            showsProfileKeyboardFocus = false
            if hovering {
                hoveredProfileMenuItem = focus
            } else if hoveredProfileMenuItem == focus {
                hoveredProfileMenuItem = nil
            }
        }
        .focusable()
        .focused($profileMenuFocus, equals: focus)
        .focusEffectDisabled()
        .accessibilityFocused($accessibleProfileMenuFocus, equals: focus)
    }

    private var location: WindowLocation {
        if let key = featureRouter?.location { return .feature(key) }
        if let section { return .section(section) }
        if matchingSelected { return .matching }
        return .settings(viewModel.page)
    }

    private var detailSelection: Binding<WindowDetail?> {
        let destination = location
        return Binding {
            history.current?.location == destination ? history.current?.detail : nil
        } set: { id in
            guard history.current?.location == destination else { return }
            history.visit(WindowVisit(location: destination, detail: id))
        }
    }

    private func restore(_ visit: WindowVisit?) {
        guard let visit, visit.location != location else { return }
        switch visit.location {
        case .section(let section): onSelectSection?(section)
        case .matching: onOpenMatching?()
        case .feature(let key): featureRouter?.restore(key)
        case .settings(let page):
            if featureContent != nil { onSelectSection?(nil) }
            viewModel.navigate(to: page)
        }
    }

    @ToolbarContentBuilder
    private var navigationToolbar: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            HStack(spacing: UMCSpacing.value4) {
                navigationButton(
                    AppLocalization.string("뒤로"), symbol: "chevron.left", shortcut: "[",
                    isEnabled: history.canGoBack
                ) { restore(history.back()) }
                navigationButton(
                    AppLocalization.string("앞으로"), symbol: "chevron.right", shortcut: "]",
                    isEnabled: history.canGoForward
                ) { restore(history.forward()) }
            }
            .frame(width: UMCSpacing.value32 * 2 + UMCSpacing.value4,
                height: UMCSpacing.value40)
        }
        .sharedBackgroundVisibility(.hidden)
    }

    private func navigationButton(
        _ title: String, symbol: String, shortcut: KeyEquivalent,
        isEnabled: Bool, action: @escaping () -> Void
    ) -> some View {
        Button {
            dismissSearchSuggestions()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(sidebarChromeForeground.opacity(isEnabled ? 0.90 : 0.46))
                .frame(width: UMCSpacing.value32, height: UMCSpacing.value32)
        }
        .buttonStyle(WindowNavigationButtonStyle())
        .keyboardShortcut(shortcut, modifiers: .command)
        .disabled(showsProfileMenu || !isEnabled)
        .accessibilityLabel(title)
        .modifier(ToolbarTooltip(
            title: "\(title) ⌘\(shortcut.character)", isSuppressed: showsProfileMenu
        ))
    }

    private var settingsSidebar: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            Text(AppLocalization.string("설정")).umcTypography(.title3Bold)
                .onTapGesture { dismissSearchSuggestions() }
            searchField
                .zIndex(1)

            ScrollView {
                VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                    if viewModel.isSearching {
                        ForEach(viewModel.searchResults) { result in
                            searchResultButton(result)
                        }
                    } else {
                        ForEach(SettingsPage.categories) { category in
                            Button {
                                dismissSearchSuggestions()
                                viewModel.navigate(to: category)
                            } label: {
                                HStack(spacing: UMCSpacing.value8) {
                                    Image(systemName: category.symbol)
                                        .font(.system(size: 16))
                                        .frame(width: 24, height: 24)
                                    Text(category.title).umcTypography(.headlineRegular)
                                }
                                .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
                                .padding(.horizontal, UMCSpacing.value8)
                                .contentShape(.rect)
                                .background(viewModel.page == category ?
                                    sidebarPalette.backgroundBrandWeak : .clear,
                                    in: .rect(cornerRadius: UMCRadius.value8))
                            }
                            .buttonStyle(SettingsPlainButtonStyle())
                            .foregroundStyle(viewModel.page == category ?
                                sidebarPalette.textBrandDefault :
                                sidebarPalette.textNeutralStrong800)
                            .accessibilityAddTraits(viewModel.page == category ? .isSelected : [])
                        }
                    }
                    if viewModel.isSearching && viewModel.searchResults.isEmpty {
                        Text(AppLocalization.string("검색 결과를 찾을 수 없어요"))
                            .umcTypography(.headlineRegular)
                            .foregroundStyle(sidebarPalette.textNeutralWeak500)
                            .padding(.vertical, UMCSpacing.value16)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .simultaneousGesture(TapGesture().onEnded { dismissSearchSuggestions() })
            Spacer(minLength: 0)
        }
        .padding(.horizontal, UMCSpacing.value20)
        .padding(.vertical, UMCSpacing.value24)
        .frame(width: Constants.sidebarWidth)
        .background {
            (sidebarPalette.colors?.background.color ??
                UMCColor.Custom.backgroundSurfaceGreyWeaker)
                .contentShape(.rect)
                .onTapGesture { dismissSearchSuggestions() }
        }
        .onKeyPress(keys: [.downArrow, .upArrow, .tab, Constants.backTab]) { press in
            moveSearchFocus(press)
        }
    }

    private var searchField: some View {
        HStack(spacing: UMCSpacing.value8) {
            Image(systemName: "magnifyingglass").accessibilityHidden(true)
            TextField(AppLocalization.string("검색"), text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .accessibilityLabel(AppLocalization.string("설정 검색"))
                .focused($searchFocus, equals: .field)
                .onTapGesture { showsSearchSuggestions = true }
                .onSubmit {
                    if let result = viewModel.isSearching ? viewModel.searchResults.first :
                        suggestionItems.first?.result {
                        selectSearchResult(result)
                    }
                }
            if !viewModel.searchText.isEmpty {
                Button {
                    viewModel.searchText = ""
                    searchFocus = .field
                    showsSearchSuggestions = true
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(SettingsPlainButtonStyle())
                .accessibilityLabel(AppLocalization.string("검색어 지우기"))
            }
        }
        .umcTypography(.headlineRegular)
        .foregroundStyle(sidebarPalette.textNeutralWeak500)
        .padding(.horizontal, UMCSpacing.value16)
        .frame(minHeight: 36)
        .background(sidebarPalette.backgroundSurfaceGreyWeak, in: .capsule)
        .overlay {
            Capsule().strokeBorder(searchFocus == .field ?
                sidebarPalette.textBrandDefault : .clear, lineWidth: 2)
        }
        .overlay(alignment: .topLeading) {
            if showsSearchSuggestions && !viewModel.isSearching {
                searchSuggestions
                    .offset(y: 36 + UMCSpacing.value8)
            }
        }
    }

    private var suggestionItems: [(focus: SearchFocus, result: SettingsSearchResult)] {
        viewModel.recentSearchItems.map { (.recent($0.id), $0) } +
            SettingsSearchResult.recommendations.map { (.recommended($0.id), $0) }
    }

    private var searchSuggestions: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                    if !viewModel.recentSearchItems.isEmpty {
                        suggestionSection(
                            AppLocalization.string("최근 항목"), items: viewModel.recentSearchItems,
                            recent: true)
                        SettingsDivider()
                    }
                    suggestionSection(
                        AppLocalization.string("추천 설정"),
                        items: SettingsSearchResult.recommendations,
                        recent: false)
                }
                .padding(UMCSpacing.value8)
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxHeight: 480)
            .fixedSize(horizontal: false, vertical: true)
            .onChange(of: searchFocus) { _, focus in
                if let focus { proxy.scrollTo(focus) }
            }
        }
        .frame(width: 280)
        .background {
            RoundedRectangle(cornerRadius: UMCRadius.value12)
                .fill(sidebarPalette.backgroundDefault)
                .shadow(color: .black.opacity(0.16), radius: 16, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: UMCRadius.value12)
                .strokeBorder(sidebarPalette.borderNeutralWeak200)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(AppLocalization.string("설정 검색 제안"))
    }

    private func suggestionSection(
        _ title: String, items: [SettingsSearchResult], recent: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value4) {
            Text(title)
                .umcTypography(.subheadlineRegular)
                .foregroundStyle(sidebarPalette.textNeutralWeak500)
                .padding(.horizontal, UMCSpacing.value8)
                .accessibilityAddTraits(.isHeader)
            ForEach(items) { result in
                let focus: SearchFocus = recent ? .recent(result.id) : .recommended(result.id)
                Button { selectSearchResult(result) } label: {
                    HStack(spacing: UMCSpacing.value8) {
                        Image(systemName: result.page.symbol)
                            .frame(width: 24)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(result.title).umcTypography(.headlineRegular)
                            Text(result.page.title)
                                .umcTypography(.captionRegular)
                                .foregroundStyle(sidebarPalette.textNeutralWeak500)
                        }
                    }
                    .foregroundStyle(sidebarPalette.textNeutralStrong800)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(UMCSpacing.value8)
                    .contentShape(.rect)
                }
                .buttonStyle(SettingsPlainButtonStyle(isFocused: searchFocus == focus))
                .focusable()
                .focused($searchFocus, equals: focus)
                .id(focus)
                .focusEffectDisabled()
                .accessibilityElement(children: .combine)
                .onKeyPress(.return) {
                    selectSearchResult(result)
                    return .handled
                }
            }
        }
    }

    private var searchFocusRows: [SearchFocus] {
        if viewModel.isSearching { return viewModel.searchResults.map { .result($0.id) } }
        return suggestionItems.map(\.focus)
    }

    private func moveSearchFocus(_ press: KeyPress) -> KeyPress.Result {
        guard viewModel.isSearching || showsSearchSuggestions else { return .ignored }
        let positions: [SearchFocus] = [.field] + searchFocusRows
        guard let focus = searchFocus, let index = positions.firstIndex(of: focus) else {
            return .ignored
        }
        let backwards = press.key == .upArrow || press.key == Constants.backTab ||
            press.modifiers.contains(.shift)
        let next = index + (backwards ? -1 : 1)
        guard positions.indices.contains(next) else {
            if press.key == .tab || press.key == Constants.backTab {
                showsSearchSuggestions = false
                if backwards || !railHelpFocus.hasFollowingKeyView {
                    tabbedPastSearchResults = false
                    return railHelpFocus.focus() ? .handled : .ignored
                }
                tabbedPastSearchResults = true
                return .ignored
            }
            return .handled
        }
        searchFocus = positions[next]
        return .handled
    }

    private func dismissSearchSuggestions() {
        tabbedPastSearchResults = false
        showsSearchSuggestions = false
        searchFocus = nil
    }

    private func selectSearchResult(_ result: SettingsSearchResult) {
        viewModel.selectSearchResult(result)
        pendingSearchResultID = result.id
        dismissSearchSuggestions()
    }

    private func searchResultButton(_ result: SettingsSearchResult) -> some View {
        Button { selectSearchResult(result) } label: {
            VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                Text(result.title)
                    .umcTypography(.headlineBold)
                    .foregroundStyle(sidebarPalette.textNeutralStrong800)
                Text(result.summary)
                    .umcTypography(.bodyRegular)
                    .foregroundStyle(sidebarPalette.textNeutralMedium600)
                Text(result.page.title)
                    .umcTypography(.captionRegular)
                    .foregroundStyle(sidebarPalette.textNeutralWeak500)
            }
            .fixedSize(horizontal: false, vertical: true)
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(UMCSpacing.value8)
            .contentShape(.rect)
        }
        .buttonStyle(SettingsPlainButtonStyle())
        .accessibilityElement(children: .combine)
        .focusable()
        .focused($searchFocus, equals: .result(result.id))
        .onKeyPress(.return) {
            selectSearchResult(result)
            return .handled
        }
    }

    @ViewBuilder
    private var pageContent: some View {
        if viewModel.page == .myPage {
            SettingsProfileView(viewModel: viewModel)
        } else {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: UMCSpacing.value24) {
                        VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                            Text(viewModel.page.title)
                                .umcTypography(.title1Bold)
                                .accessibilityAddTraits(.isHeader)
                            Text(AppLocalization.string("이 Mac에서 사용하는 앱의 환경을 설정하세요."))
                                .umcTypography(.bodyRegular)
                                .foregroundStyle(palette.textNeutralWeak500)
                        }
                        switch viewModel.page {
                        case .general: SettingsGeneralView(viewModel: viewModel)
                        case .appearance: SettingsAppearanceView(viewModel: viewModel)
                        case .notifications: SettingsNotificationsView(viewModel: viewModel)
                        case .privacy: SettingsPrivacyView(viewModel: viewModel)
                        case .about: SettingsAboutView(viewModel: viewModel)
                        case .myPage: EmptyView()
                        }
                    }
                    .frame(maxWidth: Constants.contentWidth, alignment: .leading)
                    .padding(UMCSpacing.value32)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                .scrollBounceBehavior(.basedOnSize)
                .onChange(of: pendingSearchResultID) { _, identifier in
                    guard let identifier else { return }
                    proxy.scrollTo(identifier, anchor: .center)
                    pendingSearchResultID = nil
                }
            }
        }
    }

    private func toastView(_ toast: SettingsToast) -> some View {
        HStack(spacing: UMCSpacing.value12) {
            Image(systemName: toast.isError ? "exclamationmark.circle" : "checkmark.circle")
            Text(toast.message).umcTypography(.title4Regular)
            Button { viewModel.toast = nil } label: { Image(systemName: "xmark") }
                .buttonStyle(SettingsPlainButtonStyle())
                .accessibilityLabel(AppLocalization.string("안내 닫기"))
        }
        .foregroundStyle(toast.isError ? UMCColor.Semantic.textError :
            palette.textNeutralStrong800)
        .padding(UMCSpacing.value16)
        .background(palette.backgroundSurfaceWhite,
            in: .rect(cornerRadius: UMCRadius.value12))
        .overlay {
            RoundedRectangle(cornerRadius: UMCRadius.value12)
                .strokeBorder(palette.borderNeutralWeak200)
        }
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        .accessibilityElement(children: .contain)
    }
}

private struct RailHover: ViewModifier {
    let title: String
    let hovered: Bool
    let selected: Bool
    let onHover: (Bool) -> Void

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: UMCRadius.value8)
                    .fill(selected ? UMCColor.Primitives.teal800 :
                        hovered ? UMCColor.Semantic.fillNeutralInverseStrongHoverPressed : .clear)
            }
            .contentShape(.rect)
            .onHover(perform: onHover)
            .overlay(alignment: .leading) {
                if hovered {
                    Text(verbatim: title)
                        .umcTypography(.bodyRegular)
                        .foregroundStyle(UMCColor.Primitives.white)
                        .padding(.horizontal, UMCSpacing.value12)
                        .padding(.vertical, UMCSpacing.value4)
                        .background(.black, in: .capsule)
                        .fixedSize()
                        .offset(x: SettingsView.Constants.railWidth + UMCSpacing.value8)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
    }
}

private struct ToolbarTooltip: ViewModifier {
    let title: String
    let isSuppressed: Bool

    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .onHover { isHovered = $0 }
            .background {
                ToolbarTooltipAnchor(title: title, isPresented: isHovered && !isSuppressed)
            }
    }
}

private struct SettingsTooltipLabel: View {
    let title: String

    var body: some View {
        Text(title)
            .umcTypography(.bodyRegular)
            .foregroundStyle(UMCColor.Semantic.textInverse)
            .padding(.horizontal, UMCSpacing.value12)
            .padding(.vertical, UMCSpacing.value8)
            .background(UMCColor.Semantic.textNeutralDefault,
                in: .rect(cornerRadius: UMCRadius.value8))
            .fixedSize()
    }
}

// The native toolbar clips overlays, so its tooltip needs a non-interactive child panel.
struct ToolbarTooltipAnchor: NSViewRepresentable {
    let title: String
    let isPresented: Bool

    func makeNSView(context: Context) -> AnchorView { AnchorView() }

    func updateNSView(_ view: AnchorView, context: Context) {
        view.title = title
        view.isPresented = isPresented
        view.updateTooltip()
    }

    static func dismantleNSView(_ view: AnchorView, coordinator: ()) {
        view.hideTooltip()
    }

    final class AnchorView: NSView {
        var title = ""
        var isPresented = false
        private var panel: NSPanel?

        override func hitTest(_ point: NSPoint) -> NSView? { nil }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            updateTooltip()
        }

        func updateTooltip() {
            guard isPresented, let window else {
                hideTooltip()
                return
            }
            let panel = panel ?? makePanel()
            let host = NSHostingView(rootView: SettingsTooltipLabel(title: title)
                .environment(\.colorScheme, .light))
            panel.contentView = host
            let size = host.fittingSize
            let anchor = window.convertToScreen(convert(bounds, to: nil))
            panel.setFrame(NSRect(x: anchor.midX - size.width / 2,
                y: anchor.minY - size.height - UMCSpacing.value8,
                width: size.width, height: size.height), display: true)
            if panel.parent !== window { window.addChildWindow(panel, ordered: .above) }
            panel.orderFront(nil)
        }

        func hideTooltip() {
            guard let panel else { return }
            panel.parent?.removeChildWindow(panel)
            panel.orderOut(nil)
        }

        private func makePanel() -> NSPanel {
            let panel = NSPanel(contentRect: .zero,
                styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.ignoresMouseEvents = true
            panel.hidesOnDeactivate = true
            panel.setAccessibilityElement(false)
            self.panel = panel
            return panel
        }
    }
}

func profileMenuShowsKeyboardHighlight(
    keyboardNavigation: Bool, hasHoveredItem: Bool, isFocused: Bool
) -> Bool {
    keyboardNavigation && !hasHoveredItem && isFocused
}

private struct WindowNavigationButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.isFocused) private var isFocused
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        let opacity = configuration.isPressed ? 0.28 : (isHovered ? 0.15 : 0)
        configuration.label
            .background(.white.opacity(isEnabled ? opacity : 0), in: .circle)
            .overlay {
                if isEnabled && isFocused {
                    Circle().strokeBorder(.white, lineWidth: 2)
                }
            }
            .contentShape(.rect)
            .onHover { isHovered = $0 }
    }
}
