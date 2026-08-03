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
        You maintain durable conversation memory for future AI responses.
        Do not merely shorten the full transcript.

        Preserve:
        - The user's continuing goals and ongoing tasks.
        - Active project names, technologies, and relevant project context.
        - Design or implementation decisions already made and their constraints.
        - Stable user preferences, requirements, and working constraints.

        Omit:
        - Temporary small talk.
        - One-off errors that have already been resolved.
        - Repeated explanations and details with no future value.

        Write a concise, factual memory that improves future response quality.
        Do not invent information. Return only the updated summary.

        Existing Summary:
        \(existingSummary ?? "None")

        Recent Conversation:
        \(recentConversation)
        """
    }
}
