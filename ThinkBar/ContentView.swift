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
    private let debugLogRecorder: (any DebugLogRecording)?
    @ObservedObject private var debugLogService: DebugLogService
    @ObservedObject private var conversationActionState: ConversationActionState

    init(
        provider: any AIProvider,
        providerConfiguration: ProviderConfiguration =
            .defaultConfiguration(for: .ollama),
        conversationStore: ConversationStore = ConversationStore(),
        contextBuilder: ConversationContextBuilder = ConversationContextBuilder(),
        debugLogService: DebugLogService,
        conversationActionState: ConversationActionState
    ) {
        self.conversationStore = conversationStore
        self.debugLogService = debugLogService
        self.debugLogRecorder = debugLogService
        self.conversationRunner = ConversationRunner(
            provider: provider,
            configuration: providerConfiguration,
            contextBuilder: contextBuilder,
            debugLogRecorder: debugLogService
        )
        self.conversationActionState = conversationActionState
    }

    @State private var input = ""
    @State private var attachments: [Attachment] = []
    @State private var imageAttachments: [ImageAttachment] = []
    @State private var attachmentError: String?
    @State private var conversations: [ConversationItem] = []
    @State private var conversationSnapshot = ConversationStoreSnapshot.empty
    @State private var renderingWindow = ConversationRenderingWindow()
    @State private var isSending = false
    @State private var isThinking = false
    @State private var selectedMode = ConversationMode.general
    @State private var inputFocusRequest = 0
    @State private var isNearBottom = true
    @State private var showDiscardComposerConfirmation = false
    @State private var pendingNavigation: PendingConversationNavigation?
    @State private var pendingRenderingReport: ConversationRenderingPerformanceReport?
    @State private var layoutProbeStartedAt: ContinuousClock.Instant?

    private enum PendingConversationNavigation: Equatable {
        case select(UUID)
        case newConversation
    }

    private var visibleConversations: [ConversationItem] {
        let start = renderingWindow.visibleStartIndex(
            totalCount: conversations.count
        )
        guard start < conversations.count else { return [] }
        return Array(conversations[start...])
    }

    private var sidebarItems: [ConversationSidebarItem] {
        let activeID = conversationSnapshot.activeConversationID
            ?? conversationSnapshot.activeConversation?.id
        return conversationSnapshot.conversationsSortedByUpdatedAt.map { conversation in
            ConversationSidebarItem(
                id: conversation.id,
                title: conversation.title,
                updatedAt: conversation.updatedAt,
                isActive: conversation.id == activeID
            )
        }
    }

    private var hasUnsavedComposerContent: Bool {
        !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || !attachments.isEmpty
            || !imageAttachments.isEmpty
    }

    private var canStartNewConversation: Bool {
        conversationSnapshot.canStartNewConversation && canSelectConversation
    }

    private var canSelectConversation: Bool {
        !isSending
    }

    var body: some View {
        NavigationSplitView {
            ConversationSidebarView(
                items: sidebarItems,
                selectedConversationID: conversationSnapshot.activeConversationID
                    ?? conversationSnapshot.activeConversation?.id,
                canSelectConversation: canSelectConversation,
                canStartNewConversation: canStartNewConversation,
                onSelect: requestSelectConversation,
                onNewConversation: requestStartNewConversation
            )
        } detail: {
            detailContent
        }
        .confirmationDialog(
            "Discard unsaved message?",
            isPresented: $showDiscardComposerConfirmation,
            titleVisibility: .visible
        ) {
            Button("Discard", role: .destructive) {
                guard let pendingNavigation else { return }
                performNavigation(pendingNavigation, discardComposer: true)
            }
            Button("Cancel", role: .cancel) {
                pendingNavigation = nil
            }
        } message: {
            Text("Your unsent composer text or attachments will be lost.")
        }
        .onChange(of: conversationSnapshot) { _, _ in
            syncConversationActionState()
        }
        .onChange(of: isSending) { _, _ in
            syncConversationActionState()
        }
        .onReceive(NotificationCenter.default.publisher(for: .focusThinkBarInput)) { _ in
            focusInput()
        }
        .onReceive(
            NotificationCenter.default.publisher(for: .startNewThinkBarConversation)
        ) { _ in
            requestStartNewConversation()
        }
        .task {
            loadConversations()
            syncConversationActionState()
        }
    }

    private var detailContent: some View {
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
                        ForEach(visibleConversations) { conversation in
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
                                } else if !debugLogService.bypassAssistantMarkdown,
                                          let renderedAssistant = conversation.renderedAssistant {
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
                            .id(conversation.id)
                        }

                        Color.clear
                            .frame(height: 1)
                            .id(ConversationScrollMetrics.bottomAnchorID)
                    }
                    .id(conversationSnapshot.activeConversationID)
                    .onAppear {
                        completeLayoutProbeIfNeeded()
                    }
                }
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    ConversationScrollMetrics.isNearBottom(geometry)
                } action: { _, newValue in
                    isNearBottom = newValue
                }
                .onScrollGeometryChange(for: Bool.self) { geometry in
                    ConversationScrollMetrics.isNearTop(geometry)
                } action: { _, isNearTop in
                    if isNearTop {
                        revealOlderConversations(using: proxy)
                    }
                }
                .onChange(of: conversations.count) { oldCount, newCount in
                    if abs(newCount - oldCount) == 1 {
                        renderingWindow.handleTotalCountChange(
                            from: oldCount,
                            to: newCount
                        )
                    }
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Conversation", systemImage: "square.and.pencil") {
                    requestStartNewConversation()
                }
                .disabled(!canStartNewConversation)
                .help("Start a new conversation")
            }
        }
        .contentShape(Rectangle())
        .dropDestination(for: URL.self) { urls, _ in
            loadAttachment(from: urls.first)
        }
    }

    private func requestSelectConversation(_ id: UUID) {
        guard canSelectConversation else { return }
        guard id != conversationSnapshot.activeConversation?.id else { return }

        let navigation = PendingConversationNavigation.select(id)
        if hasUnsavedComposerContent {
            pendingNavigation = navigation
            showDiscardComposerConfirmation = true
            return
        }
        performNavigation(navigation, discardComposer: true)
    }

    private func requestStartNewConversation() {
        guard canStartNewConversation else { return }

        let navigation = PendingConversationNavigation.newConversation
        if hasUnsavedComposerContent {
            pendingNavigation = navigation
            showDiscardComposerConfirmation = true
            return
        }
        performNavigation(navigation, discardComposer: true)
    }

    private func syncConversationActionState() {
        conversationActionState.update(
            canStartNewConversation: canStartNewConversation,
            canSelectConversation: canSelectConversation
        )
    }

    private func performNavigation(
        _ navigation: PendingConversationNavigation,
        discardComposer: Bool
    ) {
        pendingNavigation = nil

        let stopwatch = ConversationSwitchStopwatch()
        var timings = ConversationSwitchPerformanceReport.Timings()
        var snapshot = conversationSnapshot

        let sourceID = snapshot.activeConversation?.id
        let sourceTitle = snapshot.activeConversation?.title
            ?? ConversationTitleGenerator.placeholder
        let sourceTurns = snapshot.activeConversation?.turns.count ?? 0

        timings.saveCurrentConversation = stopwatch.measure {
            snapshot.replaceActiveTurns(conversationRecords())
        }

        let destinationID: UUID?
        switch navigation {
        case let .select(id):
            guard snapshot.conversations.contains(where: { $0.id == id }) else {
                return
            }
            timings.activateConversation = stopwatch.measure {
                snapshot.selectActiveConversation(id: id)
            }
            destinationID = id
        case .newConversation:
            let (created, activateDuration) = stopwatch.measure { () -> Conversation in
                // Turns were already persisted above; only create and select.
                let conversation = Conversation.makeNew()
                snapshot.upsert(conversation)
                return conversation
            }
            timings.activateConversation = activateDuration
            destinationID = created.id
        }

        do {
            let saveTiming = try conversationStore.saveMeasuring(snapshot)
            timings.encodeSnapshot = saveTiming.encode
            timings.writeSnapshotFile = saveTiming.write
        } catch {
            timings.encodeSnapshot = .zero
            timings.writeSnapshotFile = .zero
        }

        let (active, retrieveDuration) = stopwatch.measure {
            snapshot.activeConversation
        }
        timings.retrieveConversation = retrieveDuration

        conversationSnapshot = snapshot

        let presentation = presentActiveConversation(
            clearComposer: discardComposer,
            turns: active?.turnsForContext ?? [],
            conversationID: active?.id,
            conversationTitle: active?.title
                ?? ConversationTitleGenerator.placeholder,
            stopwatch: stopwatch,
            instrumentRendering: true
        )
        timings.buildDisplayItems = presentation.buildDisplayItems
        timings.prepareVisibleTurns = presentation.prepareVisibleTurns
        timings.uiStateUpdateRequested = presentation.uiStateUpdateRequested
        timings.total = stopwatch.elapsed()

        let destinationTitle = active?.title
            ?? ConversationTitleGenerator.placeholder
        let destinationTurns = active?.turns.count ?? 0
        let destinationCharacters = (active?.turns ?? []).reduce(into: 0) {
            count, turn in
            count += turn.user.count + turn.assistant.count
        }
        let totalTurns = snapshot.conversations.reduce(into: 0) {
            count, conversation in
            count += conversation.turns.count
        }

        let report = ConversationSwitchPerformanceReport(
            sourceConversationID: sourceID,
            destinationConversationID: destinationID ?? active?.id,
            sourceTitle: sourceTitle,
            destinationTitle: destinationTitle,
            totalConversations: snapshot.conversations.count,
            totalTurnsInSnapshot: totalTurns,
            sourceTurns: sourceTurns,
            destinationTurns: destinationTurns,
            destinationVisibleTurns: renderingWindow.visibleCount,
            destinationCharacterCount: destinationCharacters,
            timings: timings
        )

        if let renderingReport = presentation.renderingReport {
            pendingRenderingReport = renderingReport
            layoutProbeStartedAt = ContinuousClock().now
        }

        recordSwitchPerformance(report, stopwatch: stopwatch)
    }

    private func presentActiveConversation(clearComposer: Bool) {
        let active = conversationSnapshot.activeConversation
        _ = presentActiveConversation(
            clearComposer: clearComposer,
            turns: active?.turnsForContext ?? [],
            conversationID: active?.id,
            conversationTitle: active?.title
                ?? ConversationTitleGenerator.placeholder,
            stopwatch: nil,
            instrumentRendering: false
        )
    }

    private struct PresentationTimings {
        var buildDisplayItems: Duration = .zero
        var prepareVisibleTurns: Duration = .zero
        var uiStateUpdateRequested: Duration = .zero
        var renderingReport: ConversationRenderingPerformanceReport?
    }

    private func presentActiveConversation(
        clearComposer: Bool,
        turns: [ConversationRecord],
        conversationID: UUID?,
        conversationTitle: String,
        stopwatch: ConversationSwitchStopwatch?,
        instrumentRendering: Bool
    ) -> PresentationTimings {
        var timings = PresentationTimings()
        let measure = { (work: () -> Void) -> Duration in
            if let stopwatch {
                return stopwatch.measure(work)
            }
            work()
            return .zero
        }

        timings.buildDisplayItems = measure {
            conversations = turns.map {
                conversationItem(from: $0, renderMarkdown: false)
            }
        }

        var renderingReport: ConversationRenderingPerformanceReport?
        timings.prepareVisibleTurns = measure {
            renderingWindow.reset(totalCount: conversations.count)
            if instrumentRendering, debugLogService.isEnabled {
                renderingReport = renderMarkdownForVisibleConversationsMeasured(
                    conversationID: conversationID,
                    conversationTitle: conversationTitle,
                    viewConstruction: timings.buildDisplayItems
                )
            } else {
                renderMarkdownForVisibleConversations()
            }
        }
        if var report = renderingReport {
            report.prepareVisibleTurns = timings.prepareVisibleTurns
            renderingReport = report
        }
        timings.renderingReport = renderingReport

        timings.uiStateUpdateRequested = measure {
            if clearComposer {
                clearComposerState()
            }
            isNearBottom = true
            focusInput()
        }
        return timings
    }

    private func completeLayoutProbeIfNeeded() {
        guard
            let startedAt = layoutProbeStartedAt,
            var report = pendingRenderingReport
        else {
            return
        }

        report.layoutFirstAppearance = ContinuousClock().now - startedAt
        pendingRenderingReport = report
        layoutProbeStartedAt = nil
    }

    private func recordSwitchPerformance(
        _ report: ConversationSwitchPerformanceReport,
        stopwatch: ConversationSwitchStopwatch
    ) {
        let recorder = debugLogRecorder
        Task {
            guard await recorder?.loggingEnabled() == true else {
                await MainActor.run {
                    pendingRenderingReport = nil
                    layoutProbeStartedAt = nil
                }
                return
            }

            // Allow layout onAppear and the next render pass to complete.
            for _ in 0..<8 {
                await Task.yield()
                let hasLayout = await MainActor.run {
                    pendingRenderingReport?.layoutFirstAppearance != nil
                }
                if hasLayout { break }
            }
            await Task.yield()

            var finalized = report
            let firstRenderCompleted = stopwatch.elapsed()
            finalized.timings.firstRenderCompleted = firstRenderCompleted
            if firstRenderCompleted > finalized.timings.total {
                finalized.timings.total = firstRenderCompleted
            }
            await recorder?.record(finalized.asDebugLogEntry())

            let renderingEntry = await MainActor.run { () -> DebugLogEntry? in
                guard var renderingReport = pendingRenderingReport else {
                    return nil
                }
                renderingReport.firstRenderCompleted = firstRenderCompleted
                if renderingReport.layoutFirstAppearance == nil {
                    renderingReport.layoutFirstAppearance =
                        firstRenderCompleted
                }
                pendingRenderingReport = nil
                layoutProbeStartedAt = nil
                return renderingReport.asDebugLogEntry()
            }
            if let renderingEntry {
                await recorder?.record(renderingEntry)
            }
        }
    }

    private func revealOlderConversations(using proxy: ScrollViewProxy) {
        guard renderingWindow.canRevealOlder(totalCount: conversations.count) else {
            return
        }

        let anchorID = visibleConversations.first?.id
        let previousStart = renderingWindow.visibleStartIndex(
            totalCount: conversations.count
        )
        let added = renderingWindow.revealOlder(totalCount: conversations.count)
        guard added > 0 else { return }

        let newStart = renderingWindow.visibleStartIndex(
            totalCount: conversations.count
        )
        renderMarkdown(in: newStart..<previousStart)

        if let anchorID {
            DispatchQueue.main.async {
                proxy.scrollTo(anchorID, anchor: .top)
            }
        }
    }

    private func clearComposerState() {
        input = ""
        attachments.removeAll()
        imageAttachments.removeAll()
        attachmentError = nil
    }

    private func conversationItem(
        from record: ConversationRecord,
        renderMarkdown: Bool
    ) -> ConversationItem {
        let renderedAssistant: AttributedString?
        if renderMarkdown, shouldRenderMarkdown(record.assistant) {
            renderedAssistant =
                AssistantResponseFormatter.markdownPreservingWhitespace(
                    record.assistant
                )
        } else {
            renderedAssistant = nil
        }
        return ConversationItem(
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

    private func renderMarkdownForVisibleConversations() {
        let start = renderingWindow.visibleStartIndex(
            totalCount: conversations.count
        )
        renderMarkdown(in: start..<conversations.count)
    }

    private func renderMarkdownForVisibleConversationsMeasured(
        conversationID: UUID?,
        conversationTitle: String,
        viewConstruction: Duration
    ) -> ConversationRenderingPerformanceReport {
        let experiment: ConversationRenderingPerformanceReport.Experiment =
            debugLogService.bypassAssistantMarkdown
            ? .plainAssistantText
            : .normalMarkdown
        let start = renderingWindow.visibleStartIndex(
            totalCount: conversations.count
        )
        var turnTimings: [ConversationRenderingPerformanceReport.TurnTiming] = []
        var markdownParseTotal = Duration.zero
        var attributedTotal = Duration.zero
        var formatterTotal = Duration.zero
        var formattedTurnCount = 0

        for index in start..<conversations.count {
            let timing = renderMarkdownMeasured(at: index)
            turnTimings.append(timing)
            markdownParseTotal += timing.markdownParse
            attributedTotal += timing.attributedStringCreation
            formatterTotal += timing.formatterTotal
            if timing.usedFormatter {
                formattedTurnCount += 1
            }
        }

        return ConversationRenderingPerformanceReport(
            experiment: experiment,
            conversationID: conversationID,
            conversationTitle: conversationTitle,
            visibleTurnCount: renderingWindow.visibleCount,
            formattedTurnCount: formattedTurnCount,
            turnTimings: turnTimings,
            markdownParseTotal: markdownParseTotal,
            attributedStringCreationTotal: attributedTotal,
            formatterTotal: formatterTotal,
            viewConstruction: viewConstruction
        )
    }

    private func renderMarkdown(in indexRange: Range<Int>) {
        for index in indexRange {
            guard conversations.indices.contains(index) else { continue }
            _ = renderMarkdownMeasured(at: index)
        }
    }

    @discardableResult
    private func renderMarkdownMeasured(
        at index: Int
    ) -> ConversationRenderingPerformanceReport.TurnTiming {
        let item = conversations[index]
        let characterCount = item.assistant.count

        if debugLogService.bypassAssistantMarkdown {
            conversations[index].renderedAssistant = nil
            return ConversationRenderingPerformanceReport.TurnTiming(
                id: item.id,
                index: index,
                characterCount: characterCount,
                usedFormatter: false
            )
        }

        guard shouldRenderMarkdown(item.assistant) else {
            conversations[index].renderedAssistant = nil
            return ConversationRenderingPerformanceReport.TurnTiming(
                id: item.id,
                index: index,
                characterCount: characterCount,
                usedFormatter: false
            )
        }

        let measured = AssistantResponseFormatter
            .markdownPreservingWhitespaceMeasured(item.assistant)
        conversations[index].renderedAssistant = measured.value
        return ConversationRenderingPerformanceReport.TurnTiming(
            id: item.id,
            index: index,
            characterCount: characterCount,
            usedFormatter: true,
            markdownParse: measured.breakdown.markdownParse,
            attributedStringCreation: measured.breakdown.attributedStringCreation,
            formatterTotal: measured.breakdown.total
        )
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
        let conversation = ConversationItem(
            user: prompt,
            request: requestPrompt,
            attachmentContext: attachmentContext
        )
        conversations.append(conversation)
        assignGeneratedTitleIfNeeded()
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
        guard conversations.isEmpty else { return }

        var snapshot = (try? conversationStore.load()) ?? .empty
        let wasEmpty = snapshot.conversations.isEmpty
        snapshot.ensureAtLeastOneConversation()
        conversationSnapshot = snapshot
        if wasEmpty {
            try? conversationStore.save(snapshot)
        }
        presentActiveConversation(clearComposer: true)
    }

    private func saveConversations() {
        var snapshot = conversationSnapshot
        snapshot.replaceActiveTurns(conversationRecords())
        conversationSnapshot = snapshot
        try? conversationStore.save(snapshot)
    }

    private func assignGeneratedTitleIfNeeded() {
        var snapshot = conversationSnapshot
        guard snapshot.assignGeneratedTitleIfNeeded(
            from: conversationRecords()
        ) else {
            return
        }
        conversationSnapshot = snapshot
        try? conversationStore.save(snapshot)
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

        _ = renderMarkdownMeasured(at: index)
    }

    private func shouldRenderMarkdown(_ text: String) -> Bool {
        text.contains("```")
    }
}

#Preview {
    ContentView(
        provider: FakeAIProvider(),
        debugLogService: DebugLogService(),
        conversationActionState: ConversationActionState()
    )
}

private struct ConversationItem: Identifiable {
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
