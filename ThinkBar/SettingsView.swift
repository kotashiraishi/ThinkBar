import SwiftUI
import ThinkBarCore

struct SettingsView: View {
    @Binding var providerConfiguration: ProviderConfiguration

    let settingsService: ProviderSettingsService

    @State private var apiKey = ""
    @State private var statusMessage: String?

    var body: some View {
        Form {
            Section("Provider") {
                Picker("Provider", selection: Binding(
                    get: { providerConfiguration.kind },
                    set: { loadConfiguration(for: $0) }
                )) {
                    ForEach(ProviderKind.allCases) { kind in
                        Text(kind.title)
                            .tag(kind)
                    }
                }
            }

            Section("Model") {
                Picker("Model", selection: Binding(
                    get: { providerConfiguration.model },
                    set: { selectModel($0) }
                )) {
                    ForEach(ProviderModelCatalog.models(
                        for: providerConfiguration.kind
                    )) { model in
                        Text(model.title)
                            .tag(model.id)
                    }
                }
            }

            if providerConfiguration.kind == .openRouter {
                Section("OpenRouter") {
                    SecureField("API Key", text: $apiKey)

                    Button("Save API Key") {
                        saveOpenRouterAPIKey()
                    }
                }
            }

            if let statusMessage {
                Text(statusMessage)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding()
        .onAppear {
            loadConfiguration(for: providerConfiguration.kind)
        }
    }

    private func loadConfiguration(for kind: ProviderKind) {
        do {
            let loadedConfiguration = try settingsService.configuration(for: kind)
            let model = providerConfiguration.kind == kind
                ? providerConfiguration.model
                : loadedConfiguration.model
            providerConfiguration = ProviderConfiguration(
                kind: kind,
                model: model,
                apiKey: loadedConfiguration.apiKey
            )
            apiKey = loadedConfiguration.apiKey ?? ""
            statusMessage = nil
        } catch {
            providerConfiguration = .defaultConfiguration(for: kind)
            apiKey = ""
            statusMessage = error.localizedDescription
        }
    }

    private func selectModel(_ model: String) {
        providerConfiguration = ProviderConfiguration(
            kind: providerConfiguration.kind,
            model: model,
            apiKey: providerConfiguration.apiKey
        )
        statusMessage = nil
    }

    private func saveOpenRouterAPIKey() {
        let configuration = ProviderConfiguration(
            kind: .openRouter,
            model: providerConfiguration.model,
            apiKey: apiKey.isEmpty ? nil : apiKey
        )

        do {
            try settingsService.save(configuration)
            providerConfiguration = configuration
            statusMessage = "Saved"
        } catch {
            statusMessage = error.localizedDescription
        }
    }
}
