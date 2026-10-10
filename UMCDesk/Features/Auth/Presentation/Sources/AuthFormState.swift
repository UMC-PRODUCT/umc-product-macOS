//
//  AuthFormState.swift
//  AuthPresentation
//
//  Created by euijjang97 on 10/10/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class AuthFormState {
    enum EmailVerification: Equatable {
        case idle, sent, invalid, verified
    }

    var name = ""
    var nickname = ""
    var email = "" {
        didSet {
            if email != oldValue {
                emailVerification = .idle
                verificationCode = ""
            }
        }
    }
    var emailVerification: EmailVerification = .idle
    var verificationCode = ""
    var school = ""
    var password = ""
    var passwordConfirmation = ""
    var challengerCode = ""
    var agreesToService = false
    var agreesToPrivacy = false
    var showsPassword = false
    var showsPasswordConfirmation = false
    var showsSchoolPicker = false
    var showsPasswordError = false
    var initialFocus: AuthField?

    var canRequestCode: Bool {
        email.wholeMatch(of: /[^\s@]+@[^\s@.]+(?:\.[^\s@.]+)+/) != nil
    }

    var passwordsMatchRequirements: Bool {
        password.count >= 8 && password == passwordConfirmation
            && password.contains(where: \.isNumber)
            && password.unicodeScalars.contains {
                CharacterSet.punctuationCharacters.contains($0)
                    || CharacterSet.symbols.contains($0)
            }
    }

    var canRegister: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && canRequestCode && emailVerification == .verified && !school.isEmpty
            && passwordsMatchRequirements && agreesToService && agreesToPrivacy
    }

    var canResetPassword: Bool {
        canRequestCode && emailVerification == .verified && passwordsMatchRequirements
    }
}

enum AuthField: Hashable {
    case name, nickname, email, verificationCode, password, passwordConfirmation, challengerCode
}

@MainActor
@Observable
final class AuthViewModel {
    var screen: AuthScreen = .loginSelection
    var form = AuthFormState()
    var socialProvider = "카카오"
    var downloadProgress = 0.0
    var quoteOverride: String?
    var authorOverride: String?
    private(set) var navigationID = UUID()
    private var accountReturnScreen: AuthScreen = .challengerIntro

    #if DEBUG
    var playsPreviewFlow = true
    var previewScenario: AuthPreviewScenario = .success
    #endif

    func navigate(to screen: AuthScreen, resetsForm: Bool = false) {
        if screen == .logoutConfirmation || screen == .withdrawalConfirmation {
            accountReturnScreen = self.screen
        }
        let isReturningFromAccountConfirmation = self.screen == .logoutConfirmation
            || self.screen == .withdrawalConfirmation
        if self.screen != screen && !isReturningFromAccountConfirmation
            && (screen == .signup || screen == .passwordReset) {
            form.emailVerification = .idle
            form.verificationCode = ""
            form.password = ""
            form.passwordConfirmation = ""
            form.showsPasswordError = false
        }
        self.screen = screen
        quoteOverride = nil
        authorOverride = nil
        navigationID = UUID()
        if resetsForm { form = AuthFormState() }
        if screen == .updateDownloading { downloadProgress = 0 }
        #if DEBUG
        playsPreviewFlow = true
        #endif
    }

    func cancelAccountAction() {
        navigate(to: accountReturnScreen)
    }

    func submitLogin() {
        #if DEBUG
        if previewScenario == .credentialsError {
            previewScenario = .success
            navigate(to: .credentialsError)
            return
        }
        #endif
        navigate(to: .sessionChecking)
    }

    func completeRegistration() {
        #if DEBUG
        if previewScenario == .signupLoginFailure {
            previewScenario = .success
            navigate(to: .signupLoginFailure)
            return
        }
        #endif
        navigate(to: .signupComplete)
    }
}
