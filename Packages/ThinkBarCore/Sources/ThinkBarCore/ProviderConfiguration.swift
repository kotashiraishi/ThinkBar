public enum ProviderKind: CaseIterable, Hashable, Identifiable, Sendable {
    case ollama
    case openRouter

    public var id: Self { self }

    public var title: String {
        switch self {
        case .ollama:
            "Ollama"
        case .openRouter:
            "OpenRouter"
        }
    }

    fileprivate var defaultModel: String {
        switch self {
        case .ollama:
            "gemma3:4b"
        case .openRouter:
            "openai/gpt-4o-mini"
        }
    }
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

    public static func defaultConfiguration(
        for kind: ProviderKind
    ) -> ProviderConfiguration {
        ProviderConfiguration(
            kind: kind,
            model: kind.defaultModel
        )
    }
}
