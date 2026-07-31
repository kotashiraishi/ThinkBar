public enum ProviderKind: Sendable, Equatable {
    case ollama
    case openRouter
}

public struct ProviderConfiguration: Sendable, Equatable {
    public let kind: ProviderKind
    public let model: String
    public let apiKey: String?

    public init(
        kind: ProviderKind,
        model: String,
        apiKey: String? = nil
    ) {
        self.kind = kind
        self.model = model
        self.apiKey = apiKey
    }
}
