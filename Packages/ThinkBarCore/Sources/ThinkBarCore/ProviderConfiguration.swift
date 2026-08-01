public enum ProviderKind: String, CaseIterable, Hashable, Identifiable, Sendable {
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
            model: ProviderModelCatalog.defaultModel(for: kind).id
        )
    }
}
