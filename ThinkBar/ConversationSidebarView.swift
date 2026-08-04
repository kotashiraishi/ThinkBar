import SwiftUI
import ThinkBarCore

struct ConversationSidebarItem: Identifiable, Hashable {
    let id: UUID
    let title: String
    let updatedAt: Date
    let isActive: Bool
}

struct ConversationSidebarView: View {
    let items: [ConversationSidebarItem]
    let selectedConversationID: UUID?
    let isInteractionDisabled: Bool
    let canStartNewConversation: Bool
    let onSelect: (UUID) -> Void
    let onNewConversation: () -> Void

    var body: some View {
        List(selection: selectionBinding) {
            Section {
                Button {
                    onNewConversation()
                } label: {
                    Label("New Conversation", systemImage: "square.and.pencil")
                }
                .disabled(!canStartNewConversation)
            }

            Section("Conversations") {
                if items.isEmpty {
                    ContentUnavailableView(
                        "No Conversations",
                        systemImage: "bubble.left.and.bubble.right",
                        description: Text("Create a new conversation to get started.")
                    )
                    .frame(minHeight: 120)
                } else {
                    ForEach(items) { item in
                        Text(item.title)
                            .lineLimit(2)
                            .fontWeight(item.isActive ? .semibold : .regular)
                            .tag(item.id)
                            .accessibilityAddTraits(item.isActive ? .isSelected : [])
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("ThinkBar")
        .safeAreaInset(edge: .bottom) {
            if items.isEmpty {
                Button("New Conversation", systemImage: "square.and.pencil") {
                    onNewConversation()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!canStartNewConversation)
                .padding()
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var selectionBinding: Binding<UUID?> {
        Binding(
            get: { selectedConversationID },
            set: { newValue in
                guard let newValue, !isInteractionDisabled else { return }
                onSelect(newValue)
            }
        )
    }
}
