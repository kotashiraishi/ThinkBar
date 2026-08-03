import Combine
import ThinkBarCore

@MainActor
final class DebugLogService: ObservableObject, DebugLogRecording {
    @Published private(set) var isEnabled = false
    @Published private(set) var entries: [DebugLogEntry] = []

    func loggingEnabled() async -> Bool {
        isEnabled
    }

    func record(_ entry: DebugLogEntry) async {
        guard isEnabled else { return }
        entries.insert(entry, at: 0)
    }

    func setEnabled(_ isEnabled: Bool) {
        guard self.isEnabled != isEnabled else { return }

        self.isEnabled = isEnabled
        if !isEnabled {
            clear()
        }
    }

    func clear() {
        entries.removeAll()
    }

    func loadLongConversationSample() {
        guard isEnabled else { return }

        let builder = ConversationContextBuilder()
        let result = builder.buildWithStatistics(
            from: DebugConversationSample.longConversation
        )
        var sections: [String] = []
        if let summary = result.context.summary {
            sections.append("Conversation Summary:\n\(summary)")
        }
        sections += result.context.recentTurns.enumerated().map {
            index, turn in
            """
            Turn \(index + 1)
            User: \(turn.user)
            Assistant: \(turn.assistant)
            """
        }

        entries.insert(DebugLogEntry(
            provider: "Test Data",
            model: "Long Conversation Sample",
            mode: "Context Visualization",
            generatedContext: sections.joined(separator: "\n\n"),
            userMessage: result.context.recentTurns.last?.user ?? "",
            attachmentContext: nil,
            conversationSummary: result.context.summary,
            providerResponse: "Sample data only",
            contextStatistics: result.statistics,
            contextWithoutSummaryStatistics:
                result.contextWithoutSummaryStatistics
        ), at: 0)
    }
}
