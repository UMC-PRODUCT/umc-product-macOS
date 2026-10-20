//
//  SettingsAboutView.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/20/26.
//

import CoreDesignSystem
import SwiftUI

struct SettingsAboutView: View {
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
                            Text("버전 \(version) | 빌드 \(build)")
                                .umcTypography(.bodyRegular)
                                .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
                        }
                    }
                    SettingsDivider()
                    SettingsRow(title: "업데이트", description: releaseDescription) {
                        SettingsActionButton(title: viewModel.isCheckingRelease ? "확인 중" :
                            "업데이트 확인", kind: .brand) {
                            Task { await viewModel.checkRelease() }
                        }
                        .disabled(viewModel.isCheckingRelease)
                    }
                    if let release = viewModel.release {
                        HStack {
                            Text("게시된 릴리스: \(release.tag)")
                                .umcTypography(.bodyRegular)
                            Spacer()
                            SettingsActionButton(title: "릴리스 보기", symbol: "arrow.up.right") {
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
            SettingsSection(title: "도움말 및 법적 정보") {
                SettingsCard {
                    VStack(spacing: UMCSpacing.value12) {
                        unavailableLink("이용약관", description: "서비스 이용에 필요한 약관을 확인해요.")
                        SettingsDivider()
                        unavailableLink("개인정보 처리방침", description: "개인정보 처리와 보관 기준을 확인해요.")
                        SettingsDivider()
                        SettingsRow(title: "오픈소스 라이선스", description: "앱에 사용한 오픈소스 정보를 확인해요.") {
                            SettingsActionButton(title: "열기", symbol: "arrow.up.right") {
                                viewModel.dialog = .licenses
                            }
                        }
                        SettingsDivider()
                        SettingsRow(title: "문의하기(카카오톡)", description: "도움이 필요하거나 의견이 있나요?") {
                            Text("주소 확인 중")
                                .umcTypography(.headlineRegular)
                                .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
                            Image("settingsContactKakao", bundle: .module)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                                .accessibilityLabel("카카오톡 문의 주소 확인 중")
                                .help("운영 문의 주소를 확인 중이에요.")
                        }
                    }
                }
            }
        }
    }

    private func unavailableLink(_ title: String, description: String) -> some View {
        SettingsRow(title: title, description: description) {
            SettingsStatusText(text: "주소 확인 중")
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
            return "마지막 확인: \(checkedAt.formatted(date: .abbreviated, time: .shortened))"
        }
        return "공개 GitHub Releases에서 게시된 버전을 확인해요."
    }
}

struct SettingsLicenseList: View {
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
        .foregroundStyle(UMCColor.Semantic.textBrandDefault)
    }
}
