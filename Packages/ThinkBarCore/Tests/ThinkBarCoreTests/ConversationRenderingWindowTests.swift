import Testing
@testable import ThinkBarCore

struct ConversationRenderingWindowTests {
    @Test func resetShowsAtMostInitialWindow() {
        var window = ConversationRenderingWindow()
        window.reset(totalCount: 100)

        #expect(window.visibleCount == ConversationRenderingWindow.initialVisibleCount)
        #expect(window.hiddenCount(totalCount: 100) == 70)
        #expect(window.visibleStartIndex(totalCount: 100) == 70)
    }

    @Test func resetDoesNotExceedTotalCount() {
        var window = ConversationRenderingWindow()
        window.reset(totalCount: 12)

        #expect(window.visibleCount == 12)
        #expect(window.canRevealOlder(totalCount: 12) == false)
    }

    @Test func revealOlderAddsPageSizedChunks() {
        var window = ConversationRenderingWindow()
        window.reset(totalCount: 75)

        let first = window.revealOlder(totalCount: 75)
        #expect(first == ConversationRenderingWindow.pageSize)
        #expect(window.visibleCount == 50)

        let second = window.revealOlder(totalCount: 75)
        #expect(second == ConversationRenderingWindow.pageSize)
        #expect(window.visibleCount == 70)

        let third = window.revealOlder(totalCount: 75)
        #expect(third == 5)
        #expect(window.visibleCount == 75)
        #expect(window.revealOlder(totalCount: 75) == 0)
    }

    @Test func appendingKeepsPartialWindowSizeButGrowsWhenFullyRevealed() {
        var window = ConversationRenderingWindow()
        window.reset(totalCount: 40)
        #expect(window.visibleCount == 30)

        window.handleTotalCountChange(from: 40, to: 41)
        #expect(window.visibleCount == 30)

        _ = window.revealOlder(totalCount: 41)
        #expect(window.visibleCount == 41)

        window.handleTotalCountChange(from: 41, to: 42)
        #expect(window.visibleCount == 42)
    }
}
