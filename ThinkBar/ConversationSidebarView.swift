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
    let canSelectConversation: Bool
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
                        conversationRow(item)
                            .tag(item.id)
                            .accessibilityAddTraits(item.isActive ? .isSelected : [])
                    }
                    .disabled(!canSelectConversation)
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

    @ViewBuilder
    private func conversationRow(_ item: ConversationSidebarItem) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.title)
                    .lineLimit(2)
                    .fontWeight(item.isActive ? .semibold : .regular)
                if item.isActive {
                    Text("Active")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            if item.isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)
                    .imageScale(.small)
                    .accessibilityHidden(true)
            }
        }
        .contentShape(Rectangle())
    }

    private var selectionBinding: Binding<UUID?> {
        Binding(
            get: { selectedConversationID },
            set: { newValue in
                guard let newValue, canSelectConversation else { return }
                onSelect(newValue)
            }
        )
    }
}
