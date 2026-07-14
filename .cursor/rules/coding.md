# ThinkBar — Coding

## Naming

- Types: `UpperCamelCase` (`ThoughtStore`, `ActionRunner`)
- Methods / properties: `lowerCamelCase`
- Protocols: noun or `-ing` / `-able` when natural (`AIProvider`, `Sendable`)
- Prefer clear domain names over abbreviations

## Comments

Comment *why*, not *what*. Skip comments that restate the code. Document non-obvious constraints, invariants, and trade-offs briefly.

## One Responsibility per File

Each file owns one primary type or cohesive concern. Split when a file mixes unrelated responsibilities or grows hard to navigate.

## Refactoring

Refactor in small, reviewable steps. Keep behavior stable unless the change is intentional. Do not expand scope beyond the task. Leave the MVP intact.

## Conventional Commits

Use Conventional Commits:

- `feat:` new user-facing capability
- `fix:` bug fix
- `refactor:` structure change without behavior change
- `test:` tests only
- `docs:` documentation / rules
- `chore:` tooling, project config
