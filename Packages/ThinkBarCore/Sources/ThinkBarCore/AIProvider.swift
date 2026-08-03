import Foundation

public protocol AIProvider: Sendable {
    func ask(_ prompt: Prompt) async throws -> Response
    func stream(
        _ prompt: Prompt,
        onChunk: @escaping @Sendable (String) async -> Void
    ) async throws
    func stream(
        conversationContext: ConversationContext,
        mode: ConversationMode,
        onChunk: @escaping @Sendable (String) async -> Void
    ) async throws
}

public extension AIProvider {
    func stream(
        _ prompt: Prompt,
        onChunk: @escaping @Sendable (String) async -> Void
    ) async throws {
        let response = try await ask(prompt)
        await onChunk(response.text)
    }

    func stream(
        conversationContext: ConversationContext,
        mode: ConversationMode,
        onChunk: @escaping @Sendable (String) async -> Void
    ) async throws {
        let prompt = Prompt(
            text: conversationContext.recentTurns.last?.user ?? ""
        )
        try await stream(prompt, onChunk: onChunk)
    }
}
