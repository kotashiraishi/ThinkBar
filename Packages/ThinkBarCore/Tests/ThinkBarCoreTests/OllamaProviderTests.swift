import Foundation
import Testing
@testable import ThinkBarCore

@Suite(.serialized)
struct OllamaProviderTests {
    @Test func askSendsPromptAndReturnsGeneratedText() async throws {
        let session = makeSession()

        MockURLProtocol.handler = { request in
            #expect(request.url?.absoluteString == "http://localhost:11434/api/generate")
            #expect(request.httpMethod == "POST")
            #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")

            let data = try requestBody(from: request)
            let body = try JSONDecoder().decode(OllamaRequestBody.self, from: data)
            #expect(body == OllamaRequestBody(
                model: "gemma3:4b",
                prompt: "こんにちは",
                stream: false
            ))

            return try makeHTTPResponse(
                for: request,
                data: Data(#"{"response":"こんにちは！"}"#.utf8)
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
            let data = try requestBody(from: request)
            let body = try JSONDecoder().decode(OllamaRequestBody.self, from: data)
            #expect(body.stream)
            #expect(body.prompt == """
            User: user2
            Assistant: assistant2
            User: user3
            Assistant: assistant3
            User: user4
            Assistant: assistant4
            User: user5
            Assistant: assistant5
            User: user6
            Assistant:
            """)

            let lines = """
            {"response":"こん","done":false}
            {"response":"にちは","done":false}
            {"response":"","done":true}

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

        try await provider.stream(conversationHistory: history) { chunk in
            await collector.append(chunk)
        }

        #expect(await collector.text == "こんにちは")
    }
}

private struct OllamaRequestBody: Decodable, Equatable {
    let model: String
    let prompt: String
    let stream: Bool
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
