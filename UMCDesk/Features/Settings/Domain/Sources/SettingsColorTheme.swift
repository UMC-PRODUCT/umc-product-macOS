//
//  SettingsColorTheme.swift
//  SettingsDomain
//
//  Created by euijjang97 on 10/24/26.
//

import Foundation

public struct SettingsThemeColor: Codable, Equatable, Sendable {
    public let red: Double
    public let green: Double
    public let blue: Double

    public init(red: Double, green: Double, blue: Double) {
        self.red = red.isFinite ? min(1, max(0, red)) : 0
        self.green = green.isFinite ? min(1, max(0, green)) : 0
        self.blue = blue.isFinite ? min(1, max(0, blue)) : 0
    }

    public init(hex: UInt32) {
        self.init(red: Double((hex >> 16) & 255) / 255,
            green: Double((hex >> 8) & 255) / 255, blue: Double(hex & 255) / 255)
    }

    public var luminance: Double {
        func linear(_ value: Double) -> Double {
            value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }

    public func contrast(with other: Self) -> Double {
        (max(luminance, other.luminance) + 0.05) / (min(luminance, other.luminance) + 0.05)
    }

    private enum CodingKeys: CodingKey { case red, green, blue }

    public init(from decoder: any Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let red = try values.decode(Double.self, forKey: .red)
        let green = try values.decode(Double.self, forKey: .green)
        let blue = try values.decode(Double.self, forKey: .blue)
        guard [red, green, blue].allSatisfy({ $0.isFinite && (0...1).contains($0) }) else {
            throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                debugDescription: "Theme color components must be in 0...1"))
        }
        self.init(red: red, green: green, blue: blue)
    }
}

public struct SettingsThemePalette: Codable, Equatable, Sendable {
    public var background: SettingsThemeColor
    public var foreground: SettingsThemeColor

    public init(background: SettingsThemeColor, foreground: SettingsThemeColor) {
        self.background = background
        self.foreground = foreground
    }

    public var contrast: Double { background.contrast(with: foreground) }

    public var readableForeground: SettingsThemeColor {
        let black = SettingsThemeColor(hex: 0x000000)
        let white = SettingsThemeColor(hex: 0xFFFFFF)
        return background.contrast(with: black) >= background.contrast(with: white) ? black : white
    }
}

public struct SettingsThemeColors: Codable, Equatable, Sendable {
    public var sidebar: SettingsThemePalette
    public var content: SettingsThemePalette

    public init(sidebar: SettingsThemePalette, content: SettingsThemePalette) {
        self.sidebar = sidebar
        self.content = content
    }
}

public struct SettingsColorTheme: Codable, Equatable, Identifiable, Sendable {
    public let id: String
    public var name: String
    public var light: SettingsThemeColors?
    public var dark: SettingsThemeColors?

    public init(
        id: String, name: String, light: SettingsThemeColors?, dark: SettingsThemeColors?
    ) {
        self.id = id
        self.name = name
        self.light = light
        self.dark = dark
    }

    public static let standard = Self(id: "umc", name: "UMC", light: nil, dark: nil)
    public static let presets: [Self] = [
        standard,
        preset("graphite", "Graphite", light: (0xECEDEF, 0xF8F9FA, 0x24262A),
            dark: (0x202124, 0x292A2E, 0xECEEF2)),
        preset("midnight", "Midnight", light: (0xE7EDF8, 0xF5F8FF, 0x233149),
            dark: (0x111827, 0x1A2538, 0xE1EAFB)),
        preset("paper", "Paper", light: (0xEAE4D8, 0xFAF6ED, 0x473B2D),
            dark: (0x27231D, 0x332D25, 0xF0E4CF)),
        preset("ocean", "Ocean", light: (0xDEF0EF, 0xF1FAF8, 0x1C4649),
            dark: (0x102A30, 0x18383E, 0xDBF4EF)),
    ]

    private static func preset(
        _ id: String, _ name: String,
        light: (UInt32, UInt32, UInt32), dark: (UInt32, UInt32, UInt32)
    ) -> Self {
        func colors(_ values: (UInt32, UInt32, UInt32)) -> SettingsThemeColors {
            .init(sidebar: .init(background: .init(hex: values.0),
                foreground: .init(hex: values.2)),
                content: .init(background: .init(hex: values.1),
                    foreground: .init(hex: values.2)))
        }
        return .init(id: id, name: name, light: colors(light), dark: colors(dark))
    }
}
