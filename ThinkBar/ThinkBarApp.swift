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
    @State private var providerConfiguration =
        ProviderConfiguration.defaultConfiguration(for: .ollama)
    private let settingsService = ProviderSettingsService()

#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
#endif

    var body: some Scene {
        WindowGroup {
            ContentView(
                provider: ProviderFactory.makeProvider(from: providerConfiguration)
            )
        }

        Settings {
            SettingsView(
                providerConfiguration: $providerConfiguration,
                settingsService: settingsService
            )
        }
    }
}
