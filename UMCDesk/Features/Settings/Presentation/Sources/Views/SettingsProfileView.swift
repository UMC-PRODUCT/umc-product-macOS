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
                VStack(alignment: .leading, spacing: UMCSpacing.value24) {
                    profileSummary(profile)
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .top, spacing: UMCSpacing.value24) {
                            profileLinks(profile).frame(minWidth: 340)
                            activities(profile).frame(minWidth: 340)
                        }
                        VStack(spacing: UMCSpacing.value24) {
                            profileLinks(profile)
                            activities(profile)
                        }
                    }
                    HStack(spacing: UMCSpacing.value16) {
                        SettingsInlineMessage(message: "이름, 학교, 활동 정보가 다르면 운영진에게 문의해 주세요.")
                        Spacer(minLength: 0)
                        SettingsActionButton(title: "문의하기") {
                            viewModel.navigate(to: .about)
                        }
                    }
                    .padding(.horizontal, UMCSpacing.value16)
                }
                .frame(maxWidth: 960)
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
                SettingsAvatar(url: profile.profileImageURL,
                    usesDesignImage: viewModel.isDesignPreview)
                VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                    HStack(spacing: UMCSpacing.value8) {
                        Text("\(profile.nickname) / \(profile.name)")
                            .umcTypography(.title1Bold)
                        if let activity = profile.activities.last {
                            SettingsPartTag(part: activity.part)
                        }
                    }
                    Text(profile.schoolName ?? "학교 정보 없음")
                        .umcTypography(.title4Regular)
                        .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
                    Text(profile.email ?? "이메일 정보 없음")
                        .umcTypography(.title4Regular)
                        .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private func profileLinks(_ profile: SettingsProfile) -> some View {
        SettingsCard(isSubtle: true, minimumHeight: 352) {
            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                HStack(alignment: .top) {
                    profileCardHeading("프로필 링크", description: "UMC 계정에 등록한 링크예요.")
                    Spacer(minLength: UMCSpacing.value8)
                    Button(action: viewModel.editLinks) {
                        Label("편집", systemImage: "pencil")
                            .umcTypography(.headlineRegular)
                    }
                    .buttonStyle(SettingsPlainButtonStyle())
                    .padding(.top, UMCSpacing.value4)
                    .disabled(viewModel.isAccountBusy)
                    .accessibilityLabel("프로필 링크 편집")
                }
                SettingsDivider()
                VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                    ForEach(SettingsLinkKind.allCases) { kind in
                        HStack(alignment: .firstTextBaseline, spacing: UMCSpacing.value12) {
                            Text(kind.title)
                                .umcTypography(.title4Bold)
                                .frame(width: 80, alignment: .leading)
                            if let url = DefaultSettingsUseCase.validatedWebURL(
                                profile.links[kind]
                            ) {
                                Button { openURL(url) } label: {
                                    Text(displayLink(profile.links[kind]))
                                        .umcTypography(.headlineRegular)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .buttonStyle(SettingsPlainButtonStyle())
                                .foregroundStyle(UMCColor.Semantic.textBrandDefault)
                                .help(profile.links[kind])
                            } else {
                                Text("미등록")
                                    .umcTypography(.headlineRegular)
                                    .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .frame(minHeight: 30)
                    }
                }
            }
        }
    }

    private func activities(_ profile: SettingsProfile) -> some View {
        SettingsCard(isSubtle: true, minimumHeight: 352) {
            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                profileCardHeading("내 활동과 권한", description: "운영진에게 받은 코드로 활동과 역할을 추가하세요.")
                SettingsDivider()
                if profile.activities.isEmpty {
                    VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                        Text("아직 등록된 활동이 없어요.").umcTypography(.title4Bold)
                        Text("활동 기록이 없어도 권한을 추가할 수 있어요.")
                            .umcTypography(.headlineRegular)
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
                SettingsActionButton(title: "권한 추가", symbol: "plus", kind: .primary,
                    fillsWidth: true, action: viewModel.addPermission)
                    .environment(\.colorScheme, .light)
                    .disabled(viewModel.isAccountBusy)
            }
        }
    }

    private func profileCardHeading(_ title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value4) {
            Text(title).umcTypography(.title3Bold).accessibilityAddTraits(.isHeader)
            Text(description)
                .umcTypography(.headlineRegular)
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
                .umcTypography(.headlineRegular)
                .padding(.horizontal, 6)
                .frame(minHeight: 26)
                .foregroundStyle(UMCColor.Semantic.textBrandDefault)
                .background(UMCColor.Semantic.fillPrimaryWeak75,
                    in: .rect(cornerRadius: UMCRadius.value6))
            Text(partTitle(activity.part)).umcTypography(.headlineBold)
            Spacer(minLength: UMCSpacing.value8)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: UMCSpacing.value8) { roleTags }
                VStack(alignment: .trailing, spacing: UMCSpacing.value4) { roleTags }
            }
        }
        .frame(minHeight: 38)
    }

    private var roleTags: some View {
        ForEach(activity.roles, id: \.self) { role in
            Text(roleTitle(role))
                .umcTypography(.bodyRegular)
                .padding(.horizontal, 6)
                .frame(minHeight: 26)
                .foregroundStyle(roleColors(role).foreground)
                .background(roleColors(role).background,
                    in: .rect(cornerRadius: UMCRadius.value6))
        }
    }
}

struct SettingsPartTag: View {
    let part: String
    var minimumHeight: CGFloat = 26

    var body: some View {
        Text(part == "PLAN" ? "PM" : partTitle(part))
            .umcTypography(.headlineRegular)
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
    case "PRODUCT": "⚙ Product"
    case "CHALLENGER": "챌린저"
    default: role
    }
}

private func roleColors(_ role: String) -> (foreground: Color, background: Color) {
    if role.hasPrefix("CENTRAL_") {
        return (UMCColor.Semantic.tagRoleCentralStrong, UMCColor.Semantic.tagRoleCentralWeaker)
    }
    if role.hasPrefix("CHAPTER_") {
        return (UMCColor.Semantic.tagRoleChapterStrong, UMCColor.Semantic.tagRoleChapterWeaker)
    }
    if role.hasPrefix("SCHOOL_") {
        return (UMCColor.Semantic.tagRoleCampusStrong, UMCColor.Semantic.tagRoleCampusWeaker)
    }
    if role == "PRODUCT" {
        return (UMCColor.Semantic.tagRoleProductStrong, UMCColor.Custom.backgroundTagGrey)
    }
    return (UMCColor.Semantic.textBrandDefault, UMCColor.Semantic.fillPrimaryWeak75)
}
