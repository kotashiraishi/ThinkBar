import Testing
@testable import ThinkBarCore

struct ProviderSettingsServiceTests {
    @Test func loadsOpenRouterAPIKeyIntoConfiguration() throws {
        let storage = MockSecretStorage()
        storage.values["provider.openRouter.apiKey"] = "saved-key"
        let service = ProviderSettingsService(secretStorage: storage)

        let configuration = try service.configuration(for: .openRouter)

        #expect(configuration.kind == .openRouter)
        #expect(configuration.model == "openai/gpt-4o-mini")
        #expect(configuration.apiKey == "saved-key")
    }

    @Test func savesAndDeletesOpenRouterAPIKey() throws {
        let storage = MockSecretStorage()
        let service = ProviderSettingsService(secretStorage: storage)

        try service.save(ProviderConfiguration(
            kind: .openRouter,
            model: "openai/gpt-4o-mini",
            apiKey: "new-key"
        ))
        #expect(storage.values["provider.openRouter.apiKey"] == "new-key")

        try service.save(ProviderConfiguration(
            kind: .openRouter,
            model: "openai/gpt-4o-mini"
        ))
        #expect(storage.values["provider.openRouter.apiKey"] == nil)
    }

    @Test func ollamaConfigurationDoesNotUseSecretStorage() throws {
        let storage = MockSecretStorage()
        let service = ProviderSettingsService(secretStorage: storage)

        let configuration = try service.configuration(for: .ollama)
        try service.save(configuration)

        #expect(configuration.apiKey == nil)
        #expect(storage.values.isEmpty)
    }
}

private final class MockSecretStorage: SecretStorage, @unchecked Sendable {
    var values: [String: String] = [:]

    func save(key: String, value: String) throws {
        values[key] = value
    }

    func load(key: String) throws -> String? {
        values[key]
    }

    func delete(key: String) throws {
        values[key] = nil
    }
}
