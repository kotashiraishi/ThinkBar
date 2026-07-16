# Issue 0007 - Multiline Input

## Goal

Replace the single-line TextField with a multiline input suitable for everyday use.

The UI should remain minimal while making it easier to write prompts longer than one line.

## Requirements

Replace the existing TextField with a multiline editor.

Requirements:

- Approximately two lines tall by default.
- User can type multiple lines.
- Existing Send button continues to work.
- Existing AIProvider flow remains unchanged.
- Existing response display remains unchanged.

Do not implement keyboard shortcuts in this issue.

## Out of Scope

- Enter to send
- Shift+Enter
- Streaming
- History
- Voice
- Ollama
- Settings

## Acceptance Criteria

- App builds.
- User can enter multiple lines.
- Send button still works.
- Existing tests continue to pass.

## Additional Instructions

Keep the implementation as small as possible.

Do not redesign the architecture.

Do not introduce a ViewModel.

After implementation, output:

- Issue name
- Goal
- Added/Modified/Deleted files
- Design decisions
- Future work
- git diff --stat summary
