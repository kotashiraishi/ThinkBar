import SwiftUI

struct ConversationCommands: Commands {
    var body: some Commands {
        CommandGroup(after: .newItem) {
            Button("New Conversation") {
                NotificationCenter.default.post(
                    name: .startNewThinkBarConversation,
                    object: nil
                )
            }
            .keyboardShortcut("n", modifiers: [.command, .shift])
        }
    }
}
