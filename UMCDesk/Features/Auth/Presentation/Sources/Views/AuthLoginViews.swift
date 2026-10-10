//
//  AuthLoginViews.swift
//  AuthPresentation
//
//  Created by euijjang97 on 10/10/26.
//

import CoreDesignSystem
import SwiftUI

struct AuthLoginSelection: View {
    let screen: AuthScreen
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: UMCSpacing.value64) {
            AuthHeading(
                title: screen.copy.title,
                subtitle: screen.copy.subtitle
            )
            VStack(spacing: UMCSpacing.value32) {
                if screen == .socialLogin {
                    VStack(spacing: UMCSpacing.value20) {
                        AuthBanner(
                            title: "\(viewModel.socialProvider) 로그인 중⋯",
                            message: "열린 인증 창에서 로그인을 마쳐 주세요.",
                            isBrand: true
                        )
                        Button("로그인 취소") { viewModel.navigate(to: .loginSelection) }
                            .buttonStyle(.plain)
                            .umcTypography(.headlineRegular)
                            .foregroundStyle(UMCColor.Semantic.textBrandDefault)
                    }
                }
                VStack(spacing: UMCSpacing.value16) {
                    AuthSocialButton(provider: .kakao) {
                        viewModel.socialProvider = "카카오"
                        viewModel.navigate(to: .socialLogin)
                    }
                    AuthSocialButton(provider: .apple) {
                        viewModel.socialProvider = "Apple"
                        viewModel.navigate(to: .socialLogin)
                    }
                    AuthSocialButton(provider: .google) {
                        viewModel.socialProvider = "Google"
                        viewModel.navigate(to: .socialLogin)
                    }
                }
                .disabled(screen == .socialLogin)
                .opacity(screen == .socialLogin ? 0.4 : 1)
                Rectangle()
                    .fill(UMCColor.Semantic.borderNeutralMedium300)
                    .frame(height: 1)
                    .accessibilityHidden(true)
                AuthSocialButton(provider: .email) {
                    viewModel.navigate(to: .emailLogin)
                }
                .disabled(screen == .socialLogin)
                .opacity(screen == .socialLogin ? 0.4 : 1)
                VStack(spacing: 0) {
                    Text("로그인에 문제가 있으신가요?")
                    HStack(spacing: 0) {
                        AuthSupportButton(isInline: true)
                        Text("로 문의해 주세요.")
                    }
                }
                .umcTypography(.bodyRegular)
                .foregroundStyle(UMCColor.Semantic.textNeutralWeak500)
            }
        }
    }
}

private enum AuthSocialProvider {
    case kakao, apple, google, email

    var title: String {
        switch self {
        case .kakao: "카카오로 계속하기"
        case .apple: "Apple로 계속하기"
        case .google: "Google로 계속하기"
        case .email: "UMC 계정 로그인"
        }
    }

    var background: Color {
        switch self {
        case .kakao: Color(red: 1, green: 234 / 255, blue: 47 / 255)
        case .apple: UMCColor.Primitives.black
        case .google: Color(red: 242 / 255, green: 242 / 255, blue: 242 / 255)
        case .email: UMCColor.Primitives.teal75
        }
    }

    var foreground: Color {
        switch self {
        case .apple: UMCColor.Semantic.textInverse
        case .email: UMCColor.Semantic.textBrandDefault
        default: UMCColor.Semantic.textNeutralDefault
        }
    }
}

private struct AuthSocialButton: View {
    let provider: AuthSocialProvider
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                Group {
                    switch provider {
                    case .kakao:
                        Image("kakaoIcon", bundle: .module)
                            .resizable().scaledToFit().frame(width: 27, height: 27)
                    case .apple:
                        Image("appleIcon", bundle: .module)
                            .renderingMode(.template)
                            .resizable().scaledToFit().frame(width: 32, height: 32)
                    case .google:
                        Image("google", bundle: .module)
                            .resizable().scaledToFit().frame(width: 26, height: 26)
                    case .email:
                        Image(systemName: "envelope")
                            .font(.system(size: 26, weight: .medium))
                    }
                }
                .frame(width: 48, height: 48)
                .accessibilityHidden(true)
                Text(provider.title)
                    .umcTypography(.title3Regular)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, UMCSpacing.value12)
            .foregroundStyle(provider.foreground)
            .background(provider.background, in: .capsule)
            .contentShape(.capsule)
        }
        .buttonStyle(AuthPressStyle())
    }
}

struct AuthEmailLogin: View {
    let screen: AuthScreen
    @Bindable var viewModel: AuthViewModel
    @FocusState private var focusedField: AuthField?

    var body: some View {
        @Bindable var form = viewModel.form
        VStack(spacing: UMCSpacing.value64) {
            AuthHeading(
                title: screen.copy.title,
                subtitle: screen.copy.subtitle
            )
            VStack(spacing: UMCSpacing.value32) {
                VStack(spacing: UMCSpacing.value20) {
                    AuthTextField(
                        "이메일", placeholder: "이메일을 입력해 주세요.",
                        text: $form.email, field: .email, focus: $focusedField,
                        showsClear: focusedField == .email
                    )
                    AuthTextField(
                        "비밀번호", placeholder: "비밀번호를 입력해 주세요.",
                        text: $form.password, field: .password, focus: $focusedField,
                        isSecure: true, showsValue: $form.showsPassword
                    )
                    if screen == .credentialsError {
                        AuthBanner(
                            title: "이메일 또는 비밀번호가 올바르지 않아요.",
                            message: "입력한 내용을 확인한 뒤 다시 시도해 주세요.",
                            isError: true
                        )
                    }
                }
                VStack(spacing: UMCSpacing.value16) {
                    AuthButton(title: "로그인") { viewModel.submitLogin() }
                        .disabled(!form.canRequestCode || form.password.isEmpty)
                    HStack(spacing: UMCSpacing.value12) {
                        AuthButton(title: "회원가입", kind: .secondary) {
                            viewModel.navigate(to: .signup)
                        }
                        AuthButton(title: "비밀번호 찾기", kind: .secondary) {
                            viewModel.navigate(to: .passwordReset)
                        }
                    }
                    AuthButton(title: "다른 로그인 방법", kind: .tertiary) {
                        viewModel.navigate(to: .loginSelection)
                    }
                }
            }
        }
        .onAppear { focusedField = form.initialFocus }
    }
}

struct AuthSupportButton: View {
    var isInline = false
    @State private var showsNotice = false

    var body: some View {
        Button { showsNotice = true } label: {
            Text(isInline ? "고객센터" : "고객센터 문의")
                .underline(isInline)
                .umcTypography(isInline ? .bodyRegular : .title3Regular)
                .foregroundStyle(
                    isInline ? UMCColor.Semantic.textBrandDefault :
                        UMCColor.Semantic.textNeutralWeak500
                )
                .frame(minHeight: isInline ? 17 : 48)
        }
        .buttonStyle(.plain)
        .alert("고객센터 연결 준비 중", isPresented: $showsNotice) {
            Button("확인", role: .cancel) { }
        } message: {
            Text("고객센터 연결은 추후 제공될 예정이에요.")
        }
    }
}
