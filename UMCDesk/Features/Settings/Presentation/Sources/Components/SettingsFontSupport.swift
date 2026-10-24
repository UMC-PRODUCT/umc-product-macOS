//
//  SettingsFontSupport.swift
//  SettingsPresentation
//
//  Created by euijjang97 on 10/24/26.
//

import CoreText
import Foundation
import SettingsDomain
import UMCFoundation
import os

enum SettingsFontSupport {
    private static let coverage = OSAllocatedUnfairLock(
        initialState: [AppLanguage: [String: Bool]]())

    static func families(for language: AppLanguage) -> [String] {
        (CTFontManagerCopyAvailableFontFamilyNames() as? [String] ?? [])
            .filter { supports($0, language: language) }
            .sorted { $0.localizedStandardCompare($1) == .orderedAscending }
    }

    static func supports(_ family: String, language: AppLanguage) -> Bool {
        if let cached = coverage.withLock({ $0[language]?[family] }) { return cached }
        let supported = checkCoverage(family, language: language)
        coverage.withLock { $0[language, default: [:]][family] = supported }
        return supported
    }

    private static func checkCoverage(_ family: String, language: AppLanguage) -> Bool {
        let descriptor = CTFontDescriptorCreateWithAttributes(
            [kCTFontFamilyNameAttribute: family] as CFDictionary)
        let face = CTFontCreateWithFontDescriptor(descriptor, 14, nil)
        guard CTFontCopyFamilyName(face) as String == family else { return false }
        let traits = CTFontGetSymbolicTraits(face)
        // Some symbol families report no symbolic trait despite being intended for pictographs.
        let familyName = family.lowercased()
        guard !["symbol", "emoji", "dingbat"].contains(where: familyName.contains)
        else { return false }
        guard !traits.contains(.traitColorGlyphs),
              traits.rawValue & CTFontSymbolicTraits.traitClassMask.rawValue !=
                CTFontStylisticClass.symbolicClass.rawValue else { return false }
        var required = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789 .,!?-()"
            .utf16)
        if language == .korean {
            // Every modern Hangul syllable must map on this face, without font fallback.
            required.append(contentsOf: 0xAC00...0xD7A3)
        }
        var glyphs = Array(repeating: CGGlyph(), count: required.count)
        return CTFontGetGlyphsForCharacters(face, required, &glyphs, required.count)
            && glyphs.allSatisfy { $0 != 0 }
    }
}

@MainActor
public extension SettingsPreferences {
    var availableFontFamily: String? {
        guard let fontFamily, SettingsFontSupport.supports(fontFamily, language: language)
        else { return nil }
        return fontFamily
    }

    func restoreSupportedFont() {
        guard fontFamily != nil, availableFontFamily == nil else { return }
        fontFamily = nil
        font = .pretendard
    }
}
