//
//  ThinkBarApp.swift
//  ThinkBar
//
//  Created by Kota Shiraishi on 2026/07/13.
//

import Foundation
import SwiftUI
import ThinkBarCore

@main
struct ThinkBarApp: App {
#if os(macOS)
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
#endif

    var body: some Scene {
        WindowGroup {
            ContentView(provider: OllamaProvider(
                baseURL: URL(string: "http://localhost:11434")!,
                model: "gemma3:4b"
            ))
        }
    }
}
