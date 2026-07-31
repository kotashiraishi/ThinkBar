import Foundation

public struct OllamaProvider: AIProvider {
    public typealias Mode = ConversationMode

    private static let languageInstruction = """
    Answer in the same language as the user's latest message.
    Do not switch languages unless the user explicitly requests it.
    """

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
            messages: [
                Message(role: "user", content: prompt.text),
            ],
            stream: false
        )

        var request = URLRequest(
            url: baseURL.appendingPathComponent("api/chat")
        )
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, _) = try await session.data(for: request)
        let result = try JSONDecoder().decode(ResponseBody.self, from: data)
        return Response(text: result.message.content)
    }

    public func stream(
        _ prompt: Prompt,
        onChunk: @escaping @Sendable (String) async -> Void
    ) async throws {
        try await stream(
            messages: [
                Message(role: "user", content: prompt.text),
            ],
            onChunk: onChunk
        )
    }

    public func stream(
        conversationHistory: [(user: String, assistant: String)],
        mode: Mode = .general,
        onChunk: @escaping @Sendable (String) async -> Void
    ) async throws {
        try await stream(
            messages: conversationMessages(
                from: conversationHistory,
                mode: mode
            ),
            onChunk: onChunk
        )
    }

    private func stream(
        messages: [Message],
        onChunk: @escaping @Sendable (String) async -> Void
    ) async throws {
        let body = RequestBody(
            model: model,
            messages: messages,
            stream: true
        )

        var request = URLRequest(
            url: baseURL.appendingPathComponent("api/chat")
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

            if !result.message.content.isEmpty {
                await onChunk(result.message.content)
            }
            if result.done {
                break
            }
        }
    }

    private func conversationMessages(
        from history: [(user: String, assistant: String)],
        mode: Mode
    ) -> [Message] {
        var messages = [
            Message(
                role: "system",
                content: "\(mode.systemPrompt)\n\(Self.languageInstruction)"
            )
        ]

        for turn in history.suffix(5) {
            messages.append(Message(role: "user", content: turn.user))
            if !turn.assistant.isEmpty {
                messages.append(Message(role: "assistant", content: turn.assistant))
            }
        }
        return messages
    }
}

private struct RequestBody: Encodable {
    let model: String
    let messages: [Message]
    let stream: Bool
}

private struct Message: Codable {
    let role: String
    let content: String
}

private struct ResponseBody: Decodable {
    let message: Message
}

private struct StreamResponseBody: Decodable {
    let message: Message
    let done: Bool
}

