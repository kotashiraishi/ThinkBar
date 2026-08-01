import Testing
@testable import ThinkBarCore

struct ProviderModelTests {
    @Test func ollamaModelsAreAvailable() {
        #expect(ProviderModelCatalog.models(for: .ollama).map(\.id) == [
            "gemma3:4b",
            "llama3",
            "qwen2",
        ])
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
