//  DeskCardLayout.swift
//  HomePresentation
//
//  Created by euijjang97 on 11/25/26.
//

import SwiftUI

/// The first card owns the agenda. Its companions stack beside it or share the row below.
struct DeskCardLayout: Layout {
    enum Arrangement {
        case columns, rows, stack

        init(width: CGFloat) {
            self = width >= 960 ? .columns : width >= 620 ? .rows : .stack
        }
    }

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = max(0, proposal.width ?? 620)
        let frames = frames(width: width, subviews: subviews)
        return CGSize(width: width, height: frames.map(\.maxY).max() ?? 0)
    }

    func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()
    ) {
        for (view, frame) in zip(subviews, frames(width: bounds.width, subviews: subviews)) {
            view.place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY),
                       anchor: .topLeading, proposal: ProposedViewSize(frame.size))
        }
    }

    private func frames(width: CGFloat, subviews: Subviews) -> [CGRect] {
        guard let first = subviews.first else { return [] }
        let others = subviews.dropFirst()
        func height(_ view: LayoutSubview, _ width: CGFloat) -> CGFloat {
            view.sizeThatFits(ProposedViewSize(width: width, height: nil)).height
        }
        guard !others.isEmpty else {
            return [CGRect(x: 0, y: 0, width: width, height: height(first, width))]
        }
        switch Arrangement(width: width) {
        case .columns:
            let side = (width - 20) / 3
            let main = side * 2
            let sideHeights = others.map { height($0, side) }
            let gaps = CGFloat(others.count - 1) * 16
            let total = max(height(first, main), sideHeights.reduce(gaps, +))
            let extra = (total - gaps - sideHeights.reduce(0, +)) / CGFloat(others.count)
            var frames = [CGRect(x: 0, y: 0, width: main, height: total)]
            var y: CGFloat = 0
            for h in sideHeights {
                frames.append(CGRect(x: main + 20, y: y, width: side, height: h + extra))
                y += h + extra + 16
            }
            return frames
        case .rows:
            let h = height(first, width)
            let column = (width - CGFloat(others.count - 1) * 16) / CGFloat(others.count)
            let rowHeight = others.map { height($0, column) }.max() ?? 0
            return [CGRect(x: 0, y: 0, width: width, height: h)] + others.indices.enumerated().map {
                CGRect(x: CGFloat($0.offset) * (column + 16), y: h + 16,
                       width: column, height: rowHeight)
            }
        case .stack:
            var y: CGFloat = 0
            return subviews.map { view in
                let h = height(view, width)
                defer { y += h + 12 }
                return CGRect(x: 0, y: y, width: width, height: h)
            }
        }
    }
}
