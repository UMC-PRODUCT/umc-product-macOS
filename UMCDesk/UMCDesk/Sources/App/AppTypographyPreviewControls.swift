//
//  AppTypographyPreviewControls.swift
//  AuthPresentation
//
//  Created by euijjang97 on 10/12/26.
//

#if DEBUG || UMC_PRERELEASE
import CoreDesignSystem
import CoreUIComponents
import SwiftUI

struct AppTypographyPreviewControls: View {
    // MARK: - Property

    @Binding var settings: UMCTypographyPreview

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            HStack {
                Text("타이포그래피 조절")
                    .font(.headline)
                Spacer()
                Text("화면 비교")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Toggle("조절값 적용", isOn: $settings.isEnabled)
                .toggleStyle(UMCCheckboxStyle())

            VStack(alignment: .leading, spacing: UMCSpacing.value16) {
                adjustment("글자 크기", value: $settings.sizeScale,
                    range: 0.75...1.75, step: 0.05, isPercentage: true)

                Picker("굵기", selection: $settings.weight) {
                    ForEach(UMCTypographyPreview.Weight.allCases) { weight in
                        Text(weight.rawValue).tag(weight)
                    }
                }

                adjustment("자간", value: $settings.trackingAdjustment,
                    range: -2...4, step: 0.1, isPercentage: false)
                adjustment("줄높이", value: $settings.lineHeightScale,
                    range: 0.9...1.6, step: 0.05, isPercentage: true)
            }
            .disabled(!settings.isEnabled)

            Divider()

            Text("Pretendard · 화면을 이동해도 유지됩니다.\n앱을 종료하면 기본값으로 돌아갑니다.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Button("기본값 복원") { settings = UMCTypographyPreview() }
                .disabled(settings == UMCTypographyPreview())
        }
        .padding(UMCSpacing.value20)
        .frame(width: 320)
        .background(UMCColor.Semantic.backgroundDefault)
    }

    // MARK: - Function

    private func adjustment(
        _ title: String,
        value: Binding<CGFloat>,
        range: ClosedRange<CGFloat>,
        step: CGFloat,
        isPercentage: Bool
    ) -> some View {
        VStack(spacing: UMCSpacing.value4) {
            HStack {
                Text(title)
                Spacer()
                if isPercentage {
                    Text(value.wrappedValue, format: .percent.precision(.fractionLength(0)))
                } else {
                    Text("\(value.wrappedValue, specifier: "%.1f") pt")
                }
            }
            .monospacedDigit()

            Slider(value: value, in: range, step: step) {
                Text(title)
            }
            .labelsHidden()
        }
    }
}
#endif
