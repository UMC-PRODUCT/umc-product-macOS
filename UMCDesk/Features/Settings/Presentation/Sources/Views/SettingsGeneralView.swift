//
//  SettingsGeneralView.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/20/26.
//

import CoreDesignSystem
import SettingsDomain
import SwiftUI

struct SettingsGeneralView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        @Bindable var preferences = viewModel.preferences
        VStack(alignment: .leading, spacing: UMCSpacing.value32) {
            SettingsSection(title: "시작과 창") {
                SettingsCard {
                    VStack(spacing: UMCSpacing.value20) {
                        SettingsRow(title: "앱을 열 때", description: "매번 사용할 첫 화면을 선택해요.") {
                            Picker("앱을 열 때", selection: $preferences.launchPage) {
                                Text("로그인").tag(SettingsLaunchPage.login)
                                Text("마이페이지").tag(SettingsLaunchPage.myPage)
                                Text("설정").tag(SettingsLaunchPage.settings)
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .controlSize(.large)
                            .frame(width: 200)
                        }
                        SettingsDivider()
                        SettingsRow(title: "로그인 시 실행", description: loginDescription) {
                            Toggle("로그인 시 실행", isOn: Binding(
                                get: { viewModel.systemStatus.loginItem == .enabled },
                                set: { value in Task { await viewModel.setLaunchAtLogin(value) } }
                            ))
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .disabled(viewModel.isChangingLoginItem ||
                                viewModel.systemStatus.loginItem == .unavailable)
                        }
                        if viewModel.systemStatus.loginItem == .requiresApproval {
                            HStack {
                                SettingsStatusText(text: "승인 필요")
                                Spacer()
                                SettingsActionButton(title: "로그인 항목 설정 열기") {
                                    viewModel.openSystemSettings(.loginItems)
                                }
                            }
                        }
                        SettingsDivider()
                        SettingsRow(title: "메뉴 막대에 표시", description: "메뉴 막대에서 앱을 빠르게 열어요.") {
                            Toggle("메뉴 막대에 표시", isOn: $preferences.showsMenuBar)
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }
                        SettingsDivider()
                        SettingsRow(title: "메인 창을 닫았을 때", description:
                            preferences.showsMenuBar ? "메뉴 막대가 켜져 있어 앱이 계속 실행돼요." :
                                "메뉴 막대가 꺼져 있어 마지막 앱 창을 닫으면 종료해요.") {
                            SettingsStatusText(text: preferences.showsMenuBar ?
                                "백그라운드 유지" : "앱 종료")
                        }
                    }
                }
            }
            SettingsSection(title: "링크 열기") {
                SettingsCard {
                    SettingsRow(title: "외부 링크", description: "외부 링크를 이 Mac의 기본 브라우저로 열어요.") {
                        SettingsStatusText(text: "기본 브라우저")
                    }
                }
            }
        }
    }

    private var loginDescription: String {
        switch viewModel.systemStatus.loginItem {
        case .unavailable: "현재 실행 환경에서는 로그인 항목을 사용할 수 없어요."
        case .requiresApproval: "macOS 로그인 항목에서 실행을 승인해 주세요."
        default: "이 Mac에 로그인하면 UMC를 실행해요."
        }
    }
}
