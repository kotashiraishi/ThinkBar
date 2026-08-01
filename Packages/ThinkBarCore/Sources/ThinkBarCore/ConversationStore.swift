import Foundation

public struct ConversationRecord: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let user: String
    public let assistant: String

    public init(
        id: UUID = UUID(),
        user: String,
        assistant: String
    ) {
        self.id = id
        self.user = user
        self.assistant = assistant
    }
}

public struct ConversationStore: Sendable {
    private let fileURL: URL

    public init() {
        let applicationSupportURL = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        )[0]
        self.fileURL = applicationSupportURL
            .appendingPathComponent("ThinkBar", isDirectory: true)
            .appendingPathComponent("conversations.json")
    }

    public init(fileURL: URL) {
        self.fileURL = fileURL
    }

    public func load() throws -> [ConversationRecord] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            return []
        }

        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(ConversationArchive.self, from: data).conversations
    }

    public func save(_ conversations: [ConversationRecord]) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let archive = ConversationArchive(
            version: 1,
            conversations: conversations
        )
        let data = try JSONEncoder().encode(archive)
        try data.write(to: fileURL, options: .atomic)
    }
}

private struct ConversationArchive: Codable {
    let version: Int
    let conversations: [ConversationRecord]
}
