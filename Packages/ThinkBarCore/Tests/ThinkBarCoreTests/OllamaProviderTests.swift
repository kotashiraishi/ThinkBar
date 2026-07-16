import Foundation
import Testing
@testable import ThinkBarCore

@Test func ollamaProviderSendsPromptAndReturnsGeneratedText() async throws {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: configuration)

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

        let response = try #require(HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        ))
        return (response, Data(#"{"response":"こんにちは！"}"#.utf8))
    }
    defer { MockURLProtocol.handler = nil }

    let provider = OllamaProvider(
        baseURL: URL(string: "http://localhost:11434")!,
        model: "gemma3:4b",
        session: session
    )

    let response = try await provider.ask(Prompt(text: "こんにちは"))

    #expect(response.text == "こんにちは！")
}

private struct OllamaRequestBody: Decodable, Equatable {
    let model: String
    let prompt: String
    let stream: Bool
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
