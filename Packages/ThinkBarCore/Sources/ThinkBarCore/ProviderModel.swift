public struct ProviderModel: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String

    public init(id: String, title: String) {
        self.id = id
        self.title = title
    }
}

public enum ProviderModelCatalog {
    public static func models(for kind: ProviderKind) -> [ProviderModel] {
        switch kind {
        case .ollama:
            [
                ProviderModel(id: "gemma3:4b", title: "gemma3:4b"),
                ProviderModel(id: "llama3", title: "llama3"),
                ProviderModel(id: "qwen2", title: "qwen2"),
            ]
        case .openRouter:
            [
                ProviderModel(
                    id: "openai/gpt-4o-mini",
                    title: "OpenAI GPT-4o mini"
                ),
            ]
        }
    }

    public static func defaultModel(for kind: ProviderKind) -> ProviderModel {
        switch kind {
        case .ollama:
            ProviderModel(id: "gemma3:4b", title: "gemma3:4b")
        case .openRouter:
            ProviderModel(
                id: "openai/gpt-4o-mini",
                title: "OpenAI GPT-4o mini"
            )
        }
    }
}
