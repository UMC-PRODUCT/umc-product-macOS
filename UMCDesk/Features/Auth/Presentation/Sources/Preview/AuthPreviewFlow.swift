//
//  AuthPreviewFlow.swift
//  AuthPresentation
//
//  Created by euijjang97 on 10/10/26.
//

#if DEBUG
import SwiftUI

enum AuthPreviewScenario: String, CaseIterable, Identifiable {
    case success = "정상 진행"
    case offline = "인터넷 연결 실패"
    case loginFailure = "소셜 로그인 실패"
    case credentialsError = "이메일·비밀번호 불일치"
    case memberFailure = "회원 정보 확인 실패"
    case sessionExpired = "세션 만료"
    case signupLoginFailure = "가입 후 로그인 실패"
    case challengerCodeError = "챌린저 코드 오류"
    case challengerPending = "챌린저 승인 대기"
    case updateDownloadError = "다운로드 실패"
    case updateVerificationError = "업데이트 파일 확인 실패"
    case updateInstallationError = "업데이트 설치 실패"

    var id: String { rawValue }

    func destination(after screen: AuthScreen) -> AuthScreen? {
        switch (screen, self) {
        case (.sessionChecking, .offline): .offline
        case (.sessionChecking, .loginFailure): .loginFailure
        case (.sessionChecking, .sessionExpired): .sessionExpired
        case (.memberChecking, .memberFailure): .memberFailure
        case (.challengerChecking, .challengerCodeError): .challengerCodeError
        case (.challengerChecking, .challengerPending): .challengerPending
        case (.updateDownloading, .updateDownloadError): .updateDownloadError
        case (.updateVerifying, .updateVerificationError): .updateVerificationError
        case (.updateInstalling, .updateInstallationError): .updateInstallationError
        default: nil
        }
    }
}

extension AuthViewModel {
    var hasPendingPreviewStep: Bool {
        playsPreviewFlow && [.socialLogin, .sessionChecking, .memberChecking,
            .challengerChecking, .updateDownloading, .updateVerifying,
            .updateInstalling].contains(screen)
    }

    func advancePreviewFlow(for navigation: UUID) {
        guard navigationID == navigation, hasPendingPreviewStep else { return }
        if screen == .updateDownloading {
            downloadProgress = min(1, downloadProgress + 0.05)
            guard downloadProgress >= 1 else { return }
        }
        if let failure = previewScenario.destination(after: screen) {
            previewScenario = .success
            navigate(to: failure)
            return
        }
        switch screen {
        case .socialLogin: navigate(to: .sessionChecking)
        case .sessionChecking: navigate(to: .memberChecking)
        case .memberChecking: navigate(to: .challengerIntro)
        case .challengerChecking: navigate(to: .challengerComplete)
        case .updateDownloading: navigate(to: .updateVerifying)
        case .updateVerifying: navigate(to: .updateReady)
        case .updateInstalling: navigate(to: .updateComplete)
        default: break
        }
    }

    func runPreviewFlow() async {
        let navigation = navigationID
        do {
            while hasPendingPreviewStep && navigationID == navigation {
                try await Task.sleep(for: screen == .updateDownloading ?
                    .milliseconds(60) : .milliseconds(750))
                try Task.checkCancellation()
                advancePreviewFlow(for: navigation)
            }
        } catch is CancellationError {
            // Leaving a screen cancels its pending preview transition.
        } catch {
            assertionFailure("Unexpected preview delay error: \(error)")
        }
    }
}

struct AuthPreviewFlowMenu: View {
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        Menu("흐름 미리보기", systemImage: "play.rectangle") {
            Picker("다음 실행 결과", selection: $viewModel.previewScenario) {
                ForEach(AuthPreviewScenario.allCases) { scenario in
                    Text(scenario.rawValue).tag(scenario)
                }
            }
            Divider()
            if !viewModel.playsPreviewFlow {
                Button("현재 화면 이어서 재생") { viewModel.navigate(to: viewModel.screen) }
            }
            Button("로그인 처음부터") {
                viewModel.navigate(to: .loginSelection, resetsForm: true)
            }
            Button("저장된 로그인 확인") { viewModel.navigate(to: .sessionChecking) }
            Button("업데이트 흐름") { viewModel.navigate(to: .updateAvailable) }
            Button("서비스 점검") { viewModel.navigate(to: .maintenance) }
            Button("로그아웃") { viewModel.navigate(to: .logoutConfirmation) }
            Button("회원 탈퇴") { viewModel.navigate(to: .withdrawalConfirmation) }
        }
        .help("UI 흐름 재생 · 이메일 인증번호 123456 · 오류는 재시도로 복구됩니다.")
    }
}
#endif
