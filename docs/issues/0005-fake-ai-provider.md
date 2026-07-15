# Issue 0005 - Fake AI Provider

## Goal

Implement a fake AI provider for development.

The purpose of this provider is to allow the application to be developed without requiring Ollama or OpenAI.

## Requirements

Create:

Packages/ThinkBarCore/Sources/ThinkBarCore/FakeAIProvider.swift

Implement:

public struct FakeAIProvider: AIProvider

Behavior:

- Always returns a Response.
- Ignore the Prompt contents.
- Return:

Hello ThinkBar

The implementation should be deterministic.

## Out of Scope

- Ollama
- OpenAI
- Streaming
- Conversation
- Networking
- Configuration

## Tests

Add at least one Swift Testing test.

Verify:

Given any Prompt,

FakeAIProvider returns

Hello ThinkBar

## Acceptance Criteria

- ThinkBarCore only
- Build succeeds
- Tests succeed
- No existing public API changes

## Additional Instructions

Do not introduce new protocols.

Do not add configuration.

Do not make the provider customizable.

Keep it as small as possible.

YAGNI.
