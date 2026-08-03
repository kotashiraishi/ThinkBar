//
//  ThinkBarApp.swift
//  ThinkBar
//
//  Created by Kota Shiraishi on 2026/07/13.
//

import SwiftUI
import ThinkBarCore

@main
struct ThinkBarApp: App {
    @State private var providerConfiguration: ProviderConfiguration
    @StateObject private var debugLogService: DebugLogService
    private let settingsService: ProviderSettingsService

    init() {
        let settingsService = ProviderSettingsService()
        self.settingsService = settingsService
        _debugLogService = StateObject(wrappedValue: DebugLogService())
        _providerConfiguration = State(initialValue:
            (try? settingsService.configuration())
                ?? .defaultConfiguration(for: .ollama)
        )
    }

#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
#endif

    var body: some Scene {
        WindowGroup {
            ContentView(
                provider: ProviderFactory.makeProvider(from: providerConfiguration),
                providerConfiguration: providerConfiguration,
                debugLogRecorder: debugLogService
            )
        }
        .commands {
            DebugConsoleCommands(debugLogService: debugLogService)
        }

        Settings {
            SettingsView(
                providerConfiguration: $providerConfiguration,
                settingsService: settingsService,
                debugLogService: debugLogService
            )
        }

        Window("Debug Console", id: "debug-console") {
            DebugConsoleView(debugLogService: debugLogService)
        }
    }
}
