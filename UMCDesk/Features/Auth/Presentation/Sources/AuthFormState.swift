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
    enum EmailVerification {
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

    func navigate(to screen: AuthScreen) {
        self.screen = screen
        quoteOverride = nil
        authorOverride = nil
        form = AuthFormState()
        downloadProgress = 0
    }
}
