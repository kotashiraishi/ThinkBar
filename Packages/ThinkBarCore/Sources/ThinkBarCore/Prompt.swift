import Foundation

public struct Prompt: Sendable {
    public let text: String

    public init(text: String) {
        self.text = text
    }
}
