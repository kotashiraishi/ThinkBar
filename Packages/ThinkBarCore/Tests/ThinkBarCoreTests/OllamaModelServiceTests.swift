import Foundation
import Testing
@testable import ThinkBarCore

@Suite(.serialized)
struct OllamaModelServiceTests {
    @Test func fetchesInstalledModelsFromTagsAPI() async throws {
        let session = makeModelSession()
        ModelMockURLProtocol.handler = { request in
            #expect(request.url?.absoluteString == "http://localhost:11434/api/tags")

            let data = Data("""
            {
              "models": [
                {"name": "gemma3:4b"},
                {"name": "qwen2:latest"}
              ]
            }
            """.utf8)
            return try modelHTTPResponse(for: request, data: data)
        }
        defer { ModelMockURLProtocol.handler = nil }

        let service = OllamaModelService(
            baseURL: URL(string: "http://localhost:11434")!,
            session: session
        )

        #expect(try await service.models() == [
            ProviderModel(id: "gemma3:4b", title: "gemma3:4b"),
            ProviderModel(id: "qwen2:latest", title: "qwen2:latest"),
        ])
    }
}

private func makeModelSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [ModelMockURLProtocol.self]
    return URLSession(configuration: configuration)
}

private func modelHTTPResponse(
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

private final class ModelMockURLProtocol: URLProtocol {
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
                throw ModelMockError.missingHandler
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

private enum ModelMockError: Error {
    case missingHandler
}
