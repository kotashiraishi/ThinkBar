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
                assistant: "Second answer",
                context: ConversationContextMetadata(
                    request: "Attached context\nSecond question",
                    summary: "Earlier discussion summary",
                    summaryCoveredConversationCount: 2
                )
            ),
        ]

        try store.save(conversations)

        #expect(try store.load() == conversations)
    }

    @Test func loadsVersionOneArchiveWithoutContextMetadata() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let fileURL = directory.appendingPathComponent("conversations.json")
        let id = UUID()
        let data = Data("""
        {
          "version": 1,
          "conversations": [{
            "id": "\(id.uuidString)",
            "user": "Legacy question",
            "assistant": "Legacy answer"
          }]
        }
        """.utf8)
        try data.write(to: fileURL)
        let store = ConversationStore(fileURL: fileURL)

        let conversation = try #require(store.load().first)

        #expect(conversation.id == id)
        #expect(conversation.user == "Legacy question")
        #expect(conversation.context == nil)
    }

    @Test func preservesAssistantWhitespaceExactly() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConversationStore(
            fileURL: directory.appendingPathComponent("conversations.json")
        )
        let response = "First paragraph.\n\n  indented line  \n\nLast.\n"

        try store.save([
            ConversationRecord(user: "Question", assistant: response),
        ])

        #expect(try store.load().first?.assistant == response)
    }
}

private func temporaryDirectory() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
}
