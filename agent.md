# Agent Instructions

## Purpose

This file contains general instructions for agents working in this repository.

Project-specific agent instructions belong in `docs/implementation-target.md`, read that immediately after reading this file.

## Working rules

Follow these rules while developing:

1. Keep changes scoped to the requested feature or refactor.
2. Preserve existing behaviour unless the user explicitly asks to change it.
3. Prefer small, coherent changes over broad rewrites.
4. Keep modules loosely coupled.
5. Make domain types explicit rather than passing unstructured strings through core logic.
6. Every added line of code should serve a clear purpose, especially validation, parsing, and safeguards.
7. Do not add defensive code that has no plausible failure mode in the current design.
8. Do not add fallback logic unless the code is processing untrusted external input, such as user-provided files, command-line input, network responses, or scraped data. For deterministic project-controlled systems such as build tooling, test wiring, generated paths, internal APIs, and validated domain values, surface failures directly and fix the incorrect assumption instead of masking it with alternate code paths.
9. Do not add large abstractions before there is a concrete need.
10. Do not add examples unless the user explicitly requests them.
11. Do not create an implementation log.
12. Do not add new document names or artefacts unless they support the current feature directly.

## Repository and build expectations

Use the repository's declared build setup. Keep build and development commands aligned with the existing project structure.

If the repository contains `flake.nix` or is otherwise a Nix flake, use the flake workflow and do not run `cabal`, `stack`, or similar build/test commands directly. Prefer nix flake check and nix build for all build and test steps; use nix develop only for interactive troubleshooting

Before considering work complete, run the relevant checks available in the repository. Prefer the narrowest checks that validate the change, then broader checks when needed.

## Implementation style

Prefer:

- explicit domain types
- pure functions in core logic
- small modules with clear responsibilities
- parser and validation boundaries
- testable logic separated from IO
- modular implementations for replaceable behaviours

Avoid:

- mixing parsing, domain logic, IO, and presentation concerns
- implementing the whole application in one step
- adding examples or demo data unless requested
- creating broad speculative abstractions

## Review guidance

Before returning work to the user, review the change against this list:

1. The change serves the requested feature.
2. Existing behaviour is preserved unless intentionally changed.
3. Domain concepts are explicit.
4. Parsing and validation are separated from core logic.
5. Core logic is separated from IO and presentation.
6. Replaceable behaviours remain modular.
7. No examples, implementation log, or backlog document have been added.
8. Every added line of code has a clear purpose.
9. No fallback logic has been added except where handling untrusted external input; deterministic project-controlled failures are surfaced directly.
