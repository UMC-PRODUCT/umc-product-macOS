//
//  DIContainer.swift
//  CoreDI
//
//  Created by euijjang97 on 10/6/26.
//

import Foundation
import Observation

/// Protocol-based dependency registration with explicit app lifetime instances.
@MainActor
@Observable
public final class DIContainer {
    @ObservationIgnored private var factories: [ObjectIdentifier: () -> Any] = [:]
    @ObservationIgnored private var cachedInstances: [ObjectIdentifier: Any] = [:]
    @ObservationIgnored private var sharedInstances: [ObjectIdentifier: Any] = [:]

    public init() {}

    public func register<Value>(_ type: Value.Type, factory: @escaping () -> Value) {
        let key = ObjectIdentifier(type)
        sharedInstances[key] = nil
        cachedInstances[key] = nil
        factories[key] = factory
    }

    public func registerInstance<Value>(_ type: Value.Type, instance: Value) {
        let key = ObjectIdentifier(type)
        factories[key] = nil
        cachedInstances[key] = nil
        sharedInstances[key] = instance
    }

    public func resolve<Value>(_ type: Value.Type) -> Value {
        let key = ObjectIdentifier(type)
        if let instance = sharedInstances[key] as? Value { return instance }
        if let instance = cachedInstances[key] as? Value { return instance }
        guard let factory = factories[key], let instance = factory() as? Value else {
            preconditionFailure("Unregistered dependency: \(type)")
        }
        cachedInstances[key] = instance
        return instance
    }

    /// Resets session-scoped services while retaining shared transport instances.
    public func resetCache() {
        cachedInstances.removeAll()
    }
}
