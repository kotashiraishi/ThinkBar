import Foundation

/// Controls how many conversation turns are presented in the UI.
/// Full history stays in memory; only the visible window grows incrementally.
public struct ConversationRenderingWindow: Equatable, Sendable {
    public static let initialVisibleCount = 30
    public static let pageSize = 20

    public private(set) var visibleCount: Int

    public init(visibleCount: Int = 0) {
        self.visibleCount = max(0, visibleCount)
    }

    public mutating func reset(totalCount: Int) {
        visibleCount = min(Self.initialVisibleCount, max(0, totalCount))
    }

    public func hiddenCount(totalCount: Int) -> Int {
        max(0, totalCount - visibleCount)
    }

    public func canRevealOlder(totalCount: Int) -> Bool {
        hiddenCount(totalCount: totalCount) > 0
    }

    public func visibleStartIndex(totalCount: Int) -> Int {
        max(0, totalCount - visibleCount)
    }

    /// Expands the window toward older turns. Returns how many turns were revealed.
    @discardableResult
    public mutating func revealOlder(totalCount: Int) -> Int {
        let hidden = hiddenCount(totalCount: totalCount)
        guard hidden > 0 else { return 0 }
        let added = min(Self.pageSize, hidden)
        visibleCount += added
        return added
    }

    /// Keeps the latest suffix in view when turns are appended or removed.
    public mutating func handleTotalCountChange(
        from oldCount: Int,
        to newCount: Int
    ) {
        if newCount <= 0 {
            visibleCount = 0
            return
        }

        if newCount < oldCount {
            visibleCount = min(visibleCount, newCount)
            return
        }

        if visibleCount >= oldCount {
            visibleCount = newCount
        }
    }
}
