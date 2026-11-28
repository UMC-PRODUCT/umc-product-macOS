//
//  SupportPanelLayout.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/28/26.
//

import CoreDesignSystem
import SwiftUI

enum SupportLayoutMetrics {
    static let toolWidth: CGFloat = 390
    static let edge: CGFloat = 16
    static let teamWidth: CGFloat = 816
    static let teamInset: CGFloat = 25
    static func teamGridMinimum(_ scale: CGFloat) -> CGFloat { 600 * scale + 12 }
    static func fullTable(_ scale: CGFloat) -> CGFloat { 900 * scale }
    static func mediumTable(_ scale: CGFloat) -> CGFloat { 640 * scale }
}

/// Splits the available content width, keeping both children mounted during window resizing.
struct SupportPanelLayout: Layout {
    var scale: CGFloat
    var firstMinimum: CGFloat = 600
    var secondMinimum: CGFloat = 300
    var fraction: CGFloat = 898 / 1258

    func widths(for width: CGFloat) -> (CGFloat, CGFloat)? {
        let minimum = firstMinimum * scale
        let maximum = width - 24 - secondMinimum * scale
        guard maximum >= minimum else { return nil }
        let first = min(maximum, max(minimum, (width - 24) * fraction))
        return (first, width - 24 - first)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? firstMinimum + secondMinimum + 24
        let frames = frames(for: width, subviews: subviews)
        return CGSize(width: width, height: frames.map(\.maxY).max() ?? 0)
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize,
        subviews: Subviews, cache: inout ()
    ) {
        for (view, frame) in zip(subviews, frames(for: bounds.width, subviews: subviews)) {
            view.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                anchor: .topLeading, proposal: ProposedViewSize(frame.size))
        }
    }

    private func frames(for width: CGFloat, subviews: Subviews) -> [CGRect] {
        let columns = widths(for: width)
        var bottom: CGFloat = 0
        return subviews.enumerated().map { index, view in
            let columnWidth =
                subviews.count == 1
                ? width
                : (index == 0 ? columns?.0 : columns?.1) ?? width
            let height = view.sizeThatFits(.init(width: columnWidth, height: nil)).height
            let x = index == 1 ? (columns.map { $0.0 + 24 } ?? 0) : 0
            let y = columns == nil && index > 0 ? bottom + 24 : 0
            bottom = y + height
            return CGRect(x: x, y: y, width: columnWidth, height: height)
        }
    }
}

struct SupportContentInsets: Layout {
    static func horizontal(for width: CGFloat) -> CGFloat {
        min(40, max(16, (width - 784) / 8))
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let size = proposal.replacingUnspecifiedDimensions(by: CGSize(width: 976, height: 720))
        return size
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize,
        subviews: Subviews, cache: inout ()
    ) {
        let inset = Self.horizontal(for: bounds.width)
        subviews.first?.place(
            at: CGPoint(x: bounds.minX + inset, y: bounds.minY + 24),
            anchor: .topLeading,
            proposal: .init(
                width: max(0, bounds.width - 2 * inset - 14),
                height: max(0, bounds.height - 48)))
    }
}

/// A fallback scroll keeps the actions reachable when the footer leaves too little reading space.
struct SupportReadingArea<Reading: View, Actions: View>: View {
    @Environment(\.umcBodyTextScale) private var scale
    @ViewBuilder let reading: () -> Reading
    @ViewBuilder let actions: () -> Actions

    var body: some View {
        ViewThatFits(in: .vertical) {
            SupportPinnedFooter(scale: scale) {
                ScrollView { reading().frame(maxWidth: .infinity, alignment: .leading) }
                actions().fixedSize(horizontal: false, vertical: true)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    reading()
                    actions()
                }
            }
        }
    }
}

struct SupportPinnedFooter: Layout {
    let scale: CGFloat
    static func fits(height: CGFloat, footer: CGFloat, scale: CGFloat) -> Bool {
        height - footer - 12 >= 160 * scale
    }
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 600 * scale
        let footer = subviews.last?.sizeThatFits(.init(width: width, height: nil)).height ?? 0
        let minimum = footer + 12 + 160 * scale
        return .init(width: width, height: max(proposal.height ?? minimum, minimum))
    }
    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        guard subviews.count == 2 else { return }
        let footer = subviews[1].sizeThatFits(.init(width: bounds.width, height: nil)).height
        subviews[0].place(
            at: bounds.origin, anchor: .topLeading,
            proposal: .init(width: bounds.width, height: max(0, bounds.height - footer - 12)))
        subviews[1].place(
            at: .init(x: bounds.minX, y: bounds.maxY - footer), anchor: .topLeading,
            proposal: .init(width: bounds.width, height: footer))
    }
}

struct SupportActionRow<Controls: View>: View {
    @ViewBuilder let controls: () -> Controls
    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { controls() }.fixedSize(horizontal: true, vertical: false)
            VStack(alignment: .trailing, spacing: 8) { controls() }
        }.frame(maxWidth: .infinity, alignment: .trailing)
    }
}

/// For a wide toolbar/details pair each column receives the actual viewport height.
struct SupportWidePanels: Layout {
    let split: SupportPanelLayout
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions(
            by: CGSize(
                width: (split.firstMinimum + split.secondMinimum) * split.scale + 24, height: 400))
    }
    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        guard subviews.count == 2, let (left, right) = split.widths(for: bounds.width) else {
            return
        }
        subviews[0].place(
            at: bounds.origin, anchor: .topLeading,
            proposal: .init(width: left, height: bounds.height))
        subviews[1].place(
            at: .init(x: bounds.minX + left + 24, y: bounds.minY), anchor: .topLeading,
            proposal: .init(width: right, height: bounds.height))
    }
}

@Observable @MainActor final class SupportCommand {
    struct Feedback: Identifiable {
        let id: String
        let name: String
        var receipt: SupportPreviewTransport.Receipt
        var retry: (() -> Void)?
    }
    private(set) var actions: [Feedback] = []

    var isSending: Bool { actions.contains { $0.receipt == .sending } }
    func blocked(_ key: String) -> Bool {
        actions.contains { $0.id == key && ($0.receipt == .sending || $0.receipt == .uncertain) }
    }

    func run(
        _ name: String, scope: String = "", transport: SupportPreviewTransport, isOperator: Bool,
        attachment: Bool = false, apply: @escaping (Bool) -> Bool,
        success: @escaping (SupportPreviewTransport.Receipt) -> Void = { _ in }
    ) {
        let key = scope + name
        guard !blocked(key) else { return }
        actions.removeAll { $0.id == key }
        actions.append(Feedback(id: key, name: name, receipt: .sending))
        let id = UUID()
        Task { @MainActor [self] in
            let result = await transport.send(
                id: id, requiresOperator: isOperator,
                hasAttachment: attachment, apply: apply)
            guard let index = actions.firstIndex(where: { $0.id == key }) else { return }
            actions[index].receipt = result
            if result.acknowledged { success(result) }
            if result == .failed {
                actions[index].retry = { [weak self] in
                    self?.run(
                        name, scope: scope, transport: transport, isOperator: isOperator,
                        attachment: attachment, apply: apply, success: success)
                }
            }
        }
    }
}

struct SupportCommandStatus: View {
    let command: SupportCommand
    let transport: SupportPreviewTransport
    var body: some View {
        ForEach(command.actions) { item in
            switch item.receipt {
            case .sending: Text(item.name + " 중…")
            case .failed:
                VStack(alignment: .leading) {
                    Text(item.name + "에 실패했어요.")
                    Button(item.name + " 다시 시도") { item.retry?() }
                }
            case .uncertain, .refreshFailed:
                VStack(alignment: .leading) {
                    Text(
                        item.receipt == .uncertain
                            ? item.name + " 결과를 확인할 수 없어요."
                            : item.name + "를 완료했어요. 목록을 다시 불러와 주세요.")
                    Button("다시 불러오기") { Task { await transport.reload() } }
                }
            case .attachmentFailed: Text(item.name + "를 완료했어요. 예시 첨부는 실패했어요.")
            case .success: EmptyView()
            }
        }
    }
}
