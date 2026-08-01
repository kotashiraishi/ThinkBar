public struct ProviderSettingsService: Sendable {
    private static let openRouterAPIKey = "provider.openRouter.apiKey"

    private let secretStorage: any SecretStorage

    public init(secretStorage: any SecretStorage = KeychainService()) {
        self.secretStorage = secretStorage
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
            apiKey: try secretStorage.load(key: Self.openRouterAPIKey)
        )
    }

    public func save(_ configuration: ProviderConfiguration) throws {
        guard configuration.kind == .openRouter else { return }

        if let apiKey = configuration.apiKey, !apiKey.isEmpty {
            try secretStorage.save(
                key: Self.openRouterAPIKey,
                value: apiKey
            )
        } else {
            try secretStorage.delete(key: Self.openRouterAPIKey)
        }
    }
}
