//
//  SettingsProfileView.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/20/26.
//

import CoreDesignSystem
import SettingsDomain
import SwiftUI

struct SettingsProfileView: View {
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
                                SettingsUsageCard(isDesignPreview: viewModel.isDesignPreview)
                            }
                            .frame(minWidth: 340)
                            activities(profile).frame(minWidth: 340)
                        }
                        VStack(spacing: UMCSpacing.value20) {
                            profileLinks(profile)
                            activities(profile)
                            SettingsUsageCard(isDesignPreview: viewModel.isDesignPreview)
                        }
                    }
                    HStack(spacing: UMCSpacing.value16) {
                        SettingsInlineMessage(
                            message: "이름, 학교, 활동 정보가 다르면 운영진에게 문의해 주세요.",
                            typography: .bodyRegular)
                        Spacer(minLength: 0)
                        SettingsActionButton(title: "문의하기") {
                            viewModel.navigate(to: .about)
                        }
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
    }

    private func profileSummary(_ profile: SettingsProfile) -> some View {
        SettingsCard(isSubtle: true) {
            HStack(spacing: UMCSpacing.value20) {
                SettingsAvatar(url: profile.profileImageURL, size: 48,
                    usesDesignImage: viewModel.isDesignPreview)
                VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                    HStack(spacing: UMCSpacing.value8) {
                        Text("\(profile.nickname) / \(profile.name)")
                            .umcTypography(.title2Bold)
                        if let activity = profile.activities.last {
                            SettingsPartTag(part: activity.part)
                        }
                    }
                    Text(profile.schoolName ?? "학교 정보 없음")
                        .umcTypography(.headlineRegular)
                        .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
                    Text(profile.email ?? "이메일 정보 없음")
                        .umcTypography(.headlineRegular)
                        .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
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
                .accessibilityLabel(viewModel.isRefreshing ? "마이페이지 새로고침 중" : "마이페이지 새로고침")
                .help(viewModel.isRefreshing ?
                    "프로필과 활동 정보를 불러오는 중" : "프로필과 활동 정보를 다시 불러오기")
                .keyboardShortcut("r", modifiers: .command)
            }
        }
    }

    private func profileLinks(_ profile: SettingsProfile) -> some View {
        SettingsCard(isSubtle: true, minimumHeight: 324) {
            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                HStack(alignment: .top) {
                    profileCardHeading("프로필 링크", description: "UMC 계정에 등록한 링크예요.")
                    Spacer(minLength: UMCSpacing.value8)
                    Button { viewModel.editLinks() } label: {
                        Label("편집", systemImage: "pencil")
                            .umcTypography(.bodyRegular)
                            .padding(.horizontal, UMCSpacing.value8)
                            .frame(minHeight: 32)
                    }
                    .buttonStyle(SettingsPlainButtonStyle())
                    .padding(.top, UMCSpacing.value4)
                    .disabled(viewModel.isAccountBusy)
                    .accessibilityLabel("프로필 링크 편집")
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
                                        .padding(.trailing, UMCSpacing.value8)
                                        .padding(.vertical, UMCSpacing.value4)
                                        .frame(minHeight: 32, alignment: .leading)
                                }
                                .buttonStyle(SettingsPlainButtonStyle())
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .foregroundStyle(UMCColor.Semantic.textBrandDefault)
                                .help(profile.links[kind])
                                .accessibilityLabel("\(kind.title) 링크 열기")
                                .accessibilityValue(url.absoluteString)
                                .accessibilityHint("기본 브라우저에서 열립니다.")
                            } else {
                                let isEmpty = profile.links[kind]
                                    .trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                                Button {
                                    viewModel.editLinks(focusing: kind)
                                } label: {
                                    Text(isEmpty ? "추가하기" : "링크 수정")
                                        .umcTypography(.bodyRegular)
                                        .padding(.vertical, UMCSpacing.value4)
                                        .frame(minHeight: 32, alignment: .leading)
                                }
                                .buttonStyle(SettingsPlainButtonStyle())
                                .foregroundStyle(UMCColor.Semantic.textBrandDefault)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .disabled(viewModel.isAccountBusy)
                                .accessibilityLabel("\(kind.title) 링크 \(isEmpty ? "추가" : "수정")")
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
            AnyShapeStyle(UMCColor.Semantic.textNeutralDefault)
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
            AnyShapeStyle(UMCColor.Semantic.iconBrandStrong600)
        }
    }

    private func activities(_ profile: SettingsProfile) -> some View {
        SettingsCard(isSubtle: true, minimumHeight: 324) {
            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                profileCardHeading("내 활동", description: "참여한 기수와 파트, 맡은 역할을 확인하세요.")
                SettingsDivider()
                if profile.activities.isEmpty {
                    VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                        Text("아직 등록된 활동이 없어요.").umcTypography(.headlineBold)
                        Text("운영진에게 받은 챌린저 코드로 활동을 등록해 주세요.")
                            .umcTypography(.bodyRegular)
                            .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
                    }
                    .padding(.vertical, UMCSpacing.value16)
                } else {
                    VStack(spacing: UMCSpacing.value8) {
                        ForEach(profile.activities) { activity in
                            SettingsActivityRow(activity: activity)
                        }
                    }
                }
                SettingsActionButton(title: "활동 코드 등록", symbol: "plus", kind: .primary,
                    fillsWidth: true, action: viewModel.addPermission)
                    .environment(\.colorScheme, .light)
                    .disabled(viewModel.isAccountBusy)
            }
        }
    }

    private func profileCardHeading(_ title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value4) {
            Text(title).umcTypography(.title4Bold).accessibilityAddTraits(.isHeader)
            Text(description)
                .umcTypography(.bodyRegular)
                .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var accountState: some View {
        switch viewModel.profileState {
        case .idle, .loading:
            ProgressView("프로필을 불러오는 중이에요.")
                .umcTypography(.title4Regular)
                .padding(.top, UMCSpacing.value64)
        case .failed(let error):
            VStack(spacing: UMCSpacing.value24) {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 48))
                    .foregroundStyle(UMCColor.Semantic.iconNeutralMedium500)
                Text(error as? SettingsError == .authenticationRequired ?
                    "로그인이 필요해요" : "프로필을 불러오지 못했어요")
                    .umcTypography(.largeTitle3Bold)
                Text(error as? SettingsError == .authenticationRequired ?
                    "로그인한 계정의 프로필과 활동을 여기에서 확인할 수 있어요." :
                    "연결 상태를 확인한 뒤 다시 시도해 주세요.")
                    .umcTypography(.title4Regular)
                    .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
                if error as? SettingsError == .authenticationRequired {
                    SettingsActionButton(title: "로그인 화면으로", kind: .brand) {
                        viewModel.onOpenLogin?()
                    }
                    .disabled(viewModel.onOpenLogin == nil)
                } else {
                    SettingsActionButton(title: "다시 시도", kind: .brand) {
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
        case .blog: "블로그"
        case .personal: "개인 링크"
        }
    }
}

struct SettingsActivityRow: View {
    let activity: SettingsActivity

    var body: some View {
        HStack(spacing: UMCSpacing.value12) {
            Text(activity.generation.isEmpty ? "기수 미정" : "\(activity.generation)기")
                .umcTypography(.bodyRegular)
                .padding(.horizontal, 6)
                .frame(minHeight: 24)
                .foregroundStyle(UMCColor.Semantic.textBrandDefault)
                .background(UMCColor.Semantic.fillPrimaryWeak75,
                    in: .rect(cornerRadius: UMCRadius.value6))
            SettingsPartTag(part: activity.part)
            Spacer(minLength: UMCSpacing.value8)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: UMCSpacing.value8) { roleTags }
                VStack(alignment: .trailing, spacing: UMCSpacing.value4) { roleTags }
            }
        }
        .frame(minHeight: 32)
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
            .foregroundStyle(roleColors(role).foreground)
            .background(roleColors(role).background,
                in: .rect(cornerRadius: UMCRadius.value6))
        }
    }
}

struct SettingsPartTag: View {
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
            (UMCColor.Semantic.textNeutralStrong800, UMCColor.Custom.backgroundTagGrey)
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
    case "": "파트 미정"
    default: part
    }
}

func roleTitle(_ role: String) -> String {
    switch role {
    case "SCHOOL_PRESIDENT": "교내 회장"
    case "SCHOOL_VICE_PRESIDENT": "교내 부회장"
    case "SCHOOL_PART_LEADER": "교내 파트장"
    case "SCHOOL_ETC_ADMIN": "기타 교내 운영진"
    case "CENTRAL_PRESIDENT": "총괄"
    case "CENTRAL_VICE_PRESIDENT": "부총괄"
    case "CENTRAL_OPERATING_TEAM_MEMBER": "중앙 운영국원"
    case "CENTRAL_EDUCATION_TEAM_MEMBER": "중앙 교육국원"
    case "CHAPTER_PRESIDENT": "지부장"
    case "SUPER_ADMIN": "Admin"
    case "PRODUCT": "Product"
    case "CHALLENGER": "챌린저"
    default: role
    }
}

func roleColors(_ role: String) -> (foreground: Color, background: Color) {
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
        (UMCColor.Semantic.tagRoleProductStrong, UMCColor.Custom.backgroundTagGrey)
    default:
        (UMCColor.Semantic.textNeutralStrong800, UMCColor.Custom.backgroundTagGrey)
    }
}

private struct SettingsUsageCard: View {
    let isDesignPreview: Bool

    private var statistics: [String] {
        #if DEBUG || UMC_PRERELEASE
        if isDesignPreview {
            return [SettingsUsagePreview.totalDuration,
                "\(SettingsUsagePreview.activeDays)일", "\(SettingsUsagePreview.currentStreak)일"]
        }
        #endif
        return ["—", "—", "—"]
    }

    var body: some View {
        SettingsCard(isSubtle: true) {
            VStack(alignment: .leading, spacing: UMCSpacing.value24) {
                HStack(spacing: UMCSpacing.value8) {
                    Text("앱 사용 기록")
                        .umcTypography(.title4Bold)
                        .accessibilityAddTraits(.isHeader)
                    #if DEBUG || UMC_PRERELEASE
                    if isDesignPreview {
                        Text("미리보기 데이터")
                            .umcTypography(.captionRegular)
                            .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
                            .padding(.horizontal, UMCSpacing.value8)
                            .padding(.vertical, UMCSpacing.value4)
                            .background(UMCColor.Semantic.surfaceNeutralMedium,
                                in: .rect(cornerRadius: UMCRadius.value4))
                    }
                    #endif
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
                #if DEBUG || UMC_PRERELEASE
                if isDesignPreview {
                    SettingsUsageHeatmap()
                } else {
                    SettingsUsagePlaceholder()
                }
                #else
                SettingsUsagePlaceholder()
                #endif
            }
        }
    }
}

private struct SettingsUsageStatistics: View {
    let values: [String]

    var body: some View {
        ForEach(Array(zip(["누적 사용 시간", "사용 일수", "현재 연속일"], values)), id: \.0) {
            title, value in
            VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                Text(title)
                    .umcTypography(.bodyRegular)
                    .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
                Text(value).umcTypography(.title2Bold)
            }
            .fixedSize(horizontal: true, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .combine)
        }
    }
}

private struct SettingsUsagePlaceholder: View {
    var body: some View {
        Text("사용 기록 기능을 준비하고 있어요.")
            .umcTypography(.bodyRegular)
            .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
            .frame(maxWidth: .infinity, minHeight: 140)
    }
}

#if DEBUG || UMC_PRERELEASE
/// 디자인 프리뷰 전용 데이터이며 사용 기록을 수집하거나 저장하지 않습니다.
enum SettingsUsagePreview {
    struct Day: Identifiable {
        let date: Date
        let minutes: Int
        var id: Date { date }
        var label: String {
            let dateText = date.formatted(Date.FormatStyle(date: .complete, time: .omitted,
                locale: Locale(identifier: "ko_KR"), calendar: SettingsUsagePreview.calendar,
                timeZone: .gmt))
            return "\(dateText), \(minutes == 0 ? "사용 기록 없음" : "\(minutes)분 사용")"
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
    static let weeks: [Week] = stride(from: 0, to: days.count, by: 7).map { start in
        let month = calendar.component(.month, from: days[start].date)
        let previousMonth = start == 0 ?
            0 : calendar.component(.month, from: days[start - 7].date)
        return Week(days: Array(days[start..<(start + 7)]),
            month: month == previousMonth ? "" : "\(month)월")
    }
    static let totalMinutes = days.reduce(0) { $0 + $1.minutes }
    static let totalDuration = "\(totalMinutes / 60)시간 \(totalMinutes % 60)분"
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
    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
            Text("최근 12주 · 2026. 7. 27. – 10. 18.")
                .umcTypography(.bodyRegular)
                .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
            HStack(alignment: .top, spacing: UMCSpacing.value4) {
                VStack(spacing: UMCSpacing.value4) {
                    Text(" ").frame(height: 16)
                    ForEach(["월", "화", "수", "목", "금", "토", "일"], id: \.self) { day in
                        Text(day).frame(height: 16)
                    }
                }
                .umcTypography(.captionRegular)
                .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
                .padding(.trailing, UMCSpacing.value4)
                .accessibilityHidden(true)
                ForEach(SettingsUsagePreview.weeks) { week in
                    VStack(spacing: UMCSpacing.value4) {
                        Text(week.month)
                            .umcTypography(.captionRegular)
                            .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
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
                Text("적음")
                ForEach([0, 15, 35, 65, 110], id: \.self) { minutes in
                    RoundedRectangle(cornerRadius: UMCRadius.value4)
                        .fill(SettingsUsagePreview.color(minutes: minutes))
                        .frame(width: 16, height: 16)
                }
                Text("많음")
            }
            .umcTypography(.captionRegular)
            .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("사용 시간 색상: 기록 없음, 30분 미만, 1시간 미만, 1시간 30분 미만, 그 이상")
        }
    }
}
#endif
