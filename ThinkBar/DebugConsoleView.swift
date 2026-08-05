import SwiftUI
import ThinkBarCore

struct DebugConsoleView: View {
    @Environment(\.dismissWindow) private var dismissWindow
    @ObservedObject var debugLogService: DebugLogService

    var body: some View {
        Group {
            if debugLogService.isEnabled {
                VStack {
                    HStack {
                        Text("Debug Console")
                            .font(.headline)
                        Spacer()
                        Toggle(
                            "Experiment B: Plain assistant text",
                            isOn: $debugLogService.bypassAssistantMarkdown
                        )
                        .toggleStyle(.checkbox)
                        .help(
                            "Bypass Markdown/AttributedString and render assistant messages as Text(rawString)."
                        )
                        Menu("Test Data") {
                            Button("Load Long Conversation Sample") {
                                debugLogService.loadLongConversationSample()
                            }
                        }
                        Button("Clear") {
                            debugLogService.clear()
                        }
                        .disabled(debugLogService.entries.isEmpty)
                    }

                    if debugLogService.entries.isEmpty {
                        ContentUnavailableView(
                            "No Debug Logs",
                            systemImage: "terminal",
                            description: Text("Send a message to capture its AI context.")
                        )
                    } else {
                        List(debugLogService.entries) { entry in
                            DisclosureGroup {
                                debugDetails(for: entry)
                            } label: {
                                VStack(alignment: .leading) {
                                    if entry.mode == ConversationSwitchPerformanceReport.debugMode
                                        || entry.mode == ConversationRenderingPerformanceReport.debugMode {
                                        Text(entry.mode)
                                        Text(entry.userMessage)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    } else {
                                        Text("\(entry.provider) · \(entry.model)")
                                    }
                                    Text(entry.timestamp.formatted(
                                        date: .abbreviated,
                                        time: .standard
                                    ))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding()
            } else {
                ContentUnavailableView(
                    "Debug Mode is Off",
                    systemImage: "terminal",
                    description: Text("Enable Debug Mode in Settings.")
                )
            }
        }
        .frame(minWidth: 620, minHeight: 480)
        .onAppear {
            debugLogService.setEnabled(true)
        }
        .onDisappear {
            debugLogService.setEnabled(false)
        }
        .onChange(of: debugLogService.isEnabled) {
            dismissIfDisabled()
        }
    }

    @ViewBuilder
    private func debugDetails(for entry: DebugLogEntry) -> some View {
        if entry.mode == ConversationSwitchPerformanceReport.debugMode
            || entry.mode == ConversationRenderingPerformanceReport.debugMode {
            detail("Timestamp", entry.timestamp.formatted(
                date: .complete,
                time: .standard
            ))
            detail("Switch", entry.userMessage)
            detail("Report", entry.providerResponse)
        } else {
            detail("Timestamp", entry.timestamp.formatted(
                date: .complete,
                time: .standard
            ))
            detail("Provider", entry.provider)
            detail("Model", entry.model)
            detail("Mode", entry.mode)
            detail("Generated Context", entry.generatedContext)
            detail("User Message", entry.userMessage)
            detail("Attachment Context", entry.attachmentContext ?? "None")
            detail("Conversation Summary", entry.conversationSummary ?? "None")
            detail("Provider Response", entry.providerResponse)
            if let statistics = entry.contextStatistics {
                contextStatistics(
                    entry.conversationSummary == nil
                        ? "Context without Summary"
                        : "Context with Summary",
                    statistics
                )
            }
            if let statistics = entry.contextWithoutSummaryStatistics {
                contextStatistics(
                    "Context without Summary (Full History)",
                    statistics
                )
            }
            if entry.summaryGenerationTriggered {
                detail("Summary Generation Triggered", "Yes")
                detail("Previous Summary", entry.previousSummary ?? "None")
                detail("Generated Summary", entry.generatedSummary ?? "None")
                detail("Summary Update", entry.summaryUpdateStatus ?? "Unknown")
            }
        }
    }

    private func detail(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.body, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }

    private func contextStatistics(
        _ title: String,
        _ statistics: ConversationContextStatistics
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
            sizeRow("Summary", statistics.summary)
            VStack(alignment: .leading, spacing: 2) {
                Text("Recent History")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Turns: \(statistics.recentHistory.turns)")
                sizeValues(statistics.recentHistory.size)
            }
            sizeRow("Current Message", statistics.currentMessage)
            sizeRow("Total Context", statistics.total)
        }
        .font(.system(.body, design: .monospaced))
        .padding(.vertical, 8)
    }

    private func sizeRow(
        _ title: String,
        _ size: ContextSizeEstimate
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            sizeValues(size)
        }
    }

    private func sizeValues(_ size: ContextSizeEstimate) -> some View {
        Group {
            Text("Characters: \(size.characters)")
            Text("Estimated Tokens: ~\(size.estimatedTokens)")
        }
    }

    private func dismissIfDisabled() {
        if !debugLogService.isEnabled {
            dismissWindow(id: "debug-console")
        }
    }
}
