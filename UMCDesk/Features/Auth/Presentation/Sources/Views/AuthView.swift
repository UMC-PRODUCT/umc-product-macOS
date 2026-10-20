//
//  AuthView.swift
//  AuthPresentation
//
//  Created by euijjang97 on 10/10/26.
//

import CoreDesignSystem
import SwiftUI

public struct AuthView: View {
    // MARK: - Property

    @State private var viewModel: AuthViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    fileprivate enum Constants {
        static let sidebarWidth: CGFloat = 576
        static let sidebarFraction: CGFloat = 0.4
        static let referenceViewportWidth: CGFloat = 864
    }

    // MARK: - Init

    public init() {
        _viewModel = State(initialValue: AuthViewModel())
    }

    init(viewModel: AuthViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    // MARK: - Body

    public var body: some View {
        HStack(spacing: 0) {
            AuthBrandPanel(
                quote: viewModel.quoteOverride ?? viewModel.screen.copy.quote,
                author: viewModel.authorOverride ?? viewModel.screen.copy.author,
                category: viewModel.screen.copy.category
            )
            // Figma pins the brand panel to Light in both screen appearances.
            .environment(\.colorScheme, .light)
            .containerRelativeFrame(.horizontal) { width, _ in
                min(width * Constants.sidebarFraction, Constants.sidebarWidth)
            }

            ScrollView {
                ZStack {
                    AuthPageContent(screen: viewModel.screen, viewModel: viewModel)
                        .id(viewModel.navigationID)
                        .transition(AuthMotion.pageTransition(reduceMotion: reduceMotion))
                }
                .containerRelativeFrame(.horizontal) { viewportWidth, _ in
                    let availableWidth = max(0, viewportWidth - UMCSpacing.value64)
                    let scale = max(1, viewportWidth / Constants.referenceViewportWidth)
                    let preferredWidth = viewModel.screen.contentWidth * scale
                    return min(availableWidth, min(
                        preferredWidth, viewModel.screen.maximumContentWidth
                    ))
                }
                .padding(UMCSpacing.value32)
                .frame(minWidth: 0, maxWidth: .infinity)
                .animation(AuthMotion.animation(reduceMotion: reduceMotion),
                    value: viewModel.navigationID)
            }
            .defaultScrollAnchor(.center, for: .alignment)
            .scrollBounceBehavior(.basedOnSize)
            .frame(minWidth: 0, maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .background(UMCColor.Custom.backgroundDefault)
        .tint(UMCColor.Semantic.textBrandDefault)
        #if DEBUG || UMC_PRERELEASE
        .focusedSceneValue(\.authPreviewModel, $viewModel)
        .task(id: viewModel.navigationID) { await viewModel.runPreviewFlow() }
        .onAppear {
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
