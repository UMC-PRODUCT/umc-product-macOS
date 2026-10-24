//
//  SettingsView.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/20/26.
//

import CoreDesignSystem
import SettingsDomain
import SwiftUI

public struct SettingsView: View {
    // MARK: - Property

    @State private var viewModel: SettingsViewModel
    @State private var showsSearchSuggestions = false
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    fileprivate enum Constants {
        static let railWidth: CGFloat = 44
        static let sidebarWidth: CGFloat = 271
    }

    public init(viewModel: SettingsViewModel) {
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
                if viewModel.page != .myPage {
                    settingsSidebar
                        .zIndex(1)
                    Rectangle()
                        .fill(UMCColor.Semantic.borderNeutralWeak200)
                        .frame(width: 1)
                        .accessibilityHidden(true)
                }
                pageContent
                    .simultaneousGesture(TapGesture().onEnded { dismissSearchSuggestions() })
                    .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
            }
            .background(UMCColor.Custom.backgroundDefault)
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
        .accessibilityHidden(showsProfileMenu)
        .overlay(alignment: .bottomLeading) {
            if showsProfileMenu {
                ZStack(alignment: .bottomLeading) {
                    Color.clear
                        .contentShape(.rect)
                        .onTapGesture { dismissProfileMenu() }
                        .accessibilityHidden(true)
                    profileMenu
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
        .onChange(of: searchFocus) { _, focus in
            if focus == .field { showsSearchSuggestions = true }
            else if focus == nil { showsSearchSuggestions = false }
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
        .toolbar { navigationToolbar }
        .toolbarBackground(UMCColor.Custom.backgroundAppShell, for: .windowToolbar)
        .toolbarBackgroundVisibility(.visible, for: .windowToolbar)
        .toolbarColorScheme(.dark, for: .windowToolbar)
        .foregroundStyle(UMCColor.Semantic.textNeutralDefault)
        .tint(UMCColor.Semantic.textBrandDefault)
        .sheet(item: $viewModel.dialog, onDismiss: viewModel.dismissDialog) { dialog in
            SettingsDialogContent(dialog: dialog, viewModel: viewModel)
                .interactiveDismissDisabled(viewModel.isAccountBusy || viewModel.isClearingCache)
        }
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
                railItem("홈", symbol: "house")
                railItem("공지", symbol: "megaphone")
                railItem("활동", symbol: "calendar.badge.checkmark")
                railItem("스레드", symbol: "bubble.left")
                railItem("프로젝트", symbol: "square.grid.2x2")
                railItem("커뮤니티", symbol: "person.2")
                railItem("도움말", symbol: "questionmark.circle")
            }
            Spacer(minLength: UMCSpacing.value24)
            Button { showsProfileMenu.toggle() } label: {
                SettingsAvatar(url: viewModel.profile?.profileImageURL, size: 32,
                    usesDesignImage: viewModel.isDesignPreview)
                    .frame(width: 44, height: 44)
                    .contentShape(.rect(cornerRadius: UMCRadius.value12))
            }
            .buttonStyle(SettingsPlainButtonStyle(
                highlight: UMCColor.Custom.backgroundTextWhite.opacity(0.1),
                cornerRadius: UMCRadius.value12))
            .accessibilityLabel("프로필 메뉴")
            .accessibilityHint("마이페이지, 설정 및 계정 메뉴")
            .focused($profileMenuFocus, equals: .trigger)
            .accessibilityFocused($accessibleProfileMenuFocus, equals: .trigger)
            .modifier(RailTooltip(title: "프로필 메뉴", isSuppressed: showsProfileMenu))
            .padding(.bottom, UMCSpacing.value16)
        }
    }

    private func railItem(_ title: String, symbol: String) -> some View {
        Image(systemName: symbol)
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(UMCColor.Custom.backgroundTextWhite.opacity(0.75))
            .frame(width: 44, height: 44)
            .contentShape(.rect)
            .accessibilityLabel("\(title), 준비 중")
            .accessibilityHint("\(title) 화면은 아직 제공하지 않아요.")
            .modifier(RailTooltip(title: title, isSuppressed: showsProfileMenu))
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
                            .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .padding(.horizontal, UMCSpacing.value8)
                .padding(.vertical, UMCSpacing.value4)
                SettingsDivider()
            }
            VStack(spacing: UMCSpacing.value4) {
                profileMenuButton("마이페이지", symbol: "person.crop.circle", focus: .myPage) {
                    viewModel.showProfile()
                }
                profileMenuButton("설정", symbol: "gearshape", focus: .settings) {
                    viewModel.showSettings()
                }
            }
            if viewModel.profile != nil {
                SettingsDivider()
                profileMenuButton("로그아웃", symbol: "rectangle.portrait.and.arrow.right",
                    focus: .logout) {
                    viewModel.dialogMessage = nil
                    viewModel.dialog = .logout
                }
            }
        }
        .padding(UMCSpacing.value8)
        .frame(width: 240)
        .foregroundStyle(UMCColor.Semantic.textNeutralStrong800)
        .background {
            RoundedRectangle(cornerRadius: UMCRadius.value12)
                .fill(UMCColor.Custom.backgroundDefault)
                .shadow(color: .black.opacity(0.16), radius: 16, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: UMCRadius.value12)
                .strokeBorder(UMCColor.Semantic.borderNeutralWeak200)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("프로필 메뉴")
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
        if let activity = profile.activities.first { values.append("\(activity.generation)기") }
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
                UMCColor.Semantic.fillPrimaryWeakHoverPressed : .clear,
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

    @ToolbarContentBuilder
    private var navigationToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .navigation) {
            Button("뒤로", systemImage: "chevron.left") {
                dismissSearchSuggestions()
                viewModel.goBack()
            }
                .disabled(showsProfileMenu || !viewModel.canGoBack)
                .accessibilityLabel("뒤로")
                .help("뒤로")
            Button("앞으로", systemImage: "chevron.right") {
                dismissSearchSuggestions()
                viewModel.goForward()
            }
                .disabled(showsProfileMenu || !viewModel.canGoForward)
                .accessibilityLabel("앞으로")
                .help("앞으로")
        }
        .sharedBackgroundVisibility(.hidden)
    }

    private var settingsSidebar: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            Text("설정").umcTypography(.title3Bold)
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
                                    UMCColor.Semantic.backgroundBrandWeak : .clear,
                                    in: .rect(cornerRadius: UMCRadius.value8))
                            }
                            .buttonStyle(SettingsPlainButtonStyle())
                            .foregroundStyle(viewModel.page == category ?
                                UMCColor.Semantic.textBrandDefault :
                                UMCColor.Semantic.textNeutralStrong800)
                            .accessibilityAddTraits(viewModel.page == category ? .isSelected : [])
                        }
                    }
                    if viewModel.isSearching && viewModel.searchResults.isEmpty {
                        Text("검색 결과를 찾을 수 없어요")
                            .umcTypography(.headlineRegular)
                            .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
                            .padding(.vertical, UMCSpacing.value16)
                    }
                }
            }
            .scrollIndicators(.hidden)
            .simultaneousGesture(TapGesture().onEnded { dismissSearchSuggestions() })
            Spacer(minLength: 0)
            Text("변경 사항은 바로 적용돼요")
                .umcTypography(.bodyRegular)
                .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
                .onTapGesture { dismissSearchSuggestions() }
        }
        .padding(.horizontal, UMCSpacing.value20)
        .padding(.vertical, UMCSpacing.value24)
        .frame(width: Constants.sidebarWidth)
        .background {
            UMCColor.Custom.backgroundSurfaceGreyWeaker
                .contentShape(.rect)
                .onTapGesture { dismissSearchSuggestions() }
        }
        .onKeyPress(keys: [.downArrow, .upArrow, .tab]) { press in
            moveSearchFocus(press)
        }
    }

    private var searchField: some View {
        HStack(spacing: UMCSpacing.value8) {
            Image(systemName: "magnifyingglass").accessibilityHidden(true)
            TextField("검색", text: $viewModel.searchText)
                .textFieldStyle(.plain)
                .accessibilityLabel("설정 검색")
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
                .accessibilityLabel("검색어 지우기")
            }
        }
        .umcTypography(.headlineRegular)
        .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
        .padding(.horizontal, UMCSpacing.value16)
        .frame(minHeight: 36)
        .background(UMCColor.Custom.backgroundSurfaceGreyWeak, in: .capsule)
        .overlay {
            Capsule().strokeBorder(searchFocus == .field ?
                UMCColor.Semantic.textBrandDefault : .clear, lineWidth: 2)
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
                        suggestionSection("최근 항목", items: viewModel.recentSearchItems,
                            recent: true)
                        SettingsDivider()
                    }
                    suggestionSection("추천 설정", items: SettingsSearchResult.recommendations,
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
                .fill(UMCColor.Custom.backgroundDefault)
                .shadow(color: .black.opacity(0.16), radius: 16, y: 4)
        }
        .overlay {
            RoundedRectangle(cornerRadius: UMCRadius.value12)
                .strokeBorder(UMCColor.Semantic.borderNeutralWeak200)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("설정 검색 제안")
    }

    private func suggestionSection(
        _ title: String, items: [SettingsSearchResult], recent: Bool
    ) -> some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value4) {
            Text(title)
                .umcTypography(.subheadlineRegular)
                .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
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
                                .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
                        }
                    }
                    .foregroundStyle(UMCColor.Semantic.textNeutralStrong800)
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

    private func moveSearchFocus(_ press: KeyPress) -> KeyPress.Result {
        guard viewModel.isSearching || showsSearchSuggestions else { return .ignored }
        let rows = viewModel.isSearching ? viewModel.searchResults.map {
            SearchFocus.result($0.id)
        } : suggestionItems.map(\.focus)
        let positions: [SearchFocus] = [.field] + rows
        guard let focus = searchFocus, let index = positions.firstIndex(of: focus) else {
            return .ignored
        }
        let backwards = press.key == .upArrow || press.modifiers.contains(.shift)
        let next = index + (backwards ? -1 : 1)
        guard positions.indices.contains(next) else {
            if press.key == .tab {
                showsSearchSuggestions = false
                return .ignored
            }
            return .handled
        }
        searchFocus = positions[next]
        return .handled
    }

    private func dismissSearchSuggestions() {
        showsSearchSuggestions = false
        searchFocus = nil
    }

    private func selectSearchResult(_ result: SettingsSearchResult) {
        viewModel.selectSearchResult(result)
        dismissSearchSuggestions()
    }

    private func searchResultButton(_ result: SettingsSearchResult) -> some View {
        Button { selectSearchResult(result) } label: {
            VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                Text(result.title)
                    .umcTypography(.headlineBold)
                    .foregroundStyle(UMCColor.Semantic.textNeutralStrong800)
                Text(result.summary)
                    .umcTypography(.bodyRegular)
                    .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
                Text(result.page.title)
                    .umcTypography(.captionRegular)
                    .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
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
            ScrollView {
                VStack(alignment: .leading, spacing: UMCSpacing.value24) {
                    VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                        Text(viewModel.page.title)
                            .umcTypography(.title1Bold)
                            .accessibilityAddTraits(.isHeader)
                        Text("이 Mac에서 사용하는 앱의 환경을 설정하세요.")
                            .umcTypography(.bodyRegular)
                            .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
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
                .padding(UMCSpacing.value32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
    }

    private func toastView(_ toast: SettingsToast) -> some View {
        HStack(spacing: UMCSpacing.value12) {
            Image(systemName: toast.isError ? "exclamationmark.circle" : "checkmark.circle")
            Text(toast.message).umcTypography(.title4Regular)
            Button { viewModel.toast = nil } label: { Image(systemName: "xmark") }
                .buttonStyle(SettingsPlainButtonStyle())
                .accessibilityLabel("안내 닫기")
        }
        .foregroundStyle(toast.isError ? UMCColor.Semantic.textError :
            UMCColor.Semantic.textNeutralStrong800)
        .padding(UMCSpacing.value16)
        .background(UMCColor.Custom.backgroundSurfaceWhite,
            in: .rect(cornerRadius: UMCRadius.value12))
        .overlay {
            RoundedRectangle(cornerRadius: UMCRadius.value12)
                .strokeBorder(UMCColor.Semantic.borderNeutralWeak200)
        }
        .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        .accessibilityElement(children: .contain)
    }
}

private struct RailTooltip: ViewModifier {
    let title: String
    let isSuppressed: Bool

    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .onHover { isHovered = $0 }
            .overlay(alignment: .leading) {
                if isHovered && !isSuppressed {
                    Text(title)
                        .umcTypography(.bodyRegular)
                        .foregroundStyle(UMCColor.Semantic.textInverse)
                        .padding(.horizontal, UMCSpacing.value12)
                        .padding(.vertical, UMCSpacing.value8)
                        .background(UMCColor.Semantic.textNeutralDefault,
                            in: .rect(cornerRadius: UMCRadius.value8))
                        .fixedSize()
                        .offset(x: SettingsView.Constants.railWidth + UMCSpacing.value8)
                        .allowsHitTesting(false)
                        .accessibilityHidden(true)
                }
            }
    }
}

func profileMenuShowsKeyboardHighlight(
    keyboardNavigation: Bool, hasHoveredItem: Bool, isFocused: Bool
) -> Bool {
    keyboardNavigation && !hasHoveredItem && isFocused
}
