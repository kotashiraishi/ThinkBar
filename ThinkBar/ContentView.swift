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
    @State private var isNearBottom = true

    var body: some View {
        VStack {
            Picker("Mode", selection: $selectedMode) {
                ForEach(ConversationMode.builtIn) { mode in
                    Text(mode.title)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)

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
                            .id(ConversationScrollMetrics.bottomAnchorID)
                    }
                }
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    ConversationScrollMetrics.isNearBottom(geometry)
                } action: { _, newValue in
                    isNearBottom = newValue
                }
                .onChange(of: conversations.count) {
                    scrollConversationToBottom(using: proxy, force: true)
                }
                .onChange(of: conversations.last?.assistant) {
                    scrollConversationToBottom(using: proxy, force: false)
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

            ComposerView(
                input: $input,
                attachments: $attachments,
                imageAttachments: $imageAttachments,
                attachmentError: attachmentError,
                isSending: isSending,
                focusRequest: inputFocusRequest,
                onSend: {
                    Task { await send() }
                },
                onPasteImage: pasteImageFromClipboard
            )
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

    private func scrollConversationToBottom(
        using proxy: ScrollViewProxy,
        force: Bool
    ) {
        guard force || isNearBottom else { return }
        proxy.scrollTo(ConversationScrollMetrics.bottomAnchorID, anchor: .bottom)
        if force {
            isNearBottom = true
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
