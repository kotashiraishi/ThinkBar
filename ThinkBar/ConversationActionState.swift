import Combine
import Foundation

@MainActor
final class ConversationActionState: ObservableObject {
    @Published private(set) var canStartNewConversation = false
    @Published private(set) var canSelectConversation = true

    func update(
        canStartNewConversation: Bool,
        canSelectConversation: Bool
    ) {
        if self.canStartNewConversation != canStartNewConversation {
            self.canStartNewConversation = canStartNewConversation
        }
        if self.canSelectConversation != canSelectConversation {
            self.canSelectConversation = canSelectConversation
        }
    }
}
