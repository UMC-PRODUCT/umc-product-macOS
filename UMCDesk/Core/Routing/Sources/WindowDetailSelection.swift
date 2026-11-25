//
//  WindowDetailSelection.swift
//  CoreRouting
//
//  Created by euijjang97 on 11/25/26.
//

import SwiftUI

/// A feature keeps its own route type while the window stores visits across modules.
public struct WindowDetail: Equatable, Sendable {
    private let value: any Equatable & Sendable
    private let matches: @Sendable (any Equatable) -> Bool

    public init<Value: Equatable & Sendable>(_ value: Value) {
        self.value = value
        matches = { ($0 as? Value) == value }
    }

    public func route<Value>(as type: Value.Type) -> Value? { value as? Value }

    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.matches(rhs.value) }
}

public extension EnvironmentValues {
    @Entry var windowDetail: Binding<WindowDetail?>?
}

/// Standalone feature windows keep their local selection when no shell hosts them.
@propertyWrapper
public struct WindowDetailSelection<Value: Equatable & Sendable>: DynamicProperty {
    @Environment(\.windowDetail) private var window
    @State private var local: Value?

    public init() {}

    public var wrappedValue: Value? {
        get {
            guard let window else { return local }
            return window.wrappedValue?.route(as: Value.self)
        }
        nonmutating set {
            if let window { window.wrappedValue = newValue.map(WindowDetail.init) }
            else { local = newValue }
        }
    }

    public var projectedValue: Binding<Value?> {
        guard let window else { return $local }
        return Binding(
            get: { window.wrappedValue?.route(as: Value.self) },
            set: { window.wrappedValue = $0.map(WindowDetail.init) }
        )
    }
}
