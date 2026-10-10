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
