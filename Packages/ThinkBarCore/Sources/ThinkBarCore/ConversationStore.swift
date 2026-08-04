import Foundation

/// A single user/assistant exchange within a conversation.
public struct ConversationRecord: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let user: String
    public let assistant: String
    public let context: ConversationContextMetadata?

    public init(
        id: UUID = UUID(),
        user: String,
        assistant: String,
        context: ConversationContextMetadata? = nil
    ) {
        self.id = id
        self.user = user
        self.assistant = assistant
        self.context = context
    }
}

public struct ConversationContextMetadata:
    Codable,
    Equatable,
    Sendable
{
    public let request: String?
    public let attachmentContext: String?
    public let summary: String?
    public let summaryCoveredConversationCount: Int?

    public init(
        request: String? = nil,
        attachmentContext: String? = nil,
        summary: String? = nil,
        summaryCoveredConversationCount: Int? = nil
    ) {
        self.request = request
        self.attachmentContext = attachmentContext
        self.summary = summary
        self.summaryCoveredConversationCount =
            summaryCoveredConversationCount
    }
}

/// An independent conversation thread with its own turns and summary.
public struct Conversation: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var createdAt: Date
    public var updatedAt: Date
    public var title: String
    public var turns: [ConversationRecord]
    public var summary: String?
    public var summaryCoveredTurnCount: Int?

    public init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        title: String = "New Conversation",
        turns: [ConversationRecord] = [],
        summary: String? = nil,
        summaryCoveredTurnCount: Int? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.title = title
        self.turns = turns
        self.summary = summary
        self.summaryCoveredTurnCount = summaryCoveredTurnCount
    }

    public static func makeNew(now: Date = Date()) -> Conversation {
        Conversation(
            createdAt: now,
            updatedAt: now,
            title: "New Conversation",
            turns: [],
            summary: "",
            summaryCoveredTurnCount: 0
        )
    }

    public static func migrating(
        from turns: [ConversationRecord],
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) -> Conversation {
        let summaryState = Conversation.summaryState(in: turns)
        return Conversation(
            createdAt: createdAt,
            updatedAt: updatedAt,
            title: provisionalTitle(from: turns),
            turns: turns,
            summary: summaryState.summary,
            summaryCoveredTurnCount: summaryState.coveredCount
        )
    }

    public static func provisionalTitle(
        from turns: [ConversationRecord]
    ) -> String {
        guard let firstUser = turns.first?.user
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !firstUser.isEmpty
        else {
            return "New Conversation"
        }

        let limit = 40
        if firstUser.count <= limit {
            return firstUser
        }
        let end = firstUser.index(firstUser.startIndex, offsetBy: limit)
        return String(firstUser[..<end]) + "…"
    }

    public static func summaryState(
        in turns: [ConversationRecord]
    ) -> (summary: String?, coveredCount: Int?) {
        for (index, turn) in turns.enumerated().reversed() {
            guard let rawSummary = turn.context?.summary else { continue }
            let summary = rawSummary.trimmingCharacters(
                in: .whitespacesAndNewlines
            )
            guard !summary.isEmpty else { continue }

            let coveredCount =
                turn.context?.summaryCoveredConversationCount
                ?? (index + 1)
            return (summary, coveredCount)
        }
        return (nil, nil)
    }

    /// Turns with conversation-level summary mirrored onto turn metadata
    /// so ContextBuilder / SummaryService keep working unchanged.
    public var turnsForContext: [ConversationRecord] {
        guard
            let summary,
            !summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return turns
        }

        guard let last = turns.last else { return turns }

        var mirrored = turns
        let existing = last.context
        mirrored[mirrored.count - 1] = ConversationRecord(
            id: last.id,
            user: last.user,
            assistant: last.assistant,
            context: ConversationContextMetadata(
                request: existing?.request,
                attachmentContext: existing?.attachmentContext,
                summary: summary,
                summaryCoveredConversationCount:
                    summaryCoveredTurnCount
                    ?? existing?.summaryCoveredConversationCount
            )
        )
        return mirrored
    }
}

/// Persisted multi-conversation state, including which conversation is active.
public struct ConversationStoreSnapshot: Codable, Equatable, Sendable {
    public var version: Int
    public var activeConversationID: UUID?
    public var conversations: [Conversation]

    public static let currentVersion = 3

    public init(
        version: Int = ConversationStoreSnapshot.currentVersion,
        activeConversationID: UUID? = nil,
        conversations: [Conversation] = []
    ) {
        self.version = version
        self.activeConversationID = activeConversationID
        self.conversations = conversations
    }

    public static let empty = ConversationStoreSnapshot()

    public var activeConversation: Conversation? {
        guard let activeConversationID else {
            return conversations.first
        }
        return conversations.first { $0.id == activeConversationID }
            ?? conversations.first
    }

    public var conversationsSortedByUpdatedAt: [Conversation] {
        conversations.sorted { $0.updatedAt > $1.updatedAt }
    }

    /// New Conversation is allowed only when the active conversation already has turns.
    public var canStartNewConversation: Bool {
        guard let activeConversation else { return false }
        return !activeConversation.turns.isEmpty
    }

    public mutating func selectActiveConversation(id: UUID) {
        guard conversations.contains(where: { $0.id == id }) else { return }
        activeConversationID = id
    }

    public mutating func upsert(_ conversation: Conversation) {
        if let index = conversations.firstIndex(where: {
            $0.id == conversation.id
        }) {
            conversations[index] = conversation
        } else {
            conversations.append(conversation)
        }
        activeConversationID = conversation.id
    }

    /// Ensures there is an active conversation, creating an empty one if needed.
    @discardableResult
    public mutating func ensureAtLeastOneConversation(
        now: Date = Date()
    ) -> Conversation {
        if let active = activeConversation {
            if activeConversationID == nil {
                activeConversationID = active.id
            }
            return active
        }

        let conversation = Conversation.makeNew(now: now)
        upsert(conversation)
        return conversation
    }

    /// Persists the current active turns, then selects another conversation.
    @discardableResult
    public mutating func activateConversation(
        id: UUID,
        persistingActiveTurns turns: [ConversationRecord] = [],
        now: Date = Date()
    ) -> Bool {
        guard conversations.contains(where: { $0.id == id }) else {
            return false
        }
        guard activeConversation?.id != id else {
            return true
        }

        if activeConversation != nil || !turns.isEmpty {
            replaceActiveTurns(turns, updatedAt: now)
        }
        selectActiveConversation(id: id)
        return true
    }

    /// Persists the current active turns (if any), then creates and selects a new conversation.
    /// Returns `nil` when the active conversation has no turns to avoid empty duplicates.
    @discardableResult
    public mutating func startNewConversation(
        persistingActiveTurns turns: [ConversationRecord] = [],
        now: Date = Date()
    ) -> Conversation? {
        let hasTurns = !turns.isEmpty || !(activeConversation?.turns.isEmpty ?? true)
        guard hasTurns else {
            return activeConversation
        }

        if activeConversation != nil || !turns.isEmpty {
            replaceActiveTurns(turns, updatedAt: now)
        }

        let conversation = Conversation.makeNew(now: now)
        upsert(conversation)
        return conversation
    }

    public mutating func replaceActiveTurns(
        _ turns: [ConversationRecord],
        summary: String? = nil,
        summaryCoveredTurnCount: Int? = nil,
        updatedAt: Date = Date()
    ) {
        let resolvedSummary: String?
        let resolvedCovered: Int?
        if let summary {
            resolvedSummary = summary
            resolvedCovered = summaryCoveredTurnCount
        } else {
            let state = Conversation.summaryState(in: turns)
            resolvedSummary = state.summary
            resolvedCovered = state.coveredCount
        }

        if var active = activeConversation {
            active.turns = turns
            active.summary = resolvedSummary
            active.summaryCoveredTurnCount = resolvedCovered
            active.updatedAt = updatedAt
            if active.title == "New Conversation" {
                active.title = Conversation.provisionalTitle(from: turns)
            }
            upsert(active)
            return
        }

        let conversation = Conversation(
            createdAt: updatedAt,
            updatedAt: updatedAt,
            title: Conversation.provisionalTitle(from: turns),
            turns: turns,
            summary: resolvedSummary,
            summaryCoveredTurnCount: resolvedCovered
        )
        upsert(conversation)
    }
}

public struct ConversationStore: Sendable {
    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init() {
        let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        self.init(
            fileURL: applicationSupportURL
                .appendingPathComponent("ThinkBar", isDirectory: true)
                .appendingPathComponent("conversations.json")
        )
    }

    public init(fileURL: URL) {
        self.fileURL = fileURL
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func load() throws -> ConversationStoreSnapshot {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return .empty
        }

        let data = try Data(contentsOf: fileURL)
        let version = try decoder.decode(ArchiveVersion.self, from: data).version

        switch version {
        case 1, 2:
            let legacy = try decoder.decode(LegacyConversationArchive.self, from: data)
            return migrateLegacy(legacy)
        case ConversationStoreSnapshot.currentVersion:
            return try decoder.decode(ConversationStoreSnapshot.self, from: data)
        default:
            if let snapshot = try? decoder.decode(
                ConversationStoreSnapshot.self,
                from: data
            ) {
                return snapshot
            }
            let legacy = try decoder.decode(
                LegacyConversationArchive.self,
                from: data
            )
            return migrateLegacy(legacy)
        }
    }

    public func save(_ snapshot: ConversationStoreSnapshot) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        var archive = snapshot
        archive.version = ConversationStoreSnapshot.currentVersion
        if archive.activeConversationID == nil {
            archive.activeConversationID = archive.conversations.first?.id
        }
        let data = try encoder.encode(archive)
        try data.write(to: fileURL, options: .atomic)
    }

    private func migrateLegacy(
        _ legacy: LegacyConversationArchive
    ) -> ConversationStoreSnapshot {
        guard !legacy.conversations.isEmpty else {
            return .empty
        }

        let conversation = Conversation.migrating(from: legacy.conversations)
        return ConversationStoreSnapshot(
            version: ConversationStoreSnapshot.currentVersion,
            activeConversationID: conversation.id,
            conversations: [conversation]
        )
    }
}

private struct ArchiveVersion: Codable {
    let version: Int
}

private struct LegacyConversationArchive: Codable {
    let version: Int
    let conversations: [ConversationRecord]
}
