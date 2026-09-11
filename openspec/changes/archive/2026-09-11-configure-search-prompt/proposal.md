## Why

Pickr currently hard-codes `◉/> ` for every picker, so users cannot choose a clearer label or distinguish variants through their search prompts. Provide a shared `Search: ` default with optional per-variant customization in the existing plugin configuration.

## What Changes

- Add an optional `prompt` object to `config.json`, with `default` for the global text and `variants` for individual overrides.
- Default the global text to exactly `"Search: "` (including the trailing space), with no built-in variant overrides.
- Support `tabs_current`, `tabs_all`, `spaces`, `agents_current`, and `agents_all`; each omitted or null override inherits the global value.
- Preserve configured text, including whitespace, Unicode, and an explicitly empty string, and validate types and unknown fields through existing configuration diagnostics.
- Apply the destination variant's prompt when switching; refresh and retry retain the current variant's prompt. Configuration edits take effect on reopening.
- Document the new default and how to restore the previous prompt with a global override.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `plugin-configuration`: Extend the accepted configuration schema and define global/per-variant prompt resolution, validation, and launch-scoped behavior.

## Impact

Implementation will affect `src/pickr/config.lua` (validation, resolution, snapshot handoff), `src/pickr/core.lua` (fzf prompt selection), the existing Lua configuration/picker fixtures, and `README.md`. The visible default changes from `◉/> ` to `Search: `; existing configuration remains valid. No new dependency, Herdr action, or manifest change is required. Prompt color continues to use the existing theme role.
