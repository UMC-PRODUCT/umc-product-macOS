//
//  SettingsAboutView.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/20/26.
//

import UMCFoundation
import CoreDesignSystem
import SwiftUI

struct SettingsAboutView: View {
    @Environment(\.settingsAppearancePalette) private var palette
    @Bindable var viewModel: SettingsViewModel
    @Environment(\.openURL) private var openURL

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value24) {
            SettingsCard {
                VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                    HStack(spacing: UMCSpacing.value20) {
                        Image("settingsAppIcon", bundle: .module)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 64, height: 64)
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                            Text(appName).umcTypography(.title3Bold)
                            Text(AppLocalization.string("버전 \(version) | 빌드 \(build)"))
                                .textSelection(.enabled)
                                .umcTypography(.bodyRegular)
                                .foregroundStyle(palette.textNeutralWeak500)
                        }
                    }
                    SettingsDivider()
                    Text(AppLocalization.string("게시된 릴리스를 조회하며, 업데이트를 자동으로 설치하지 않아요."))
                        .umcTypography(.bodyRegular)
                        .foregroundStyle(palette.textNeutralMedium600)
                    SettingsRow(
                        title: AppLocalization.string("업데이트"), description: releaseDescription
                    ) {
                        SettingsActionButton(
                            title: viewModel.isCheckingRelease
                                ? AppLocalization.string("확인 중")
                                :
                            AppLocalization.string("업데이트 확인"), kind: .brand) {
                            Task { await viewModel.checkRelease() }
                        }
                        .disabled(viewModel.isCheckingRelease)
                    }
                    if let release = viewModel.release {
                        HStack {
                            Text(AppLocalization.string("게시된 릴리스: \(release.tag)"))
                                .umcTypography(.bodyRegular)
                            Spacer()
                            SettingsActionButton(
                                title: AppLocalization.string("릴리스 보기"), symbol: "arrow.up.right"
                            ) {
                                openURL(release.url)
                            }
                        }
                    }
                    if let message = viewModel.releaseMessage {
                        SettingsInlineMessage(message: message,
                            isError: viewModel.releaseFailed)
                    }
                }
            }
            SettingsSection(title: AppLocalization.string("도움말 및 법적 정보")) {
                SettingsCard {
                    VStack(spacing: UMCSpacing.value12) {
                        unavailableLink(
                            AppLocalization.string("이용약관"),
                            description: AppLocalization.string("서비스 이용에 필요한 약관을 확인해요."))
                        SettingsDivider()
                        unavailableLink(
                            AppLocalization.string("개인정보 처리방침"),
                            description: AppLocalization.string("개인정보 처리와 보관 기준을 확인해요."))
                        SettingsDivider()
                        SettingsRow(
                            title: AppLocalization.string("오픈소스 라이선스"),
                            description: AppLocalization.string("앱에 사용한 오픈소스 정보를 확인해요.")
                        ) {
                            SettingsActionButton(title: AppLocalization.string("열기")) {
                                viewModel.dialog = .licenses
                            }
                        }
                        SettingsDivider()
                        SettingsRow(
                            title: AppLocalization.string("문의하기(카카오톡)"),
                            description: AppLocalization.string("도움이 필요하거나 의견이 있나요?")
                        ) {
                            SettingsStatusText(text: AppLocalization.string("준비 중"))
                        }
                    }
                }
            }
        }
    }

    private func unavailableLink(_ title: String, description: String) -> some View {
        SettingsRow(title: title, description: description) {
            SettingsStatusText(text: AppLocalization.string("준비 중"))
        }
    }

    private var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? "UMC Desk"
    }

    private var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
    }

    private var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
    }

    private var releaseDescription: String {
        if let checkedAt = viewModel.releaseCheckedAt {
            let dateText = checkedAt.formatted(Date.FormatStyle(
                date: .abbreviated, time: .shortened,
                locale: AppLocalization.shared.language.locale))
            return AppLocalization.string("마지막 확인: \(dateText)")
        }
        return AppLocalization.string("공개 GitHub Releases에서 게시된 버전을 확인해요.")
    }
}

struct SettingsLicenseList: View {
    @Environment(\.settingsAppearancePalette) private var palette
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                license("Aquila · MIT",
                    url: "https://github.com/JEONG-J/Aquila/blob/main/LICENSE")
                license("Alamofire · MIT",
                    url: "https://github.com/Alamofire/Alamofire/blob/master/LICENSE")
                license("Moya · MIT", url: "https://github.com/Moya/Moya/blob/master/License.md")
                license("ReactiveSwift · MIT",
                    url: "https://github.com/ReactiveCocoa/ReactiveSwift/blob/master/LICENSE.md")
                license("RxSwift · MIT",
                    url: "https://github.com/ReactiveX/RxSwift/blob/main/LICENSE.md")
                license("Pretendard · SIL Open Font License",
                    url: "https://github.com/orioncactus/pretendard/blob/main/LICENSE")
            }
        }
        .frame(maxHeight: 340)
    }

    private func license(_ title: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Text(title).umcTypography(.title4Regular)
                Spacer()
                Image(systemName: "arrow.up.right")
            }
            .padding(.vertical, UMCSpacing.value8)
        }
        .buttonStyle(SettingsPlainButtonStyle())
        .foregroundStyle(palette.textBrandDefault)
    }
}
