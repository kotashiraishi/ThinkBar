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
    @State private var isSending = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack {
            TextEditor(text: $input)
                .font(.title3)
                .frame(height: 44)
                .focused($isInputFocused)
                .disabled(isSending)

            Button("Send") {
                Task { await send() }
            }
            .disabled(isSending)

            ScrollView {
                Text(responseText)
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .frame(maxHeight: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.08))
            }
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2))
            }
        }
        .padding()
    }

    private func send() async {
        guard !isSending else { return }

        isSending = true

        do {
            let response = try await provider.ask(Prompt(text: input))
            responseText = response.text
            input = ""
        } catch {
            // Keep the input unchanged so the user can retry.
        }

        isSending = false
        isInputFocused = true
    }
}

#Preview {
    ContentView(provider: FakeAIProvider())
}
