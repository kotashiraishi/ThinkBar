import Testing
import ThinkBarCore

struct StubAIProvider: AIProvider {
    let responseText: String

    func ask(_ prompt: Prompt) async throws -> Response {
        Response(text: responseText)
    }
}

@Test func promptStoresText() {
    let prompt = Prompt(text: "hello")
    #expect(prompt.text == "hello")
}

@Test func responseStoresText() {
    let response = Response(text: "world")
    #expect(response.text == "world")
}

@Test func aiProviderAskReturnsResponse() async throws {
    let provider: any AIProvider = StubAIProvider(responseText: "ok")
    let response = try await provider.ask(Prompt(text: "ping"))
    #expect(response.text == "ok")
}
