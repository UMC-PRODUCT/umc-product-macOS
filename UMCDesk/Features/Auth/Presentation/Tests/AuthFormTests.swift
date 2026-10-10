//
//  AuthFormTests.swift
//  AuthPresentationTests
//
//  Created by euijjang97 on 10/10/26.
//

import Testing
@testable import AuthPresentation

@MainActor
struct AuthFormTests {
    @Test("Moving between authentication screens preserves entered form data")
    func navigationPreservesInput() {
        let viewModel = AuthViewModel()
        viewModel.form.email = "member@example.com"
        viewModel.form.name = "김유엠"
        viewModel.navigate(to: .passwordReset)
        viewModel.navigate(to: .emailLogin)
        #expect(viewModel.form.email == "member@example.com")
        #expect(viewModel.form.name == "김유엠")
    }

    @Test("A different form keeps identity but starts a new email verification")
    func formVerificationIsScoped() {
        let viewModel = AuthViewModel()
        viewModel.navigate(to: .signup)
        viewModel.form.email = "member@example.com"
        viewModel.form.emailVerification = .verified
        viewModel.form.password = "oldPassword1!"
        viewModel.navigate(to: .passwordReset)
        #expect(viewModel.form.email == "member@example.com")
        #expect(viewModel.form.emailVerification == .idle)
        #expect(viewModel.form.password.isEmpty)
    }

    @Test("Cancel returns from account confirmation without clearing entered data")
    func accountCancellationRestoresScreen() {
        for screen in [AuthScreen.signup, .passwordReset, .challengerCode] {
            for confirmation in [AuthScreen.logoutConfirmation, .withdrawalConfirmation] {
                let viewModel = AuthViewModel()
                viewModel.navigate(to: screen)
                viewModel.form.challengerCode = "UMC123"
                viewModel.form.emailVerification = .verified
                viewModel.form.password = "password1!"
                viewModel.navigate(to: confirmation)
                viewModel.cancelAccountAction()
                #expect(viewModel.screen == screen)
                #expect(viewModel.form.challengerCode == "UMC123")
                #expect(viewModel.form.emailVerification == .verified)
                #expect(viewModel.form.password == "password1!")
            }
        }
    }

    #if DEBUG
    @Test("Social login preview continues through session and member checks")
    func loginPreviewCompletesWaitingScreens() {
        let viewModel = AuthViewModel()
        viewModel.navigate(to: .socialLogin)
        for _ in 0..<3 {
            viewModel.advancePreviewFlow(for: viewModel.navigationID)
        }
        #expect(viewModel.screen == .challengerIntro)
        #expect(!viewModel.hasPendingPreviewStep)
    }

    @Test("A simulated failure is consumed so retry can recover")
    func previewRetryRecovers() {
        let viewModel = AuthViewModel()
        viewModel.form.email = "member@example.com"
        viewModel.previewScenario = .memberFailure
        viewModel.navigate(to: .memberChecking)
        viewModel.advancePreviewFlow(for: viewModel.navigationID)
        #expect(viewModel.screen == .memberFailure)
        viewModel.navigate(to: .memberChecking)
        viewModel.advancePreviewFlow(for: viewModel.navigationID)
        #expect(viewModel.screen == .challengerIntro)
        #expect(viewModel.form.email == "member@example.com")
    }

    @Test("Update preview completes download, verification and installation")
    func updatePreviewCompletes() {
        let viewModel = AuthViewModel()
        viewModel.navigate(to: .updateDownloading)
        for _ in 0..<20 {
            viewModel.advancePreviewFlow(for: viewModel.navigationID)
        }
        #expect(viewModel.downloadProgress == 1)
        #expect(viewModel.screen == .updateVerifying)
        viewModel.advancePreviewFlow(for: viewModel.navigationID)
        #expect(viewModel.screen == .updateReady)
        #expect(!viewModel.hasPendingPreviewStep)
        viewModel.navigate(to: .updateInstalling)
        viewModel.advancePreviewFlow(for: viewModel.navigationID)
        #expect(viewModel.screen == .updateComplete)
    }

    @Test("Cancelled preview work cannot move the new screen or restart a download")
    func cancelledPreviewCannotNavigate() {
        let viewModel = AuthViewModel()
        viewModel.navigate(to: .updateDownloading)
        let cancelledNavigation = viewModel.navigationID
        viewModel.navigate(to: .updateAvailable)
        viewModel.advancePreviewFlow(for: cancelledNavigation)
        #expect(viewModel.screen == .updateAvailable)
        #expect(viewModel.downloadProgress == 0)
    }

    @Test("All design screens are reachable while gallery snapshots stay still")
    func galleryCoversEveryScreen() {
        #expect(Set(AuthDesignPreview.all.map(\.screen)) == Set(AuthScreen.allCases))
        for preview in AuthDesignPreview.all {
            #expect(!preview.makeViewModel().playsPreviewFlow)
        }
    }
    #endif

    @Test("Email requires nonempty domain labels before requesting verification")
    func emailRequiresValidDomain() {
        let form = AuthFormState()
        for email in ["member@.", "member@example.", "member@.com", "member@@example.com"] {
            form.email = email
            #expect(!form.canRequestCode)
        }
        form.email = "member@example.com"
        #expect(form.canRequestCode)
    }

    @Test("Changing an email clears its displayed verification state")
    func changingEmailClearsVerification() {
        let form = AuthFormState()
        form.email = "member@example.com"
        form.emailVerification = .verified
        form.verificationCode = "123456"
        form.email = "other@example.com"
        #expect(form.emailVerification == .idle)
        #expect(form.verificationCode.isEmpty)
    }

    @Test("Registration requires both agreements and matching password requirements")
    func registrationRequirements() {
        let form = AuthFormState()
        form.name = "김유엠"
        form.nickname = "유엠"
        form.email = "member@example.com"
        form.emailVerification = .verified
        form.school = "가천대학교"
        form.password = "password1!"
        form.passwordConfirmation = "password1!"
        #expect(!form.canRegister)
        form.agreesToService = true
        form.agreesToPrivacy = true
        #expect(form.canRegister)
        form.passwordConfirmation = "different1!"
        #expect(!form.canRegister)
    }

    @Test("Whitespace-only identity fields cannot enable registration")
    func whitespaceIdentityIsRejected() {
        let form = AuthFormState()
        form.name = "   "
        form.nickname = "유엠"
        form.email = "member@example.com"
        form.emailVerification = .verified
        form.school = "가천대학교"
        form.password = "password1!"
        form.passwordConfirmation = "password1!"
        form.agreesToService = true
        form.agreesToPrivacy = true
        #expect(!form.canRegister)
    }

    @Test("Password input needs eight characters including a number and special character")
    func passwordRequirements() {
        let form = AuthFormState()
        for password in ["short1!", "password!", "password1", "password "] {
            form.password = password
            form.passwordConfirmation = password
            #expect(!form.passwordsMatchRequirements)
        }
        form.password = "password1!"
        form.passwordConfirmation = "password1!"
        #expect(form.passwordsMatchRequirements)
    }
}
