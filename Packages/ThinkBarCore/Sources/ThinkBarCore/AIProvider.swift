import Foundation

public protocol AIProvider: Sendable {
    func ask(_ prompt: Prompt) async throws -> Response
    func stream(
        _ prompt: Prompt,
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
}
