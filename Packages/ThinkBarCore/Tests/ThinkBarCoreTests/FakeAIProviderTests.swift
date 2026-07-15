import Testing
import ThinkBarCore

@Test func fakeAIProviderReturnsHelloThinkBarForAnyPrompt() async throws {
    let provider = FakeAIProvider()
    let response = try await provider.ask(Prompt(text: "ignored"))
    #expect(response.text == "Hello ThinkBar")
}
