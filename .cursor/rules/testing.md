# ThinkBar — Testing

## Swift Testing

Use Swift Testing (`import Testing`) for new unit tests. Prefer `#expect` / `#require` over XCTest-style assertions for new code.

## At Least One Test per New Feature

Every new Feature must ship with at least one meaningful test covering core behavior or a critical path.

## Prefer Mocks

Depend on protocols so tests inject mocks / fakes. Prefer lightweight test doubles over live network, disk, or AI providers.

## Design for Testability

Inject dependencies. Separate pure logic from side effects. Keep Core and Feature logic testable without launching the full UI.
