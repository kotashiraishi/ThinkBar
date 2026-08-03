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
                                    Text("\(entry.provider) · \(entry.model)")
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
        if entry.summaryGenerationTriggered {
            detail("Summary Generation Triggered", "Yes")
            detail("Previous Summary", entry.previousSummary ?? "None")
            detail("Generated Summary", entry.generatedSummary ?? "None")
            detail("Summary Update", entry.summaryUpdateStatus ?? "Unknown")
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

    private func dismissIfDisabled() {
        if !debugLogService.isEnabled {
            dismissWindow(id: "debug-console")
        }
    }
}
