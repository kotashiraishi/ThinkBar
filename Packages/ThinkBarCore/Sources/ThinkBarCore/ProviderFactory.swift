import Foundation

public enum ProviderFactory {
    private static let ollamaBaseURL = URL(string: "http://localhost:11434")!

    public static func makeProvider(
        from configuration: ProviderConfiguration
    ) -> any AIProvider {
        switch configuration.kind {
        case .ollama:
            OllamaProvider(
                baseURL: ollamaBaseURL,
                model: configuration.model
            )
        case .openRouter:
            OpenRouterProvider(
                apiKey: configuration.apiKey ?? OpenRouterProvider.defaultAPIKey,
                model: configuration.model
            )
        }
    }

    public static func makeModelDiscoveryService(
        for kind: ProviderKind
    ) -> (any ProviderModelDiscovering)? {
        switch kind {
        case .ollama:
            OllamaModelService(baseURL: ollamaBaseURL)
        case .openRouter:
            nil
        }
    }
}
