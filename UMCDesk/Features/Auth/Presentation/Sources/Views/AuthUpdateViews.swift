//
//  AuthUpdateViews.swift
//  AuthPresentation
//
//  Created by euijjang97 on 10/10/26.
//

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
                        Text(String(format: "STEP %02d", step)).umcTypography(.headlineBold)
                        Text("/ 05").umcTypography(.headlineRegular)
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
                    isLeading: true
                )
            }
            VStack(spacing: UMCSpacing.value24) {
                switch screen {
                case .updateDownloading:
                    AuthUpdateCard(
                        title: "다운로드 중", progress: viewModel.downloadProgress
                    )
                    AuthButton(title: "다운로드 취소", kind: .tertiary) {
                        viewModel.navigate(to: .updateAvailable)
                    }
                case .updateVerifying:
                    AuthUpdateCard(
                        title: "파일 확인 중",
                        message: "확인이 끝나면 설치 준비 화면으로 이동해요."
                    )
                case .updateReady:
                    AuthBanner(
                        title: "진행 중인 작업을 먼저 저장해 주세요.",
                        message: "설치 후 앱이 다시 시작돼요."
                    )
                    AuthButton(title: "설치하고 다시 시작") {
                        viewModel.navigate(to: .updateInstalling)
                    }
                case .updateInstalling:
                    AuthUpdateCard(
                        title: "설치 중", message: "설치 중에는 업데이트를 취소할 수 없어요."
                    )
                case .updateComplete:
                    AuthButton(title: "UMC 다시 시작") {
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

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            HStack(spacing: UMCSpacing.value12) {
                Group {
                    if progress != nil {
                        Image(systemName: "arrow.down")
                            .font(.system(size: 20))
                    } else {
                        ProgressView().controlSize(.small)
                    }
                }
                .foregroundStyle(UMCColor.Semantic.iconBrandMedium500)
                .frame(width: 40, height: 40)
                .background(
                    UMCColor.Semantic.backgroundBrandWeak,
                    in: .rect(cornerRadius: UMCRadius.value8)
                )
                .accessibilityHidden(true)
                Text(title)
                    .umcTypography(.title3Regular)
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
                    .accessibilityLabel("업데이트 다운로드 진행률")
            } else {
                Text(message)
                    .umcTypography(.headlineRegular)
                    .foregroundStyle(UMCColor.Semantic.textNeutralMedium600)
            }
        }
        .padding(.horizontal, UMCSpacing.value16)
        .padding(.top, UMCSpacing.value16)
        .padding(.bottom, UMCSpacing.value20)
        .background(UMCColor.Semantic.surfaceDefault, in: .rect(cornerRadius: UMCRadius.value12))
        .overlay {
            RoundedRectangle(cornerRadius: UMCRadius.value12)
                .strokeBorder(UMCColor.Semantic.borderNeutralWeak200)
        }
    }
}

private struct AuthDownloadProgressStyle: ProgressViewStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        GeometryReader { geometry in
            Capsule()
                .fill(UMCColor.Semantic.fillNeutralWeak75)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(UMCColor.Semantic.iconBrandMedium500)
                        .frame(width: geometry.size.width * (configuration.fractionCompleted ?? 0))
                }
        }
        .frame(height: 5)
        .animation(reduceMotion ? nil : .linear(duration: 0.08),
            value: configuration.fractionCompleted)
    }
}
