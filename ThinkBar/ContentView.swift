//
//  ContentView.swift
//  ThinkBar
//
//  Created by Kota Shiraishi on 2026/07/13.
//

import SwiftUI
import ThinkBarCore

struct ContentView: View {
    let provider: any AIProvider

    @State private var input = ""
    @State private var responseText = ""

    var body: some View {
        VStack {
            TextEditor(text: $input)
                .frame(height: 44)

            Button("Send") {
                Task { await send() }
            }

            Text(responseText)
        }
        .padding()
    }

    private func send() async {
        let response = try? await provider.ask(Prompt(text: input))
        responseText = response?.text ?? ""
    }
}

#Preview {
    ContentView(provider: FakeAIProvider())
}
