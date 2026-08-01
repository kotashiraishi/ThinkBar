import SwiftUI
import ThinkBarCore

struct SettingsView: View {
    @Binding var providerConfiguration: ProviderConfiguration

    let settingsService: ProviderSettingsService

    @State private var draftConfiguration: ProviderConfiguration
    @State private var draftAPIKey: String
    @State private var availableModels: [ProviderModel] = []
    @State private var isLoadingModels = false
    @State private var statusMessage: String?

    init(
        providerConfiguration: Binding<ProviderConfiguration>,
        settingsService: ProviderSettingsService
    ) {
        _providerConfiguration = providerConfiguration
        self.settingsService = settingsService
        _draftConfiguration = State(
            initialValue: providerConfiguration.wrappedValue
        )
        _draftAPIKey = State(
            initialValue: providerConfiguration.wrappedValue.apiKey ?? ""
        )
    }

    var body: some View {
        Form {
            Section("Provider") {
                Picker("Provider", selection: Binding(
                    get: { draftConfiguration.kind },
                    set: { selectProvider($0) }
                )) {
                    ForEach(ProviderKind.allCases) { kind in
                        Text(kind.title)
                            .tag(kind)
                    }
                }
            }

            Section("Model") {
                Picker("Model", selection: Binding(
                    get: { draftConfiguration.model },
                    set: { selectModel($0) }
                )) {
                    ForEach(availableModels) { model in
                        Text(model.title)
                            .tag(model.id)
                    }
                }

                if draftConfiguration.kind == .ollama {
                    HStack {
                        Button("Refresh") {
                            Task { await refreshOllamaModels() }
                        }
                        .disabled(isLoadingModels)

                        if isLoadingModels {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
            }

            if draftConfiguration.kind == .openRouter {
                Section("OpenRouter") {
                    SecureField("API Key", text: $draftAPIKey)
                }
            }

            Button("Save") {
                saveSettings()
            }

            if let statusMessage {
                Text(statusMessage)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 420)
        .padding()
        .task {
            resetDraft()
            if draftConfiguration.kind == .ollama {
                await refreshOllamaModels()
            }
        }
    }

    private func selectProvider(_ kind: ProviderKind) {
        loadConfiguration(for: kind)
        if kind == .ollama {
            Task { await refreshOllamaModels() }
        }
    }

    private func resetDraft() {
        draftConfiguration = providerConfiguration
        draftAPIKey = providerConfiguration.apiKey ?? ""
        availableModels = initialModels(
            for: providerConfiguration.kind,
            selectedModel: providerConfiguration.model
        )
        statusMessage = nil
    }

    private func loadConfiguration(for kind: ProviderKind) {
        do {
            let loadedConfiguration = try settingsService.configuration(for: kind)
            draftConfiguration = loadedConfiguration
            availableModels = initialModels(
                for: kind,
                selectedModel: loadedConfiguration.model
            )
            draftAPIKey = loadedConfiguration.apiKey ?? ""
            statusMessage = nil
        } catch {
            draftConfiguration = .defaultConfiguration(for: kind)
            availableModels = initialModels(
                for: kind,
                selectedModel: draftConfiguration.model
            )
            draftAPIKey = ""
            statusMessage = error.localizedDescription
        }
    }

    private func selectModel(_ model: String) {
        draftConfiguration = ProviderConfiguration(
            kind: draftConfiguration.kind,
            model: model,
            apiKey: draftConfiguration.apiKey
        )
        statusMessage = nil
    }

    private func refreshOllamaModels() async {
        guard
            draftConfiguration.kind == .ollama,
            !isLoadingModels,
            let modelService = ProviderFactory.makeModelDiscoveryService(for: .ollama)
        else { return }

        isLoadingModels = true
        defer { isLoadingModels = false }

        do {
            let models = try await modelService.models()
            guard draftConfiguration.kind == .ollama else { return }
            guard !models.isEmpty else {
                statusMessage = "No installed Ollama models found."
                return
            }

            availableModels = models
            if !models.contains(where: { $0.id == draftConfiguration.model }),
               let firstModel = models.first {
                selectModel(firstModel.id)
            }
            statusMessage = nil
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private func initialModels(
        for kind: ProviderKind,
        selectedModel: String
    ) -> [ProviderModel] {
        if kind == .ollama {
            return [
                ProviderModel(id: selectedModel, title: selectedModel),
            ]
        }
        return ProviderModelCatalog.models(for: kind)
    }

    private func saveSettings() {
        let configuration = ProviderConfiguration(
            kind: draftConfiguration.kind,
            model: draftConfiguration.model,
            apiKey: draftConfiguration.kind == .openRouter
                ? normalizedAPIKey
                : nil
        )

        do {
            try settingsService.save(configuration)
            providerConfiguration = configuration
            draftConfiguration = configuration
            statusMessage = "Saved"
        } catch {
            statusMessage = error.localizedDescription
        }
    }

    private var normalizedAPIKey: String? {
        let apiKey = draftAPIKey.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        return apiKey.isEmpty ? nil : apiKey
    }
}
