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
    var body: some Scene {
        WindowGroup {
            ContentView(provider: OllamaProvider(
                baseURL: URL(string: "http://localhost:11434")!,
                model: "gemma3:4b"
            ))
        }
    }
}
