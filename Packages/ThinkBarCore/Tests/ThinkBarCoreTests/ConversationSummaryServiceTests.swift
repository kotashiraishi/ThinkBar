import Testing
@testable import ThinkBarCore

struct ConversationSummaryServiceTests {
    @Test func shortConversationDoesNotTriggerSummary() async {
        let provider = SummaryProvider(result: .success("Summary"))
        let service = ConversationSummaryService(
            provider: provider,
            policy: ConversationSummaryPolicy(
                turnThreshold: 10,
                characterThreshold: 10_000
            )
        )

        let outcome = await service.updateIfNeeded(conversations: [
            conversation(1),
        ])

        #expect(outcome == .notTriggered)
        #expect(await provider.prompts.isEmpty)
    }

    @Test func turnThresholdGeneratesDurableMemorySummary() async throws {
        let provider = SummaryProvider(result: .success("Durable memory"))
        let service = ConversationSummaryService(
            provider: provider,
            policy: ConversationSummaryPolicy(
                turnThreshold: 2,
                characterThreshold: 10_000
            )
        )
        let conversations = [conversation(1), conversation(2)]

        let outcome = await service.updateIfNeeded(
            conversations: conversations
        )

        let update = try #require(updatedValue(from: outcome))
        #expect(update.summary == "Durable memory")
        #expect(update.coveredConversationCount == 2)
        #expect(update.trigger == .turnThreshold)
        let prompt = try #require(await provider.prompts.first)
        #expect(prompt.contains("continuing goals"))
        #expect(prompt.contains("Design or implementation decisions"))
        #expect(prompt.contains("Stable user preferences"))
        #expect(prompt.contains("One-off errors"))
        #expect(prompt.contains("Do not merely shorten"))
    }

    @Test func characterThresholdTriggersSummary() async throws {
        let provider = SummaryProvider(result: .success("Summary"))
        let service = ConversationSummaryService(
            provider: provider,
            policy: ConversationSummaryPolicy(
                turnThreshold: 10,
                characterThreshold: 5
            )
        )

        let outcome = await service.updateIfNeeded(conversations: [
            conversation(1),
        ])

        let update = try #require(updatedValue(from: outcome))
        #expect(update.trigger == .characterThreshold)
    }

    @Test func providerFailureKeepsPreviousSummary() async {
        let provider = SummaryProvider(result: .failure(SummaryTestError()))
        let service = ConversationSummaryService(
            provider: provider,
            policy: ConversationSummaryPolicy(
                turnThreshold: 1,
                characterThreshold: 10_000
            )
        )
        let conversations = [
            ConversationRecord(
                user: "Question",
                assistant: "Answer",
                context: ConversationContextMetadata(
                    summary: "Existing memory",
                    summaryCoveredConversationCount: 0
                )
            ),
        ]

        let outcome = await service.updateIfNeeded(
            conversations: conversations
        )

        guard case let .failed(previousSummary, _, _) = outcome else {
            Issue.record("Expected summary generation to fail.")
            return
        }
        #expect(previousSummary == "Existing memory")
    }

    @Test func updatesExistingSummaryWithOnlyUncoveredTurns() async throws {
        let provider = SummaryProvider(result: .success("Updated memory"))
        let service = ConversationSummaryService(
            provider: provider,
            policy: ConversationSummaryPolicy(
                turnThreshold: 1,
                characterThreshold: 10_000
            )
        )
        let conversations = [
            conversation(1),
            ConversationRecord(
                user: "User 2",
                assistant: "Assistant 2",
                context: ConversationContextMetadata(
                    summary: "Existing memory",
                    summaryCoveredConversationCount: 2
                )
            ),
            conversation(3),
        ]

        let outcome = await service.updateIfNeeded(
            conversations: conversations
        )

        let update = try #require(updatedValue(from: outcome))
        #expect(update.previousSummary == "Existing memory")
        #expect(update.coveredConversationCount == 3)
        let prompt = try #require(await provider.prompts.first)
        #expect(prompt.contains("Existing memory"))
        #expect(prompt.contains("User 3"))
        #expect(!prompt.contains("User 1"))
        #expect(!prompt.contains("User 2"))
    }

    private func conversation(_ index: Int) -> ConversationRecord {
        ConversationRecord(
            user: "User \(index)",
            assistant: "Assistant \(index)"
        )
    }

    private func updatedValue(
        from outcome: ConversationSummaryOutcome
    ) -> ConversationSummaryUpdate? {
        guard case let .updated(update) = outcome else { return nil }
        return update
    }
}

private struct SummaryTestError: Error {}

private actor SummaryProvider: AIProvider {
    let result: Result<String, Error>
    private(set) var prompts: [String] = []

    init(result: Result<String, Error>) {
        self.result = result
    }

    func ask(_ prompt: Prompt) async throws -> Response {
        prompts.append(prompt.text)
        return Response(text: try result.get())
    }
}
