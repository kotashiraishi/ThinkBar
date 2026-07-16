# Issue 0008 - Keyboard Workflow

## User Value

After sending a prompt, the user can immediately start typing the next thought without touching the mouse.

## Goal

Complete the basic keyboard workflow for ThinkBar.

## Requirements

Implement the following behavior:

- Press Enter to send the prompt.
- Press Shift+Enter to insert a newline.
- Clicking the Send button behaves identically.
- After a successful response, clear the input.
- If sending fails, keep the input unchanged.
- While sending:
  - Disable the input.
  - Disable the Send button.

The existing AIProvider abstraction must remain unchanged.

## Out of Scope

- Ollama
- History
- Voice input
- Attachments
- Menu bar
- Global shortcut

## Acceptance Criteria

- Enter sends.
- Shift+Enter inserts a newline.
- Send button still works.
- Successful send clears the editor.
- Failed send preserves the editor.
- App builds.
- Existing tests continue to pass.

## Additional Instructions

Keep the implementation as small as possible.

Do not redesign the architecture.

Do not introduce a ViewModel unless it becomes clearly necessary.

After implementation, output:

- Issue name
- Goal
- Added/Modified/Deleted files
- Design decisions
- Future work
- git diff --stat summary	
