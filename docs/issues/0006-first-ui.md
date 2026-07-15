# Issue 0006 - First Working UI

## Goal

Create the first working ThinkBar UI.

The app should allow the user to enter text, press Return (or click Send), call FakeAIProvider, and display the response.

## Requirements

UI should contain only:

- TextField
- Send Button
- Response Text

Behavior:

1. User enters text.
2. User presses Return or clicks Send.
3. FakeAIProvider.ask() is called.
4. Response text is displayed.

Use SwiftUI.

Do not introduce ViewModels unless necessary.

Dependency injection should happen in the App target.

## Out of Scope

- Ollama
- OpenAI
- Menu Bar
- Global Shortcut
- History
- Voice
- Settings

## Acceptance Criteria

- App builds
- Enter key works
- Button works
- "Hello ThinkBar" appears on screen
- Existing tests continue to pass

## Additional Instructions

Keep the implementation as small as possible.

Do not redesign the architecture.

Do not add future features.

YAGNI.

After implementation, output:

- Issue name
- Goal
- Added/Modified/Deleted files
- Design decisions
- Future work
- git diff --stat summary
