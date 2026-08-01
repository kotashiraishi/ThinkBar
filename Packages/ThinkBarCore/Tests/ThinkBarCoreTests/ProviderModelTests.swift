import Testing
@testable import ThinkBarCore

struct ProviderModelTests {
    @Test func ollamaModelsAreDiscoveredDynamically() {
        #expect(ProviderModelCatalog.models(for: .ollama).isEmpty)
        #expect(
            ProviderModelCatalog.defaultModel(for: .ollama).id
                == "gemma3:4b"
        )
    }

    @Test func openRouterModelsAreAvailable() {
        #expect(ProviderModelCatalog.models(for: .openRouter).map(\.id) == [
            "openai/gpt-4o-mini",
        ])
        #expect(
            ProviderModelCatalog.defaultModel(for: .openRouter).id
                == "openai/gpt-4o-mini"
        )
    }
}
