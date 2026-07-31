public struct ConversationMode: Identifiable, Hashable, Sendable {
    public let id: String
    public let title: String
    let systemPrompt: String

    public static let general = ConversationMode(
        id: "general",
        title: "💬 General",
        systemPrompt: """
        You are a helpful assistant. \
        Give direct, practical, and accurate answers. \
        Be concise by default, but provide more detail when the user's question requires it. \
        Do not unnecessarily repeat or paraphrase the user's question.
        """
    )
    public static let horn = ConversationMode(
        id: "horn",
        title: "🎺 Horn",
        systemPrompt: """
        You are an experienced professional horn teacher. Give practical advice \
        on horn technique, practice, and musicianship.
        """
    )
    public static let swift = ConversationMode(
        id: "swift",
        title: "💻 Swift",
        systemPrompt: """
        You are a senior Swift engineer. Provide accurate, idiomatic Swift and \
        Apple-platform guidance.
        """
    )
    public static let php = ConversationMode(
        id: "php",
        title: "🐘 PHP",
        systemPrompt: """
        You are a senior PHP engineer. Provide secure, maintainable, modern PHP \
        guidance.
        """
    )
    public static let run = ConversationMode(
        id: "run",
        title: "🏃 Run",
        systemPrompt: """
        You are an experienced running coach. Give practical, safe advice on \
        training, recovery, and running technique.
        """
    )

    public static let builtIn: [ConversationMode] = [
        .general,
        .horn,
        .swift,
        .php,
        .run,
    ]

    private init(id: String, title: String, systemPrompt: String) {
        self.id = id
        self.title = title
        self.systemPrompt = systemPrompt
    }
}
