import Foundation

public struct FakeAIProvider: AIProvider {
    public init() {}

    public func ask(_ prompt: Prompt) async throws -> Response {
        Response(text: "Hello ThinkBar")
    }
}
