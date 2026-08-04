import Testing
@testable import ThinkBarCore

struct ConversationContextBuilderTests {
    @Test func buildsContextFromFiveMostRecentTurns() {
        let conversations = (1...6).map { index in
            ConversationRecord(
                user: "user\(index)",
                assistant: "assistant\(index)"
            )
        }

        let context = ConversationContextBuilder().build(
            from: conversations
        )

        #expect(context.summary == nil)
        #expect(context.recentTurns.count == 5)
        #expect(context.recentTurns.first?.user == "user2")
        #expect(context.recentTurns.last?.user == "user6")
    }

    @Test func usesContextRequestInsteadOfDisplayText() {
        let conversation = ConversationRecord(
            user: "Question",
            assistant: "Answer",
            context: ConversationContextMetadata(
                request: "Attachment context\nQuestion"
            )
        )

        let context = ConversationContextBuilder().build(
            from: [conversation]
        )

        #expect(context.recentTurns.first?.user == "Attachment context\nQuestion")
        #expect(context.recentTurns.first?.assistant == "Answer")
    }

    @Test func includesLatestNonemptySummary() {
        let conversations = [
            ConversationRecord(
                user: "Old question",
                assistant: "Old answer",
                context: ConversationContextMetadata(summary: "Old summary")
            ),
            ConversationRecord(
                user: "Current question",
                assistant: "",
                context: ConversationContextMetadata(summary: " Latest summary ")
            ),
        ]

        let context = ConversationContextBuilder().build(
            from: conversations
        )

        #expect(context.summary == "Latest summary")
        #expect(context.recentTurns.count == 2)
    }

    @Test func buildsContextFromConversationEntitySummary() {
        let conversation = Conversation(
            turns: [
                ConversationRecord(user: "user1", assistant: "assistant1"),
                ConversationRecord(user: "user2", assistant: "assistant2"),
            ],
            summary: " Conversation memory ",
            summaryCoveredTurnCount: 2
        )

        let context = ConversationContextBuilder().build(from: conversation)

        #expect(context.summary == "Conversation memory")
        #expect(context.recentTurns.count == 2)
        #expect(context.recentTurns.last?.user == "user2")
    }
}
