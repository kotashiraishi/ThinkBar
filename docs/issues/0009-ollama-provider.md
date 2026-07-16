# Issue 0009 - Ollama Provider

## User Value

ThinkBar can talk to a real local AI running on another Mac without changing the UI.

## Goal

Replace FakeAIProvider with a real Ollama-backed AIProvider implementation.

## Requirements

Create:

Packages/ThinkBarCore/Sources/ThinkBarCore/OllamaProvider.swift

Implement:

public struct OllamaProvider: AIProvider

Initializer:

public init(baseURL: URL, model: String)

Implementation requirements:

- Use Foundation only.
- Use URLSession with async/await.
- POST to:

/api/generate

Request body:

{
  "model": "<model>",
  "prompt": "<prompt>",
  "stream": false
}

Decode only the fields required to obtain the generated response.

Return:

Response(text: ...)

Do not implement streaming.

Do not implement conversation history.

Do not implement retries.

Do not implement configuration objects.

YAGNI.

## App Changes

In ThinkBarApp.swift:

Replace FakeAIProvider with:

OllamaProvider(
    baseURL: URL(string: "http://<YOUR_M4_IP>:11434")!,
    model: "gemma3:4b"
)

No UI changes.

## Out of Scope

- Streaming
- Chat history
- Voice input
- Settings
- Provider selection
- Attachments

## Acceptance Criteria

- App builds.
- Existing tests continue to pass.
- Typing "こんにちは" returns a response from Gemma 3.
- FakeAIProvider is no longer used by the app.

## Manual Test

- [ ] App launches.
- [ ] Send "こんにちは".
- [ ] Response comes from Gemma 3.
- [ ] Send another prompt immediately afterwards.
- [ ] Japanese input still works normally.

## Additional Instructions

Keep the implementation as small as possible.

Do not redesign the architecture.

After implementation, output:

- Issue name
- Goal
- Added/Modified/Deleted files
- Design decisions
- Future work
- git diff --stat summary
