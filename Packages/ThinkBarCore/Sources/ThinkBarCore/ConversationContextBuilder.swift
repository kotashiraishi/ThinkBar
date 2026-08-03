import Foundation

public struct ConversationContext: Equatable, Sendable {
    public let summary: String?
    public let recentTurns: [ConversationTurn]

    public init(
        summary: String? = nil,
        recentTurns: [ConversationTurn]
    ) {
        self.summary = summary
        self.recentTurns = recentTurns
    }
}

public struct ConversationTurn: Equatable, Sendable {
    public let user: String
    public let assistant: String

    public init(user: String, assistant: String) {
        self.user = user
        self.assistant = assistant
    }
}

public struct ConversationContextBuildResult: Equatable, Sendable {
    public let context: ConversationContext
    public let statistics: ConversationContextStatistics
    public let contextWithoutSummaryStatistics:
        ConversationContextStatistics?

    public init(
        context: ConversationContext,
        statistics: ConversationContextStatistics,
        contextWithoutSummaryStatistics:
            ConversationContextStatistics? = nil
    ) {
        self.context = context
        self.statistics = statistics
        self.contextWithoutSummaryStatistics =
            contextWithoutSummaryStatistics
    }
}

public struct ConversationContextBuilder: Sendable {
    public let recentTurnLimit: Int
    private let tokenEstimator: ContextTokenEstimator

    public init(
        recentTurnLimit: Int = 5,
        tokenEstimator: ContextTokenEstimator = ContextTokenEstimator()
    ) {
        self.recentTurnLimit = max(1, recentTurnLimit)
        self.tokenEstimator = tokenEstimator
    }

    public func build(
        from conversations: [ConversationRecord]
    ) -> ConversationContext {
        buildWithStatistics(from: conversations).context
    }

    public func buildWithStatistics(
        from conversations: [ConversationRecord]
    ) -> ConversationContextBuildResult {
        let summary = conversations.reversed().compactMap {
            normalizedSummary($0.context?.summary)
        }.first
        let allTurns = conversations.map { turn(from: $0) }
        let context = ConversationContext(
            summary: summary,
            recentTurns: Array(allTurns.suffix(recentTurnLimit))
        )
        let contextWithoutSummaryStatistics = summary.map { _ in
            statistics(for: ConversationContext(
                recentTurns: allTurns
            ))
        }

        return ConversationContextBuildResult(
            context: context,
            statistics: statistics(for: context),
            contextWithoutSummaryStatistics:
                contextWithoutSummaryStatistics
        )
    }

    public func statistics(
        for context: ConversationContext
    ) -> ConversationContextStatistics {
        let summaryText = context.summary ?? ""
        let currentTurn = context.recentTurns.last
        let historyTurns = context.recentTurns.dropLast()
        let historyText = historyTurns.map {
            $0.user + $0.assistant
        }
        .joined()
        let currentText = (currentTurn?.user ?? "")
            + (currentTurn?.assistant ?? "")
        let totalText = summaryText + historyText + currentText

        return ConversationContextStatistics(
            summary: size(of: summaryText),
            recentHistory: ContextHistoryStatistics(
                turns: historyTurns.count,
                size: size(of: historyText)
            ),
            currentMessage: size(of: currentText),
            total: size(of: totalText)
        )
    }

    private func turn(
        from conversation: ConversationRecord
    ) -> ConversationTurn {
        ConversationTurn(
            user: conversation.context?.request ?? conversation.user,
            assistant: conversation.assistant
        )
    }

    private func size(of text: String) -> ContextSizeEstimate {
        ContextSizeEstimate(
            characters: text.count,
            estimatedTokens: tokenEstimator.estimateTokens(in: text)
        )
    }

    private func normalizedSummary(_ summary: String?) -> String? {
        guard let summary else { return nil }
        let normalized = summary.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return normalized.isEmpty ? nil : normalized
    }
}
