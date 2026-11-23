//
//  AuthPublishedTermsView.swift
//  AuthPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import AuthDomain
import CoreDesignSystem
import SwiftUI
import UMCFoundation

public struct AuthPublishedTermsView: View {
    public enum Kind: String, Identifiable, Sendable {
        case service = "SERVICE"
        case privacy = "PRIVACY"

        public var id: String { rawValue }

        fileprivate var title: String {
            switch self {
            case .service: AppLocalization.string("서비스 이용약관")
            case .privacy: AppLocalization.string("개인정보 처리방침")
            }
        }

        fileprivate func matches(_ term: RegistrationTerm) -> Bool {
            if let type = term.type { return type == rawValue }
            // Older responses expose TermType's original Korean description only.
            switch self {
            case .service: return term.title == "서비스 이용약관"
            case .privacy: return term.title == "개인정보 처리방침"
            }
        }
    }

    private let repository: any AuthFlowRepository
    private let requested: Kind
    private let onClose: () -> Void

    public init(
        repository: any AuthFlowRepository, requested: Kind, onClose: @escaping () -> Void
    ) {
        self.repository = repository
        self.requested = requested
        self.onClose = onClose
    }

    public var body: some View {
        PublishedTermSheet(repository: repository, requested: requested, onClose: onClose)
            .id(requested)
    }
}

enum PublishedTermState: Equatable {
    case loading, unpublished, failed
    case published(URL)

    static func load(
        requested: AuthPublishedTermsView.Kind,
        terms: @Sendable () async throws -> [RegistrationTerm]
    ) async -> Self {
        do {
            guard let term = try await terms().first(where: requested.matches) else {
                return .unpublished
            }
            guard let components = URLComponents(string: term.link),
                  components.scheme?.lowercased() == "https",
                  let host = components.host, !host.isEmpty,
                  components.user == nil, components.password == nil,
                  let url = components.url else { return .failed }
            return .published(url)
        } catch {
            return .failed
        }
    }
}

private struct PublishedTermSheet: View {
    let repository: any AuthFlowRepository
    let requested: AuthPublishedTermsView.Kind
    let onClose: () -> Void

    @Environment(\.openURL) private var openURL
    @State private var state = PublishedTermState.loading
    @State private var attempt = 0
    @State private var openFailed = false

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value24) {
            Text(requested.title)
                .umcTypography(.title2Bold)
                .accessibilityAddTraits(.isHeader)
            Group {
                switch state {
                case .loading:
                    ProgressView(authLocalized("게시된 문서를 확인하고 있어요."))
                        .controlSize(.small)
                case .unpublished:
                    Text(authLocalized("아직 게시된 문서가 없어요."))
                case .failed:
                    Text(authLocalized("문서를 불러올 수 없어요. 잠시 후 다시 시도해 주세요."))
                case .published(let url):
                    Text(url.host() ?? url.absoluteString)
                        .textSelection(.enabled)
                }
            }
            .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
            HStack {
                Spacer()
                Button(AppLocalization.string("닫기"), action: onClose)
                    .keyboardShortcut(.cancelAction)
                switch state {
                case .published(let url):
                    Button(authLocalized("문서 열기")) {
                        openURL(url) { openFailed = !$0 }
                    }
                    .keyboardShortcut(.defaultAction)
                case .unpublished, .failed:
                    Button(AppLocalization.string("다시 확인")) {
                        state = .loading
                        attempt += 1
                    }
                    .keyboardShortcut(.defaultAction)
                case .loading:
                    EmptyView()
                }
            }
        }
        .padding(UMCSpacing.value24)
        .frame(minWidth: 360, idealWidth: 420)
        .task(id: attempt) {
            let result = await PublishedTermState.load(requested: requested) { [repository] in
                try await repository.terms()
            }
            if !Task.isCancelled { state = result }
        }
        .alert(authLocalized("문서 링크를 열 수 없어요."), isPresented: $openFailed) {
            Button(AppLocalization.string("확인"), role: .cancel) {}
        }
    }
}
