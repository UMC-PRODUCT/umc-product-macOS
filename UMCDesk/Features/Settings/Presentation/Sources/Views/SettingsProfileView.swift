//
//  SettingsProfileView.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/20/26.
//

import UMCFoundation
import CoreDesignSystem
import SettingsDomain
import CoreRouting
import SwiftUI

struct SettingsProfileView: View {
    @Environment(\.settingsAppearancePalette) private var palette
    @Environment(\.settingsOpenWindow) private var openWindow
    @FocusState private var focusesScroll: Bool
    @State private var position = ScrollPosition()
    @State private var visiblePage = CGRect.zero

    @Bindable var viewModel: SettingsViewModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        ScrollView {
            if let profile = viewModel.profile {
                VStack(alignment: .leading, spacing: UMCSpacing.value20) {
                    profileSummary(profile)
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: UMCSpacing.value20) {
                            VStack(spacing: UMCSpacing.value20) {
                                profileLinks(profile)
                                usageCard
                            }
                            .frame(minWidth: 340)
                            activities(profile).frame(minWidth: 340)
                        }
                        VStack(spacing: UMCSpacing.value20) {
                            profileLinks(profile)
                            activities(profile)
                            usageCard
                        }
                    }
                    HStack(spacing: UMCSpacing.value16) {
                        SettingsInlineMessage(
                            message: AppLocalization.string("이름, 학교, 활동 정보가 다르면 운영진에게 문의해 주세요."),
                            typography: .bodyRegular)
                        Spacer(minLength: 0)
                        SettingsProfileSupportButton {
                            openWindow(DeskWindow.support)
                        }
                        .fixedSize()
                    }
                    .padding(.horizontal, UMCSpacing.value16)
                }
                .frame(maxWidth: 880)
                .frame(maxWidth: .infinity)
                .padding(UMCSpacing.value32)
            } else {
                accountState
                    .frame(maxWidth: .infinity)
                    .padding(UMCSpacing.value64)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollPosition($position)
        .onScrollGeometryChange(for: CGRect.self) { $0.visibleRect } action: { _, rect in
            visiblePage = rect
        }
        .focusable(interactions: .edit)
        .focused($focusesScroll)
        .defaultFocus($focusesScroll, true)
        .onKeyPress(keys: [.pageDown, .pageUp, .home, .end]) { press in
            guard press.modifiers.subtracting(.numericPad).subtracting(.function).isEmpty
            else { return .ignored }
            switch press.key {
            case .pageDown: position.scrollTo(y: visiblePage.maxY)
            case .pageUp: position.scrollTo(y: max(0, visiblePage.minY - visiblePage.height))
            case .home: position.scrollTo(edge: .top)
            case .end: position.scrollTo(edge: .bottom)
            default: return .ignored
            }
            return .handled
        }
    }

    @ViewBuilder
    private var usageCard: some View {
        if viewModel.previewProfile?.activities.isEmpty == true {
            SettingsCard(isSubtle: true) {
                profileCardHeading(AppLocalization.string("앱 사용 기록"),
                    description: AppLocalization.string("사용 기록 없음"))
            }
        } else {
            SettingsUsageCard(isDesignPreview: viewModel.isDesignPreview)
        }
    }

    private func profileSummary(_ profile: SettingsProfile) -> some View {
        SettingsCard(isSubtle: true) {
            HStack(spacing: UMCSpacing.value20) {
                SettingsAvatar(url: profile.profileImageURL, size: 56,
                    usesDesignImage: viewModel.isDesignPreview)
                VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                    HStack(spacing: UMCSpacing.value8) {
                        Text("\(profile.nickname) / \(profile.name)")
                            .umcTypography(.title1Bold).accessibilityAddTraits(.isHeader)
                        if let activity = profile.activities.last {
                            SettingsPartTag(part: activity.part)
                        }
                    }
                    Text(profile.schoolName ?? AppLocalization.string("학교 정보 없음"))
                        .umcTypography(.headlineRegular)
                        .modifier(SettingsProfileDetailColor())
                    Text(profile.email ?? AppLocalization.string("이메일 정보 없음"))
                        .umcTypography(.headlineRegular)
                        .modifier(SettingsProfileDetailColor())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Button {
                    Task { await viewModel.refreshProfile() }
                } label: {
                    ZStack {
                        if viewModel.isRefreshing {
                            ProgressView().controlSize(.small)
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .frame(width: 32, height: 32)
                    .contentShape(.rect)
                }
                .buttonStyle(SettingsPlainButtonStyle())
                .disabled(viewModel.isRefreshing || viewModel.isAccountBusy)
                .accessibilityLabel(
                    viewModel.isRefreshing
                        ? AppLocalization.string("마이페이지 새로고침 중")
                        : AppLocalization.string("마이페이지 새로고침")
                )
                .help(viewModel.isRefreshing ?
                        AppLocalization.string("프로필과 활동 정보를 불러오는 중")
                        : AppLocalization.string("프로필과 활동 정보를 다시 불러오기")
                )
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }

    private func profileLinks(_ profile: SettingsProfile) -> some View {
        SettingsCard(isSubtle: true, minimumHeight: 324) {
            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                HStack(alignment: .top) {
                    profileCardHeading(
                        AppLocalization.string("프로필 링크"),
                        description: AppLocalization.string("UMC 계정에 등록한 링크예요."))
                    Spacer(minLength: UMCSpacing.value8)
                    Button { viewModel.editLinks() } label: {
                        Label(AppLocalization.string("편집"), systemImage: "pencil")
                            .umcTypography(.bodyRegular)
                            .padding(.horizontal, UMCSpacing.value8)
                            .frame(minHeight: 32)
                    }
                    .buttonStyle(SettingsPlainButtonStyle())
                    .padding(.top, UMCSpacing.value4)
                    .disabled(viewModel.isAccountBusy)
                    .accessibilityLabel(AppLocalization.string("프로필 링크 편집"))
                }
                SettingsDivider()
                VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                    ForEach(SettingsLinkKind.allCases) { kind in
                        HStack(alignment: .firstTextBaseline, spacing: UMCSpacing.value12) {
                            HStack(spacing: UMCSpacing.value8) {
                                profileLinkIcon(kind)
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundStyle(profileLinkIconStyle(kind))
                                    .frame(width: UMCSpacing.value16, height: UMCSpacing.value16)
                                    .accessibilityHidden(true)
                                Text(kind.title)
                                    .umcTypography(.headlineBold)
                            }
                            .frame(width: 96, alignment: .leading)
                            if let url = DefaultSettingsUseCase.validatedWebURL(
                                profile.links[kind]
                            ) {
                                Button { openURL(url) } label: {
                                    Text(displayLink(profile.links[kind]))
                                        .umcTypography(.bodyRegular)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .padding(.horizontal, UMCSpacing.value8)
                                        .padding(.vertical, UMCSpacing.value4)
                                        .frame(minHeight: 32, alignment: .leading)
                                }
                                .buttonStyle(SettingsPlainButtonStyle())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(palette.textBrandDefault)
                                .help(profile.links[kind])
                                .accessibilityLabel(AppLocalization.string("\(kind.title) 링크 열기"))
                                .accessibilityValue(url.absoluteString)
                                .accessibilityHint(AppLocalization.string("기본 브라우저에서 열립니다."))
                            } else {
                                let isEmpty = profile.links[kind]
                                    .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                Button {
                                    viewModel.editLinks(focusing: kind)
                                } label: {
                                    Text(
                                        isEmpty
                                            ? AppLocalization.string("추가하기")
                                            : AppLocalization.string("링크 수정")
                                    )
                                        .umcTypography(.bodyRegular)
                                        .padding(.horizontal, UMCSpacing.value8)
                                        .padding(.vertical, UMCSpacing.value4)
                                        .frame(minHeight: 32, alignment: .leading)
                                }
                                .buttonStyle(SettingsPlainButtonStyle())
                                .foregroundStyle(palette.textBrandDefault)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .disabled(viewModel.isAccountBusy)
                                .accessibilityLabel(
                                    isEmpty
                                        ? AppLocalization.string("\(kind.title) 링크 추가")
                                        :
                                    AppLocalization.string("\(kind.title) 링크 수정"))
                            }
                        }
                        .frame(minHeight: 30)
                    }
                }
            }
        }
    }

    private func profileLinkIcon(_ kind: SettingsLinkKind) -> Image {
        switch kind {
        case .github: Image("settingsLinkGitHub", bundle: .module)
        case .linkedIn: Image("settingsLinkLinkedIn", bundle: .module)
        case .instagram: Image("settingsLinkInstagram", bundle: .module)
        case .blog: Image(systemName: "globe")
        case .personal: Image(systemName: "link")
        }
    }

    private func profileLinkIconStyle(_ kind: SettingsLinkKind) -> AnyShapeStyle {
        switch kind {
        case .github:
            AnyShapeStyle(palette.textNeutralDefault)
        case .linkedIn:
            AnyShapeStyle(Color(red: 10 / 255, green: 102 / 255, blue: 194 / 255))
        case .instagram:
            AnyShapeStyle(LinearGradient(
                colors: [
                    Color(red: 131 / 255, green: 58 / 255, blue: 180 / 255),
                    Color(red: 225 / 255, green: 48 / 255, blue: 108 / 255),
                    Color(red: 252 / 255, green: 175 / 255, blue: 69 / 255)
                ],
                startPoint: .topTrailing,
                endPoint: .bottomLeading
            ))
        case .blog, .personal:
            AnyShapeStyle(palette.iconBrandStrong600)
        }
    }

    private func activities(_ profile: SettingsProfile) -> some View {
        SettingsCard(isSubtle: true, minimumHeight: 324) {
            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                    if profile.activities.isEmpty {
                        activitiesTitle
                    } else {
                        HStack {
                            activitiesTitle
                            Spacer(minLength: UMCSpacing.value12)
                            registrationButton(primary: false)
                        }
                    }
                    Text(AppLocalization.string("참여한 기수와 파트, 맡은 역할을 확인하세요."))
                        .umcTypography(.bodyRegular)
                        .foregroundStyle(palette.textNeutralMedium600)
                }
                SettingsDivider()
                if profile.activities.isEmpty {
                    VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                        Text(AppLocalization.string("아직 등록된 활동이 없어요.")).umcTypography(
                            .headlineBold)
                        Text(AppLocalization.string("운영진에게 받은 챌린저 코드로 활동을 등록해 주세요."))
                            .umcTypography(.bodyRegular)
                            .foregroundStyle(palette.textNeutralMedium600)
                    }
                    .padding(.vertical, UMCSpacing.value16)
                } else {
                    SettingsActivityList(activities: profile.activities)
                }
                if profile.activities.isEmpty { registrationButton(primary: true) }
            }
        }
    }

    private var activitiesTitle: some View {
        Text(AppLocalization.string("내 활동")).umcTypography(.title4Bold)
            .fixedSize()
            .accessibilityAddTraits(.isHeader)
    }

    private func registrationButton(primary: Bool) -> some View {
        SettingsProfileRegistrationButton(isPrimary: primary, action: viewModel.addPermission)
            .frame(maxWidth: primary ? .infinity : nil, minHeight: 40)
            .fixedSize(horizontal: !primary, vertical: true)
            .disabled(viewModel.isAccountBusy)
    }

    private func profileCardHeading(_ title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value4) {
            Text(title).umcTypography(.title4Bold).accessibilityAddTraits(.isHeader)
            Text(description)
                .umcTypography(.bodyRegular)
                .foregroundStyle(palette.textNeutralMedium600)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var accountState: some View {
        switch viewModel.profileState {
        case .idle, .loading:
            ProgressView(AppLocalization.string("프로필을 불러오는 중이에요."))
                .umcTypography(.title4Regular)
                .padding(.top, UMCSpacing.value64)
        case .failed(let error):
            VStack(spacing: UMCSpacing.value24) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(palette.iconNeutralMedium500)
                Text(error as? SettingsError == .authenticationRequired ?
                    AppLocalization.string("로그인이 필요해요") : AppLocalization.string("프로필을 불러오지 못했어요"))
                    .umcTypography(.largeTitle3Bold)
                Text(error as? SettingsError == .authenticationRequired ?
                    AppLocalization.string("로그인한 계정의 프로필과 활동을 여기에서 확인할 수 있어요.") :
                    AppLocalization.string("연결 상태를 확인한 뒤 다시 시도해 주세요."))
                    .umcTypography(.title4Regular)
                    .foregroundStyle(palette.textNeutralMedium600)
                if error as? SettingsError == .authenticationRequired {
                    SettingsActionButton(title: AppLocalization.string("로그인 화면으로"), kind: .brand) {
                        viewModel.onOpenLogin?()
                    }
                    .disabled(viewModel.onOpenLogin == nil)
                } else {
                    SettingsActionButton(title: AppLocalization.string("다시 시도"), kind: .brand) {
                        Task { await viewModel.refreshProfile() }
                    }
                    .keyboardShortcut("r", modifiers: .command)
                }
            }
            .multilineTextAlignment(.center)
            .padding(.top, UMCSpacing.value64)
        case .loaded:
            EmptyView()
        }
    }

    private func displayLink(_ value: String) -> String {
        value.replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
    }
}

extension SettingsLinkKind {
    var title: String {
        switch self {
        case .github: "GitHub"
        case .linkedIn: "LinkedIn"
        case .instagram: "Instagram"
        case .blog: AppLocalization.string("블로그")
        case .personal: AppLocalization.string("개인 링크")
        }
    }
}

struct SettingsActivityList: View {
    @Environment(\.settingsAppearancePalette) private var palette
    let activities: [SettingsActivity]

    var body: some View {
        Grid(alignment: .leading, horizontalSpacing: UMCSpacing.value12,
             verticalSpacing: UMCSpacing.value8) {
            GridRow {
                Text(AppLocalization.string("기수"))
                Text(AppLocalization.string("파트"))
                Text(AppLocalization.string("직책"))
            }
            .umcTypography(.captionRegular)
            .foregroundStyle(palette.textNeutralMedium600)
            ForEach(activities) { activity in
                SettingsActivityRow(activity: activity)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SettingsActivityRow: View {
    @Environment(\.settingsAppearancePalette) private var palette
    let activity: SettingsActivity

    var body: some View {
        GridRow {
            Text(activity.generation.isEmpty ? AppLocalization.string("기수 미정") :
                AppLocalization.string("\(activity.generation)기"))
                .umcTypography(.bodyRegular)
                .padding(.horizontal, 6)
                .frame(minHeight: 24)
                .foregroundStyle(palette.textBrandDefault)
                .background(palette.fillPrimaryWeak75,
                    in: .rect(cornerRadius: UMCRadius.value6))
            SettingsPartTag(part: activity.part)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: UMCSpacing.value8) { roleTags }
                VStack(alignment: .leading, spacing: UMCSpacing.value4) { roleTags }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private var roleTags: some View {
        ForEach(activity.roles, id: \.self) { role in
            HStack(spacing: UMCSpacing.value4) {
                if role == "PRODUCT" {
                    Image(systemName: "gearshape.fill").accessibilityHidden(true)
                }
                Text(roleTitle(role))
            }
            .umcTypography(.bodyRegular)
            .padding(.horizontal, 6)
            .frame(minHeight: 24)
            .foregroundStyle(roleColors(role, palette: palette).foreground)
            .background(roleColors(role, palette: palette).background,
                in: .rect(cornerRadius: UMCRadius.value6))
        }
    }
}

struct SettingsPartTag: View {
    @Environment(\.settingsAppearancePalette) private var palette
    let part: String
    var minimumHeight: CGFloat = 24

    var body: some View {
        Text(part == "PLAN" ? "PM" : partTitle(part))
            .umcTypography(.bodyRegular)
            .foregroundStyle(colors.foreground)
            .padding(.horizontal, 6)
            .frame(minHeight: minimumHeight)
            .background(colors.background,
                in: .rect(cornerRadius: UMCRadius.value6))
    }

    private var colors: (foreground: Color, background: Color) {
        switch part {
        case "PLAN", "PM":
            (UMCColor.Semantic.tagPartPmStrong, UMCColor.Semantic.tagPartPmWeaker)
        case "DESIGN":
            (UMCColor.Semantic.tagPartDesignStrong, UMCColor.Semantic.tagPartDesignWeaker)
        case "IOS", "ANDROID", "MOBILE_PRODUCT_ENGINEER":
            (UMCColor.Semantic.tagPartMobilePeStrong, UMCColor.Semantic.tagPartMobilePeWeaker)
        case "WEB", "WEB_PRODUCT_ENGINEER":
            (UMCColor.Semantic.tagPartWebPeStrong, UMCColor.Semantic.tagPartWebPeWeaker)
        default:
            (palette.textNeutralStrong800, palette.backgroundTagGrey)
        }
    }
}

func partTitle(_ part: String) -> String {
    switch part {
    case "PLAN", "PM": "Plan"
    case "DESIGN": "Design"
    case "IOS": "iOS"
    case "ANDROID": "Android"
    case "WEB": "Web"
    case "SPRINGBOOT": "SpringBoot"
    case "NODEJS": "Node.js"
    case "ADMIN": "Admin"
    case "WEB_PRODUCT_ENGINEER": "Web PE"
    case "MOBILE_PRODUCT_ENGINEER": "Mobile PE"
    case "": AppLocalization.string("파트 미정")
    default: part
    }
}

func roleTitle(_ role: String) -> String {
    switch role {
    case "SCHOOL_PRESIDENT": AppLocalization.string("교내 회장")
    case "SCHOOL_VICE_PRESIDENT": AppLocalization.string("교내 부회장")
    case "SCHOOL_PART_LEADER": AppLocalization.string("교내 파트장")
    case "SCHOOL_ETC_ADMIN": AppLocalization.string("기타 교내 운영진")
    case "CENTRAL_PRESIDENT": AppLocalization.string("총괄")
    case "CENTRAL_VICE_PRESIDENT": AppLocalization.string("부총괄")
    case "CENTRAL_OPERATING_TEAM_MEMBER": AppLocalization.string("중앙 운영국원")
    case "CENTRAL_EDUCATION_TEAM_MEMBER": AppLocalization.string("중앙 교육국원")
    case "CHAPTER_PRESIDENT": AppLocalization.string("지부장")
    case "SUPER_ADMIN": "Admin"
    case "PRODUCT": "Product"
    case "CHALLENGER": AppLocalization.string("챌린저")
    default: role
    }
}

func roleColors(_ role: String, palette: SettingsAppearancePalette = .init()) -> (
    foreground: Color, background: Color
) {
    switch role {
    case "CENTRAL_PRESIDENT", "CENTRAL_VICE_PRESIDENT",
        "CENTRAL_OPERATING_TEAM_MEMBER", "CENTRAL_EDUCATION_TEAM_MEMBER":
        (UMCColor.Semantic.tagRoleCentralStrong, UMCColor.Semantic.tagRoleCentralWeak)
    case "CHAPTER_PRESIDENT":
        (UMCColor.Semantic.tagRoleChapterStrong, UMCColor.Semantic.tagRoleChapterWeak)
    case "SCHOOL_PRESIDENT", "SCHOOL_VICE_PRESIDENT", "SCHOOL_PART_LEADER", "SCHOOL_ETC_ADMIN":
        (UMCColor.Semantic.tagRoleCampusStrong, UMCColor.Semantic.tagRoleCampusWeak)
    case "SUPER_ADMIN", "CHALLENGER":
        (UMCColor.Semantic.tagRoleChallengerSuperAdminStrong,
            UMCColor.Semantic.tagRoleChallengerSuperAdminWeak)
    case "PRODUCT":
        (UMCColor.Semantic.tagRoleProductStrong, palette.backgroundTagGrey)
    default:
        (palette.textNeutralStrong800, palette.backgroundTagGrey)
    }
}

private struct SettingsUsageCard: View {
    @Environment(\.settingsAppearancePalette) private var palette
    let isDesignPreview: Bool

    private var statistics: [String] {
        if isDesignPreview {
            return [SettingsUsagePreview.totalDuration,
                AppLocalization.string("\(SettingsUsagePreview.activeDays)일"),
                AppLocalization.string("\(SettingsUsagePreview.currentStreak)일")]
        }
        return ["—", "—", "—"]
    }

    var body: some View {
        SettingsCard(isSubtle: true) {
            VStack(alignment: .leading, spacing: UMCSpacing.value24) {
                HStack(spacing: UMCSpacing.value8) {
                    Text(AppLocalization.string("앱 사용 기록"))
                        .umcTypography(.title4Bold)
                        .accessibilityAddTraits(.isHeader)
                    if isDesignPreview {
                        Text(AppLocalization.string("미리보기 데이터"))
                            .umcTypography(.captionRegular)
                            .foregroundStyle(palette.textNeutralMedium600)
                            .padding(.horizontal, UMCSpacing.value8)
                            .padding(.vertical, UMCSpacing.value4)
                            .background(palette.surfaceNeutralMedium,
                                in: .rect(cornerRadius: UMCRadius.value4))
                    }
                }
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: UMCSpacing.value24) {
                        SettingsUsageStatistics(values: statistics)
                    }
                    VStack(alignment: .leading, spacing: UMCSpacing.value24) {
                        SettingsUsageStatistics(values: statistics)
                    }
                }
                SettingsDivider()
                if isDesignPreview {
                    SettingsUsageHeatmap()
                } else {
                    SettingsUsagePlaceholder()
                }
            }
        }
    }
}

private struct SettingsUsageStatistics: View {
    @Environment(\.settingsAppearancePalette) private var palette
    let values: [String]

    var body: some View {
        ForEach(
            Array(
                zip(
                    [
                        AppLocalization.string("누적 사용 시간"), AppLocalization.string("사용 일수"),
                        AppLocalization.string("현재 연속일"),
                    ], values)), id: \.0
        ) {
            title, value in
            VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                Text(title)
                    .umcTypography(.bodyRegular)
                    .foregroundStyle(palette.textNeutralMedium600)
                Text(value).umcTypography(.title2Bold)
            }
            .fixedSize(horizontal: true, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }
}

private struct SettingsUsagePlaceholder: View {
    @Environment(\.settingsAppearancePalette) private var palette
    var body: some View {
        Text(AppLocalization.string("사용 기록 기능을 준비하고 있어요."))
            .umcTypography(.bodyRegular)
            .foregroundStyle(palette.textNeutralMedium600)
            .frame(maxWidth: .infinity, minHeight: 140)
    }
}

/// 디자인 프리뷰 전용 데이터이며 사용 기록을 수집하거나 저장하지 않습니다.
enum SettingsUsagePreview {
    struct Day: Identifiable {
        let date: Date
        let minutes: Int
        var id: Date { date }
        var label: String {
            let dateText = date.formatted(Date.FormatStyle(date: .complete, time: .omitted,
                        locale: AppLocalization.shared.language.locale,
                        calendar: SettingsUsagePreview.calendar,
                timeZone: .gmt))
            let usage = minutes == 0 ? AppLocalization.string("사용 기록 없음") :
                AppLocalization.string("\(minutes)분 사용")
            return "\(dateText), \(usage)"
        }
    }

    struct Week: Identifiable {
        let days: [Day]
        let month: String
        var id: Date { days[0].date }
    }

    static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }()
    static let days: [Day] = {
        let start = calendar.date(from: DateComponents(year: 2026, month: 7, day: 27))!
        return (0..<84).map { offset in
            let minutes = offset % 9 == 0 || offset % 7 == 5 ?
                0 : [15, 35, 65, 110][offset % 4]
            return Day(date: calendar.date(byAdding: .day, value: offset, to: start)!,
                minutes: minutes)
        }
    }()
    static var weeks: [Week] { stride(from: 0, to: days.count, by: 7).map { start in
        let month = calendar.component(.month, from: days[start].date)
        let previousMonth = start == 0 ?
            0 : calendar.component(.month, from: days[start - 7].date)
        return Week(days: Array(days[start..<(start + 7)]),
            month: month == previousMonth ? "" : AppLocalization.string("\(month)월"))
    } }
    static let totalMinutes = days.reduce(0) { $0 + $1.minutes }
    static var totalDuration: String {
        AppLocalization.string("\(totalMinutes / 60)시간 \(totalMinutes % 60)분")
    }
    static let activeDays = days.filter { $0.minutes > 0 }.count
    static let currentStreak = days.reversed().prefix { $0.minutes > 0 }.count

    static func color(minutes: Int) -> Color {
        switch minutes {
        case 0: UMCColor.Semantic.surfaceNeutralMedium
        case 1..<30: UMCColor.Semantic.fillPrimaryMedium100
        case 30..<60: UMCColor.Semantic.fillPrimaryStrong200
        case 60..<90: UMCColor.Semantic.fillPrimaryStronger300
        default: UMCColor.Semantic.fillPrimaryInverseStrong500
        }
    }
}

private struct SettingsUsageHeatmap: View {
    @Environment(\.settingsAppearancePalette) private var palette
    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
            Text(AppLocalization.string("최근 12주 · 2026. 7. 27. – 10. 18."))
                .umcTypography(.bodyRegular)
                .foregroundStyle(palette.textNeutralMedium600)
            HStack(alignment: .top, spacing: UMCSpacing.value4) {
                VStack(spacing: UMCSpacing.value4) {
                    Text(" ").frame(height: 16)
                        ForEach(
                            [
                                AppLocalization.string("월"), AppLocalization.string("화"),
                                AppLocalization.string("수"), AppLocalization.string("목"),
                                AppLocalization.string("금"), AppLocalization.string("토"),
                                AppLocalization.string("일"),
                            ], id: \.self
                        ) { day in
                        Text(day).frame(height: 16)
                    }
                }
                .umcTypography(.captionRegular)
                .modifier(SettingsProfileDetailColor())
                .padding(.trailing, UMCSpacing.value4)
                .accessibilityHidden(true)
                ForEach(SettingsUsagePreview.weeks) { week in
                    VStack(spacing: UMCSpacing.value4) {
                        Text(week.month)
                            .umcTypography(.captionRegular)
                            .modifier(SettingsProfileDetailColor())
                            .frame(height: 16)
                            .accessibilityHidden(true)
                        ForEach(week.days) { day in
                            RoundedRectangle(cornerRadius: UMCRadius.value4)
                                .fill(SettingsUsagePreview.color(minutes: day.minutes))
                                .frame(height: 16)
                                .help(day.label)
                                .accessibilityElement(children: .ignore)
                                .accessibilityLabel(day.label)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            HStack(spacing: UMCSpacing.value4) {
                Spacer(minLength: 0)
                Text(AppLocalization.string("적음"))
                ForEach([0, 15, 35, 65, 110], id: \.self) { minutes in
                    RoundedRectangle(cornerRadius: UMCRadius.value4)
                        .fill(SettingsUsagePreview.color(minutes: minutes))
                        .frame(width: 16, height: 16)
                }
                Text(AppLocalization.string("많음"))
            }
            .umcTypography(.captionRegular)
            .foregroundStyle(palette.textNeutralMedium600)
            .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    AppLocalization.string("사용 시간 색상: 기록 없음, 30분 미만, 1시간 미만, 1시간 30분 미만, 그 이상"))
        }
    }
}

private struct SettingsProfileDetailColor: ViewModifier {
    @Environment(\.settingsAppearancePalette) private var palette
    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        content.foregroundStyle(contrast == .increased ?
            palette.textNeutralDefault : palette.textNeutralStrong800)
    }
}

/// The same AppKit control owns the AX action, key-window first responder and focus ring.
private struct SettingsProfileRegistrationButton: NSViewRepresentable {
    @Environment(\.isEnabled) private var isEnabled
    let isPrimary: Bool
    let action: () -> Void

    func makeNSView(context: Context) -> RegistrationButton {
        let button = RegistrationButton()
        button.bezelStyle = .rounded
        button.controlSize = .large
        button.image = NSImage(systemSymbolName: "plus", accessibilityDescription: nil)
        button.imagePosition = .imageLeading
        button.target = button
        button.action = #selector(RegistrationButton.openRegistration)
        return button
    }

    func updateNSView(_ button: RegistrationButton, context: Context) {
        let title = AppLocalization.string("활동 코드 등록")
        button.title = title
        button.setAccessibilityLabel(title)
        button.bezelColor = isPrimary ? NSColor(UMCColor.Semantic.fillPrimaryInverseStrong500) : nil
        button.isEnabled = isEnabled
        button.open = action
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView: RegistrationButton,
                      context: Context) -> CGSize? {
        CGSize(width: isPrimary ? proposal.width ?? nsView.intrinsicContentSize.width :
            nsView.intrinsicContentSize.width, height: 40)
    }

    final class RegistrationButton: SettingsProfileKeyButton {
        var open: (() -> Void)?
        private var isPresentingRegistration = false

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            NotificationCenter.default.removeObserver(self, name: NSWindow.didEndSheetNotification,
                                                      object: nil)
            if let window {
                NotificationCenter.default.addObserver(self, selector: #selector(sheetDidEnd),
                    name: NSWindow.didEndSheetNotification, object: window)
            }
        }

        @objc private func sheetDidEnd() {
            guard isPresentingRegistration else { return }
            isPresentingRegistration = false
            // Let the sheet finish handing the key window back before restoring its responder.
            Task { @MainActor [weak self] in
                guard let self, let window, window.attachedSheet == nil, canBecomeKeyView
                else { return }
                window.makeFirstResponder(self)
            }
        }

        @objc func openRegistration() {
            guard isEnabled, let window else { return }
            window.makeFirstResponder(self)
            isPresentingRegistration = true
            open?()
        }
    }
}

/// AppKit resolves Tab before a SwiftUI key handler when a native control is in the key loop.
private struct SettingsProfileSupportButton: NSViewRepresentable {
    let action: () -> Void

    func makeNSView(context: Context) -> SupportButton {
        let button = SupportButton()
        button.bezelStyle = .rounded
        button.controlSize = .large
        button.target = button
        button.action = #selector(SupportButton.openSupport)
        return button
    }

    func updateNSView(_ button: SupportButton, context: Context) {
        button.title = AppLocalization.string("문의하기")
        button.setAccessibilityLabel(button.title)
        button.open = action
    }

    final class SupportButton: SettingsProfileKeyButton {
        var open: (() -> Void)?
        private var pageNavigationPending = false
        private var returnsFromSupport = false
        private var keyMonitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
            keyMonitor = nil
            pageNavigationPending = false
            returnsFromSupport = false
            NotificationCenter.default.removeObserver(self, name: NSWindow.didBecomeKeyNotification,
                                                      object: nil)
            guard let window else { return }
            NotificationCenter.default.addObserver(self, selector: #selector(restoreFocus),
                name: NSWindow.didBecomeKeyNotification, object: window)
            keyMonitor = NSEvent.addLocalMonitorForEvents(
                matching: [.keyDown, .leftMouseDown, .rightMouseDown]
            ) { [weak self] event in
                self?.handlesNavigation(event) == true ? nil : event
            }
        }

        private func handlesNavigation(_ event: NSEvent) -> Bool {
            guard let window, event.window === window, window.attachedSheet == nil,
                  event.type == .keyDown else {
                pageNavigationPending = false
                return false
            }
            let modifiers = event.modifierFlags.intersection([.command, .control, .shift, .option])
            let key = event.specialKey
            let followsPageNavigation = pageNavigationPending
            pageNavigationPending = modifiers.isEmpty && (key == .pageDown || key == .end)
            guard followsPageNavigation, modifiers.isEmpty, event.characters == "\t",
                  let scroll = enclosingScrollView, let document = scroll.documentView
            else { return false }
            let viewport = scroll.documentVisibleRect
            guard viewport.minY > document.bounds.minY,
                  viewport.maxY >= document.bounds.maxY - 1,
                  visibleRect.intersects(bounds) else { return false }
            return window.makeFirstResponder(self)
        }

        @objc func openSupport() {
            guard let window else { return }
            window.makeFirstResponder(self)
            returnsFromSupport = true
            open?()
        }

        @objc private func restoreFocus() {
            guard returnsFromSupport else { return }
            returnsFromSupport = false
            window?.makeFirstResponder(self)
        }
    }
}

private class SettingsProfileKeyButton: NSButton {
    override var acceptsFirstResponder: Bool { isEnabled }
    override var canBecomeKeyView: Bool { isEnabled && !isHiddenOrHasHiddenAncestor }

    override func keyDown(with event: NSEvent) {
        if event.charactersIgnoringModifiers == "\r",
           event.modifierFlags.intersection([.command, .control, .option, .shift]).isEmpty {
            performClick(nil)
        } else {
            super.keyDown(with: event)
        }
    }
}
