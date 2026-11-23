//
//  AuthFormState.swift
//  AuthPresentation
//
//  Created by euijjang97 on 10/10/26.
//

import AuthDomain
import UMCFoundation
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
                verificationSession = nil
                verificationToken = nil
                emailVerification = .idle
                verificationCode = ""
                showsEmailError = false
            }
        }
    }
    var emailVerification: EmailVerification = .idle
    var verificationCode = ""
    var verificationSession: String?
    var verificationToken: String?
    var schoolID = ""
    var schools: [RegistrationSchool] = []
    var terms: [RegistrationTerm] = []
    var acceptedTerms: Set<String> = []
    var usesServerTerms = false
    var hasRequiredAgreements: Bool {
        if usesServerTerms {
            return !terms.isEmpty && terms.allSatisfy { !$0.isMandatory || acceptedTerms.contains($0.id) }
        }
        return agreesToService && agreesToPrivacy
    }
    var school = ""
    var password = ""
    var passwordConfirmation = ""
    var challengerCode = ""
    var agreesToService = false
    var agreesToPrivacy = false
    var showsPassword = false
    var showsPasswordConfirmation = false
    var showsSchoolPicker = false
    var showsEmailError = false
    var showsPasswordError = false
    var initialFocus: AuthField?

    var canRequestCode: Bool {
        email.wholeMatch(of: /[^\s@]+@[^\s@.]+(?:\.[^\s@.]+)+/) != nil
    }

    var canSubmitEmailVerification: Bool {
        !email.isEmpty && emailVerification != .verified
    }

    @discardableResult
    func requestVerificationCode() -> Bool {
        guard canSubmitEmailVerification else { return false }
        guard canRequestCode else {
            showsEmailError = true
            return false
        }
        showsEmailError = false
        verificationCode = ""
        emailVerification = .sent
        return true
    }

    var passwordsMatchRequirements: Bool {
        guard (8...64).contains(password.utf16.count), password == passwordConfirmation,
              !password.unicodeScalars.contains(where: {
                  CharacterSet.whitespacesAndNewlines.union(.controlCharacters).contains($0)
              }) else { return false }
        let characters = password.unicodeScalars
        let groups = [CharacterSet.letters, .decimalDigits,
                      CharacterSet.letters.union(.decimalDigits).inverted]
        return groups.filter { group in characters.contains(where: group.contains) }.count >= 2
    }

    var canRegister: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && canRequestCode && emailVerification == .verified && !school.isEmpty
            && name.utf16.count <= 5 && passwordsMatchRequirements && hasRequiredAgreements
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
    var login: (@MainActor (String, String) async throws -> Void)?
    var repository: (any AuthFlowRepository)?
    var entry: AuthEntry = .login
    var onSignOut: (@MainActor () async throws -> Void)?
    var onMemberRefresh: (@MainActor () async throws -> Void)?
    var notice: String?
    var isWorking = false
    var hasCheckedStatus = false
    var linkedCode = false
    var withdrew = false
    private(set) var isSigningIn = false
    private var loginTask: Task<Void, Never>?

    var screen: AuthScreen = .loginSelection
    var form = AuthFormState()
    var socialProvider = "Kakao"
    var downloadProgress = 0.0
    var quoteOverride: String.LocalizationValue?
    var authorOverride: String.LocalizationValue?
    private(set) var navigationID = UUID()
    private var accountReturnScreen: AuthScreen = .challengerIntro

    #if DEBUG || UMC_PRERELEASE
    var playsPreviewFlow = true
    var previewScenario: AuthPreviewScenario = .success
    #endif

    func navigate(to screen: AuthScreen, resetsForm: Bool = false) {
        if screen == .logoutConfirmation || screen == .withdrawalConfirmation {
            accountReturnScreen = self.screen
        }
        let isReturningFromAccountConfirmation = self.screen == .logoutConfirmation
            || self.screen == .withdrawalConfirmation
        let verificationScreens: Set<AuthScreen> = [.signup, .passwordReset]
        let enteringVerification = verificationScreens.contains(screen)
            && !isReturningFromAccountConfirmation
        let leavingVerification = verificationScreens.contains(self.screen)
            && screen != .logoutConfirmation && screen != .withdrawalConfirmation
        if self.screen != screen && (enteringVerification || leavingVerification) {
            form.verificationSession = nil
            form.verificationToken = nil
            form.emailVerification = .idle
            form.verificationCode = ""
            form.password = ""
            form.passwordConfirmation = ""
            form.showsPasswordError = false
            form.showsEmailError = false
            form.acceptedTerms.removeAll()
        }
        self.screen = screen
        quoteOverride = nil
        authorOverride = nil
        navigationID = UUID()
        if resetsForm {
            form = AuthFormState()
            form.usesServerTerms = repository != nil
        }
        if screen == .updateDownloading { downloadProgress = 0 }
        #if DEBUG || UMC_PRERELEASE
        playsPreviewFlow = true
        #endif
    }

    func cancelAccountAction() {
        if withdrew {
            confirmAccountAction()
            return
        }
        navigate(to: accountReturnScreen)
    }

    func cancelLogin() {
        loginTask?.cancel()
    }

    func submitLogin() {
        if let login {
            guard !isSigningIn, form.canRequestCode, !form.password.isEmpty else { return }
            isSigningIn = true
            let email = form.email
            let password = form.password
            loginTask = Task {
                defer { isSigningIn = false; loginTask = nil }
                do {
                    try await login(email, password)
                    form.password = ""
                } catch is CancellationError {
                    return
                } catch EmailLoginError.invalidCredentials {
                    navigate(to: .credentialsError)
                } catch {
                    navigate(to: .loginFailure)
                }
            }
            return
        }
        #if DEBUG || UMC_PRERELEASE
        if previewScenario == .credentialsError {
            previewScenario = .success
            navigate(to: .credentialsError)
            return
        }
        #endif
        navigate(to: .sessionChecking)
    }

    func completeRegistration() {
        if let repository {
            guard form.canRegister, let token = form.verificationToken else { return }
            let registration = EmailRegistration(
                name: form.name, nickname: form.nickname, password: form.password,
                verificationToken: token, schoolID: form.schoolID,
                agreements: Dictionary(uniqueKeysWithValues: form.terms.map {
                    ($0.id, form.acceptedTerms.contains($0.id))
                })
            )
            perform {
                do {
                    try await repository.register(registration)
                } catch AuthFlowError.registrationSessionUnavailable {
                    self.navigate(to: .signupLoginFailure, resetsForm: true)
                    return
                }
                self.form = AuthFormState()
                self.navigate(to: .signupComplete)
                try await self.onMemberRefresh?()
            }
            return
        }
        guard login == nil else { return }
        #if DEBUG || UMC_PRERELEASE
        if previewScenario == .signupLoginFailure {
            previewScenario = .success
            navigate(to: .signupLoginFailure)
            return
        }
        #endif
        navigate(to: .signupComplete)
    }
}

extension AuthViewModel {
    func perform(_ operation: @escaping @MainActor () async throws -> Void) {
        guard !isWorking else { return }
        isWorking = true
        Task {
            defer { isWorking = false }
            do {
                try await operation()
            } catch is CancellationError {
                return
            } catch AuthFlowError.verificationExpired {
                form.verificationSession = nil
                form.verificationToken = nil
                form.verificationCode = ""
                form.emailVerification = .idle
                notice = "이메일 인증 시간이 지났어요. 인증번호를 새로 받아 주세요."
            } catch {
                notice = error.localizedDescription
            }
        }
    }

    func checkStatus() {
        guard let repository else { return }
        perform {
            do {
                let maintenance = try await repository.isInMaintenance()
                self.hasCheckedStatus = true
                if maintenance {
                    self.navigate(to: .maintenance)
                } else if self.screen == .maintenance || self.screen == .offline {
                    self.navigate(to: self.entry.screen)
                }
            } catch {
                self.navigate(to: .offline)
            }
        }
    }

    func loadRegistrationOptions() async {
        guard let repository else { return }
        form.usesServerTerms = true
        do {
            async let schools = repository.schools()
            async let terms = repository.terms()
            let options = try await (schools, terms)
            try Task.checkCancellation()
            form.schools = options.0
            form.terms = options.1
            form.acceptedTerms.formIntersection(Set(options.1.map(\.id)))
        } catch {
            if !Task.isCancelled { notice = error.localizedDescription }
        }
    }

    func sendVerification() {
        guard form.canRequestCode else { form.showsEmailError = true; return }
        guard let repository else {
            if login == nil { form.requestVerificationCode() }
            return
        }
        let purpose: VerificationPurpose = screen == .signup ? .registration : .passwordReset
        perform {
            if let session = self.form.verificationSession {
                try await repository.resendCode(sessionID: session)
            } else {
                self.form.verificationSession = try await repository.sendCode(
                    email: self.form.email, purpose: purpose
                )
            }
            self.form.requestVerificationCode()
        }
    }

    func verifyCode() {
        let code = form.verificationCode
        guard code.wholeMatch(of: /[0-9]{6}/) != nil else { return }
        guard let repository else {
            #if DEBUG || UMC_PRERELEASE
            if login == nil { form.emailVerification = code == "123456" ? .verified : .invalid }
            #endif
            return
        }
        guard let session = form.verificationSession else { return }
        perform {
            do {
                self.form.verificationToken = try await repository.verifyCode(
                    sessionID: session, code: code
                )
                self.form.emailVerification = .verified
            } catch AuthFlowError.invalidVerificationCode {
                self.form.emailVerification = .invalid
            }
        }
    }

    func resetPassword() {
        guard form.canResetPassword else { form.showsPasswordError = true; return }
        guard let repository else {
            if login == nil { navigate(to: .passwordResetComplete) }
            return
        }
        guard let token = form.verificationToken else { return }
        perform {
            try await repository.resetPassword(token: token, password: self.form.password)
            self.navigate(to: .passwordResetComplete, resetsForm: true)
        }
    }

    func submitChallenger() {
        guard let repository else {
            if login == nil { navigate(to: .challengerChecking) }
            return
        }
        let code = form.challengerCode
        guard code.wholeMatch(of: /[A-Za-z0-9]{6}/) != nil else { return }
        perform {
            if !self.linkedCode {
                do {
                    try await repository.linkChallenger(code: code)
                    self.linkedCode = true
                } catch AuthFlowError.usedChallengerCode {
                    self.navigate(to: .challengerCodeError)
                    return
                }
            }
            guard let refresh = self.onMemberRefresh else {
                self.navigate(to: .memberFailure)
                return
            }
            do {
                try await refresh()
                self.navigate(to: .challengerComplete)
            } catch {
                self.navigate(to: .memberFailure)
                throw error
            }
        }
    }

    func confirmAccountAction() {
        guard let repository else {
            if login == nil { navigate(to: .loginSelection, resetsForm: true) }
            return
        }
        guard let onSignOut else {
            notice = "현재 창에서 계정 작업을 완료할 수 없어요."
            return
        }
        perform {
            if self.screen == .withdrawalConfirmation && !self.withdrew {
                try await repository.withdraw()
                self.withdrew = true
            }
            try await onSignOut()
        }
    }
}
