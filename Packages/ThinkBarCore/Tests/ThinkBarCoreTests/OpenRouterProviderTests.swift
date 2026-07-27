import Foundation
import Testing
@testable import ThinkBarCore

@Suite(.serialized)
struct OpenRouterProviderTests {
    @Test func askSendsChatCompletionAndReturnsText() async throws {
        let session = makeOpenRouterSession()
        OpenRouterMockURLProtocol.handler = { request in
            #expect(request.url?.absoluteString == "https://openrouter.test/chat/completions")
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-key")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            let body = try JSONDecoder().decode(
                OpenRouterRequestBody.self,
                from: try openRouterRequestBody(from: request)
            )
            #expect(body == OpenRouterRequestBody(
                model: "openai/gpt-4o-mini",
                messages: [
                    .init(role: "user", content: "Hello"),
                ],
                stream: false
            ))

            return try openRouterHTTPResponse(
                for: request,
                data: Data(#"{"choices":[{"message":{"role":"assistant","content":"Hi"}}]}"#.utf8)
            )
        }
        defer { OpenRouterMockURLProtocol.handler = nil }

        let provider = makeOpenRouterProvider(session: session)
        let response = try await provider.ask(Prompt(text: "Hello"))

        #expect(response.text == "Hi")
    }

    @Test func conversationStreamSendsRecentMessagesAndDeliversChunks() async throws {
        let session = makeOpenRouterSession()
        OpenRouterMockURLProtocol.handler = { request in
            let body = try JSONDecoder().decode(
                OpenRouterRequestBody.self,
                from: try openRouterRequestBody(from: request)
            )
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

            let events = """
            data: {"choices":[{"delta":{"content":"こん"}}]}

            data: {"choices":[{"delta":{"content":"にちは"}}]}

            data: [DONE]

            """
            return try openRouterHTTPResponse(
                for: request,
                data: Data(events.utf8)
            )
        }
        defer { OpenRouterMockURLProtocol.handler = nil }

        let collector = OpenRouterChunkCollector()
        let provider = makeOpenRouterProvider(session: session)
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

private struct OpenRouterRequestBody: Decodable, Equatable {
    let model: String
    let messages: [OpenRouterMessage]
    let stream: Bool
}

private struct OpenRouterMessage: Decodable, Equatable {
    let role: String
    let content: String
}

private func makeOpenRouterSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [OpenRouterMockURLProtocol.self]
    return URLSession(configuration: configuration)
}

private func makeOpenRouterProvider(session: URLSession) -> OpenRouterProvider {
    OpenRouterProvider(
        apiKey: "test-key",
        model: "openai/gpt-4o-mini",
        endpoint: URL(string: "https://openrouter.test/chat/completions")!,
        session: session
    )
}

private func openRouterHTTPResponse(
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

private func openRouterRequestBody(from request: URLRequest) throws -> Data {
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
            throw stream.streamError ?? OpenRouterMockError.unreadableBody
        }
        if count == 0 {
            break
        }
        data.append(contentsOf: buffer.prefix(count))
    }
    return data
}

private actor OpenRouterChunkCollector {
    private(set) var text = ""

    func append(_ chunk: String) {
        text += chunk
    }
}

private final class OpenRouterMockURLProtocol: URLProtocol {
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
                throw OpenRouterMockError.missingHandler
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

private enum OpenRouterMockError: Error {
    case missingHandler
    case unreadableBody
}
