import Foundation
import Testing
@testable import ThinkBarCore

struct ConversationStoreTests {
    @Test func missingFileLoadsEmptyHistory() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConversationStore(
            fileURL: directory.appendingPathComponent("conversations.json")
        )

        #expect(try store.load().isEmpty)
    }

    @Test func savesAndRestoresConversationsInOrder() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConversationStore(
            fileURL: directory.appendingPathComponent("conversations.json")
        )
        let conversations = [
            ConversationRecord(
                user: "First question",
                assistant: "First answer"
            ),
            ConversationRecord(
                user: "Second question",
                assistant: "Second answer"
            ),
        ]

        try store.save(conversations)

        #expect(try store.load() == conversations)
    }
}

private func temporaryDirectory() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
}
