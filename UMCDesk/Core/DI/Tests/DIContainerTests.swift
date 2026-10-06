//
//  DIContainerTests.swift
//  CoreDITests
//
//  Created by euijjang97 on 10/6/26.
//

import Testing
@testable import CoreDI

@Suite("DIContainer")
@MainActor
struct DIContainerTests {
    private final class Service {}

    @Test("Shared instances survive reset")
    func sharedInstancesSurviveReset() {
        let container = DIContainer()
        let service = Service()
        container.registerInstance(Service.self, instance: service)
        container.resetCache()
        #expect(container.resolve(Service.self) === service)
    }

    @Test("Session-scoped factory instances are recreated after reset")
    func sessionInstancesAreRecreated() {
        let container = DIContainer()
        container.register(Service.self) { Service() }
        let previous = container.resolve(Service.self)
        #expect(container.resolve(Service.self) === previous)
        container.resetCache()
        #expect(container.resolve(Service.self) !== previous)
    }
}
