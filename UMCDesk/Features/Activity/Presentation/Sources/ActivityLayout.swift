//  ActivityLayout.swift
//  ActivityPresentation
//
//  Created by euijjang97 on 11/27/26.
//

import SwiftUI

/// Uses the content proposal, never the window width or a measurement feedback loop.
struct ActivityColumns: Layout {
    var expandedText = false

    static func isHorizontal(width: CGFloat, expandedText: Bool) -> Bool {
        width >= 816 && !expandedText
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 816
        let horizontal = Self.isHorizontal(width: width, expandedText: expandedText)
        let column = horizontal ? (width - 16) / 2 : width
        let heights = subviews.map { $0.sizeThatFits(.init(width: column, height: nil)).height }
        return CGSize(
            width: width,
            height: horizontal
                ? heights.max() ?? 0
                : heights.reduce(0, +) + CGFloat(max(0, heights.count - 1)) * 16)
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize,
        subviews: Subviews, cache: inout ()
    ) {
        let horizontal = Self.isHorizontal(width: bounds.width, expandedText: expandedText)
        let width = horizontal ? (bounds.width - 16) / 2 : bounds.width
        var origin = bounds.origin
        for view in subviews {
            let size = view.sizeThatFits(.init(width: width, height: nil))
            view.place(
                at: origin, anchor: .topLeading, proposal: .init(width: width, height: size.height)
            )
            if horizontal { origin.x += width + 16 } else { origin.y += size.height + 16 }
        }
    }
}

/// Two content regions stay side by side only when both intrinsic minima fit.
struct ActivityAdaptiveRow: Layout {
    var minimumLeadingWidth: CGFloat
    var minimumTrailingWidth: CGFloat = 0
    var spacing: CGFloat = 16
    var trailingFlexible = false

    private func widths(_ width: CGFloat, _ subviews: Subviews) -> [CGFloat] {
        guard subviews.count == 2 else { return subviews.map { _ in width } }
        let leading = max(minimumLeadingWidth, subviews[0].sizeThatFits(.zero).width)
        let trailing = max(
            minimumTrailingWidth,
            subviews[1].sizeThatFits(trailingFlexible ? .zero : .unspecified).width)
        guard width >= leading + spacing + trailing else { return [width, width] }
        return trailingFlexible
            ? [leading, width - leading - spacing]
            : [width - trailing - spacing, trailing]
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 600
        let widths = widths(width, subviews)
        let heights = zip(subviews, widths).map {
            $0.sizeThatFits(.init(width: $1, height: nil)).height
        }
        let horizontal = widths.count == 2 && widths[0] < width
        return CGSize(
            width: width,
            height: horizontal
                ? heights.max() ?? 0
                : heights.reduce(0, +) + CGFloat(max(0, heights.count - 1)) * spacing)
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize,
        subviews: Subviews, cache: inout ()
    ) {
        let widths = widths(bounds.width, subviews)
        let horizontal = widths.count == 2 && widths[0] < bounds.width
        var origin = bounds.origin
        for (index, pair) in zip(subviews, widths).enumerated() {
            let (view, width) = pair
            let size = view.sizeThatFits(.init(width: width, height: nil))
            let alignTrailing = !horizontal && index == 1 && !trailingFlexible
            view.place(
                at: CGPoint(x: alignTrailing ? bounds.maxX : origin.x, y: origin.y),
                anchor: alignTrailing ? .topTrailing : .topLeading,
                proposal: .init(width: width, height: size.height))
            if horizontal {
                origin.x += width + spacing
            } else {
                origin.y += size.height + spacing
            }
        }
    }
}

/// Wraps native controls at their ideal width without scaling text or dropping actions.
struct ActivityFlow: Layout {
    var spacing: CGFloat = 12
    var alignment: HorizontalAlignment = .leading

    private func frames(width: CGFloat, subviews: Subviews) -> [CGRect] {
        var origin = CGPoint.zero
        var lineHeight: CGFloat = 0
        let frames = subviews.map { view in
            let ideal = view.sizeThatFits(.unspecified)
            let size = view.sizeThatFits(.init(width: min(width, ideal.width), height: nil))
            if origin.x > 0 && origin.x + size.width > width {
                origin.x = 0
                origin.y += lineHeight + spacing
                lineHeight = 0
            }
            let frame = CGRect(origin: origin, size: size)
            origin.x += size.width + spacing
            lineHeight = max(lineHeight, size.height)
            return frame
        }
        guard alignment == .trailing else { return frames }
        return frames.map { frame in
            let end = frames.filter { $0.minY == frame.minY }.map(\.maxX).max() ?? 0
            return frame.offsetBy(dx: width - end, dy: 0)
        }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width =
            proposal.width
            ?? subviews.reduce(0) { $0 + $1.sizeThatFits(.unspecified).width + spacing }
        let frames = frames(width: width, subviews: subviews)
        return CGSize(width: width, height: frames.map(\.maxY).max() ?? 0)
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize,
        subviews: Subviews, cache: inout ()
    ) {
        for (view, frame) in zip(subviews, frames(width: bounds.width, subviews: subviews)) {
            view.place(
                at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                anchor: .topLeading, proposal: .init(frame.size))
        }
    }
}
