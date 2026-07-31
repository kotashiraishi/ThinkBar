import Foundation
import Testing
@testable import ThinkBarCore

@Suite(.serialized)
struct OllamaProviderTests {
    @Test func builtInModesAreAvailable() {
        #expect(OllamaProvider.Mode.builtIn.map(\.title) == [
            "💬 General",
            "🎺 Horn",
            "💻 Swift",
            "🐘 PHP",
            "🏃 Run",
        ])
    }

    @Test func eachBuiltInModeIsSentAsSystemMessage() async throws {
        let session = makeSession()
        let provider = makeProvider(session: session)
        defer { MockURLProtocol.handler = nil }

        for mode in OllamaProvider.Mode.builtIn {
            MockURLProtocol.handler = { request in
                let body = try JSONDecoder().decode(
                    OllamaRequestBody.self,
                    from: try requestBody(from: request)
                )
                #expect(body.messages.first == .init(
                    role: "system",
                    content: """
                    \(mode.systemPrompt)
                    Answer in the same language as the user's latest message.
                    Do not switch languages unless the user explicitly requests it.
                    """
                ))

                let line = """
                {"message":{"role":"assistant","content":""},"done":true}

                """
                return try makeHTTPResponse(
                    for: request,
                    data: Data(line.utf8)
                )
            }

            try await provider.stream(
                conversationHistory: [(user: "Hello", assistant: "")],
                mode: mode
            ) { _ in }
        }
    }

    @Test func askSendsChatMessageAndReturnsGeneratedText() async throws {
        let session = makeSession()

        MockURLProtocol.handler = { request in
            #expect(request.url?.absoluteString == "http://localhost:11434/api/chat")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            let data = try requestBody(from: request)
            let body = try JSONDecoder().decode(OllamaRequestBody.self, from: data)
            #expect(body == OllamaRequestBody(
                model: "gemma3:4b",
                messages: [
                    .init(role: "user", content: "こんにちは"),
                ],
                stream: false
            ))

            return try makeHTTPResponse(
                for: request,
                data: Data(
                    #"{"message":{"role":"assistant","content":"こんにちは！"}}"#.utf8
                )
            )
        }
        defer { MockURLProtocol.handler = nil }

        let provider = makeProvider(session: session)
        let response = try await provider.ask(Prompt(text: "こんにちは"))

        #expect(response.text == "こんにちは！")
    }

    @Test func conversationStreamUsesFiveRecentTurnsAndDeliversChunks() async throws {
        let session = makeSession()

        MockURLProtocol.handler = { request in
            #expect(request.url?.absoluteString == "http://localhost:11434/api/chat")
            let data = try requestBody(from: request)
            let body = try JSONDecoder().decode(OllamaRequestBody.self, from: data)
            #expect(body.stream)
            #expect(body.messages == [
                .init(
                    role: "system",
                    content: """
                    You are a senior Swift engineer. Provide accurate, idiomatic Swift and Apple-platform guidance.
                    Answer in the same language as the user's latest message.
                    Do not switch languages unless the user explicitly requests it.
                    """
                ),
                .init(role: "user", content: "user2"),
                .init(role: "assistant", content: "assistant2"),
                .init(role: "user", content: "user3"),
                .init(role: "assistant", content: "assistant3"),
                .init(role: "user", content: "user4"),
                .init(role: "assistant", content: "assistant4"),
                .init(role: "user", content: "user5"),
                .init(role: "assistant", content: "assistant5"),
                .init(role: "user", content: "user6"),
            ])

            let lines = """
            {"message":{"role":"assistant","content":"こん"},"done":false}
            {"message":{"role":"assistant","content":"にちは"},"done":false}
            {"message":{"role":"assistant","content":""},"done":true}

            """
            return try makeHTTPResponse(for: request, data: Data(lines.utf8))
        }
        defer { MockURLProtocol.handler = nil }

        let collector = ChunkCollector()
        let provider = makeProvider(session: session)
        let history = [
            (user: "user1", assistant: "assistant1"),
            (user: "user2", assistant: "assistant2"),
            (user: "user3", assistant: "assistant3"),
            (user: "user4", assistant: "assistant4"),
            (user: "user5", assistant: "assistant5"),
            (user: "user6", assistant: ""),
        ]

        try await provider.stream(
            conversationHistory: history,
            mode: .swift
        ) { chunk in
            await collector.append(chunk)
        }

        #expect(await collector.text == "こんにちは")
    }
}

private struct OllamaRequestBody: Decodable, Equatable {
    let model: String
    let messages: [OllamaMessage]
    let stream: Bool
}

private struct OllamaMessage: Decodable, Equatable {
    let role: String
    let content: String
}

private func makeSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: configuration)
}

private func makeProvider(session: URLSession) -> OllamaProvider {
    OllamaProvider(
        baseURL: URL(string: "http://localhost:11434")!,
        model: "gemma3:4b",
        session: session
    )
}

private func makeHTTPResponse(
    for request: URLRequest,
    data: Data
) throws -> (HTTPURLResponse, Data) {
    let response = try #require(HTTPURLResponse(
        url: request.url!,
        statusCode: 200,
        httpVersion: nil,
        headerFields: nil
    ))
    return (response, data)
}

private func requestBody(from request: URLRequest) throws -> Data {
    if let body = request.httpBody {
        return body
    }

    let stream = try #require(request.httpBodyStream)
    stream.open()
    defer { stream.close() }

    var data = Data()
    var buffer = [UInt8](repeating: 0, count: 1_024)

    while stream.hasBytesAvailable {
        let count = stream.read(&buffer, maxLength: buffer.count)
        if count < 0 {
            throw stream.streamError ?? MockURLProtocolError.unreadableBody
        }
        if count == 0 {
            break
        }
        data.append(contentsOf: buffer.prefix(count))
    }

    return data
}

private actor ChunkCollector {
    private(set) var text = ""

    func append(_ chunk: String) {
        text += chunk
    }
}

private final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var handler:
        (@Sendable (URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        do {
            guard let handler = Self.handler else {
                throw MockURLProtocolError.missingHandler
            }
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private enum MockURLProtocolError: Error {
    case missingHandler
    case unreadableBody
}
