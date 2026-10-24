//
//  SettingsPrivacyView.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/20/26.
//

import UMCFoundation
import CoreDesignSystem
import SettingsDomain
import SwiftUI

struct SettingsPrivacyView: View {
    @Environment(\.settingsAppearancePalette) private var palette
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value24) {
            SettingsSection(title: AppLocalization.string("시스템 권한")) {
                SettingsCard {
                    SettingsRow(
                        title: AppLocalization.string("위치 접근"),
                        description: AppLocalization.string("시스템에서 변경할 수 있어요. 현재 위치를 수집하지 않아요.")
                    ) {
                        SettingsStatusText(text: locationStatus)
                        SettingsActionButton(title: AppLocalization.string("macOS 설정 열기")) {
                            viewModel.openSystemSettings(.location)
                        }
                    }
                }
            }
            SettingsSection(title: AppLocalization.string("이 Mac의 저장 공간")) {
                SettingsCard {
                    VStack(spacing: UMCSpacing.value12) {
                        SettingsRow(
                            title: AppLocalization.string("임시 캐시"),
                            description: AppLocalization.string("앱 전용 임시 캐시 폴더의 파일만 정리해요.")
                        ) {
                            SettingsStatusText(text: viewModel.cacheSizeText)
                            SettingsActionButton(title: AppLocalization.string("다시 확인")) {
                                Task { await viewModel.refreshCacheSize() }
                            }
                            .disabled(viewModel.isRefreshingCache || viewModel.isClearingCache)
                            SettingsActionButton(title: AppLocalization.string("삭제")) {
                                viewModel.dialogMessage = nil
                                viewModel.dialog = .clearCache
                            }
                            .disabled(!viewModel.canClearCache)
                        }
                    }
                }
            }
            SettingsCard {
                VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                    Text(AppLocalization.string("캐시 삭제는 앱 전용 임시파일만 정리해요"))
                        .umcTypography(.headlineRegular)
                    Text(AppLocalization.string("계정 정보와 환경 설정, 사용자 문서와 다운로드 폴더는 삭제하지 않아요."))
                        .umcTypography(.bodyRegular)
                        .foregroundStyle(palette.textNeutralMedium600)
                }
            }
        }
        .task { await viewModel.refreshCacheSize() }
    }

    private var locationStatus: String {
        switch viewModel.systemStatus.location {
        case .notDetermined: AppLocalization.string("미설정")
        case .denied: AppLocalization.string("허용 안 됨")
        case .restricted: AppLocalization.string("제한됨")
        case .authorized: AppLocalization.string("허용됨")
        }
    }
}
