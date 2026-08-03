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
        providerResponse: String
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
    }
}

public protocol DebugLogRecording: Sendable {
    func loggingEnabled() async -> Bool
    func record(_ entry: DebugLogEntry) async
}
