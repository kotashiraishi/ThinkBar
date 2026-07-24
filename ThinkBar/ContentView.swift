//
//  ContentView.swift
//  ThinkBar
//
//  Created by Kota Shiraishi on 2026/07/13.
//

import AppKit
import Foundation
import SwiftUI
import ThinkBarCore

struct ContentView: View {
    private static let supportedAttachmentExtensions: Set<String> = [
        "txt", "md", "swift", "php", "json", "log", "yaml", "yml", "xml",
    ]

    let provider: any AIProvider

    @State private var input = ""
    @State private var attachments: [Attachment] = []
    @State private var imageAttachments: [ImageAttachment] = []
    @State private var attachmentError: String?
    @State private var conversations: [Conversation] = []
    @State private var isSending = false
    @State private var isThinking = false
    @State private var selectedMode = OllamaProvider.Mode.general
    @State private var inputFocusRequest = 0

    var body: some View {
        VStack {
            Picker("Mode", selection: $selectedMode) {
                ForEach(OllamaProvider.Mode.builtIn) { mode in
                    Text(mode.title)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)

            ForEach(attachments) { attachment in
                HStack {
                    Text("📎 \(attachment.fileName)")
                    Spacer()
                    Button {
                        attachments.removeAll { $0.id == attachment.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .disabled(isSending)
                    .accessibilityLabel("Remove \(attachment.fileName)")
                }
            }

            ForEach(imageAttachments) { imageAttachment in
                HStack {
                    Text("🖼 Screenshot")
                    Spacer()
                    Button {
                        imageAttachments.removeAll { $0.id == imageAttachment.id }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .disabled(isSending)
                    .accessibilityLabel("Remove screenshot")
                }
            }

            if let attachmentError {
                Text(attachmentError)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            IMESafeTextEditor(
                text: $input,
                isEnabled: !isSending,
                focusRequest: inputFocusRequest,
                onSend: {
                    Task { await send() }
                },
                onPasteImage: pasteImageFromClipboard
            )
                .frame(height: 44)

            Button("Send") {
                Task { await send() }
            }
            .disabled(isSending)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(conversations) { conversation in
                            VStack(alignment: .leading) {
                                HStack {
                                    Text("User")
                                        .foregroundStyle(.secondary)
                                    Spacer()
                                    Button {
                                        edit(conversation.user)
                                    } label: {
                                        Image(systemName: "pencil")
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(isSending)
                                    .accessibilityLabel("Edit message")
                                }
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
                                } else if let renderedAssistant = conversation.renderedAssistant {
                                    Text(renderedAssistant)
                                        .font(.title3)
                                        .textSelection(.enabled)
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
        .contentShape(Rectangle())
        .dropDestination(for: URL.self) { urls, _ in
            loadAttachment(from: urls.first)
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusThinkBarInput)) { _ in
            focusInput()
        }
    }

    private func send() async {
        guard !isSending else { return }

        let prompt = input
        let mode = selectedMode
        let requestPrompt = requestPrompt(
            for: prompt,
            attachment: attachments.first,
            imageAttachment: imageAttachments.first
        )
        let conversation = Conversation(user: prompt, request: requestPrompt)
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
                        (user: $0.request, assistant: $0.assistant)
                    }
                    try await ollamaProvider.stream(
                        conversationHistory: history,
                        mode: mode
                    ) { chunk in
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
                let response = try await provider.ask(Prompt(text: requestPrompt))
                append(response.text, to: conversation.id)
            }

            renderMarkdown(for: conversation.id)
            attachments.removeAll()
            imageAttachments.removeAll()
            attachmentError = nil
        } catch {
            input = prompt
            if conversations.last?.id == conversation.id {
                conversations.removeLast()
            }
        }

        isThinking = false
        isSending = false
        focusInput()
    }

    private func edit(_ message: String) {
        guard !isSending else { return }

        input = message
        focusInput()
    }

    private func focusInput() {
        inputFocusRequest += 1
    }

    private func loadAttachment(from url: URL?) {
        guard !isSending, let url, url.isFileURL else { return }

        guard Self.supportedAttachmentExtensions.contains(url.pathExtension.lowercased()) else {
            attachmentError = "Unsupported file type: \(url.lastPathComponent)"
            return
        }

        do {
            let content = try String(contentsOf: url, encoding: .utf8)
            attachments = [
                Attachment(fileName: url.lastPathComponent, content: content)
            ]
            attachmentError = nil
        } catch {
            attachmentError = "Could not read \(url.lastPathComponent) as UTF-8."
        }
    }

    private func pasteImageFromClipboard() -> Bool {
        guard
            !isSending,
            let image = NSImage(pasteboard: .general)
        else { return false }

        imageAttachments = [ImageAttachment(image: image)]
        return true
    }

    private func requestPrompt(
        for question: String,
        attachment: Attachment?,
        imageAttachment: ImageAttachment?
    ) -> String {
        var context = ""

        if let attachment {
            context += """
            Attachment: \(attachment.fileName)

            \(attachment.content)

            ---

            """
        }

        if imageAttachment != nil {
            context += """
            Image attached:
            Screenshot

            """
        }

        guard !context.isEmpty else { return question }
        return "\(context)Question:\n\(question)"
    }

    private func append(_ text: String, to conversationID: UUID) {
        guard
            let index = conversations.indices.last,
            conversations[index].id == conversationID
        else { return }

        conversations[index].assistant += text
    }

    private func renderMarkdown(for conversationID: UUID) {
        guard
            let index = conversations.indices.last,
            conversations[index].id == conversationID
        else { return }

        let text = conversations[index].assistant
        guard shouldRenderMarkdown(text) else {
            conversations[index].renderedAssistant = nil
            return
        }

        conversations[index].renderedAssistant = try? AttributedString(
            markdown: text
        )
    }

    private func shouldRenderMarkdown(_ text: String) -> Bool {
        text.contains("```")
    }
}

private struct IMESafeTextEditor: NSViewRepresentable {
    @Binding var text: String

    let isEnabled: Bool
    let focusRequest: Int
    let onSend: () -> Void
    let onPasteImage: () -> Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let textView = SendingTextView()
        textView.delegate = context.coordinator
        textView.font = .systemFont(ofSize: 20)
        textView.isRichText = false
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.autoresizingMask = [.width]
        textView.textContainer?.widthTracksTextView = true
        textView.textContainerInset = NSSize(width: 4, height: 8)

        let scrollView = NSScrollView()
        scrollView.documentView = textView
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? SendingTextView else { return }

        if textView.string != text {
            textView.string = text
        }
        textView.isEditable = isEnabled
        textView.onSend = onSend
        textView.onPasteImage = onPasteImage

        if context.coordinator.lastFocusRequest != focusRequest {
            context.coordinator.lastFocusRequest = focusRequest
            scrollView.window?.makeFirstResponder(textView)
        }
    }

    final class Coordinator: NSObject, NSTextViewDelegate {
        private var text: Binding<String>
        var lastFocusRequest: Int?

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }
    }
}

private final class SendingTextView: NSTextView {
    private static let returnKeyCode: UInt16 = 36
    private static let keypadEnterKeyCode: UInt16 = 76

    var onSend: (() -> Void)?
    var onPasteImage: (() -> Bool)?

    override func keyDown(with event: NSEvent) {
        let isEnter = event.keyCode == Self.returnKeyCode
            || event.keyCode == Self.keypadEnterKeyCode
        guard isEnter, !hasMarkedText() else {
            super.keyDown(with: event)
            return
        }

        let modifiers = event.modifierFlags.intersection([
            .command, .control, .option, .shift,
        ])
        if (modifiers.isEmpty || modifiers == .command), let onSend {
            onSend()
            return
        }

        super.keyDown(with: event)
    }

    override func paste(_ sender: Any?) {
        if onPasteImage?() == true {
            return
        }
        super.paste(sender)
    }
}

#Preview {
    ContentView(provider: FakeAIProvider())
}

private struct Conversation: Identifiable {
    let id = UUID()
    let user: String
    let request: String
    var assistant = ""
    var renderedAssistant: AttributedString?
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
