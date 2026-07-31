import Testing
@testable import ThinkBarCore

struct ProviderConfigurationTests {
    @Test func storesOllamaConfigurationWithoutAPIKey() {
        let configuration = ProviderConfiguration(
            kind: .ollama,
            model: "gemma3:4b"
        )

        #expect(configuration.kind == .ollama)
        #expect(configuration.model == "gemma3:4b")
        #expect(configuration.apiKey == nil)
    }

    @Test func storesOpenRouterConfigurationWithAPIKey() {
        let configuration = ProviderConfiguration(
            kind: .openRouter,
            model: "openai/gpt-4o-mini",
            apiKey: "test-key"
        )

        #expect(configuration.kind == .openRouter)
        #expect(configuration.model == "openai/gpt-4o-mini")
        #expect(configuration.apiKey == "test-key")
    }
}
