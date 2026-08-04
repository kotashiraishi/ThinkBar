import Combine
import Foundation

@MainActor
final class ConversationActionState: ObservableObject {
    @Published private(set) var canStartNewConversation = false

    func update(canStartNewConversation: Bool) {
        guard self.canStartNewConversation != canStartNewConversation else { return }
        self.canStartNewConversation = canStartNewConversation
    }
}
