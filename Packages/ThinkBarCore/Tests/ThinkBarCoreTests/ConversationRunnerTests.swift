import Testing
@testable import ThinkBarCore

struct ConversationRunnerTests {
    @Test func recordsGeneratedContextAndResponseWhenEnabled() async throws {
        let recorder = TestDebugLogRecorder(isEnabled: true)
        let runner = ConversationRunner(
            provider: RunnerProvider(),
            configuration: ProviderConfiguration(
                kind: .ollama,
                model: "gemma3:4b"
            ),
            debugLogRecorder: recorder
        )
        let conversations = [
            ConversationRecord(
                user: "Question",
                assistant: "",
                context: ConversationContextMetadata(
                    request: "Attachment\nQuestion",
                    attachmentContext: "Attachment\n",
                    summary: "Earlier summary"
                )
            ),
        ]

        try await runner.stream(
            conversations: conversations,
            mode: .general
        ) { _ in }

        let entry = try #require(await recorder.entries.first)
        #expect(entry.provider == "Ollama")
        #expect(entry.model == "gemma3:4b")
        #expect(entry.userMessage == "Question")
        #expect(entry.attachmentContext == "Attachment\n")
        #expect(entry.conversationSummary == "Earlier summary")
        #expect(entry.generatedContext.contains("Attachment\nQuestion"))
        #expect(entry.providerResponse == "Hello")
        #expect(entry.contextStatistics?.summary.characters == 15)
        #expect(entry.contextStatistics?.currentMessage.characters == 19)
        #expect(entry.contextWithoutSummaryStatistics != nil)
    }

    @Test func doesNotRecordWhenDisabled() async throws {
        let recorder = TestDebugLogRecorder(isEnabled: false)
        let runner = ConversationRunner(
            provider: RunnerProvider(),
            configuration: .defaultConfiguration(for: .ollama),
            debugLogRecorder: recorder
        )

        try await runner.stream(
            conversations: [
                ConversationRecord(user: "Question", assistant: ""),
            ],
            mode: .general
        ) { _ in }

        #expect(await recorder.entries.isEmpty)
    }
}

private struct RunnerProvider: AIProvider {
    func ask(_ prompt: Prompt) async throws -> Response {
        Response(text: "Hello")
    }

    func stream(
        conversationContext: ConversationContext,
        mode: ConversationMode,
        onChunk: @escaping @Sendable (String) async -> Void
    ) async throws {
        await onChunk("Hel")
        await onChunk("lo")
    }
}

private actor TestDebugLogRecorder: DebugLogRecording {
    let isEnabled: Bool
    private(set) var entries: [DebugLogEntry] = []

    init(isEnabled: Bool) {
        self.isEnabled = isEnabled
    }

    func loggingEnabled() async -> Bool {
        isEnabled
    }

    func record(_ entry: DebugLogEntry) async {
        entries.append(entry)
    }
}
