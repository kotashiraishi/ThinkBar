import Foundation
import Testing
@testable import ThinkBarCore

struct ConversationStoreTests {
    @Test func missingFileLoadsEmptySnapshot() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConversationStore(
            fileURL: directory.appendingPathComponent("conversations.json")
        )

        let snapshot = try store.load()
        #expect(snapshot.conversations.isEmpty)
        #expect(snapshot.activeConversationID == nil)
    }

    @Test func savesAndRestoresMultipleConversationsWithActiveSelection() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConversationStore(
            fileURL: directory.appendingPathComponent("conversations.json")
        )
        let first = Conversation(
            title: "ThinkBar開発相談",
            turns: [
                ConversationRecord(
                    user: "First question",
                    assistant: "First answer"
                ),
            ],
            summary: "Project summary",
            summaryCoveredTurnCount: 1
        )
        let second = Conversation(
            title: "ホルン練習相談",
            turns: [
                ConversationRecord(
                    user: "Second question",
                    assistant: "Second answer",
                    context: ConversationContextMetadata(
                        request: "Attached context\nSecond question"
                    )
                ),
            ]
        )
        var snapshot = ConversationStoreSnapshot(
            conversations: [first, second]
        )
        snapshot.selectActiveConversation(id: second.id)

        try store.save(snapshot)

        let loaded = try store.load()
        #expect(loaded.version == ConversationStoreSnapshot.currentVersion)
        #expect(loaded.conversations.count == 2)
        #expect(loaded.activeConversationID == second.id)
        #expect(loaded.activeConversation?.title == "ホルン練習相談")
        #expect(loaded.conversations[0].summary == "Project summary")
        #expect(loaded.conversations[0].summaryCoveredTurnCount == 1)
        #expect(
            loaded.conversations[1].turns.first?.context?.request
                == "Attached context\nSecond question"
        )
    }

    @Test func migratesVersionTwoArchiveIntoSingleConversation() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        let fileURL = directory.appendingPathComponent("conversations.json")
        let firstID = UUID()
        let secondID = UUID()
        let data = Data("""
        {
          "version": 2,
          "conversations": [
            {
              "id": "\(firstID.uuidString)",
              "user": "First question",
              "assistant": "First answer"
            },
            {
              "id": "\(secondID.uuidString)",
              "user": "Second question",
              "assistant": "Second answer",
              "context": {
                "request": "Attached context\\nSecond question",
                "summary": "Earlier discussion summary",
                "summaryCoveredConversationCount": 2
              }
            }
          ]
        }
        """.utf8)
        try data.write(to: fileURL)
        let store = ConversationStore(fileURL: fileURL)

        let snapshot = try store.load()
        let conversation = try #require(snapshot.conversations.first)

        #expect(snapshot.conversations.count == 1)
        #expect(snapshot.activeConversationID == conversation.id)
        #expect(conversation.turns.count == 2)
        #expect(conversation.turns[0].id == firstID)
        #expect(conversation.turns[1].id == secondID)
        #expect(conversation.summary == "Earlier discussion summary")
        #expect(conversation.summaryCoveredTurnCount == 2)
        #expect(conversation.title == "First question")
        #expect(conversation.turnsForContext.last?.context?.summary
            == "Earlier discussion summary")
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

        let conversation = try #require(store.load().activeConversation)

        #expect(conversation.turns.count == 1)
        #expect(conversation.turns[0].id == id)
        #expect(conversation.turns[0].user == "Legacy question")
        #expect(conversation.turns[0].context == nil)
        #expect(conversation.summary == nil)
    }

    @Test func preservesAssistantWhitespaceExactly() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConversationStore(
            fileURL: directory.appendingPathComponent("conversations.json")
        )
        let response = "First paragraph.\n\n  indented line  \n\nLast.\n"
        var snapshot = ConversationStoreSnapshot.empty
        snapshot.replaceActiveTurns([
            ConversationRecord(user: "Question", assistant: response),
        ])

        try store.save(snapshot)

        #expect(
            try store.load().activeConversation?.turns.first?.assistant
                == response
        )
    }

    @Test func replaceActiveTurnsCreatesConversationWhenEmpty() {
        var snapshot = ConversationStoreSnapshot.empty
        snapshot.replaceActiveTurns([
            ConversationRecord(user: "Hello", assistant: "Hi"),
        ])

        #expect(snapshot.conversations.count == 1)
        #expect(snapshot.activeConversation?.title == "Hello")
        #expect(snapshot.activeConversation?.turns.count == 1)
    }

    @Test func migratingPreservesExistingMessagesAndSummary() {
        let turns = [
            ConversationRecord(user: "One", assistant: "A"),
            ConversationRecord(
                user: "Two",
                assistant: "B",
                context: ConversationContextMetadata(
                    summary: "Kept summary",
                    summaryCoveredConversationCount: 2
                )
            ),
        ]

        let conversation = Conversation.migrating(from: turns)

        #expect(conversation.turns == turns)
        #expect(conversation.summary == "Kept summary")
        #expect(conversation.summaryCoveredTurnCount == 2)
    }

    @Test func makeNewConversationStartsEmpty() {
        let conversation = Conversation.makeNew()

        #expect(conversation.title == "New Conversation")
        #expect(conversation.turns.isEmpty)
        #expect(conversation.summary == "")
        #expect(conversation.summaryCoveredTurnCount == 0)
    }

    @Test func startNewConversationKeepsPreviousAndSwitchesActive() throws {
        let directory = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConversationStore(
            fileURL: directory.appendingPathComponent("conversations.json")
        )
        var snapshot = ConversationStoreSnapshot.empty
        snapshot.replaceActiveTurns([
            ConversationRecord(
                user: "Keep me",
                assistant: "Still here",
                context: ConversationContextMetadata(
                    summary: "Old summary",
                    summaryCoveredConversationCount: 1
                )
            ),
        ])
        let previousID = try #require(snapshot.activeConversationID)

        let created = snapshot.startNewConversation(
            persistingActiveTurns: [
                ConversationRecord(
                    user: "Keep me",
                    assistant: "Still here",
                    context: ConversationContextMetadata(
                        summary: "Old summary",
                        summaryCoveredConversationCount: 1
                    )
                ),
            ]
        )
        try store.save(snapshot)

        let loaded = try store.load()
        #expect(loaded.conversations.count == 2)
        #expect(loaded.activeConversationID == created.id)
        #expect(loaded.activeConversation?.turns.isEmpty == true)
        #expect(loaded.activeConversation?.summary == "")
        #expect(loaded.activeConversation?.summaryCoveredTurnCount == 0)

        let previous = try #require(
            loaded.conversations.first { $0.id == previousID }
        )
        #expect(previous.turns.count == 1)
        #expect(previous.summary == "Old summary")
        #expect(previous.summaryCoveredTurnCount == 1)
    }
}

private func temporaryDirectory() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent(UUID().uuidString, isDirectory: true)
}
