import Foundation

public struct Response: Sendable {
    public let text: String

    public init(text: String) {
        self.text = text
    }
}
