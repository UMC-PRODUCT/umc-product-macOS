//
//  AuthStatusViews.swift
//  AuthPresentation
//
//  Created by euijjang97 on 10/10/26.
//

import CoreDesignSystem
import SwiftUI

struct AuthStatusPage: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: UMCSpacing.value64) {
            AuthHeading(
                title: viewModel.screen.copy.title,
                subtitle: viewModel.screen.copy.subtitle,
                icon: viewModel.screen.copy.icon
            )
            VStack(spacing: UMCSpacing.value24) {
                AuthStatusBanner(screen: viewModel.screen)
                AuthStatusActions(viewModel: viewModel)
            }
        }
    }
}

private struct AuthStatusBanner: View {
    let screen: AuthScreen

    var body: some View {
        switch screen {
        case .memberFailure:
            AuthBanner(
                title: "잠시 후 다시 확인해 주세요.",
                message: "다시 확인하면 회원 정보 조회부터 이어서 진행할게요."
            )
        case .sessionExpired:
            VStack(spacing: UMCSpacing.value20) {
                AuthBanner(
                    title: "저장한 프로젝트는 유지돼요.",
                    message: "같은 계정으로 로그인하면 저장한 기록을 다시 볼 수 있어요."
                )
                AuthBanner(
                    title: "임시 내용은 유지되지 않아요.",
                    message: "저장하지 않은 초안과 외부 웹 로그인 세션은 정리돼요."
                )
            }
        case .signupLoginFailure:
            AuthBanner(
                title: "회원가입을 다시 할 필요는 없어요.",
                message: "같은 로그인 방법을 선택하면 가입한 계정으로 이어서 진행할 수 있어요."
            )
        case .maintenance:
            AuthBanner(
                title: "지금은 앱을 이용할 수 없어요.",
                message: "점검 종료 후 아래 버튼으로 다시 확인해 주세요."
            )
        case .updateAvailable:
            AuthBanner(
                title: "업데이트 후 앱이 다시 시작돼요.",
                message: "진행 중인 작업을 저장한 뒤 업데이트해 주세요."
            )
        case .updateDownloadError, .updateVerificationError, .updateInstallationError:
            AuthBanner(
                title: "업데이트를 완료하지 못했어요.",
                message: "같은 문제가 반복되면 고객센터에 문의해 주세요.",
                isError: true
            )
        case .withdrawalConfirmation:
            AuthBanner(
                title: "탈퇴하면 현재 계정이 삭제돼요.",
                message: "이 작업은 되돌릴 수 없어요.", isError: true
            )
        default:
            EmptyView()
        }
    }
}

private struct AuthStatusActions: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: UMCSpacing.value16) {
            switch viewModel.screen {
            case .offline:
                AuthButton(title: "다시 확인") { viewModel.screen = .sessionChecking }
                AuthButton(title: "고객센터 문의", kind: .secondary) { showsSupport = true }
            case .loginFailure:
                AuthButton(title: "다시 확인") { viewModel.screen = .sessionChecking }
                AuthButton(title: "다른 로그인 방법 선택", kind: .secondary) {
                    viewModel.navigate(to: .loginSelection)
                }
                AuthButton(title: "고객센터 문의", kind: .tertiary) { showsSupport = true }
            case .memberFailure:
                AuthButton(title: "회원 정보 다시 확인") { viewModel.screen = .memberChecking }
                AuthButton(title: "로그인으로 돌아가기", kind: .secondary) {
                    viewModel.navigate(to: .emailLogin)
                }
                AuthButton(title: "다른 로그인 방법", kind: .tertiary) {
                    viewModel.navigate(to: .loginSelection)
                }
            case .sessionExpired:
                AuthButton(title: "다시 로그인") { viewModel.navigate(to: .loginSelection) }
            case .signupComplete, .challengerPending:
                AuthButton(title: "확인") { viewModel.navigate(to: .loginSelection) }
            case .signupLoginFailure, .passwordResetComplete:
                AuthButton(title: "로그인으로 이동") { viewModel.navigate(to: .emailLogin) }
            case .maintenance:
                AuthButton(title: "점검 상태 다시 확인") { }
            case .updateAvailable:
                AuthButton(title: "지금 업데이트") { viewModel.screen = .updateDownloading }
                AuthButton(title: "나중에", kind: .secondary) {
                    viewModel.navigate(to: .loginSelection)
                }
            case .updateDownloadError, .updateVerificationError:
                AuthButton(title: "다시 다운로드") { viewModel.screen = .updateDownloading }
                AuthButton(title: "나중에", kind: .secondary) {
                    viewModel.navigate(to: .loginSelection)
                }
                AuthSupportButton()
            case .updateInstallationError:
                AuthButton(title: "앱 다시 시작") { viewModel.navigate(to: .loginSelection) }
                AuthSupportButton()
            case .logoutConfirmation, .withdrawalConfirmation:
                HStack(spacing: UMCSpacing.value12) {
                    AuthButton(title: "취소", kind: .secondary) {
                        viewModel.screen = .challengerIntro
                    }
                    AuthButton(
                        title: viewModel.screen == .logoutConfirmation ? "로그아웃" : "회원 탈퇴",
                        kind: viewModel.screen == .logoutConfirmation ? .primary : .destructive
                    ) {
                        // UI navigation only; no tokens or account data are changed.
                        viewModel.navigate(to: .loginSelection)
                    }
                }
            default:
                EmptyView()
            }
        }
        .alert("고객센터 연결 준비 중", isPresented: $showsSupport) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("고객센터 연결은 추후 제공될 예정이에요.")
        }
    }

    @State private var showsSupport = false
}

struct AuthChallengerIntro: View {
    @Bindable var viewModel: AuthViewModel
    @State private var showsWebsiteNotice = false

    var body: some View {
        VStack(spacing: UMCSpacing.value64) {
            AuthHeading(
                title: viewModel.screen.copy.title,
                subtitle: viewModel.screen.copy.subtitle
            )
            VStack(spacing: UMCSpacing.value24) {
                AuthBanner(
                    title: "기존 챌린저라면?",
                    message: "운영진에게 발급받은 6자리 코드를 등록해 주세요.\n등록 후에도 최종 승인이 필요할 수 있어요."
                )
                VStack(spacing: UMCSpacing.value16) {
                    AuthButton(title: "UMC 챌린저 인증하기") {
                        viewModel.navigate(to: .challengerCode)
                    }
                    AuthButton(title: "UMC 홈페이지", kind: .brand) {
                        showsWebsiteNotice = true
                    }
                    HStack(spacing: UMCSpacing.value12) {
                        AuthButton(title: "로그아웃", kind: .secondary) {
                            viewModel.screen = .logoutConfirmation
                        }
                        AuthButton(title: "회원 탈퇴", kind: .destructiveQuiet) {
                            viewModel.screen = .withdrawalConfirmation
                        }
                    }
                    AuthSupportButton()
                }
            }
        }
        .alert("홈페이지 연결 준비 중", isPresented: $showsWebsiteNotice) {
            Button("확인", role: .cancel) { }
        }
    }
}

struct AuthChallengerCode: View {
    @Bindable var viewModel: AuthViewModel
    @FocusState private var focusedField: AuthField?

    var body: some View {
        @Bindable var form = viewModel.form
        VStack(spacing: UMCSpacing.value64) {
            AuthHeading(
                title: viewModel.screen.copy.title,
                subtitle: viewModel.screen.copy.subtitle
            )
            VStack(spacing: UMCSpacing.value24) {
                VStack(alignment: .leading, spacing: UMCSpacing.value20) {
                    AuthTextField(
                        "챌린저 코드", placeholder: "6자리 코드를 입력해 주세요.",
                        text: $form.challengerCode, field: .challengerCode, focus: $focusedField,
                        showsClear: viewModel.screen == .challengerCodeError &&
                            focusedField == .challengerCode
                    )
                    if viewModel.screen == .challengerCodeError {
                        AuthBanner(
                            title: "이미 사용된 챌린저 코드예요.",
                            message: "운영진에게 코드를 확인해 주세요.\n다른 코드를 받았다면 다시 입력할 수 있어요.",
                            isError: true
                        )
                    } else {
                        Text("이름, 학교는 회원가입 때 입력한 정보와 일치해야 해요.")
                            .umcTypography(.bodyRegular)
                            .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
                    }
                }
                VStack(spacing: UMCSpacing.value16) {
                    AuthButton(
                        title: viewModel.screen == .challengerCodeError ? "다시 입력" : "코드 인증"
                    ) {
                        if viewModel.screen == .challengerCodeError {
                            form.challengerCode = ""
                            viewModel.screen = .challengerCode
                            focusedField = .challengerCode
                        } else {
                            viewModel.screen = .challengerChecking
                        }
                    }
                    .disabled(viewModel.screen == .challengerCode && !isValidCode)
                    AuthButton(
                        title: viewModel.screen == .challengerCodeError ? "뒤로" : "취소",
                        kind: .secondary
                    ) { viewModel.navigate(to: .challengerIntro) }
                    if viewModel.screen == .challengerCodeError {
                        AuthSupportButton()
                    }
                }
            }
        }
        .onAppear { focusedField = form.initialFocus }
    }

    private var isValidCode: Bool {
        viewModel.form.challengerCode.count == 6 &&
            viewModel.form.challengerCode.unicodeScalars.allSatisfy {
                CharacterSet.alphanumerics.contains($0) && $0.isASCII
            }
    }
}

struct AuthVerificationStatus: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: UMCSpacing.value64) {
            AuthHeading(
                title: viewModel.screen.copy.title,
                subtitle: viewModel.screen.copy.subtitle
            )
            VStack(spacing: UMCSpacing.value20) {
                AuthSteps(titles: titles, completedCount: completedCount)
                if viewModel.screen == .challengerComplete {
                    AuthButton(title: "시작하기") { viewModel.navigate(to: .loginSelection) }
                } else {
                    AuthBanner(
                        title: "확인이 끝나면 자동으로 다음 화면으로 이동해요.",
                        symbol: "info.circle"
                    )
                }
            }
        }
    }

    private var completedCount: Int {
        switch viewModel.screen {
        case .memberChecking: 1
        case .challengerComplete: 3
        default: 0
        }
    }

    private var titles: [String] {
        switch viewModel.screen {
        case .memberChecking: ["계정 로그인 완료", "회원 정보 확인 중", "UMC 인증 확인"]
        case .challengerChecking: ["챌린저 코드 확인", "회원 정보 재확인", "UMC 승인 상태 확인"]
        case .challengerComplete: ["챌린저 코드 등록 완료", "회원 정보 확인 완료", "UMC 승인 확인 완료"]
        default: ["로그인 상태 확인 중", "회원 정보 확인", "UMC 인증 확인"]
        }
    }
}
