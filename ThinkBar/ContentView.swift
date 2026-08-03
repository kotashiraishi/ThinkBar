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

    let conversationStore: ConversationStore
    let conversationRunner: ConversationRunner

    init(
        provider: any AIProvider,
        providerConfiguration: ProviderConfiguration =
            .defaultConfiguration(for: .ollama),
        conversationStore: ConversationStore = ConversationStore(),
        contextBuilder: ConversationContextBuilder = ConversationContextBuilder(),
        debugLogRecorder: (any DebugLogRecording)? = nil
    ) {
        self.conversationStore = conversationStore
        self.conversationRunner = ConversationRunner(
            provider: provider,
            configuration: providerConfiguration,
            contextBuilder: contextBuilder,
            debugLogRecorder: debugLogRecorder
        )
    }

    @State private var input = ""
    @State private var attachments: [Attachment] = []
    @State private var imageAttachments: [ImageAttachment] = []
    @State private var attachmentError: String?
    @State private var conversations: [Conversation] = []
    @State private var isSending = false
    @State private var isThinking = false
    @State private var selectedMode = ConversationMode.general
    @State private var inputFocusRequest = 0

    var body: some View {
        VStack {
            Picker("Mode", selection: $selectedMode) {
                ForEach(ConversationMode.builtIn) { mode in
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
                    VStack(alignment: .leading, spacing: 12) {
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
                                    .fixedSize(horizontal: false, vertical: true)
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

                                if let errorMessage = conversation.errorMessage {
                                    Label(errorMessage, systemImage: "exclamationmark.triangle")
                                        .font(.title3)
                                        .foregroundStyle(.red)
                                        .textSelection(.enabled)
                                        .fixedSize(horizontal: false, vertical: true)
                                } else if isThinking && conversation.id == conversations.last?.id {
                                    HStack {
                                        ProgressView()
                                        Text("Thinking...")
                                    }
                                    .font(.title3)
                                } else if let renderedAssistant = conversation.renderedAssistant {
                                    Text(renderedAssistant)
                                        .font(.title3)
                                        .textSelection(.enabled)
                                        .fixedSize(horizontal: false, vertical: true)
                                } else {
                                    Text(conversation.assistant)
                                        .font(.title3)
                                        .textSelection(.enabled)
                                        .fixedSize(horizontal: false, vertical: true)
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
        .task {
            loadConversations()
        }
    }

    private func send() async {
        guard !isSending else { return }

        let prompt = input
        let mode = selectedMode
        let attachmentContext = attachmentContext(
            attachment: attachments.first,
            imageAttachment: imageAttachments.first
        )
        let requestPrompt = requestPrompt(
            for: prompt,
            attachmentContext: attachmentContext
        )
        let conversation = Conversation(
            user: prompt,
            request: requestPrompt,
            attachmentContext: attachmentContext
        )
        conversations.append(conversation)
        input = ""
        isSending = true
        isThinking = true

        do {
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
                try await conversationRunner.stream(
                    conversations: conversationRecords(),
                    mode: mode,
                    onSummaryUpdate: { update in
                        await MainActor.run {
                            applySummaryUpdate(update)
                        }
                    }
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

            renderMarkdown(for: conversation.id)
            saveConversations()
            attachments.removeAll()
            imageAttachments.removeAll()
            attachmentError = nil
        } catch {
            input = prompt
            setError(error.localizedDescription, on: conversation.id)
        }

        isThinking = false
        isSending = false
        focusInput()
    }

    private func loadConversations() {
        guard conversations.isEmpty, let records = try? conversationStore.load() else {
            return
        }

        conversations = records.map { record in
            let renderedAssistant: AttributedString?
            if shouldRenderMarkdown(record.assistant) {
                renderedAssistant =
                    AssistantResponseFormatter.markdownPreservingWhitespace(
                        record.assistant
                    )
            } else {
                renderedAssistant = nil
            }
            return Conversation(
                id: record.id,
                user: record.user,
                request: record.context?.request ?? record.user,
                assistant: record.assistant,
                renderedAssistant: renderedAssistant,
                attachmentContext: record.context?.attachmentContext,
                contextSummary: record.context?.summary,
                summaryCoveredConversationCount:
                    record.context?.summaryCoveredConversationCount
            )
        }
    }

    private func saveConversations() {
        try? conversationStore.save(conversationRecords())
    }

    private func conversationRecords() -> [ConversationRecord] {
        conversations
            .filter { $0.errorMessage == nil }
            .map {
                ConversationRecord(
                    id: $0.id,
                    user: $0.user,
                    assistant: $0.assistant,
                    context: ConversationContextMetadata(
                        request: $0.request,
                        attachmentContext: $0.attachmentContext,
                        summary: $0.contextSummary,
                        summaryCoveredConversationCount:
                            $0.summaryCoveredConversationCount
                    )
                )
            }
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
        attachmentContext: String?
    ) -> String {
        guard let attachmentContext else { return question }
        return "\(attachmentContext)Question:\n\(question)"
    }

    private func attachmentContext(
        attachment: Attachment?,
        imageAttachment: ImageAttachment?
    ) -> String? {
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

        return context.isEmpty ? nil : context
    }

    private func append(_ text: String, to conversationID: UUID) {
        guard
            let index = conversations.indices.last,
            conversations[index].id == conversationID
        else { return }

        conversations[index].assistant += text
    }

    private func setError(_ message: String, on conversationID: UUID) {
        guard
            let index = conversations.indices.last,
            conversations[index].id == conversationID
        else { return }

        conversations[index].errorMessage = message
    }

    private func applySummaryUpdate(
        _ update: ConversationSummaryUpdate
    ) {
        guard let index = conversations.firstIndex(where: {
            $0.id == update.conversationID
        }) else { return }

        conversations[index].contextSummary = update.summary
        conversations[index].summaryCoveredConversationCount =
            update.coveredConversationCount
        saveConversations()
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

        conversations[index].renderedAssistant =
            AssistantResponseFormatter.markdownPreservingWhitespace(
                text
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
    let id: UUID
    let user: String
    let request: String
    var assistant: String
    var renderedAssistant: AttributedString?
    var errorMessage: String?
    var attachmentContext: String?
    var contextSummary: String?
    var summaryCoveredConversationCount: Int?

    init(
        id: UUID = UUID(),
        user: String,
        request: String,
        assistant: String = "",
        renderedAssistant: AttributedString? = nil,
        errorMessage: String? = nil,
        attachmentContext: String? = nil,
        contextSummary: String? = nil,
        summaryCoveredConversationCount: Int? = nil
    ) {
        self.id = id
        self.user = user
        self.request = request
        self.assistant = assistant
        self.renderedAssistant = renderedAssistant
        self.errorMessage = errorMessage
        self.attachmentContext = attachmentContext
        self.contextSummary = contextSummary
        self.summaryCoveredConversationCount =
            summaryCoveredConversationCount
    }
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
