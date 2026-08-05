import Foundation

/// Timing breakdown for a conversation switch. Safe to keep as debug-only instrumentation.
public struct ConversationSwitchPerformanceReport: Equatable, Sendable {
    public struct Timings: Equatable, Sendable {
        public var saveCurrentConversation: Duration
        public var encodeSnapshot: Duration
        public var writeSnapshotFile: Duration
        public var activateConversation: Duration
        public var retrieveConversation: Duration
        public var buildDisplayItems: Duration
        public var prepareVisibleTurns: Duration
        public var uiStateUpdateRequested: Duration
        public var firstRenderCompleted: Duration?
        public var total: Duration

        public init(
            saveCurrentConversation: Duration = .zero,
            encodeSnapshot: Duration = .zero,
            writeSnapshotFile: Duration = .zero,
            activateConversation: Duration = .zero,
            retrieveConversation: Duration = .zero,
            buildDisplayItems: Duration = .zero,
            prepareVisibleTurns: Duration = .zero,
            uiStateUpdateRequested: Duration = .zero,
            firstRenderCompleted: Duration? = nil,
            total: Duration = .zero
        ) {
            self.saveCurrentConversation = saveCurrentConversation
            self.encodeSnapshot = encodeSnapshot
            self.writeSnapshotFile = writeSnapshotFile
            self.activateConversation = activateConversation
            self.retrieveConversation = retrieveConversation
            self.buildDisplayItems = buildDisplayItems
            self.prepareVisibleTurns = prepareVisibleTurns
            self.uiStateUpdateRequested = uiStateUpdateRequested
            self.firstRenderCompleted = firstRenderCompleted
            self.total = total
        }
    }

    public let sourceConversationID: UUID?
    public let destinationConversationID: UUID?
    public let sourceTitle: String
    public let destinationTitle: String
    public let totalConversations: Int
    public let totalTurnsInSnapshot: Int
    public let sourceTurns: Int
    public let destinationTurns: Int
    public let destinationVisibleTurns: Int
    public let destinationCharacterCount: Int
    public var timings: Timings

    public init(
        sourceConversationID: UUID?,
        destinationConversationID: UUID?,
        sourceTitle: String,
        destinationTitle: String,
        totalConversations: Int,
        totalTurnsInSnapshot: Int,
        sourceTurns: Int,
        destinationTurns: Int,
        destinationVisibleTurns: Int,
        destinationCharacterCount: Int,
        timings: Timings
    ) {
        self.sourceConversationID = sourceConversationID
        self.destinationConversationID = destinationConversationID
        self.sourceTitle = sourceTitle
        self.destinationTitle = destinationTitle
        self.totalConversations = totalConversations
        self.totalTurnsInSnapshot = totalTurnsInSnapshot
        self.sourceTurns = sourceTurns
        self.destinationTurns = destinationTurns
        self.destinationVisibleTurns = destinationVisibleTurns
        self.destinationCharacterCount = destinationCharacterCount
        self.timings = timings
    }

    public var formattedSummary: String {
        var lines = [
            "Conversation Switch Performance",
            "",
            "Source Conversation: \(sourceTitle) (\(shortID(sourceConversationID)))",
            "Destination Conversation: \(destinationTitle) (\(shortID(destinationConversationID)))",
            "Total conversations: \(totalConversations)",
            "Total turns in snapshot: \(totalTurnsInSnapshot)",
            "Source turns: \(sourceTurns)",
            "Destination turns: \(destinationTurns)",
            "Destination visible turns: \(destinationVisibleTurns)",
            "Destination characters: \(destinationCharacterCount)",
            "",
            "Timings:",
            "- Save current conversation: \(format(timings.saveCurrentConversation))",
            "- Encode snapshot: \(format(timings.encodeSnapshot))",
            "- Write snapshot file: \(format(timings.writeSnapshotFile))",
            "- Activate conversation: \(format(timings.activateConversation))",
            "- Retrieve conversation: \(format(timings.retrieveConversation))",
            "- Build display items: \(format(timings.buildDisplayItems))",
            "- Prepare visible turns: \(format(timings.prepareVisibleTurns))",
            "- UI state update requested: \(format(timings.uiStateUpdateRequested))",
        ]
        if let firstRenderCompleted = timings.firstRenderCompleted {
            lines.append(
                "- First render completed: \(format(firstRenderCompleted))"
            )
        } else {
            lines.append("- First render completed: n/a")
        }
        lines.append("- Total: \(format(timings.total))")
        return lines.joined(separator: "\n")
    }

    public func asDebugLogEntry() -> DebugLogEntry {
        DebugLogEntry(
            provider: "Performance",
            model: "Conversation Switch",
            mode: Self.debugMode,
            generatedContext: "",
            userMessage: "\(sourceTitle) → \(destinationTitle)",
            attachmentContext: nil,
            conversationSummary: nil,
            providerResponse: formattedSummary
        )
    }

    public static let debugMode = "Conversation Switch Performance"

    private func shortID(_ id: UUID?) -> String {
        guard let id else { return "none" }
        return String(id.uuidString.prefix(8))
    }

    private func format(_ duration: Duration) -> String {
        let milliseconds = duration.milliseconds
        return String(format: "%.1f ms", milliseconds)
    }
}

public extension Duration {
    var milliseconds: Double {
        let components = self.components
        return Double(components.seconds) * 1_000
            + Double(components.attoseconds) / 1_000_000_000_000_000
    }
}

/// Lightweight ContinuousClock stopwatch for conversation-switch instrumentation.
public struct ConversationSwitchStopwatch: Sendable {
    private let clock = ContinuousClock()
    private let startedAt: ContinuousClock.Instant

    public init() {
        startedAt = clock.now
    }

    public func elapsed() -> Duration {
        clock.now - startedAt
    }

    public func measure(_ work: () throws -> Void) rethrows -> Duration {
        let start = clock.now
        try work()
        return clock.now - start
    }

    public func measure<T>(_ work: () throws -> T) rethrows -> (T, Duration) {
        let start = clock.now
        let value = try work()
        return (value, clock.now - start)
    }
}
