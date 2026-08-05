import Foundation
import Testing
@testable import ThinkBarCore

struct ConversationSwitchPerformanceTests {
    @Test func formattedSummaryIncludesTimingSections() {
        let report = ConversationSwitchPerformanceReport(
            sourceConversationID: UUID(),
            destinationConversationID: UUID(),
            sourceTitle: "Source",
            destinationTitle: "Destination",
            totalConversations: 2,
            totalTurnsInSnapshot: 12,
            sourceTurns: 4,
            destinationTurns: 8,
            destinationVisibleTurns: 8,
            destinationCharacterCount: 1200,
            timings: .init(
                saveCurrentConversation: .milliseconds(1),
                encodeSnapshot: .milliseconds(2),
                writeSnapshotFile: .milliseconds(3),
                activateConversation: .milliseconds(4),
                retrieveConversation: .milliseconds(5),
                buildDisplayItems: .milliseconds(6),
                prepareVisibleTurns: .milliseconds(7),
                uiStateUpdateRequested: .milliseconds(8),
                firstRenderCompleted: .milliseconds(20),
                total: .milliseconds(20)
            )
        )

        let summary = report.formattedSummary
        #expect(summary.contains("Conversation Switch Performance"))
        #expect(summary.contains("Source turns: 4"))
        #expect(summary.contains("Destination turns: 8"))
        #expect(summary.contains("Encode snapshot:"))
        #expect(summary.contains("Write snapshot file:"))
        #expect(summary.contains("First render completed:"))
        #expect(summary.contains("Total:"))
    }

    @Test func saveMeasuringSeparatesEncodeAndWrite() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let store = ConversationStore(
            fileURL: directory.appendingPathComponent("conversations.json")
        )
        var snapshot = ConversationStoreSnapshot.empty
        snapshot.replaceActiveTurns([
            ConversationRecord(user: "Hello", assistant: "World"),
        ])

        let timing = try store.saveMeasuring(snapshot)

        #expect(timing.encode >= .zero)
        #expect(timing.write >= .zero)
        #expect(try store.load().activeConversation?.turns.count == 1)
    }
}
