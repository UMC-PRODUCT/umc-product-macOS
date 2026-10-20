//
//  SettingsPrivacyView.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/20/26.
//

import CoreDesignSystem
import SettingsDomain
import SwiftUI

struct SettingsPrivacyView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value24) {
            SettingsSection(title: "시스템 권한") {
                SettingsCard {
                    SettingsRow(title: "위치 접근", description: "시스템에서 변경할 수 있어요. 현재 위치를 수집하지 않아요.") {
                        SettingsStatusText(text: locationStatus)
                        SettingsActionButton(title: "macOS 설정 열기") {
                            viewModel.openSystemSettings(.location)
                        }
                    }
                }
            }
            SettingsSection(title: "이 Mac의 저장 공간") {
                SettingsCard {
                    VStack(spacing: UMCSpacing.value12) {
                        SettingsRow(title: "임시 캐시", description: "앱 전용 임시 캐시 폴더의 파일만 정리해요.") {
                            SettingsStatusText(text: viewModel.cacheSizeText)
                            SettingsActionButton(title: "삭제") {
                                viewModel.dialogMessage = nil
                                viewModel.dialog = .clearCache
                            }
                            .disabled(viewModel.cacheBytes == nil || viewModel.isClearingCache)
                        }
                        SettingsDivider()
                        SettingsRow(title: "개인 프로젝트", description: "개인 프로젝트는 아직 제공하지 않아요.") {
                            SettingsStatusText(text: "준비 중")
                        }
                    }
                }
            }
            SettingsCard {
                VStack(alignment: .leading, spacing: UMCSpacing.value4) {
                    Text("캐시 삭제는 앱 전용 임시파일만 정리해요")
                        .umcTypography(.headlineRegular)
                    Text("계정 정보와 환경 설정, 사용자 문서와 다운로드 폴더는 삭제하지 않아요.")
                        .umcTypography(.bodyRegular)
                        .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
                }
            }
        }
        .task { await viewModel.refreshCacheSize() }
    }

    private var locationStatus: String {
        switch viewModel.systemStatus.location {
        case .notDetermined: "미설정"
        case .denied: "허용 안 됨"
        case .restricted: "제한됨"
        case .authorized: "허용됨"
        }
    }
}
