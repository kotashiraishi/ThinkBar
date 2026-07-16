import Foundation

public struct OllamaProvider: AIProvider {
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
}

private struct RequestBody: Encodable {
    let model: String
    let prompt: String
    let stream: Bool
}

private struct ResponseBody: Decodable {
    let response: String
}
