//
//  AdaptiveMasonryLayout.swift
//  Armory Inventory
//

import SwiftUI

struct AdaptiveMasonryLayout: Layout {
    let minimumColumnWidth: CGFloat
    let spacing: CGFloat

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) -> CGSize {
        makeLayout(width: proposal.width, subviews: subviews).size
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Void
    ) {
        let result = makeLayout(width: bounds.width, subviews: subviews)

        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y),
                anchor: .topLeading,
                proposal: ProposedViewSize(width: result.columnWidth, height: nil)
            )
        }
    }

    private func makeLayout(width proposedWidth: CGFloat?, subviews: Subviews) -> LayoutResult {
        let availableWidth: CGFloat
        if let proposedWidth, proposedWidth.isFinite, proposedWidth > 0 {
            availableWidth = proposedWidth
        } else {
            availableWidth = minimumColumnWidth
        }

        let columnCount = max(
            1,
            Int((availableWidth + spacing) / (minimumColumnWidth + spacing))
        )
        let columnWidth = (
            availableWidth - (CGFloat(columnCount - 1) * spacing)
        ) / CGFloat(columnCount)
        let subviewProposal = ProposedViewSize(width: columnWidth, height: nil)
        var columnHeights = Array(repeating: CGFloat.zero, count: columnCount)
        var origins: [CGPoint] = []
        origins.reserveCapacity(subviews.count)

        for subview in subviews {
            let column = columnHeights.indices.min {
                columnHeights[$0] < columnHeights[$1]
            } ?? 0
            let size = subview.sizeThatFits(subviewProposal)
            let origin = CGPoint(
                x: CGFloat(column) * (columnWidth + spacing),
                y: columnHeights[column]
            )
            origins.append(origin)
            columnHeights[column] += size.height + spacing
        }

        let height = max(0, (columnHeights.max() ?? spacing) - spacing)
        return LayoutResult(
            size: CGSize(width: availableWidth, height: height),
            columnWidth: columnWidth,
            origins: origins
        )
    }

    private struct LayoutResult {
        let size: CGSize
        let columnWidth: CGFloat
        let origins: [CGPoint]
    }
}
