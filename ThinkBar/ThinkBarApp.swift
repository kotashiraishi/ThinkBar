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
    private let provider = ProviderFactory.makeProvider(from: ProviderConfiguration(
        kind: .ollama,
        model: "gemma3:4b"
    ))

#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
#endif

    var body: some Scene {
        WindowGroup {
            ContentView(provider: provider)
        }
    }
}
