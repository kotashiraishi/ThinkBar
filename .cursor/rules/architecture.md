# ThinkBar — Architecture

## Swift Package First

Prefer Swift Packages for Core, Features, and shared infrastructure. Keep the app target thin: composition, lifecycle, and wiring.

## Core Knows No UI

`Core` must not import SwiftUI or AppKit UI types. Domain logic, models, and use cases stay UI-agnostic so Features and the app layer own presentation.

## Protocol First

Define behavior with protocols. Depend on abstractions for AI, storage, networking, and system services so implementations can change independently.

## Dependency Injection

Pass dependencies explicitly (initializers / factories). Avoid hidden singletons for app services. Composition roots live at the app or feature boundary.

## Composition over Inheritance

Build features by composing small types and protocols. Prefer value types and clear ownership over deep class hierarchies.

## Small Features

Keep each Feature focused and shippable. Prefer many small packages/modules over one growing monolith. Cross-feature coupling should go through shared Core contracts.
