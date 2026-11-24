//
//  ThreadSummaryPanel.swift
//  CommunityPresentation
//
//  Created by euijjang97 on 11/23/26.
//

import CoreDesignSystem
import SwiftUI

struct ThreadSummaryPanel: View {
    let model: ThreadConversationModel
    let unread: String

    var body: some View {
        Button(action: start) {
            HStack(spacing: 7) {
                Image(systemName: "sparkles").accessibilityHidden(true)
                Text(unread == "0" ? "최근 대화 요약" : "읽지 않은 메시지 \(unread)개 요약")
                    .font(.callout.weight(.medium))
                Image(systemName: "chevron.right")
                    .font(.caption2.bold()).accessibilityHidden(true)
            }
            .padding(.horizontal, 4)
            .foregroundStyle(UMCColor.Semantic.textBrandStrong)
        }
        .buttonStyle(.bordered)
        .buttonBorderShape(.capsule)
        .controlSize(.regular)
        .tint(UMCColor.Semantic.textBrandDefault)
        .help("요약 보기")
        .disabled(!model.messages.contains { !$0.isHidden && !$0.text.isEmpty })
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: Binding(
            get: { if case .closed = model.summary.phase { false } else { true } },
            set: { if !$0 { model.summary.close() } }
        )) {
            ThreadSummaryDialog(session: model.summary, regenerate: start)
                .presentationSizing(.fitted)
        }
    }

    private func start() {
        model.summary.start(messages: model.messages, accountID: model.accountID, unread: unread)
    }
}

struct ThreadSummaryDialog: View {
    let session: ThreadSummarySession
    let regenerate: () -> Void

    var body: some View {
        Group {
            switch session.phase {
            case .closed: EmptyView()
            case .ready(let content): result(content)
            case .unavailable: unavailable
            case .loading, .failed: progressOrFailure
            }
        }
        .foregroundStyle(UMCColor.Semantic.textNeutralDefault)
        .background(UMCColor.Semantic.surfaceDefault)
    }

    private func result(_ content: ThreadSummaryContent) -> some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            HStack {
                Text("이런 이야기가 오갔어요").font(.system(size: 24, weight: .bold))
                Spacer()
                Image(systemName: "sparkles").foregroundStyle(.secondary).accessibilityHidden(true)
            }
            Text("Apple Intelligence · \(session.scope)")
                .font(.system(size: 12, weight: .medium))
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(UMCColor.Semantic.fillNeutralWeaker50, in: Capsule())
            ViewThatFits(in: .vertical) {
                details(content).fixedSize(horizontal: false, vertical: true)
                ScrollView { details(content) }
            }
            .frame(maxHeight: 430)
            .fixedSize(horizontal: false, vertical: true)
            Text("요약은 기기에서 생성되며, 실제 대화와 다를 수 있어요.")
                .font(.system(size: 12)).foregroundStyle(.secondary)
            HStack {
                Button("다시 요약", action: regenerate)
                    .buttonStyle(SummaryButtonStyle(kind: .ai, width: 120))
                Spacer()
                Button("원문 보기", action: session.close)
                    .buttonStyle(SummaryButtonStyle(kind: .primary, width: 120))
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
        .frame(width: 620)
    }

    private func details(_ content: ThreadSummaryContent) -> some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value16) {
            ForEach(content.highlights.indices, id: \.self) { index in
                HStack(alignment: .firstTextBaseline, spacing: UMCSpacing.value12) {
                    Image(systemName: "checkmark").foregroundStyle(.secondary)
                        .frame(width: 16).accessibilityHidden(true)
                    Text(content.highlights[index]).umcTypography(.headlineRegular)
                }
            }
            Divider()
            Text("내 액션 아이템").umcTypography(.title4Bold)
            if content.actions.isEmpty {
                Text("대화에서 확인된 내 액션 아이템이 없어요.")
                    .umcTypography(.headlineRegular).foregroundStyle(.secondary)
            }
            ForEach(content.actions.indices, id: \.self) { index in
                let action = content.actions[index]
                VStack(alignment: .leading, spacing: UMCSpacing.value8) {
                    Text(action.title).umcTypography(.headlineBold)
                    Text(action.detail).font(.system(size: 12)).foregroundStyle(.secondary)
                }
                .padding(18)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(UMCColor.Semantic.fillNeutralWeaker50, in: .rect(cornerRadius: 12))
            }
        }
        .textSelection(.enabled)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var unavailable: some View {
        VStack(alignment: .leading, spacing: UMCSpacing.value12) {
            HStack {
                Text("AI 요약을 사용할 수 없어요").umcTypography(.title1Bold)
                Spacer()
                Button("닫기", systemImage: "xmark", action: session.close)
                    .labelStyle(.iconOnly).buttonStyle(.plain)
            }
            Text("Apple Intelligence를 지원하고 활성화한 기기에서 이용할 수 있어요. 대화는 계속 읽을 수 있어요.")
                .umcTypography(.title4Regular).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: UMCSpacing.value12) {
                Spacer()
                Button("취소", action: session.close)
                    .buttonStyle(SummaryButtonStyle(kind: .outline, width: 90, height: 44))
                    .keyboardShortcut(.cancelAction)
                Button("대화 보기", action: session.close)
                    .buttonStyle(SummaryButtonStyle(kind: .primary, width: 102, height: 44))
                    .keyboardShortcut(.defaultAction)
            }.padding(.top, UMCSpacing.value16)
        }
        .padding(UMCSpacing.value24)
        .frame(width: 560)
    }

    private var progressOrFailure: some View {
        VStack(spacing: UMCSpacing.value16) {
            if case .loading = session.phase {
                ProgressView("기기에서 대화를 요약하고 있어요.")
            } else {
                Text("대화 요약을 완료하지 못했어요.").umcTypography(.title4Bold)
                Button("다시 요약", action: regenerate)
                    .buttonStyle(SummaryButtonStyle(kind: .ai, width: 120))
            }
            Button("대화 보기", action: session.close).keyboardShortcut(.cancelAction)
        }
        .padding(28).frame(width: 560)
    }
}

private struct SummaryButtonStyle: ButtonStyle {
    enum Kind { case ai, primary, outline }
    let kind: Kind
    let width: CGFloat
    var height: CGFloat = 36
    @Environment(\.isEnabled) private var enabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .frame(width: width, height: height)
            .foregroundStyle(foreground)
            .background(background, in: .rect(cornerRadius: 9))
            .overlay {
                if kind == .outline {
                    RoundedRectangle(cornerRadius: 9)
                        .strokeBorder(UMCColor.Semantic.borderPrimaryStrong500, lineWidth: 2)
                }
            }
            .contentShape(.rect(cornerRadius: 9))
            .opacity(enabled ? (configuration.isPressed ? 0.75 : 1) : 0.5)
    }

    private var foreground: Color {
        switch kind {
        case .ai: UMCColor.Primitives.violet600
        case .primary: UMCColor.Semantic.textInverse
        case .outline: UMCColor.Semantic.textNeutralDefault
        }
    }

    private var background: Color {
        switch kind {
        case .ai: UMCColor.Primitives.violet50
        case .primary: UMCColor.Semantic.fillPrimaryInverseStrong500
        case .outline: UMCColor.Semantic.surfaceDefault
        }
    }
}
