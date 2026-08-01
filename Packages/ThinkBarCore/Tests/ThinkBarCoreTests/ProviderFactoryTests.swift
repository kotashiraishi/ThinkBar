import Testing
@testable import ThinkBarCore

struct ProviderFactoryTests {
    @Test func createsOllamaProvider() {
        let configuration = ProviderConfiguration(
            kind: .ollama,
            model: "gemma3:4b"
        )

        let provider = ProviderFactory.makeProvider(from: configuration)

        #expect(provider is OllamaProvider)
    }

    @Test func createsOpenRouterProvider() {
        let configuration = ProviderConfiguration(
            kind: .openRouter,
            model: "openai/gpt-4o-mini",
            apiKey: "test-key"
        )

        let provider = ProviderFactory.makeProvider(from: configuration)

        #expect(provider is OpenRouterProvider)
    }

    @Test func createsModelDiscoveryOnlyForOllama() {
        let ollamaService = ProviderFactory.makeModelDiscoveryService(for: .ollama)
        let openRouterService = ProviderFactory.makeModelDiscoveryService(
            for: .openRouter
        )

        #expect(ollamaService is OllamaModelService)
        #expect(openRouterService == nil)
    }
}
