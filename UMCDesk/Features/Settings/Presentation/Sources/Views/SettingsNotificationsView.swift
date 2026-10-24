//
//  SettingsNotificationsView.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/20/26.
//

import CoreDesignSystem
import SettingsDomain
import SwiftUI

struct SettingsNotificationsView: View {
    @Environment(\.settingsAppearancePalette) private var palette
    let viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value24) {
            SettingsCard(isSubtle: true) {
                SettingsInlineMessage(message: "알림 기능을 준비하고 있어요. "
                    + "기존 설정은 보존되며, 기능 제공 후 변경할 수 있어요.",
                    typography: .headlineRegular)
            }
            SettingsSection(title: "macOS 알림") {
                SettingsCard {
                    SettingsRow(title: "알림 접근", description: notificationDescription) {
                        SettingsStatusText(text: notificationStatus)
                        if viewModel.systemStatus.notifications == .notDetermined {
                            SettingsActionButton(title: "알림 허용", kind: .brand) {
                                Task { await viewModel.requestNotifications() }
                            }
                            .disabled(viewModel.isRequestingNotifications)
                        } else {
                            SettingsActionButton(title: "macOS 설정 열기") {
                                viewModel.openSystemSettings(.notifications)
                            }
                        }
                    }
                }
            }
            SettingsSection(title: "받을 알림") {
                SettingsCard {
                    VStack(spacing: UMCSpacing.value12) {
                        pendingNotification("출석 가능 시간", description: "출석 알림 연결 시 사용할 수신 설정이에요.")
                        SettingsDivider()
                        pendingNotification("새 공지", description: "공지 알림 연결 시 사용할 수신 설정이에요.")
                        SettingsDivider()
                        pendingNotification("스레드 메시지", description: "메시지 알림 연결 시 사용할 수신 설정이에요.")
                        SettingsDivider()
                        pendingNotification("알림 내용 표시",
                            description: "알림 연결 시 이름 · 제목 · 본문 표시 여부예요.")
                    }
                }
            }
            Text("""
                macOS에서 권한을 허용해도 출석 · 공지 · 메시지 알림은 아직 오지 않아요.
                앱이 종료된 동안 받는 원격 푸시는 제공하지 않아요.
                """)
                .umcTypography(.headlineRegular)
                .foregroundStyle(palette.textNeutralWeak500)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func pendingNotification(
        _ title: String, description: String
    ) -> some View {
        SettingsRow(title: title, description: description) {
            SettingsStatusText(text: "준비 중")
        }
    }

    private var notificationStatus: String {
        switch viewModel.systemStatus.notifications {
        case .notDetermined: "미설정"
        case .denied: "허용 안 됨"
        case .authorized: "허용됨"
        case .provisional: "조용히 전달"
        }
    }

    private var notificationDescription: String {
        switch viewModel.systemStatus.notifications {
        case .authorized, .provisional: "이 Mac에서 알림을 표시할 수 있어요."
        case .denied: "macOS 설정에서 알림을 허용할 수 있어요."
        case .notDetermined: "알림을 사용하려면 먼저 접근을 허용해 주세요."
        }
    }
}
