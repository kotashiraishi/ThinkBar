import Foundation

public struct OllamaProvider: AIProvider {
    private static let languageInstruction = """
    Answer in the same language as the user's latest message.
    Do not switch languages unless the user explicitly requests it.
    """

    public struct Mode: Identifiable, Hashable, Sendable {
        public let id: String
        public let title: String
        fileprivate let systemPrompt: String

        public static let general = Mode(
            id: "general",
            title: "💬 General",
            systemPrompt: "You are a helpful, concise assistant."
        )
        public static let horn = Mode(
            id: "horn",
            title: "🎺 Horn",
            systemPrompt: """
            You are an experienced professional horn teacher. Give practical advice \
            on horn technique, practice, and musicianship.
            """
        )
        public static let swift = Mode(
            id: "swift",
            title: "💻 Swift",
            systemPrompt: """
            You are a senior Swift engineer. Provide accurate, idiomatic Swift and \
            Apple-platform guidance.
            """
        )
        public static let php = Mode(
            id: "php",
            title: "🐘 PHP",
            systemPrompt: """
            You are a senior PHP engineer. Provide secure, maintainable, modern PHP \
            guidance.
            """
        )
        public static let run = Mode(
            id: "run",
            title: "🏃 Run",
            systemPrompt: """
            You are an experienced running coach. Give practical, safe advice on \
            training, recovery, and running technique.
            """
        )

        public static let builtIn: [Mode] = [
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

    private let baseURL: URL
    private let model: String
    private let session: URLSession

    public init(baseURL: URL, model: String) {
        self.init(baseURL: baseURL, model: model, session: .shared)
    }

    init(baseURL: URL, model: String, session: URLSession) {
        self.baseURL = baseURL
        self.model = model
        self.session = session
    }

    public func ask(_ prompt: Prompt) async throws -> Response {
        let body = RequestBody(
            model: model,
            prompt: prompt.text,
            stream: false
        )

        var request = URLRequest(
            url: baseURL.appendingPathComponent("api/generate")
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await session.data(for: request)
        let result = try JSONDecoder().decode(ResponseBody.self, from: data)
        return Response(text: result.response)
    }

    public func stream(
        _ prompt: Prompt,
        onChunk: @escaping @Sendable (String) async -> Void
    ) async throws {
        try await stream(promptText: prompt.text, onChunk: onChunk)
    }

    public func stream(
        conversationHistory: [(user: String, assistant: String)],
        mode: Mode = .general,
        onChunk: @escaping @Sendable (String) async -> Void
    ) async throws {
        let promptText = conversationPrompt(
            from: conversationHistory,
            mode: mode
        )
        try await stream(promptText: promptText, onChunk: onChunk)
    }

    private func stream(
        promptText: String,
        onChunk: @escaping @Sendable (String) async -> Void
    ) async throws {
        let body = RequestBody(
            model: model,
            prompt: promptText,
            stream: true
        )

        var request = URLRequest(
            url: baseURL.appendingPathComponent("api/generate")
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (bytes, _) = try await session.bytes(for: request)

        for try await line in bytes.lines {
            let result = try JSONDecoder().decode(
                StreamResponseBody.self,
                from: Data(line.utf8)
            )

            if !result.response.isEmpty {
                await onChunk(result.response)
            }
            if result.done {
                break
            }
        }
    }

    private func conversationPrompt(
        from history: [(user: String, assistant: String)],
        mode: Mode
    ) -> String {
        var lines = [
            """
            System: \(mode.systemPrompt)
            \(Self.languageInstruction)
            """
        ]

        for turn in history.suffix(5) {
            lines.append("User: \(turn.user)")
            if !turn.assistant.isEmpty {
                lines.append("Assistant: \(turn.assistant)")
            }
        }

        lines.append("Assistant:")
        return lines.joined(separator: "\n")
    }
}

private struct RequestBody: Encodable {
    let model: String
    let prompt: String
    let stream: Bool
}

private struct ResponseBody: Decodable {
    let response: String
}

private struct StreamResponseBody: Decodable {
    let response: String
    let done: Bool
}
