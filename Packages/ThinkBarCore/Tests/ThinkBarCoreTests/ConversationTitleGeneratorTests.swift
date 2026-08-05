import Testing
@testable import ThinkBarCore

struct ConversationTitleGeneratorTests {
    @Test func generatesShortTitleFromJapaneseRequest() {
        #expect(
            ConversationTitleGenerator.title(
                fromUserMessage: "0046の設計を相談したい"
            ) == "0046の設計"
        )
        #expect(
            ConversationTitleGenerator.title(
                fromUserMessage: "ホルンの高音について"
            ) == "ホルンの高音"
        )
    }

    @Test func usesFirstLineAndKeepsPlaceholderForEmptyMessage() {
        #expect(
            ConversationTitleGenerator.title(
                fromUserMessage: "  \nFirst line\nSecond line"
            ) == "First line"
        )
        #expect(
            ConversationTitleGenerator.title(fromUserMessage: "   ")
                == ConversationTitleGenerator.placeholder
        )
    }

    @Test func truncatesVeryLongTitles() {
        let message = String(repeating: "あ", count: 40)
        let title = ConversationTitleGenerator.title(fromUserMessage: message)

        #expect(title.count == ConversationTitleGenerator.maxLength + 1)
        #expect(title.hasSuffix("…"))
    }

    @Test func assignGeneratedTitleOnlyOnce() {
        var snapshot = ConversationStoreSnapshot.empty
        snapshot.ensureAtLeastOneConversation()
        let turns = [
            ConversationRecord(
                user: "0046の設計を相談したい",
                assistant: "了解"
            ),
        ]

        let assigned = snapshot.assignGeneratedTitleIfNeeded(from: turns)
        #expect(assigned)
        #expect(snapshot.activeConversation?.title == "0046の設計")

        let moreTurns = turns + [
            ConversationRecord(user: "別の質問", assistant: "答え"),
        ]
        let assignedAgain = snapshot.assignGeneratedTitleIfNeeded(from: moreTurns)
        #expect(assignedAgain == false)
        #expect(snapshot.activeConversation?.title == "0046の設計")

        snapshot.replaceActiveTurns(moreTurns)
        #expect(snapshot.activeConversation?.title == "0046の設計")
    }
}
