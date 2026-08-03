import Foundation

public struct ConversationRunner: Sendable {
    private let provider: any AIProvider
    private let configuration: ProviderConfiguration
    private let contextBuilder: ConversationContextBuilder
    private let debugLogRecorder: (any DebugLogRecording)?

    public init(
        provider: any AIProvider,
        configuration: ProviderConfiguration,
        contextBuilder: ConversationContextBuilder = ConversationContextBuilder(),
        debugLogRecorder: (any DebugLogRecording)? = nil
    ) {
        self.provider = provider
        self.configuration = configuration
        self.contextBuilder = contextBuilder
        self.debugLogRecorder = debugLogRecorder
    }

    public func stream(
        conversations: [ConversationRecord],
        mode: ConversationMode,
        onChunk: @escaping @Sendable (String) async -> Void
    ) async throws {
        let context = contextBuilder.build(from: conversations)
        let loggingEnabled = await debugLogRecorder?.loggingEnabled() ?? false
        let responseBuffer = loggingEnabled ? DebugResponseBuffer() : nil

        do {
            try await provider.stream(
                conversationContext: context,
                mode: mode
            ) { chunk in
                if let responseBuffer {
                    await responseBuffer.append(chunk)
                }
                await onChunk(chunk)
            }
        } catch {
            if let responseBuffer {
                let response = await responseBuffer.text
                await record(
                    conversations: conversations,
                    context: context,
                    mode: mode,
                    response: response.isEmpty
                        ? "Error: \(error.localizedDescription)"
                        : "\(response)\n\nError: \(error.localizedDescription)"
                )
            }
            throw error
        }

        if let responseBuffer {
            await record(
                conversations: conversations,
                context: context,
                mode: mode,
                response: await responseBuffer.text
            )
        }
    }

    private func record(
        conversations: [ConversationRecord],
        context: ConversationContext,
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
            providerResponse: response
        ))
    }
}

private actor DebugResponseBuffer {
    private(set) var text = ""

    func append(_ chunk: String) {
        text += chunk
    }
}
