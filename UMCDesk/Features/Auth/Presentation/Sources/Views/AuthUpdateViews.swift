//
//  AuthUpdateViews.swift
//  AuthPresentation
//
//  Created by euijjang97 on 10/10/26.
//

import UMCFoundation
import CoreDesignSystem
import SwiftUI

struct AuthUpdateProgress: View {
    let screen: AuthScreen
    @Bindable var viewModel: AuthViewModel

    var body: some View {
        VStack(spacing: UMCSpacing.value64) {
            VStack(alignment: .leading, spacing: UMCSpacing.value24) {
                if let step = screen.updateStep {
                    HStack(spacing: UMCSpacing.value4) {
                        Text(String(format: "STEP %02d", step)).umcTypography(.title4Bold)
                        Text("/ 05")
                            .umcTypography(.title4Regular)
                            .foregroundStyle(UMCColor.Semantic.textBrandDisabled)
                    }
                    .foregroundStyle(UMCColor.Semantic.textBrandDefault)
                    .padding(.horizontal, UMCSpacing.value12)
                    .frame(height: 32)
                    .background(UMCColor.Semantic.backgroundBrandWeak, in: .capsule)
                    .overlay {
                        Capsule().strokeBorder(UMCColor.Semantic.borderPrimaryWeak200)
                    }
                }
                AuthHeading(
                    title: screen.copy.title,
                    subtitle: screen.copy.subtitle,
                    isLeading: true,
                    subtitleTypography: screen == .updateDownloading ?
                        .title4Regular : .title3Regular
                )
            }
            VStack(spacing: UMCSpacing.value24) {
                switch screen {
                case .updateDownloading:
                    AuthUpdateCard(
                        title: AppLocalization.string("다운로드 중"),
                        progress: viewModel.downloadProgress
                    )
                    AuthButton(title: AppLocalization.string("다운로드 취소"), kind: .tertiary) {
                        viewModel.navigate(to: .updateAvailable)
                    }
                case .updateVerifying:
                    AuthUpdateCard(
                        title: AppLocalization.string("파일 확인 중"),
                        message: AppLocalization.string("확인이 끝나면 설치 준비 화면으로 이동해요.")
                    )
                case .updateReady:
                    AuthBanner(
                        title: AppLocalization.string("진행 중인 작업을 먼저 저장해 주세요."),
                        message: AppLocalization.string("설치 후 앱이 다시 시작돼요.")
                    )
                    AuthButton(title: AppLocalization.string("설치하고 다시 시작")) {
                        viewModel.navigate(to: .updateInstalling)
                    }
                case .updateInstalling:
                    AuthUpdateCard(
                        title: AppLocalization.string("설치 중"),
                        message: AppLocalization.string("설치 중에는 업데이트를 취소할 수 없어요.")
                    )
                case .updateComplete:
                    AuthButton(title: AppLocalization.string("UMC 다시 시작")) {
                        viewModel.navigate(to: .loginSelection)
                    }
                default:
                    EmptyView()
                }
            }
        }
    }
}

private struct AuthUpdateCard: View {
    let title: String
    var message = ""
    var progress: Double?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: progress == nil ?
            UMCSpacing.value12 : UMCSpacing.value16) {
            HStack(spacing: UMCSpacing.value12) {
                Image(systemName: progress == nil ? "progress.indicator" : "arrow.down")
                    .font(.system(size: 15, weight: .medium))
                    .symbolEffect(.rotate, options: .repeating,
                        isActive: progress == nil && !reduceMotion)
                    .symbolEffectsRemoved(reduceMotion)
                    .foregroundStyle(UMCColor.Semantic.iconBrandMedium500)
                    .frame(width: 40, height: 40)
                    .background(
                        UMCColor.Semantic.backgroundBrandWeak,
                        in: .rect(cornerRadius: UMCRadius.value8)
                    )
                    .accessibilityHidden(true)
                Text(title)
                    .umcTypography(.title3Regular)
                    .foregroundStyle(UMCColor.Semantic.textNeutralDefault)
                    .frame(maxWidth: .infinity, alignment: .leading)
                if let progress {
                    Text(progress, format: .percent.precision(.fractionLength(0)))
                        .umcTypography(.largeTitle3Bold)
                        .foregroundStyle(UMCColor.Semantic.textBrandDefault)
                        .monospacedDigit()
                }
            }
            if let progress {
                ProgressView(value: progress)
                    .progressViewStyle(AuthDownloadProgressStyle())
                    .accessibilityLabel(AppLocalization.string("업데이트 다운로드 진행률"))
            } else {
                Text(message)
                    .umcTypography(.title4Regular)
                    .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
            }
        }
        .padding(.horizontal, UMCSpacing.value16)
        .padding(.top, UMCSpacing.value16)
        .padding(.bottom, UMCSpacing.value20)
        .background(UMCColor.Custom.backgroundDefault, in: .rect(cornerRadius: UMCRadius.value12))
        .overlay {
            RoundedRectangle(cornerRadius: UMCRadius.value12)
                .strokeBorder(UMCColor.Semantic.borderNeutralWeak200)
        }
    }
}

private struct AuthDownloadProgressStyle: ProgressViewStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        Capsule()
            .fill(UMCColor.Semantic.fillNeutralWeak75)
            .overlay {
                AuthDownloadProgressFill(fractionCompleted: configuration.fractionCompleted ?? 0)
                    .fill(UMCColor.Semantic.iconBrandMedium500)
            }
            .frame(height: 5)
            .animation(reduceMotion ? nil : .linear(duration: 0.08),
                value: configuration.fractionCompleted)
    }
}

struct AuthDownloadProgressFill: Shape {
    var fractionCompleted: Double

    var animatableData: Double {
        get { fractionCompleted }
        set { fractionCompleted = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let progress = fractionCompleted.isFinite ? min(max(fractionCompleted, 0), 1) : 0
        return Capsule().path(in: CGRect(
            x: rect.minX, y: rect.minY, width: rect.width * progress, height: rect.height
        ))
    }
}
