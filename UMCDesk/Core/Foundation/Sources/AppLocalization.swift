//
//  AppLocalization.swift
//  UMCFoundation
//
//  Created by euijjang97 on 10/24/26.
//

import Foundation
import Observation
import os

public enum AppLanguage: String, CaseIterable, Identifiable, Sendable {
    case korean = "ko"
    case english = "en"

    public var id: String { rawValue }
    public var locale: Locale { Locale(identifier: rawValue) }
}

/// Resolves app-owned copy without changing server or user-provided text.
@Observable
public final class AppLocalization: Sendable {
    public static let shared = AppLocalization()

    @ObservationIgnored private let storage = OSAllocatedUnfairLock(initialState: AppLanguage.korean)

    public var language: AppLanguage {
        get {
            access(keyPath: \.language)
            return storage.withLock { $0 }
        }
        set {
            withMutation(keyPath: \.language) {
                storage.withLock { $0 = newValue }
            }
        }
    }

    private init() { }

    public static func string(
        _ value: String.LocalizationValue,
        language: AppLanguage? = nil
    ) -> String {
        let language = language ?? shared.language
        let bundle = Bundle.module.path(forResource: language.rawValue, ofType: "lproj")
            .flatMap(Bundle.init(path:)) ?? Bundle.module
        return String(localized: value, bundle: bundle, locale: language.locale)
    }
}
