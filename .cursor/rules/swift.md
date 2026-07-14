# ThinkBar — Swift

## SwiftUI

Use SwiftUI for UI. Keep views thin: state and side effects live in models / use cases. Prefer declarative composition over imperative view logic.

## async / await

Prefer `async`/`await` for asynchronous work. Avoid legacy completion-handler APIs unless bridging is required.

## Sendable

Mark shared / cross-isolation types `Sendable` when safe. Treat concurrency warnings as design signals, not noise to silence casually.

## Actor

Use `actor` for mutable shared state that needs isolation. Prefer actors over ad-hoc locks for app services and caches.

## Foundation Dependency

Prefer Foundation (and stdlib) in Core. Avoid AppKit/SwiftUI imports outside UI layers. Pull in heavier frameworks only where needed.

## Observable

Prefer modern Observation (`@Observable`) for UI-facing state. Keep observation at the presentation boundary; Core stays free of UI observation concerns.
