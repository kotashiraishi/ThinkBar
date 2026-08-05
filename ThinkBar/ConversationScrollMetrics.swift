import SwiftUI

/// Scroll-position helpers for conversation auto-follow.
/// Kept independent so future "New messages" UI can reuse the same near-bottom checks.
enum ConversationScrollMetrics {
    static let bottomAnchorID = "responseBottom"
    static let nearBottomThreshold: CGFloat = 48
    static let nearTopThreshold: CGFloat = 48

    static func isNearBottom(_ geometry: ScrollGeometry) -> Bool {
        isNearBottom(
            contentOffsetY: geometry.contentOffset.y,
            contentHeight: geometry.contentSize.height,
            containerHeight: geometry.containerSize.height,
            threshold: nearBottomThreshold
        )
    }

    static func isNearBottom(
        contentOffsetY: CGFloat,
        contentHeight: CGFloat,
        containerHeight: CGFloat,
        threshold: CGFloat = nearBottomThreshold
    ) -> Bool {
        let visibleBottom = contentOffsetY + containerHeight
        let distanceFromBottom = contentHeight - visibleBottom
        return distanceFromBottom <= threshold
    }

    static func isNearTop(_ geometry: ScrollGeometry) -> Bool {
        isNearTop(
            contentOffsetY: geometry.contentOffset.y,
            threshold: nearTopThreshold
        )
    }

    static func isNearTop(
        contentOffsetY: CGFloat,
        threshold: CGFloat = nearTopThreshold
    ) -> Bool {
        contentOffsetY <= threshold
    }
}
