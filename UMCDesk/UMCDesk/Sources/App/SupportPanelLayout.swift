//
//  SupportPanelLayout.swift
//  UMCDesk
//
//  Created by euijjang97 on 11/28/26.
//

import CoreDesignSystem
import SwiftUI

extension EnvironmentValues {
    @Entry var supportExitDecision: SupportExitGate? = nil
}

enum SupportDiscardChoice {
    case composition, uncertainCreation, faq
    var title: String {
        switch self {
        case .composition: "작성 중인 문의를 버릴까요?"
        case .uncertainCreation: "보낸 문의의 로컬 초안을 버릴까요?"
        case .faq: "FAQ 변경사항을 버릴까요?"
        }
    }
    var explanation: String {
        switch self {
        case .composition: "입력한 내용과 첨부는 저장되지 않아요."
        case .uncertainCreation: "초안을 버린 뒤에도 고객센터에서 보낸 문의의 접수 결과를 확인할 수 있어요."
        case .faq: "마지막 저장 이후의 수정 내용이 사라져요."
        }
    }
    var keep: String { self == .faq ? "계속 편집" : "계속 작성" }
    var discard: String { self == .faq ? "변경사항 버리기" : "초안 버리기" }
}

struct SupportDiscardAlert: ViewModifier {
    let choice: SupportDiscardChoice
    let presented: Bool
    let stay: () -> Void
    let discard: () -> Void

    func body(content: Content) -> some View {
        content.alert(choice.title, isPresented: Binding(get: { presented }, set: { _ in })) {
            Button(choice.keep, role: .cancel, action: stay)
            Button(choice.discard, role: .destructive, action: discard).keyboardShortcut(nil)
        } message: {
            Text(choice.explanation)
        }
    }
}

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

/// Uses the table width for all rows even when a single title has a large ideal width.
struct SupportTableWidth: Layout {
    let minimum: CGFloat
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = max(minimum, proposal.width ?? minimum)
        return .init(
            width: width,
            height: subviews.first?.sizeThatFits(.init(width: width, height: nil)).height ?? 0)
    }
    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        subviews.first?.place(at: bounds.origin, anchor: .topLeading, proposal: .init(bounds.size))
    }
}

/// The trigger is in the workspace toolbar. Keep the panel inside the safe edges when enlarged.
struct SupportToolsPlacement: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions(by: .init(width: 422, height: 480))
    }
    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        guard let menu = subviews.first else { return }
        let edge = SupportLayoutMetrics.edge
        let width = min(SupportLayoutMetrics.toolWidth, max(0, bounds.width - 2 * edge))
        let natural = menu.sizeThatFits(.init(width: width, height: nil)).height
        let safe = bounds.insetBy(dx: edge, dy: edge)
        let position = SupportFieldMenuPlacement.position(
            height: max(0, safe.height),
            prefix: max(0, 4 - edge), field: 26, menu: natural)
        menu.place(
            at: .init(x: safe.maxX - width, y: safe.minY + position.menuY), anchor: .topLeading,
            proposal: .init(width: width, height: position.menuHeight))
    }
}

/// Positions a panel against its field in the visible processing viewport.
/// The menu receives the larger remaining interval if neither side can fit its natural height.
struct SupportFieldMenuPlacement: Layout {
    struct Placement {
        let fieldY: CGFloat
        let menuY: CGFloat
        let menuHeight: CGFloat
    }

    static func position(height: CGFloat, prefix: CGFloat, field: CGFloat, menu: CGFloat)
        -> Placement
    {
        let gap: CGFloat = 6
        let fieldY = min(max(0, prefix), max(0, height - field))
        let above = max(0, fieldY - gap)
        let below = max(0, height - fieldY - field - gap)
        if below >= menu || (above < menu && below >= above) {
            return .init(fieldY: fieldY, menuY: fieldY + field + gap, menuHeight: min(below, menu))
        }
        let shown = min(above, menu)
        return .init(fieldY: fieldY, menuY: fieldY - gap - shown, menuHeight: shown)
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        proposal.replacingUnspecifiedDimensions(by: .init(width: 360, height: 480))
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        guard subviews.count == 4 else { return }
        let width = max(0, bounds.width - 48)
        let column = ProposedViewSize(width: width, height: nil)
        let field = subviews[1].sizeThatFits(column).height
        let menuWidth = min(312, width)
        let menu = subviews[3].sizeThatFits(.init(width: menuWidth, height: nil)).height
        let placement = Self.position(
            height: bounds.height, prefix: 36 + subviews[0].sizeThatFits(column).height,
            field: field, menu: menu)
        let left = bounds.minX + 24
        subviews[0].place(
            at: .init(x: left, y: bounds.minY + 24), anchor: .topLeading, proposal: column)
        subviews[1].place(
            at: .init(x: left, y: bounds.minY + placement.fieldY),
            anchor: .topLeading, proposal: .init(width: width, height: field))
        subviews[2].place(
            at: .init(x: left, y: bounds.minY + placement.fieldY + field + 12),
            anchor: .topLeading, proposal: column)
        subviews[3].place(
            at: .init(x: left, y: bounds.minY + placement.menuY), anchor: .topLeading,
            proposal: .init(width: menuWidth, height: placement.menuHeight))
    }
}

@Observable @MainActor final class SupportCommand {
    struct Feedback: Identifiable {
        let id: String
        let name: String
        let request: UUID
        var receipt: SupportPreviewTransport.Receipt
        var retry: (() -> Void)?
    }
    private(set) var actions: [Feedback] = []

    var isSending: Bool { actions.contains { $0.receipt == .sending } }
    func run(
        _ name: String, scope: String = "", transport: SupportPreviewTransport, isOperator: Bool,
        attachment: Bool = false, payload: [String] = [], retrying expected: UUID? = nil,
        apply: @escaping (Bool) -> Bool,
        success: @escaping (SupportPreviewTransport.Receipt) -> Void = { _ in }
    ) {
        let destination = SupportPreviewTransport.Key(
            scope: scope, action: name, isOperator: isOperator)
        guard !transport.blocked(destination) else { return }
        if let expected {
            guard transport.requests[destination] == expected,
                transport.state(destination) == .failed
            else { return }
        }
        let key = scope + name
        guard !actions.contains(where: { $0.id == key && $0.receipt == .sending }) else { return }
        actions.removeAll { $0.id == key }
        let id = expected ?? transport.requestID(for: destination, payload: payload)
        actions.append(Feedback(id: key, name: name, request: id, receipt: .sending))
        Task { @MainActor [self] in
            let result = await transport.send(
                id: id, key: destination, payload: payload, retrying: expected,
                requiresOperator: isOperator,
                hasAttachment: attachment, apply: apply)
            guard let index = actions.firstIndex(where: { $0.id == key }) else { return }
            if result == .sending {
                actions.remove(at: index)
                return
            }
            actions[index].receipt = result
            if result.acknowledged { success(result) }
            if result == .failed {
                actions[index].retry = { [weak self] in
                    self?.run(
                        name, scope: scope, transport: transport, isOperator: isOperator,
                        attachment: attachment, payload: payload, retrying: id, apply: apply,
                        success: success)
                }
            }
        }
    }
}

struct SupportCommandStatus: View {
    let command: SupportCommand
    let transport: SupportPreviewTransport
    let scope: String
    let isOperator: Bool
    var body: some View {
        let keys = transport.requests.keys.filter {
            $0.scope == scope && $0.isOperator == isOperator
        }
        ForEach(keys.sorted { $0.action < $1.action }, id: \.self) { key in
            switch transport.state(key) {
            case .sending: Text(key.action + " 중…")
            case .failed:
                VStack(alignment: .leading) {
                    Text(key.action + "이 반영되지 않았어요.")
                    if let retry = command.actions.first(where: {
                        $0.id == scope + key.action && $0.request == transport.requests[key]
                    })?
                    .retry {
                        Button(key.action + " 다시 시도", action: retry)
                    } else {
                        Text("입력을 확인한 뒤 " + key.action + " 동작을 다시 선택해 주세요.")
                    }
                }
            case .uncertain, .refreshFailed:
                VStack(alignment: .leading) {
                    Text(
                        transport.state(key) == .uncertain
                            ? key.action + " 결과를 확인할 수 없어요."
                            : key.action + "를 완료했어요. 목록을 다시 불러와 주세요.")
                    Button("다시 불러오기") { Task { await transport.reload(verifying: key) } }
                }
            case .attachmentFailed: Text(key.action + "를 완료했어요. 예시 첨부는 실패했어요.")
            case .success: Text(key.action + " 완료").font(.caption)
            case nil: EmptyView()
            }
        }
    }
}
