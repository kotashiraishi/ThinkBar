import Foundation

/// Debug-only breakdown of conversation rendering during a switch.
public struct ConversationRenderingPerformanceReport: Equatable, Sendable {
    public enum Experiment: String, Equatable, Sendable {
        case normalMarkdown = "A: Normal markdown rendering"
        case plainAssistantText = "B: Plain Text(rawString) bypass"
    }

    public struct TurnTiming: Equatable, Sendable, Identifiable {
        public let id: UUID
        public let index: Int
        public let characterCount: Int
        public let usedFormatter: Bool
        public var markdownParse: Duration
        public var attributedStringCreation: Duration
        public var formatterTotal: Duration

        public init(
            id: UUID,
            index: Int,
            characterCount: Int,
            usedFormatter: Bool,
            markdownParse: Duration = .zero,
            attributedStringCreation: Duration = .zero,
            formatterTotal: Duration = .zero
        ) {
            self.id = id
            self.index = index
            self.characterCount = characterCount
            self.usedFormatter = usedFormatter
            self.markdownParse = markdownParse
            self.attributedStringCreation = attributedStringCreation
            self.formatterTotal = formatterTotal
        }
    }

    public let experiment: Experiment
    public let conversationID: UUID?
    public let conversationTitle: String
    public let visibleTurnCount: Int
    public let formattedTurnCount: Int
    public var turnTimings: [TurnTiming]
    public var markdownParseTotal: Duration
    public var attributedStringCreationTotal: Duration
    public var formatterTotal: Duration
    public var viewConstruction: Duration
    public var prepareVisibleTurns: Duration
    public var layoutFirstAppearance: Duration?
    public var firstRenderCompleted: Duration?

    public init(
        experiment: Experiment,
        conversationID: UUID?,
        conversationTitle: String,
        visibleTurnCount: Int,
        formattedTurnCount: Int,
        turnTimings: [TurnTiming] = [],
        markdownParseTotal: Duration = .zero,
        attributedStringCreationTotal: Duration = .zero,
        formatterTotal: Duration = .zero,
        viewConstruction: Duration = .zero,
        prepareVisibleTurns: Duration = .zero,
        layoutFirstAppearance: Duration? = nil,
        firstRenderCompleted: Duration? = nil
    ) {
        self.experiment = experiment
        self.conversationID = conversationID
        self.conversationTitle = conversationTitle
        self.visibleTurnCount = visibleTurnCount
        self.formattedTurnCount = formattedTurnCount
        self.turnTimings = turnTimings
        self.markdownParseTotal = markdownParseTotal
        self.attributedStringCreationTotal = attributedStringCreationTotal
        self.formatterTotal = formatterTotal
        self.viewConstruction = viewConstruction
        self.prepareVisibleTurns = prepareVisibleTurns
        self.layoutFirstAppearance = layoutFirstAppearance
        self.firstRenderCompleted = firstRenderCompleted
    }

    public var slowestTurn: TurnTiming? {
        turnTimings.max(by: { $0.formatterTotal < $1.formatterTotal })
    }

    public var formattedSummary: String {
        var lines = [
            "Conversation Rendering Performance",
            "",
            "Experiment: \(experiment.rawValue)",
            "Conversation: \(conversationTitle) (\(shortID(conversationID)))",
            "Visible turns: \(visibleTurnCount)",
            "Formatted turns: \(formattedTurnCount)",
            "",
            "Timings:",
            "- Markdown parse: \(format(markdownParseTotal))",
            "- AttributedString creation: \(format(attributedStringCreationTotal))",
            "- AssistantResponseFormatter total: \(format(formatterTotal))",
            "- View construction (display items): \(format(viewConstruction))",
            "- Prepare visible turns: \(format(prepareVisibleTurns))",
            "- Layout / first appearance: \(formatOptional(layoutFirstAppearance))",
            "- First render completed: \(formatOptional(firstRenderCompleted))",
        ]

        if let slowestTurn {
            lines.append("")
            lines.append("Slowest turn:")
            lines.append(
                "- Index: \(slowestTurn.index), id: \(shortID(slowestTurn.id)), chars: \(slowestTurn.characterCount)"
            )
            lines.append(
                "- Formatter: \(format(slowestTurn.formatterTotal)) (markdown \(format(slowestTurn.markdownParse)), attributed \(format(slowestTurn.attributedStringCreation)))"
            )
            lines.append(
                "- Used formatter: \(slowestTurn.usedFormatter ? "yes" : "no")"
            )
        }

        if !turnTimings.isEmpty {
            lines.append("")
            lines.append("Per-turn formatter timings:")
            for turn in turnTimings.sorted(by: { $0.formatterTotal > $1.formatterTotal }).prefix(5) {
                lines.append(
                    "- #\(turn.index) \(format(turn.formatterTotal)) (\(turn.characterCount) chars, formatter=\(turn.usedFormatter ? "yes" : "no"))"
                )
            }
        }

        return lines.joined(separator: "\n")
    }

    public func asDebugLogEntry() -> DebugLogEntry {
        DebugLogEntry(
            provider: "Performance",
            model: "Conversation Rendering",
            mode: Self.debugMode,
            generatedContext: "",
            userMessage: "\(experiment.rawValue) · \(conversationTitle)",
            attachmentContext: nil,
            conversationSummary: nil,
            providerResponse: formattedSummary
        )
    }

    public static let debugMode = "Conversation Rendering Performance"

    private func shortID(_ id: UUID?) -> String {
        guard let id else { return "none" }
        return String(id.uuidString.prefix(8))
    }

    private func format(_ duration: Duration) -> String {
        String(format: "%.1f ms", duration.milliseconds)
    }

    private func formatOptional(_ duration: Duration?) -> String {
        guard let duration else { return "n/a" }
        return format(duration)
    }
}
