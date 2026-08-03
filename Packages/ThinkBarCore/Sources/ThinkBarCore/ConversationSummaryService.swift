import Foundation

public struct ConversationSummaryPolicy: Equatable, Sendable {
    public let turnThreshold: Int
    public let characterThreshold: Int

    public init(
        turnThreshold: Int = 10,
        characterThreshold: Int = 12_000
    ) {
        self.turnThreshold = max(1, turnThreshold)
        self.characterThreshold = max(1, characterThreshold)
    }
}

public enum ConversationSummaryTrigger: String, Equatable, Sendable {
    case turnThreshold
    case characterThreshold
}

public struct ConversationSummaryUpdate: Equatable, Sendable {
    public let conversationID: UUID
    public let summary: String
    public let coveredConversationCount: Int
    public let previousSummary: String?
    public let trigger: ConversationSummaryTrigger

    public init(
        conversationID: UUID,
        summary: String,
        coveredConversationCount: Int,
        previousSummary: String?,
        trigger: ConversationSummaryTrigger
    ) {
        self.conversationID = conversationID
        self.summary = summary
        self.coveredConversationCount = coveredConversationCount
        self.previousSummary = previousSummary
        self.trigger = trigger
    }
}

public enum ConversationSummaryOutcome: Equatable, Sendable {
    case notTriggered
    case updated(ConversationSummaryUpdate)
    case failed(
        previousSummary: String?,
        trigger: ConversationSummaryTrigger,
        errorDescription: String
    )
}

public actor ConversationSummaryService {
    private let provider: any AIProvider
    private let policy: ConversationSummaryPolicy
    private var isGenerating = false

    public init(
        provider: any AIProvider,
        policy: ConversationSummaryPolicy = ConversationSummaryPolicy()
    ) {
        self.provider = provider
        self.policy = policy
    }

    public func updateIfNeeded(
        conversations: [ConversationRecord]
    ) async -> ConversationSummaryOutcome {
        guard !isGenerating else { return .notTriggered }

        let state = summaryState(in: conversations)
        let unsummarized = Array(conversations.dropFirst(state.coveredCount))
        guard
            !unsummarized.isEmpty,
            let trigger = trigger(for: unsummarized)
        else {
            return .notTriggered
        }

        isGenerating = true
        defer { isGenerating = false }

        do {
            let response = try await provider.ask(Prompt(text: summaryPrompt(
                existingSummary: state.summary,
                conversations: unsummarized
            )))
            let summary = response.text.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            guard !summary.isEmpty else {
                return .failed(
                    previousSummary: state.summary,
                    trigger: trigger,
                    errorDescription: "The provider returned an empty summary."
                )
            }
            guard let conversationID = conversations.last?.id else {
                return .notTriggered
            }

            return .updated(ConversationSummaryUpdate(
                conversationID: conversationID,
                summary: summary,
                coveredConversationCount: conversations.count,
                previousSummary: state.summary,
                trigger: trigger
            ))
        } catch {
            return .failed(
                previousSummary: state.summary,
                trigger: trigger,
                errorDescription: error.localizedDescription
            )
        }
    }

    private func summaryState(
        in conversations: [ConversationRecord]
    ) -> (summary: String?, coveredCount: Int) {
        for (index, conversation) in conversations.enumerated().reversed() {
            guard let rawSummary = conversation.context?.summary else {
                continue
            }
            let summary = rawSummary.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            guard
                !summary.isEmpty
            else { continue }

            let coveredCount =
                conversation.context?.summaryCoveredConversationCount
                ?? (index + 1)
            return (
                summary,
                min(max(0, coveredCount), conversations.count)
            )
        }
        return (nil, 0)
    }

    private func trigger(
        for conversations: [ConversationRecord]
    ) -> ConversationSummaryTrigger? {
        if conversations.count >= policy.turnThreshold {
            return .turnThreshold
        }

        let characterCount = conversations.reduce(into: 0) { count, item in
            count += (item.context?.request ?? item.user).count
            count += item.assistant.count
        }
        if characterCount >= policy.characterThreshold {
            return .characterThreshold
        }
        return nil
    }

    private func summaryPrompt(
        existingSummary: String?,
        conversations: [ConversationRecord]
    ) -> String {
        let recentConversation = conversations.map { conversation in
            """
            <User>
            \(conversation.context?.request ?? conversation.user)
            <Assistant>
            \(conversation.assistant)
            """
        }
        .joined(separator: "\n\n")

        return """
        You maintain durable user memory for a future assistant.
        This is not a conversation recap, meeting minutes, or transcript summary.
        Write what the future assistant needs to know about the user and their work.

        Focus on:
        - The user's continuing goals and what they are trying to achieve.
        - Active projects, product intent, and useful project context.
        - Important design or architectural decisions and their constraints.
        - Stable user preferences, requirements, and working constraints.
        - Background that will improve future responses.

        Write about the user and project state, not about what the AI said.
        Keep important decisions, but stay concise.
        Prefer describing the current state over chronological implementation history.
        Prefer stable facts that will remain useful in future conversations over temporary events.
        Describe capabilities and design decisions, not the steps taken to achieve them.

        Omit:
        - AI opinions, praise, evaluations, or self-commentary.
        - Generic advice or explanations.
        - Temporary small talk and one-off questions.
        - Resolved temporary problems and one-off errors.
        - Chronological conversation logs or turn-by-turn history.
        - Issue numbers and fine-grained implementation history.
        - Repeated details with no future value.

        Do not invent information. Return only the updated memory summary.

        Existing Summary:
        \(existingSummary ?? "None")

        Recent Conversation:
        \(recentConversation)
        """
    }
}
