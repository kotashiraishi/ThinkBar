public struct ProviderSettingsService: Sendable {
    private static let openRouterAPIKey = "provider.openRouter.apiKey"
    private static let selectedKind = "provider.selected.kind"
    private static let selectedModel = "provider.selected.model"

    private let secretStorage: any SecretStorage

    public init(secretStorage: any SecretStorage = KeychainService()) {
        self.secretStorage = secretStorage
    }

    public func configuration() throws -> ProviderConfiguration {
        let storedKind = try secretStorage.load(key: Self.selectedKind)
        let kind = storedKind.flatMap(ProviderKind.init(rawValue:)) ?? .ollama
        let defaultConfiguration = ProviderConfiguration.defaultConfiguration(
            for: kind
        )

        return ProviderConfiguration(
            kind: kind,
            model: try secretStorage.load(key: Self.selectedModel)
                ?? defaultConfiguration.model,
            apiKey: try apiKey(for: kind)
        )
    }

    public func configuration(
        for kind: ProviderKind
    ) throws -> ProviderConfiguration {
        let configuration = ProviderConfiguration.defaultConfiguration(for: kind)
        guard kind == .openRouter else {
            return configuration
        }

        return ProviderConfiguration(
            kind: kind,
            model: configuration.model,
            apiKey: try apiKey(for: kind)
        )
    }

    public func save(_ configuration: ProviderConfiguration) throws {
        let previousKind = try secretStorage.load(key: Self.selectedKind)
        let previousModel = try secretStorage.load(key: Self.selectedModel)
        let previousAPIKey: String?
        if configuration.kind == .openRouter {
            previousAPIKey = try secretStorage.load(
                key: Self.openRouterAPIKey
            )
        } else {
            previousAPIKey = nil
        }

        do {
            if configuration.kind == .openRouter {
                try replaceValue(
                    configuration.apiKey,
                    for: Self.openRouterAPIKey
                )
            }

            try secretStorage.save(
                key: Self.selectedModel,
                value: configuration.model
            )
            try secretStorage.save(
                key: Self.selectedKind,
                value: configuration.kind.rawValue
            )
        } catch {
            try? replaceValue(previousModel, for: Self.selectedModel)
            try? replaceValue(previousKind, for: Self.selectedKind)
            if configuration.kind == .openRouter {
                try? replaceValue(
                    previousAPIKey,
                    for: Self.openRouterAPIKey
                )
            }
            throw error
        }
    }

    private func apiKey(for kind: ProviderKind) throws -> String? {
        guard kind == .openRouter else { return nil }
        return try secretStorage.load(key: Self.openRouterAPIKey)
    }

    private func replaceValue(_ value: String?, for key: String) throws {
        if let value, !value.isEmpty {
            try secretStorage.save(key: key, value: value)
        } else {
            try secretStorage.delete(key: key)
        }
    }
}
