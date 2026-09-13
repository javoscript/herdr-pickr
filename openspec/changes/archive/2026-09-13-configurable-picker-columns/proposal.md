## Why

Pickr currently fixes the displayed columns and their order in every view. Users need to prioritize the information they scan and remove unwanted columns, with search reflecting the information they chose to display.

## What Changes

- Add a `columns` configuration object with independent ordered column arrays for `spaces`, `tabs_current`, `tabs_all`, `agents_current`, and `agents_all`.
- Default to every existing column in its current order. Omitted/null settings retain defaults; overrides must be nonempty arrays of unique column names available in that variant.
- Render and search only configured columns, preserving independent per-column matching.
- Move or hide the status glyph and text together. Keep worktree and pane-label annotations attached to their columns.
- Preserve candidate ordering, scope, selection and preview targets, and launch-stable configuration through switching and refresh.
- Document the defaults, supported names, validation, and examples in README.md.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `picker-column-order`: Make existing column orders defaults; support ordered subsets, visible-only matching, and column-bound styling.
- `plugin-configuration`: Accept and validate per-variant column lists and preserve them in the launch settings snapshot.
- `agent-pane-labels`: Make pane-label display and search conditional on the pane column being visible.

## Impact

Configuration decoding and snapshot handling in `src/pickr/config.lua`; candidate/header rendering and fzf search-field selection in `src/pickr/core.lua`; configuration, rendering, matching, and session regression checks in `tests/`; and README.md configuration documentation. No new runtime dependencies or Herdr API changes are needed. Existing configurations retain their current display and matching behavior.
