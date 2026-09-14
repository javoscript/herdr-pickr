## Why

Adding panes expands Pickr's scope-specific views and shortcuts into a growing navigation inventory. Separating four picker types from a shared scope selector makes searching, switching, and configuration predictable without losing direct scoped launches.

## What Changes

- Present Spaces, Tabs, Panes, and Agents as the four picker types, with configurable Ctrl+S/T/R/A shortcuts respectively.
- Add mutually exclusive All spaces, This space, and This tab scope controls, defaulting to Ctrl+Z/X/C. Tabs supports all/space; Panes and Agents support all/space/tab; Spaces has no scope.
- Carry a popup-wide chosen scope across types, temporarily using the nearest broader supported scope without erasing the choice. Keep narrow scopes anchored to the immutable launch origin.
- Show all three scope choices near the search prompt, with effective scope emphasized and unavailable choices dimmed. Keep four picker hints in the footer.
- Remember query and selection per picker type within the popup; scope changes preserve the current query and eligible selection. Configure columns and prompts once per type, with columns stable across scopes.
- Provide unqualified launches defaulting to all spaces plus explicit `-all`, `-space`, and applicable `-tab` presets, including agents in this tab.
- **BREAKING**: Remove `-current` actions and entrypoints; users must rename their Herdr bindings to `-space`. Remove scope-specific configuration keys with replacement diagnostics rather than silently merging them.
- **BREAKING**: Ctrl+C selects This tab instead of closing; Esc remains the default close key. Replace the old scope-specific in-popup picker shortcuts.

## Capabilities

### New Capabilities

- `picker-scopes`: Four-type scope matrix, chosen/effective scope carryover, origin-based filtering, and direct launch presets.

### Modified Capabilities

- `picker-keybindings`: Four picker actions, three scope actions, lifecycle-safe transitions, and per-type memory.
- `picker-footer-layout`: Compact four-picker footer and persistent scope state near the prompt.
- `plugin-configuration`: Per-type prompts/columns, unified settings lifecycle, and explicit legacy-key migration.
- `picker-column-order`: Scope-independent default columns and matching fields.
- `picker-refresh`: Scope-aware refresh, cancellation on type/scope changes, and shared per-type recovery memory.
- `plugin-distribution`: New public action inventory and user-facing configuration/launch migration documentation.
- `pane-picker`: Rename pane launch presets and replace scope-specific presentation with the shared type/scope model. This capability is supplied by the prerequisite `add-pane-picker` change and is not yet in main specs.

## Impact

Implementation touches `herdr-plugin.toml`, both Lua entrypoints, `pickr.core`, `runtime`, `keymap`, `columns`, and `config`, plus Lua unit/real-fzf PTY/relocation/documentation checks and README. No new runtime dependency or platform change is proposed.

Sequence implementation and spec synchronization after `remember-per-view-search-and-selection`, then `add-pane-picker`. Reuse their identity-restoration and immutable-origin machinery; this change deliberately replaces their scope-specific memory/configuration/shortcut contracts. The prerequisite artifacts are not edited by this proposal. Its deltas target the resulting combined spec baseline and must be synchronized last.
