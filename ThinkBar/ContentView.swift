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
    @State private var lastPrompt = ""
    @State private var responseText = ""
    @State private var isSending = false
    @State private var isThinking = false
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

            if !lastPrompt.isEmpty {
                VStack(alignment: .leading) {
                    Text("You")
                        .foregroundStyle(.secondary)
                    Text(lastPrompt)
                        .font(.title3)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.08))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.secondary.opacity(0.2))
                }
            }

            ScrollView {
                if isThinking {
                    HStack {
                        ProgressView()
                        Text("Thinking...")
                    }
                    .font(.title3)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                } else {
                    Text(responseText)
                        .font(.title3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
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

        lastPrompt = input
        input = ""
        responseText = ""
        isSending = true
        isThinking = true

        do {
            if let ollamaProvider = provider as? OllamaProvider {
                try await ollamaProvider.stream(Prompt(text: lastPrompt)) { chunk in
                    await MainActor.run {
                        isThinking = false
                        responseText += chunk
                    }
                }
            } else {
                let response = try await provider.ask(Prompt(text: lastPrompt))
                responseText = response.text
            }
        } catch {
            input = lastPrompt
        }

        isThinking = false
        isSending = false
        isInputFocused = true
    }
}

#Preview {
    ContentView(provider: FakeAIProvider())
}
