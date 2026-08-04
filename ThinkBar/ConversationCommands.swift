import SwiftUI

struct ConversationCommands: Commands {
    @ObservedObject var conversationActionState: ConversationActionState

    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Conversation") {
                NotificationCenter.default.post(
                    name: .startNewThinkBarConversation,
                    object: nil
                )
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
            .disabled(!conversationActionState.canStartNewConversation)
        }
    }
}
