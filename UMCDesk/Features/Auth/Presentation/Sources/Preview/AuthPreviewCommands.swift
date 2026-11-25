//
//  AuthPreviewCommands.swift
//  AuthPresentation
//
//  Created by euijjang97 on 10/20/26.
//

#if DEBUG || UMC_PRERELEASE
import SwiftUI
import UMCFoundation

/// Owns the mock model shared by the View menu and the dedicated preview window.
@MainActor
@Observable
public final class AuthPreviewSession {
    public static let windowID = "auth-preview"

    fileprivate var viewModel = AuthViewModel()

    public init() {}

    public var content: some View {
        AuthView(viewModel: viewModel)
            .id(ObjectIdentifier(viewModel))
    }
}

public struct AuthPreviewCommands: Commands {
    @Environment(\.openWindow) private var openWindow
    private let session: AuthPreviewSession

    public init(session: AuthPreviewSession) {
        self.session = session
    }

    public var body: some Commands {
        CommandGroup(after: .sidebar) {
            AuthPreviewFlowMenu(viewModel: session.viewModel, showWindow: showWindow)
            AuthPreviewMenu { preview in
                session.viewModel = preview.makeViewModel()
                showWindow()
            }
        }
    }

    private func showWindow() {
        openWindow(id: AuthPreviewSession.windowID)
    }
}
#endif
