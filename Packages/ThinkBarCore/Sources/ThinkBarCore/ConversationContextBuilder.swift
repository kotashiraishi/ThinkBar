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

public struct ConversationContextBuilder: Sendable {
    public let recentTurnLimit: Int

    public init(recentTurnLimit: Int = 5) {
        self.recentTurnLimit = max(1, recentTurnLimit)
    }

    public func build(
        from conversations: [ConversationRecord]
    ) -> ConversationContext {
        let summary = conversations.reversed().compactMap {
            normalizedSummary($0.context?.summary)
        }.first
        let recentTurns = conversations.suffix(recentTurnLimit).map {
            conversation in
            ConversationTurn(
                user: conversation.context?.request ?? conversation.user,
                assistant: conversation.assistant
            )
        }

        return ConversationContext(
            summary: summary,
            recentTurns: recentTurns
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
