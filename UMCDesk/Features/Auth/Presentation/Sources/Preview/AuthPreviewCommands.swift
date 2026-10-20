//
//  AuthPreviewCommands.swift
//  AuthPresentation
//
//  Created by euijjang97 on 10/20/26.
//

#if DEBUG || UMC_PRERELEASE
import SwiftUI

struct AuthPreviewModelKey: FocusedValueKey {
    typealias Value = Binding<AuthViewModel>
}

extension FocusedValues {
    var authPreviewModel: Binding<AuthViewModel>? {
        get { self[AuthPreviewModelKey.self] }
        set { self[AuthPreviewModelKey.self] = newValue }
    }
}

public struct AuthPreviewCommands: Commands {
    @FocusedBinding(\.authPreviewModel) private var viewModel

    public init() {}

    public var body: some Commands {
        CommandGroup(after: .sidebar) {
            if let binding = Binding($viewModel) {
                AuthPreviewFlowMenu(viewModel: binding.wrappedValue)
                AuthPreviewMenu(viewModel: binding)
            } else {
                Menu("흐름 미리보기") {}.disabled(true)
                Menu("디자인 미리보기") {}.disabled(true)
            }
        }
    }
}
#endif
