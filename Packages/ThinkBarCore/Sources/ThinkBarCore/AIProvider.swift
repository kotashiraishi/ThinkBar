import Foundation

public protocol AIProvider: Sendable {
    func ask(_ prompt: Prompt) async throws -> Response
}
