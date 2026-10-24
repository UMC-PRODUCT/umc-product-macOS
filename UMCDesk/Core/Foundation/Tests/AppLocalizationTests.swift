//
//  AppLocalizationTests.swift
//  UMCFoundationTests
//
//  Created by euijjang97 on 10/24/26.
//

import Foundation
import Observation
import os
import Testing
@testable import UMCFoundation

@Suite(.serialized)
struct AppLocalizationTests {
    @Test("Explicit app language overrides the system bundle language")
    func resolvesSelectedLanguage() {
        #expect(AppLocalization.string("로그인", language: .korean) == "로그인")
        #expect(AppLocalization.string("로그인", language: .english) == "Sign In")
    }

    @Test("Localized interpolation preserves user-provided values")
    func interpolatesWithoutTranslatingData() {
        let field = "사용자 닉네임"
        #expect(AppLocalization.string("\(field) 지우기", language: .english)
            == "Clear 사용자 닉네임")
        let status = 503
        #expect(AppLocalization.string("요청 실패 status: \(status)", language: .english)
            == "Request failed with status: 503")
    }

    @Test("Changing language invalidates observers and resolves immediately")
    func switchesImmediately() {
        let original = AppLocalization.shared.language
        defer { AppLocalization.shared.language = original }
        AppLocalization.shared.language = .korean
        let changed = OSAllocatedUnfairLock(initialState: false)
        withObservationTracking {
            _ = AppLocalization.string("로그인")
        } onChange: {
            changed.withLock { $0 = true }
        }
        AppLocalization.shared.language = .english
        #expect(changed.withLock { $0 })
        #expect(AppLocalization.string("로그인") == "Sign In")
        AppLocalization.shared.language = .korean
        #expect(AppLocalization.string("로그인") == "로그인")
    }
}
