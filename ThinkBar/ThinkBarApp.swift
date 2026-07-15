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
    var body: some Scene {
        WindowGroup {
            ContentView(provider: FakeAIProvider())
        }
    }
}
