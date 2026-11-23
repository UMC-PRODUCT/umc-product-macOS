//
//  AuthUpdateCheckView.swift
//  AuthPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import CoreDesignSystem
import SwiftUI
import UMCFoundation

public struct AuthUpdateCheckView: View {
    private enum Status {
        case checking, failed
        case available(AuthReleaseCatalog.Release), current(AuthReleaseCatalog.Release)
    }

    @Environment(\.openURL) private var openURL
    @State private var status: Status = .checking
    @State private var attempt = 0
    @State private var openFailed = false
    private let onClose: () -> Void

    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    public var body: some View {
        let screen = AuthScreen.updateAvailable
        AuthPageLayout(screen: screen, quote: screen.copy.quote, author: screen.copy.author) {
            VStack(spacing: UMCSpacing.value64) {
                AuthHeading(title: title, subtitle: subtitle, icon: .update,
                    subtitleTypography: .title4Regular)
                VStack(spacing: UMCSpacing.value16) {
                    switch status {
                    case .checking:
                        ProgressView().accessibilityLabel(title)
                    case .available(let release), .current(let release):
                        let version = release.version.version
                        let build = String(release.version.build)
                        AuthBanner(
                            title: AppLocalization.string("버전 \(version) | 빌드 \(build)"),
                            message: releaseMessage
                        )
                        .padding(.bottom, UMCSpacing.value8)
                        AuthButton(title: authLocalized("공식 설치 안내 열기")) {
                            openURL(release.notes) { accepted in openFailed = !accepted }
                        }
                    case .failed:
                        AuthButton(title: AppLocalization.string("다시 확인")) {
                            status = .checking
                            attempt += 1
                        }
                    }
                    AuthButton(title: AppLocalization.string("닫기"), kind: .secondary,
                        action: onClose)
                }
            }
        }
        .task(id: attempt) {
            do {
                guard let info = Bundle.main.infoDictionary,
                      let version = info["CFBundleShortVersionString"] as? String,
                      let build = info["CFBundleVersion"] as? String,
                      let installed = AuthReleaseVersion(version: version, build: build) else {
                    throw URLError(.cannotParseResponse)
                }
                let release = try await AuthReleaseCatalog.latest()
                try Task.checkCancellation()
                status = installed < release.version ? .available(release) : .current(release)
            } catch {
                if !Task.isCancelled { status = .failed }
            }
        }
        .alert(authLocalized("설치 안내를 열 수 없어요"), isPresented: $openFailed) {
            Button(AppLocalization.string("확인"), role: .cancel) {}
        }
    }

    private var title: String {
        switch status {
        case .checking: AppLocalization.string("업데이트 확인")
        case .available: AuthScreen.updateAvailable.copy.title
        case .current: authLocalized("사용 가능한 새 버전이 없어요")
        case .failed: authLocalized("배포 정보를 확인하지 못했어요")
        }
    }

    private var releaseMessage: String {
        if case .available = status {
            return AppLocalization.string("진행 중인 작업을 저장한 뒤 업데이트해 주세요.")
        }
        return authLocalized("공식 배포본")
    }

    private var subtitle: String {
        switch status {
        case .checking: authLocalized("공식 배포본을 확인하고 있어요.")
        case .available: authLocalized("공식 설치 안내에서 새 버전을 다운로드할 수 있어요.")
        case .current: ""
        case .failed: AppLocalization.string("인터넷 연결을 확인한 뒤 다시 시도해 주세요.")
        }
    }
}

func authLocalized(_ key: String.LocalizationValue) -> String {
    let language = AppLocalization.shared.language
    let bundle = Bundle.module.path(forResource: language.rawValue, ofType: "lproj")
        .flatMap(Bundle.init(path:)) ?? Bundle.module
    return String(localized: key, table: "Auth", bundle: bundle, locale: language.locale)
}
