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

    @Test func savesAndRestoresSelectedProviderConfiguration() throws {
        let storage = MockSecretStorage()
        let service = ProviderSettingsService(secretStorage: storage)

        let configuration = ProviderConfiguration(
            kind: .ollama,
            model: "llama3.2:latest"
        )
        try service.save(configuration)
        let restoredConfiguration = try service.configuration()

        #expect(restoredConfiguration == configuration)
        #expect(storage.values["provider.openRouter.apiKey"] == nil)
    }

    @Test func failedSaveRestoresPreviousSettings() throws {
        let storage = MockSecretStorage()
        storage.values["provider.selected.kind"] = ProviderKind.ollama.rawValue
        storage.values["provider.selected.model"] = "gemma3:4b"
        storage.values["provider.openRouter.apiKey"] = "old-key"
        storage.failNextSaveForKey = "provider.selected.model"
        let service = ProviderSettingsService(secretStorage: storage)

        #expect(throws: MockSecretStorageError.self) {
            try service.save(ProviderConfiguration(
                kind: .openRouter,
                model: "openai/gpt-4o-mini",
                apiKey: "new-key"
            ))
        }

        #expect(storage.values["provider.selected.kind"] == "ollama")
        #expect(storage.values["provider.selected.model"] == "gemma3:4b")
        #expect(storage.values["provider.openRouter.apiKey"] == "old-key")
    }
}

private struct MockSecretStorageError: Error {}

private final class MockSecretStorage: SecretStorage, @unchecked Sendable {
    var values: [String: String] = [:]
    var failNextSaveForKey: String?

    func save(key: String, value: String) throws {
        if failNextSaveForKey == key {
            failNextSaveForKey = nil
            throw MockSecretStorageError()
        }
        values[key] = value
    }

    func load(key: String) throws -> String? {
        values[key]
    }

    func delete(key: String) throws {
        values[key] = nil
    }
}
