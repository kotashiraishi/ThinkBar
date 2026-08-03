import Foundation

public struct ConversationRunner: Sendable {
    private let provider: any AIProvider
    private let configuration: ProviderConfiguration
    private let contextBuilder: ConversationContextBuilder
    private let debugLogRecorder: (any DebugLogRecording)?
    private let summaryService: ConversationSummaryService

    public init(
        provider: any AIProvider,
        configuration: ProviderConfiguration,
        contextBuilder: ConversationContextBuilder = ConversationContextBuilder(),
        debugLogRecorder: (any DebugLogRecording)? = nil,
        summaryPolicy: ConversationSummaryPolicy = ConversationSummaryPolicy()
    ) {
        self.provider = provider
        self.configuration = configuration
        self.contextBuilder = contextBuilder
        self.debugLogRecorder = debugLogRecorder
        self.summaryService = ConversationSummaryService(
            provider: provider,
            policy: summaryPolicy
        )
    }

    public func stream(
        conversations: [ConversationRecord],
        mode: ConversationMode,
        onSummaryUpdate: @escaping @Sendable (
            ConversationSummaryUpdate
        ) async -> Void = { _ in },
        onChunk: @escaping @Sendable (String) async -> Void
    ) async throws {
        let buildResult = contextBuilder.buildWithStatistics(
            from: conversations
        )
        let context = buildResult.context
        let loggingEnabled = await debugLogRecorder?.loggingEnabled() ?? false
        let responseBuffer = DebugResponseBuffer()

        do {
            try await provider.stream(
                conversationContext: context,
                mode: mode
            ) { chunk in
                await responseBuffer.append(chunk)
                await onChunk(chunk)
            }
        } catch {
            if loggingEnabled {
                let response = await responseBuffer.text
                await record(
                    conversations: conversations,
                    context: context,
                    statistics: buildResult.statistics,
                    contextWithoutSummaryStatistics:
                        buildResult.contextWithoutSummaryStatistics,
                    mode: mode,
                    response: response.isEmpty
                        ? "Error: \(error.localizedDescription)"
                        : "\(response)\n\nError: \(error.localizedDescription)"
                )
            }
            throw error
        }

        let response = await responseBuffer.text
        if loggingEnabled {
            await record(
                conversations: conversations,
                context: context,
                statistics: buildResult.statistics,
                contextWithoutSummaryStatistics:
                    buildResult.contextWithoutSummaryStatistics,
                mode: mode,
                response: response
            )
        }

        let completedConversations = completingLatestConversation(
            in: conversations,
            with: response
        )
        let summaryService = self.summaryService
        let debugLogRecorder = self.debugLogRecorder
        let configuration = self.configuration
        Task {
            let outcome = await summaryService.updateIfNeeded(
                conversations: completedConversations
            )
            if case let .updated(update) = outcome {
                await onSummaryUpdate(update)
            }
            if loggingEnabled, let debugLogRecorder {
                await recordSummaryOutcome(
                    outcome,
                    conversations: completedConversations,
                    configuration: configuration,
                    debugLogRecorder: debugLogRecorder
                )
            }
        }
    }

    private func record(
        conversations: [ConversationRecord],
        context: ConversationContext,
        statistics: ConversationContextStatistics,
        contextWithoutSummaryStatistics:
            ConversationContextStatistics?,
        mode: ConversationMode,
        response: String
    ) async {
        guard let debugLogRecorder else { return }

        let latestConversation = conversations.last
        var generatedSections: [String] = []
        if let summary = context.summary {
            generatedSections.append(
                "Conversation Summary:\n\(summary)"
            )
        }
        generatedSections += context.recentTurns.enumerated().map {
            index, turn in
            """
            Turn \(index + 1)
            User: \(turn.user)
            Assistant: \(turn.assistant)
            """
        }
        let generatedContext = generatedSections.joined(separator: "\n\n")

        await debugLogRecorder.record(DebugLogEntry(
            provider: configuration.kind.title,
            model: configuration.model,
            mode: mode.title,
            generatedContext: generatedContext,
            userMessage: latestConversation?.user ?? "",
            attachmentContext: latestConversation?.context?.attachmentContext,
            conversationSummary: context.summary,
            providerResponse: response,
            contextStatistics: statistics,
            contextWithoutSummaryStatistics:
                contextWithoutSummaryStatistics
        ))
    }

    private func completingLatestConversation(
        in conversations: [ConversationRecord],
        with response: String
    ) -> [ConversationRecord] {
        guard let latest = conversations.last else { return conversations }

        var completed = conversations
        completed[completed.count - 1] = ConversationRecord(
            id: latest.id,
            user: latest.user,
            assistant: response,
            context: latest.context
        )
        return completed
    }

    private func recordSummaryOutcome(
        _ outcome: ConversationSummaryOutcome,
        conversations: [ConversationRecord],
        configuration: ProviderConfiguration,
        debugLogRecorder: any DebugLogRecording
    ) async {
        guard outcome != .notTriggered else { return }

        let previousSummary: String?
        let generatedSummary: String?
        let status: String
        switch outcome {
        case .notTriggered:
            return
        case let .updated(update):
            previousSummary = update.previousSummary
            generatedSummary = update.summary
            status = "Success (\(update.trigger.rawValue))"
        case let .failed(summary, trigger, errorDescription):
            previousSummary = summary
            generatedSummary = nil
            status = "Failed (\(trigger.rawValue)): \(errorDescription)"
        }

        await debugLogRecorder.record(DebugLogEntry(
            provider: configuration.kind.title,
            model: configuration.model,
            mode: "Conversation Summary",
            generatedContext: "",
            userMessage: conversations.last?.user ?? "",
            attachmentContext: nil,
            conversationSummary: previousSummary,
            providerResponse: "",
            summaryGenerationTriggered: true,
            previousSummary: previousSummary,
            generatedSummary: generatedSummary,
            summaryUpdateStatus: status
        ))
    }
}

private actor DebugResponseBuffer {
    private(set) var text = ""

    func append(_ chunk: String) {
        text += chunk
    }
}
