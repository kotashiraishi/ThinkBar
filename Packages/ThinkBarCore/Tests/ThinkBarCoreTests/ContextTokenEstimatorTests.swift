import Testing
@testable import ThinkBarCore

struct ContextTokenEstimatorTests {
    @Test func estimatesMixedJapaneseAndEnglishText() {
        let estimator = ContextTokenEstimator()

        #expect(estimator.estimateTokens(in: "abcd") == 1)
        #expect(estimator.estimateTokens(in: "日本") == 2)
        #expect(estimator.estimateTokens(in: "ab日本") == 3)
        #expect(estimator.estimateTokens(in: "  \n") == 0)
    }

    @Test func contextStatisticsMatchBuiltProviderContext() {
        let longText = String(repeating: "context", count: 20)
        var conversations = (1...6).map { index in
            ConversationRecord(
                user: "\(index)-\(longText)",
                assistant: longText
            )
        }
        conversations[0] = ConversationRecord(
            id: conversations[0].id,
            user: conversations[0].user,
            assistant: conversations[0].assistant,
            context: ConversationContextMetadata(
                summary: "Durable summary",
                summaryCoveredConversationCount: 1
            )
        )
        let builder = ConversationContextBuilder(recentTurnLimit: 5)

        let result = builder.buildWithStatistics(
            from: conversations
        )

        #expect(result.context.recentTurns.count == 5)
        #expect(result.statistics.summary.characters == 15)
        #expect(result.statistics.recentHistory.turns == 4)
        #expect(
            result.statistics.total.characters
                < result.contextWithoutSummaryStatistics!.total.characters
        )
    }
}
