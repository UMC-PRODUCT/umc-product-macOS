//
//  AuthView.swift
//  AuthPresentation
//
//  Created by euijjang97 on 10/10/26.
//

import AuthDomain
import CoreDesignSystem
import SwiftUI
import UMCFoundation

public enum AuthEntry {
    case login, challenger, withdrawal

    var screen: AuthScreen {
        switch self {
        case .login: .loginSelection
        case .challenger: .challengerIntro
        case .withdrawal: .withdrawalConfirmation
        }
    }
}

public struct AuthView: View {
    // MARK: - Property

    @State private var viewModel: AuthViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - Init

    #if DEBUG || UMC_PRERELEASE
    public init() {
        _viewModel = State(initialValue: AuthViewModel())
    }

    #endif

    public init(login: @escaping @MainActor (String, String) async throws -> Void) {
        let model = AuthViewModel()
        model.login = login
        _viewModel = State(initialValue: model)
    }

    public init(
        login: @escaping @MainActor (String, String) async throws -> Void,
        repository: any AuthFlowRepository, entry: AuthEntry = .login,
        onSignOut: (@MainActor () async throws -> Void)? = nil,
        onMemberRefresh: (@MainActor () async throws -> Void)? = nil,
        onCloseAccount: (() -> Void)? = nil
    ) {
        let model = AuthViewModel()
        model.login = login
        model.repository = repository
        model.entry = entry
        model.navigate(to: entry.screen)
        model.onCloseAccount = onCloseAccount
        model.onSignOut = onSignOut
        model.onMemberRefresh = onMemberRefresh
        model.form.usesServerTerms = true
        _viewModel = State(initialValue: model)
    }

    init(viewModel: AuthViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    public var body: some View {
        AuthPageLayout(
            screen: viewModel.screen,
            quote: viewModel.quoteOverride.map { AppLocalization.string($0) }
                ?? viewModel.screen.copy.quote,
            author: viewModel.authorOverride.map { AppLocalization.string($0) }
                ?? viewModel.screen.copy.author
        ) {
            ZStack {
                AuthPageContent(screen: viewModel.screen, viewModel: viewModel)
                    .id(viewModel.navigationID)
                    .transition(AuthMotion.pageTransition(reduceMotion: reduceMotion))
            }
            .animation(AuthMotion.animation(reduceMotion: reduceMotion),
                value: viewModel.navigationID)
        }
        .disabled(viewModel.isSigningIn || viewModel.isWorking)
        .overlay { if viewModel.isSigningIn || viewModel.isWorking { ProgressView() } }
        .task {
            if viewModel.entry == .login && !viewModel.hasCheckedStatus { viewModel.checkStatus() }
        }
        .alert("안내", isPresented: Binding(
            get: { viewModel.notice != nil }, set: { if !$0 { viewModel.notice = nil } }
        )) { Button("확인", role: .cancel) {} } message: { Text(viewModel.notice ?? "") }
        .onDisappear { viewModel.cancelLogin() }
        #if DEBUG || UMC_PRERELEASE
        .task(id: viewModel.navigationID) { await viewModel.runPreviewFlow() }
        .onAppear {
            guard viewModel.login != nil else { return }
            let arguments = ProcessInfo.processInfo.arguments
            if let index = arguments.firstIndex(of: "--auth-preview"),
               arguments.indices.contains(index + 1),
               let preview = AuthDesignPreview.all.first(where: {
                   $0.id == arguments[index + 1]
               }) {
                viewModel = preview.makeViewModel()
            }
        }
        #endif
    }
}

private enum AuthLayoutMetrics {
    static let sidebarWidth: CGFloat = 576
    static let sidebarFraction: CGFloat = 0.4
    static let referenceViewportWidth: CGFloat = 864
}

struct AuthPageLayout<Content: View>: View {
    let screen: AuthScreen
    let quote: String
    let author: String
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 0) {
            AuthBrandPanel(
                quote: quote,
                author: author,
                category: screen.copy.category
            )
            // Figma pins the brand panel to Light in both screen appearances.
            .environment(\.colorScheme, .light)
            .containerRelativeFrame(.horizontal) { width, _ in
                min(width * AuthLayoutMetrics.sidebarFraction, AuthLayoutMetrics.sidebarWidth)
            }

            ScrollView {
                content
                    .containerRelativeFrame(.horizontal) { viewportWidth, _ in
                        let availableWidth = max(0, viewportWidth - UMCSpacing.value64)
                        let reference = AuthLayoutMetrics.referenceViewportWidth
                        let scale = max(1, viewportWidth / reference)
                        let preferredWidth = screen.contentWidth * scale
                        return min(availableWidth, min(
                            preferredWidth, screen.maximumContentWidth
                        ))
                    }
                    .padding(UMCSpacing.value32)
                    .frame(minWidth: 0, maxWidth: .infinity)
            }
            .defaultScrollAnchor(.center, for: .alignment)
            .scrollBounceBehavior(.basedOnSize)
            .frame(minWidth: 0, maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(UMCColor.Custom.backgroundDefault)
        .tint(UMCColor.Semantic.textBrandDefault)
    }
}

private struct AuthBrandPanel: View {
    let quote: String
    let author: String
    let category: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    fileprivate enum Constants {
        static let contentWidth: CGFloat = 448
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: UMCSpacing.value12) {
                Image("logoLight", bundle: .module)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 124, height: 40)
                    .accessibilityLabel("UMC")
                Text("University MakeUs Challenge")
                    .umcTypography(.bodyRegular)
            }

            Spacer(minLength: UMCSpacing.value24)

            VStack(alignment: .leading, spacing: UMCSpacing.value20) {
                Text(quote)
                    .contentTransition(.opacity)
                    .umcTypography(.largeTitle1Regular)
                    .fixedSize(horizontal: false, vertical: true)
                Text("- \(author)")
                    .contentTransition(.opacity)
                    .umcTypography(.title2Regular)
            }
            .accessibilityElement(children: .combine)

            Spacer(minLength: UMCSpacing.value24)

            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                Rectangle()
                    .fill(UMCColor.Semantic.textInverse.opacity(0.4))
                    .frame(height: 1)
                    .accessibilityHidden(true)
                Text(category)
                    .contentTransition(.opacity)
                    .umcTypography(.headlineRegular)
            }
        }
        .foregroundStyle(UMCColor.Semantic.textInverse)
        .animation(AuthMotion.animation(reduceMotion: reduceMotion), value: quote)
        .animation(AuthMotion.animation(reduceMotion: reduceMotion), value: category)
        .frame(maxWidth: Constants.contentWidth)
        .padding(UMCSpacing.value64)
        .frame(maxWidth: .infinity, minHeight: 0, maxHeight: .infinity, alignment: .leading)
        .background {
            LinearGradient(
                stops: [
                    .init(color: UMCColor.Primitives.tealGrey900, location: 0.267),
                    .init(color: UMCColor.Primitives.teal900, location: 0.888),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

private struct AuthPageContent: View {
    let screen: AuthScreen
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        switch screen {
        case .loginSelection, .socialLogin:
            AuthLoginSelection(screen: screen, viewModel: viewModel)
        case .emailLogin, .credentialsError:
            AuthEmailLogin(screen: screen, viewModel: viewModel)
        case .signup:
            AuthRegistration(viewModel: viewModel)
        case .passwordReset:
            AuthPasswordReset(viewModel: viewModel)
        case .challengerIntro:
            AuthChallengerIntro(screen: screen, viewModel: viewModel)
        case .challengerCode, .challengerCodeError:
            AuthChallengerCode(screen: screen, viewModel: viewModel)
        case .sessionChecking, .memberChecking, .challengerChecking, .challengerComplete:
            AuthVerificationStatus(screen: screen, viewModel: viewModel)
        case .updateDownloading, .updateVerifying, .updateReady, .updateInstalling,
             .updateComplete:
            AuthUpdateProgress(screen: screen, viewModel: viewModel)
        default:
            AuthStatusPage(screen: screen, viewModel: viewModel)
        }
    }
}
