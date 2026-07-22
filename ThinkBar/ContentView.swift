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
    @State private var conversations: [Conversation] = []
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

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(conversations) { conversation in
                            VStack(alignment: .leading) {
                                Text("User")
                                    .foregroundStyle(.secondary)
                                Text(conversation.user)
                                    .font(.title3)
                                    .textSelection(.enabled)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.secondary.opacity(0.08))
                            }

                            VStack(alignment: .leading) {
                                Text("Assistant")
                                    .foregroundStyle(.secondary)

                                if isThinking && conversation.id == conversations.last?.id {
                                    HStack {
                                        ProgressView()
                                        Text("Thinking...")
                                    }
                                    .font(.title3)
                                } else {
                                    Text(conversation.assistant)
                                        .font(.title3)
                                        .textSelection(.enabled)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.accentColor.opacity(0.08))
                            }
                        }

                        Color.clear
                            .frame(height: 1)
                            .id("responseBottom")
                    }
                }
                .onChange(of: conversations.count) {
                    proxy.scrollTo("responseBottom", anchor: .bottom)
                }
                .onChange(of: conversations.last?.assistant) {
                    proxy.scrollTo("responseBottom", anchor: .bottom)
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
        }
        .padding()
        .onReceive(NotificationCenter.default.publisher(for: .focusThinkBarInput)) { _ in
            isInputFocused = true
        }
    }

    private func send() async {
        guard !isSending else { return }

        let prompt = input
        let conversation = Conversation(user: prompt)
        conversations.append(conversation)
        input = ""
        isSending = true
        isThinking = true

        do {
            if let ollamaProvider = provider as? OllamaProvider {
                let buffer = StreamBuffer()
                let updateTask = Task { @MainActor in
                    while !Task.isCancelled {
                        try await Task.sleep(for: .milliseconds(75))
                        let bufferedText = await buffer.drain()

                        if !bufferedText.isEmpty {
                            isThinking = false
                            append(bufferedText, to: conversation.id)
                        }
                    }
                }

                do {
                    let history = conversations.map {
                        (user: $0.user, assistant: $0.assistant)
                    }
                    try await ollamaProvider.stream(conversationHistory: history) { chunk in
                        await buffer.append(chunk)
                    }
                } catch {
                    updateTask.cancel()
                    try? await updateTask.value
                    throw error
                }

                updateTask.cancel()
                try? await updateTask.value

                let remainingText = await buffer.drain()
                if !remainingText.isEmpty {
                    isThinking = false
                    append(remainingText, to: conversation.id)
                }
            } else {
                let response = try await provider.ask(Prompt(text: prompt))
                append(response.text, to: conversation.id)
            }
        } catch {
            input = prompt
            if conversations.last?.id == conversation.id {
                conversations.removeLast()
            }
        }

        isThinking = false
        isSending = false
        isInputFocused = true
    }

    private func append(_ text: String, to conversationID: UUID) {
        guard
            let index = conversations.indices.last,
            conversations[index].id == conversationID
        else { return }

        conversations[index].assistant += text
    }
}

#Preview {
    ContentView(provider: FakeAIProvider())
}

private struct Conversation: Identifiable {
    let id = UUID()
    let user: String
    var assistant = ""
}

private actor StreamBuffer {
    private var text = ""

    func append(_ chunk: String) {
        text += chunk
    }

    func drain() -> String {
        defer { text = "" }
        return text
    }
}
