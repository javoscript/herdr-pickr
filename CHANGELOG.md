# Changelog

## Unreleased

## v0.3.0 (2026-09-14)

- Add opt-in automatic candidate and selected-preview updates for all picker
  types and scopes through `refresh.interval_ms`, disabled by default. Set it
  to `1000` for one-second updates, then close and reopen Pickr to apply it.
- Keep displayed results usable while fetching fresh candidates and after
  recoverable failures, with automatic retry when periodic refresh is enabled.
- Refresh selected visible previews asynchronously, allowing slow captures to
  finish and cancelling obsolete work when selection, visibility, or views change.
- **Breaking:** Refresh no longer clears results or disables acceptance throughout
  fetching and failure. Final replacement uses native fzf identity tracking and
  can ignore keystrokes; preview refresh returns scrolling to the top. Reopen
  Pickr after updating, and repeat an input if it coincides with replacement.
  Existing configuration requires no key renames.

## v0.2.0 (2026-09-14)

- Add pane picking across all spaces, the original space, or the original tab,
  with exact-pane previews and focus, including ordinary terminals and embedded
  plugin panes while excluding popup overlays and detached panes.
- Unify Spaces, Tabs, Panes, and Agents with shared scope controls and twelve
  direct launch presets, including agents in the original tab. Carry the chosen
  scope across types and display effective and remembered scope near the query.
- Remember each type's search and highlighted entity for the lifetime of the
  popup. Preserve queries and eligible selections through scope changes,
  refresh, and retry, with independent memory for Panes and Agents.
- Keep configured columns and searchable space/tab context stable across scopes.
- Refresh the README showcase with five picker screenshots.
- **Breaking:** Rename `tabs-current` and `agents-current` launch actions and
  pane entrypoints to `tabs-space` and `agents-space`. Update Herdr bindings and
  reload configuration. For direct launches, replace scope `current` with
  `space` and `lua src/main.lua workspaces all` with `lua src/main.lua spaces`.
- **Breaking:** Consolidate `tabs_current`/`tabs_all` and
  `agents_current`/`agents_all` leaves under `keys`, `columns`, and
  `prompt.variants` into `tabs` and `agents`. Legacy settings are rejected;
  manually choose the desired per-type overrides. Type and scope shortcuts
  are now separate actions.
- **Breaking:** Default type shortcuts are Ctrl+S/T/R/A for
  Spaces/Tabs/Panes/Agents; Ctrl+Z/X/C select All spaces/This space/This tab.
  Ctrl+C no longer closes the picker; use Esc. If a close override includes
  Ctrl+C, remove it or remap/disable `scope_tab`, then reopen Pickr.
