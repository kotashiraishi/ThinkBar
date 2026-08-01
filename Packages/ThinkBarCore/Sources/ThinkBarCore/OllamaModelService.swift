import Foundation

public protocol ProviderModelDiscovering: Sendable {
    func models() async throws -> [ProviderModel]
}

public struct OllamaModelService: ProviderModelDiscovering {
    private let baseURL: URL
    private let session: URLSession

    public init(baseURL: URL) {
        self.init(baseURL: baseURL, session: .shared)
    }

    init(baseURL: URL, session: URLSession) {
        self.baseURL = baseURL
        self.session = session
    }

    public func models() async throws -> [ProviderModel] {
        let url = baseURL.appendingPathComponent("api/tags")
        let (data, response) = try await session.data(from: url)

        guard let response = response as? HTTPURLResponse else {
            throw OllamaModelServiceError.invalidResponse
        }
        guard (200..<300).contains(response.statusCode) else {
            throw OllamaModelServiceError.requestFailed(
                statusCode: response.statusCode
            )
        }

        let result = try JSONDecoder().decode(TagsResponse.self, from: data)
        return result.models.map {
            ProviderModel(id: $0.name, title: $0.name)
        }
    }
}

private struct TagsResponse: Decodable {
    let models: [Model]

    struct Model: Decodable {
        let name: String
    }
}

private enum OllamaModelServiceError: LocalizedError {
    case invalidResponse
    case requestFailed(statusCode: Int)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Ollama returned an invalid response."
        case let .requestFailed(statusCode):
            "Ollama model request failed with status \(statusCode)."
        }
    }
}
