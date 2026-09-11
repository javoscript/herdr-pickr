## Why

Pickr currently has no root-level `AGENTS.md` to introduce the project to coding agents or document the requested commit-message convention. A concise project guide will make that context and expectation easy to discover.

## What Changes

- Add `AGENTS.md` at the project root with a description of Pickr as a local Herdr plugin providing fuzzy tab, space, and agent pickers with terminal previews, implemented in Lua 5.3+ with `luv` and `fzf`.
- Include the guideline: "Commits should be made following the Conventional Commits format."
- Illustrate the format with `type(scope): description`, noting that scope is optional, and a short example.

## Capabilities

### New Capabilities

None. This is a documentation-only change; `.openspec.yaml` sets `skip_specs: true`.

### Modified Capabilities

None.

## Impact

The implementation adds only root-level `AGENTS.md`. Its description is grounded in `README.md`, `herdr-plugin.toml`, and `main.lua`. It introduces contributor guidance without changing runtime behavior, APIs, dependencies, or commit tooling.
