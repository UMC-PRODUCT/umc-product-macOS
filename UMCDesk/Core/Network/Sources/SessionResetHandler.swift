//
//  SessionResetHandler.swift
//  CoreNetwork
//
//  Created by euijjang97 on 10/6/26.
//

/// Bridges transport cleanup to the app's MainActor session state.
public struct SessionResetHandler: SessionResetting {
    private let action: @MainActor @Sendable () async -> Void

    public init(action: @escaping @MainActor @Sendable () async -> Void) {
        self.action = action
    }

    public func resetSession() async {
        await action()
    }
}
