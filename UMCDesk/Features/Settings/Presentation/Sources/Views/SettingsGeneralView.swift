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
        VStack(alignment: .leading, spacing: UMCSpacing.value24) {
            SettingsSection(title: "시작") {
                SettingsCard {
                    VStack(spacing: UMCSpacing.value12) {
                        SettingsRow(title: "시작 화면", description: "앱을 완전히 종료한 뒤 다시 실행할 때 적용돼요.") {
                            Picker("시작 화면", selection: $preferences.launchPage) {
                                Text("로그인").tag(SettingsLaunchPage.login)
                                Text("마이페이지").tag(SettingsLaunchPage.myPage)
                                Text("설정").tag(SettingsLaunchPage.settings)
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .controlSize(.large)
                            .frame(width: 160, alignment: .trailing)
                        }
                        SettingsDivider()
                        SettingsRow(title: "Mac 로그인 시 자동 실행", description: loginDescription) {
                            Toggle("Mac 로그인 시 자동 실행", isOn: Binding(
                                get: { viewModel.systemStatus.loginItem == .enabled },
                                set: { value in Task { await viewModel.setLaunchAtLogin(value) } }
                            ))
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .disabled(viewModel.isChangingLoginItem ||
                                viewModel.systemStatus.loginItem == .unavailable)
                        }
                        if viewModel.isChangingLoginItem {
                            SettingsStatusText(text: "변경 중…")
                        } else if viewModel.systemStatus.loginItem == .requiresApproval {
                            HStack {
                                SettingsStatusText(text: "승인 필요")
                                Spacer()
                                SettingsActionButton(title: "로그인 항목 설정 열기") {
                                    viewModel.openSystemSettings(.loginItems)
                                }
                            }
                        }
                    }
                }
            }
            SettingsSection(title: "창과 메뉴 막대") {
                SettingsCard {
                    VStack(spacing: UMCSpacing.value12) {
                        SettingsRow(title: "메뉴 막대에 표시", description: "메뉴 막대에서 앱을 빠르게 열어요.") {
                            Toggle("메뉴 막대에 표시", isOn: $preferences.showsMenuBar)
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }
                        SettingsDivider()
                        SettingsRow(title: "마지막 창을 닫으면", description:
                            "계속 실행하면 Dock에서 앱을 다시 열 수 있어요.") {
                            Picker("마지막 창을 닫으면", selection: $preferences.windowCloseBehavior) {
                                Text("계속 실행").tag(SettingsWindowCloseBehavior.keepRunning)
                                Text("앱 종료").tag(SettingsWindowCloseBehavior.quit)
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .controlSize(.large)
                            .frame(width: 160, alignment: .trailing)
                        }
                    }
                }
            }
            SettingsSection(title: "링크 열기") {
                SettingsCard {
                    SettingsRow(title: "기본 웹 브라우저", description:
                        "외부 링크는 Mac의 기본 브라우저로 열어요. " +
                        "시스템 설정 > 데스크탑 및 Dock > 기본 웹 브라우저에서 변경해요.") {
                        SettingsActionButton(title: "시스템 설정 열기") {
                            viewModel.openSystemSettings(.defaultBrowser)
                        }
                    }
                }
            }
        }
    }

    private var loginDescription: String {
        switch viewModel.systemStatus.loginItem {
        case .unavailable: "현재 실행 환경에서는 로그인 항목을 사용할 수 없어요."
        case .requiresApproval: "macOS 로그인 항목에서 실행을 승인해 주세요."
        default: "이 Mac에 로그인하면 UMC Desk를 실행해요."
        }
    }
}
