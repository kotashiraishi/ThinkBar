import Foundation

public struct DebugLogEntry: Identifiable, Equatable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let provider: String
    public let model: String
    public let mode: String
    public let generatedContext: String
    public let userMessage: String
    public let attachmentContext: String?
    public let conversationSummary: String?
    public let providerResponse: String
    public let summaryGenerationTriggered: Bool
    public let previousSummary: String?
    public let generatedSummary: String?
    public let summaryUpdateStatus: String?
    public let contextStatistics: ConversationContextStatistics?
    public let contextWithoutSummaryStatistics:
        ConversationContextStatistics?

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        provider: String,
        model: String,
        mode: String,
        generatedContext: String,
        userMessage: String,
        attachmentContext: String?,
        conversationSummary: String?,
        providerResponse: String,
        summaryGenerationTriggered: Bool = false,
        previousSummary: String? = nil,
        generatedSummary: String? = nil,
        summaryUpdateStatus: String? = nil,
        contextStatistics: ConversationContextStatistics? = nil,
        contextWithoutSummaryStatistics:
            ConversationContextStatistics? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.provider = provider
        self.model = model
        self.mode = mode
        self.generatedContext = generatedContext
        self.userMessage = userMessage
        self.attachmentContext = attachmentContext
        self.conversationSummary = conversationSummary
        self.providerResponse = providerResponse
        self.summaryGenerationTriggered = summaryGenerationTriggered
        self.previousSummary = previousSummary
        self.generatedSummary = generatedSummary
        self.summaryUpdateStatus = summaryUpdateStatus
        self.contextStatistics = contextStatistics
        self.contextWithoutSummaryStatistics =
            contextWithoutSummaryStatistics
    }
}

public protocol DebugLogRecording: Sendable {
    func loggingEnabled() async -> Bool
    func record(_ entry: DebugLogEntry) async
}
