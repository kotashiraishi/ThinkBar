import Foundation

public struct OpenRouterProvider: AIProvider {
    private static let defaultAPIKey = "YOUR_OPENROUTER_API_KEY"
    private static let defaultEndpoint = URL(
        string: "https://openrouter.ai/api/v1/chat/completions"
    )!
    private static let languageInstruction = """
    Answer in the same language as the user's latest message.
    Do not switch languages unless the user explicitly requests it.
    """

    private let apiKey: String
    private let model: String
    private let endpoint: URL
    private let session: URLSession

    public init() {
        self.init(apiKey: Self.defaultAPIKey)
    }

    public init(
        apiKey: String,
        model: String = "openai/gpt-4o-mini"
    ) {
        self.init(
            apiKey: apiKey,
            model: model,
            endpoint: Self.defaultEndpoint,
            session: .shared
        )
    }

    init(
        apiKey: String,
        model: String,
        endpoint: URL,
        session: URLSession
    ) {
        self.apiKey = apiKey
        self.model = model
        self.endpoint = endpoint
        self.session = session
    }

    public func ask(_ prompt: Prompt) async throws -> Response {
        let request = try makeRequest(
            messages: [Message(role: "user", content: prompt.text)],
            stream: false
        )
        let (data, response) = try await session.data(for: request)
        try validate(response)

        let result = try JSONDecoder().decode(ChatCompletionResponse.self, from: data)
        guard let text = result.choices.first?.message.content else {
            throw OpenRouterError.missingResponse
        }
        return Response(text: text)
    }

    public func stream(
        _ prompt: Prompt,
        onChunk: @escaping @Sendable (String) async -> Void
    ) async throws {
        try await stream(
            messages: [Message(role: "user", content: prompt.text)],
            onChunk: onChunk
        )
    }

    public func stream(
        conversationHistory: [(user: String, assistant: String)],
        mode: OllamaProvider.Mode = .general,
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
        let request = try makeRequest(messages: messages, stream: true)
        let (bytes, response) = try await session.bytes(for: request)
        try validate(response)

        for try await line in bytes.lines {
            guard line.hasPrefix("data:") else { continue }

            let payload = line
                .dropFirst("data:".count)
                .trimmingCharacters(in: .whitespaces)
            if payload == "[DONE]" {
                break
            }

            let event = try JSONDecoder().decode(
                StreamResponse.self,
                from: Data(payload.utf8)
            )
            for choice in event.choices {
                if let content = choice.delta.content, !content.isEmpty {
                    await onChunk(content)
                }
            }
        }
    }

    private func makeRequest(
        messages: [Message],
        stream: Bool
    ) throws -> URLRequest {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(RequestBody(
            model: model,
            messages: messages,
            stream: stream
        ))
        return request
    }

    private func conversationMessages(
        from history: [(user: String, assistant: String)],
        mode: OllamaProvider.Mode
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

    private func validate(_ response: URLResponse) throws {
        guard let response = response as? HTTPURLResponse else {
            throw OpenRouterError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            throw OpenRouterError.requestFailed(statusCode: response.statusCode)
        }
    }
}

private struct RequestBody: Encodable {
    let model: String
    let messages: [Message]
    let stream: Bool
}

private struct Message: Codable, Equatable {
    let role: String
    let content: String
}

private struct ChatCompletionResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let message: Message
    }
}

private struct StreamResponse: Decodable {
    let choices: [Choice]

    struct Choice: Decodable {
        let delta: Delta
    }

    struct Delta: Decodable {
        let content: String?
    }
}

private enum OpenRouterError: LocalizedError {
    case invalidResponse
    case requestFailed(statusCode: Int)
    case missingResponse

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "OpenRouter returned an invalid response."
        case let .requestFailed(statusCode):
            "OpenRouter request failed with status \(statusCode)."
        case .missingResponse:
            "OpenRouter returned no response text."
        }
    }
}
