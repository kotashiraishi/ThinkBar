# Issue 0008a - Restore IME Compatibility

## User Value

Japanese users can use ThinkBar naturally without breaking the standard macOS input experience.

## Goal

Restore proper Japanese IME behavior while keeping the improvements from Issue 0008.

## Requirements

Remove Enter-to-send behavior.

Keep:

- Multiline input
- Send button
- Successful send clears the input
- Failed send preserves the input
- Focus restoration after sending
- Disabled UI while sending

Japanese IME confirmation must work normally.

Do not modify ThinkBarCore.

## Out of Scope

- New keyboard shortcuts
- Ollama
- History
- Voice input
- Menu bar

## Acceptance Criteria

- Japanese IME conversion works normally.
- Pressing Enter confirms text instead of sending.
- Send button continues to work.
- App builds.
- Existing tests continue to pass.

## Additional Instructions

This is a bug fix.

Prefer the smallest possible change.

Do not redesign the architecture.

After implementation, output:

- Issue name
- Goal
- Added/Modified/Deleted files
- Design decisions
- Future work
- git diff --stat summary
