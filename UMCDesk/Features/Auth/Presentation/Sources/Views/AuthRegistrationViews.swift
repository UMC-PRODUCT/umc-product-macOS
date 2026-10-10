//
//  AuthRegistrationViews.swift
//  AuthPresentation
//
//  Created by euijjang97 on 10/10/26.
//

import CoreDesignSystem
import SwiftUI

struct AuthRegistration: View {
    @Bindable var viewModel: AuthViewModel
    @FocusState private var focusedField: AuthField?

    var body: some View {
        @Bindable var form = viewModel.form
        VStack(spacing: UMCSpacing.value40) {
            AuthHeading(
                title: viewModel.screen.copy.title,
                subtitle: viewModel.screen.copy.subtitle,
                isLeading: true
            )
            VStack(spacing: UMCSpacing.value32) {
                VStack(spacing: UMCSpacing.value20) {
                    HStack(alignment: .top, spacing: UMCSpacing.value12) {
                        AuthTextField(
                            "이름", placeholder: "이름을 입력해 주세요.",
                            text: $form.name, field: .name, focus: $focusedField
                        )
                        AuthTextField(
                            "닉네임", placeholder: "닉네임을 입력해 주세요.",
                            text: $form.nickname, field: .nickname, focus: $focusedField
                        )
                    }
                    AuthEmailVerificationFields(form: form, focus: $focusedField)
                    AuthSchoolPicker(form: form)
                    if form.emailVerification == .verified && !form.school.isEmpty {
                        AuthPasswordFields(form: form, focus: $focusedField)
                    }
                    AuthTermsAgreement(form: form)
                }
                .zIndex(form.showsSchoolPicker ? 1 : 0)
                VStack(spacing: UMCSpacing.value16) {
                    AuthButton(title: "가입 완료") { viewModel.screen = .signupComplete }
                        .disabled(!form.canRegister)
                    AuthButton(title: "로그인으로 돌아가기", kind: .tertiary) {
                        viewModel.navigate(to: .emailLogin)
                    }
                }
            }
        }
        .onAppear { focusedField = form.initialFocus }
    }
}

struct AuthPasswordReset: View {
    @Bindable var viewModel: AuthViewModel
    @FocusState private var focusedField: AuthField?

    var body: some View {
        @Bindable var form = viewModel.form
        VStack(spacing: UMCSpacing.value40) {
            AuthHeading(
                title: form.emailVerification == .verified ?
                    "새 비밀번호를 설정해 주세요" : "비밀번호 찾기",
                subtitle: form.emailVerification == .verified ?
                    "이메일 인증을 마쳤어요. 새 비밀번호를 입력해 주세요." :
                    "이메일을 인증하고 새 비밀번호를 설정해 주세요.",
                isLeading: true
            )
            VStack(spacing: UMCSpacing.value32) {
                VStack(spacing: UMCSpacing.value20) {
                    AuthEmailVerificationFields(form: form, focus: $focusedField)
                    AuthPasswordFields(form: form, focus: $focusedField, isReset: true)
                }
                VStack(spacing: UMCSpacing.value16) {
                    AuthButton(title: "비밀번호 변경") {
                        if form.canResetPassword {
                            viewModel.screen = .passwordResetComplete
                        } else {
                            form.showsPasswordError = true
                        }
                    }
                    .disabled(form.emailVerification != .verified || form.password.isEmpty)
                    AuthButton(title: "로그인으로 돌아가기", kind: .tertiary) {
                        viewModel.navigate(to: .emailLogin)
                    }
                }
            }
        }
        .onAppear { focusedField = form.initialFocus }
    }
}

private struct AuthEmailVerificationFields: View {
    @Bindable var form: AuthFormState
    let focus: FocusState<AuthField?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value20) {
            HStack(alignment: .bottom, spacing: UMCSpacing.value12) {
                AuthTextField(
                    "이메일", placeholder: "이메일을 입력해 주세요.",
                    text: $form.email, field: .email, focus: focus,
                    isDisabled: form.emailVerification == .verified,
                    showsClear: focus.wrappedValue == .email
                )
                AuthButton(title: buttonTitle) {
                    // Local display state only; email delivery is connected in a later task.
                    form.verificationCode = ""
                    form.emailVerification = .sent
                    focus.wrappedValue = .verificationCode
                }
                .frame(width: 183)
                .disabled(!form.canRequestCode || form.emailVerification == .verified)
            }
            if form.emailVerification == .sent || form.emailVerification == .invalid {
                VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                    HStack(alignment: .bottom, spacing: UMCSpacing.value12) {
                        AuthTextField(
                            "이메일 인증번호", placeholder: "6자리 숫자를 입력해 주세요.",
                            text: $form.verificationCode, field: .verificationCode, focus: focus,
                            isInvalid: form.emailVerification == .invalid
                        )
                        AuthButton(title: "인증번호 확인") {
                            form.emailVerification = .verified
                            focus.wrappedValue = nil
                        }
                        .frame(width: 183)
                        .disabled(
                            form.verificationCode.count != 6 ||
                                !form.verificationCode.allSatisfy(\.isNumber)
                        )
                    }
                    if form.emailVerification == .invalid {
                        Text("최신 메일의 번호를 입력하세요. 재전송 시 이전 번호는 만료돼요.")
                            .umcTypography(.bodyRegular)
                            .foregroundStyle(UMCColor.Semantic.textError)
                    }
                }
            }
        }
    }

    private var buttonTitle: String {
        switch form.emailVerification {
        case .idle: "인증번호 받기"
        case .sent, .invalid: "재전송"
        case .verified: "인증 완료"
        }
    }
}

private struct AuthPasswordFields: View {
    @Bindable var form: AuthFormState
    let focus: FocusState<AuthField?>.Binding
    var isReset = false

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value8) {
            HStack(alignment: .top, spacing: UMCSpacing.value12) {
                AuthTextField(
                    isReset ? "새 비밀번호" : "비밀번호",
                    placeholder: "숫자, 특수문자를 포함한 8자리 이상",
                    text: $form.password, field: .password, focus: focus,
                    isSecure: true, showsValue: $form.showsPassword,
                    isDisabled: form.emailVerification != .verified
                )
                AuthTextField(
                    isReset ? "새 비밀번호 확인" : "비밀번호 확인",
                    placeholder: "비밀번호를 다시 입력해 주세요.",
                    text: $form.passwordConfirmation, field: .passwordConfirmation, focus: focus,
                    isSecure: true, showsValue: $form.showsPasswordConfirmation,
                    isDisabled: form.emailVerification != .verified
                )
            }
            if form.showsPasswordError {
                Text("입력 조건을 충족하지 않거나 비밀번호가 일치하지 않아요.")
                    .umcTypography(.bodyRegular)
                    .foregroundStyle(UMCColor.Semantic.textError)
            }
        }
    }
}

private struct AuthSchoolPicker: View {
    @Bindable var form: AuthFormState

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value4) {
            Text("학교")
                .umcTypography(.title3Regular)
            Button { form.showsSchoolPicker.toggle() } label: {
                HStack {
                    Text(form.school.isEmpty ? "학교를 선택해 주세요." : form.school)
                        .umcTypography(.headlineRegular)
                        .foregroundStyle(
                            form.school.isEmpty ? UMCColor.Primitives.tealGrey400 :
                                UMCColor.Semantic.textNeutralDefault
                        )
                    Spacer()
                    Image(systemName: form.showsSchoolPicker ? "chevron.up" : "chevron.down")
                        .foregroundStyle(UMCColor.Semantic.iconNeutralMedium500)
                        .frame(width: 32)
                }
                .padding(.horizontal, UMCSpacing.value16)
                .frame(minHeight: 48)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .background(UMCColor.Semantic.surfaceDefault)
            .overlay {
                RoundedRectangle(cornerRadius: UMCRadius.value12)
                    .strokeBorder(UMCColor.Semantic.borderNeutralMedium300)
            }
            .accessibilityLabel("학교 선택")
            .accessibilityValue(form.school)
            .overlay(alignment: .top) {
                if form.showsSchoolPicker {
                    AuthSchoolOptions(form: form)
                        .padding(.top, 52)
                }
            }
        }
        .foregroundStyle(UMCColor.Semantic.textNeutralDefault)
        .zIndex(form.showsSchoolPicker ? 1 : 0)
        .onExitCommand { form.showsSchoolPicker = false }
    }
}

private struct AuthSchoolOptions: View {
    @Bindable var form: AuthFormState

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                #if DEBUG
                ForEach(AuthPreviewSchool.all) { school in
                    Button {
                        form.school = school.name
                        form.showsSchoolPicker = false
                    } label: {
                        Text(school.label)
                            .umcTypography(.headlineRegular)
                            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                            .padding(.horizontal, UMCSpacing.value16)
                            .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
                #endif
            }
        }
        .frame(height: 240)
        .background(UMCColor.Semantic.surfaceDefault, in: .rect(cornerRadius: UMCRadius.value12))
        .overlay {
            RoundedRectangle(cornerRadius: UMCRadius.value12)
                .strokeBorder(UMCColor.Semantic.borderNeutralWeak200)
        }
        .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
    }
}

private struct AuthTermsAgreement: View {
    @Bindable var form: AuthFormState
    @State private var selectedTerm: String?

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value8) {
            Toggle("전체 약관 동의", isOn: Binding(
                get: { form.agreesToService && form.agreesToPrivacy },
                set: { form.agreesToService = $0; form.agreesToPrivacy = $0 }
            ))
            .frame(minHeight: 40)
            Rectangle()
                .fill(UMCColor.Semantic.borderNeutralMedium300)
                .frame(height: 1)
                .accessibilityHidden(true)
            AuthTermRow(
                title: "[필수] 서비스 이용약관", isOn: $form.agreesToService
            ) { selectedTerm = "서비스 이용약관" }
            AuthTermRow(
                title: "[필수] 개인정보 처리방침", isOn: $form.agreesToPrivacy
            ) { selectedTerm = "개인정보 처리방침" }
        }
        .toggleStyle(AuthAgreementStyle())
        .umcTypography(.title3Regular)
        .foregroundStyle(UMCColor.Semantic.textNeutralStrong800)
        .alert(selectedTerm ?? "", isPresented: Binding(
            get: { selectedTerm != nil }, set: { if !$0 { selectedTerm = nil } }
        )) {
            Button("확인", role: .cancel) { selectedTerm = nil }
        } message: {
            Text("약관 내용은 추후 연결될 예정이에요.")
        }
    }
}

private struct AuthAgreementStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            HStack(spacing: UMCSpacing.value4) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(configuration.isOn ?
                        UMCColor.Semantic.textBrandDefault :
                        UMCColor.Semantic.borderNeutralMedium300)
                    .frame(width: 32, height: 32)
                configuration.label
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityRepresentation {
            Toggle(isOn: configuration.$isOn) { configuration.label }
                .toggleStyle(.checkbox)
        }
    }
}

private struct AuthTermRow: View {
    let title: String
    @Binding var isOn: Bool
    let showTerm: () -> Void

    var body: some View {
        HStack(spacing: UMCSpacing.value4) {
            Toggle(title, isOn: $isOn)
            Button(action: showTerm) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(UMCColor.Semantic.iconNeutralWeak400)
                    .frame(width: 24, height: 32)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("\(title) 내용 보기")
            Spacer(minLength: 0)
        }
        .frame(minHeight: 32)
    }
}
