## Why

Pickr can focus tabs and agent panes, but ordinary shells, editors, and test runners inside split tabs lack a direct searchable destination. Three pane scopes let users find a nearby split, a terminal in their project space, or a terminal whose location they have forgotten.

## What Changes

- Add three directly launchable and internally switchable views: **Panes in this tab**, **Panes in this space**, and **Panes in all spaces** (`panes-tab`, `panes-current`, `panes-all`).
- List ordinary tab-layout panes, including agent panes and plugin terminals embedded in tab layouts, without listing transient popup overlays. Preview and acceptance target the exact selected pane.
- Capture the original tab as well as workspace for every popup launch, so narrow scopes remain anchored while switching and refreshing.
- Show configurable status, title, pane ID/label, directory, and scope-appropriate tab/space columns. Preserve space/worktree grouping and tab/layout order rather than agent-priority sorting.
- Add `panes_tab`, `panes_current`, and `panes_all` configuration variants, with proposed default shortcuts `Alt+1`, `Alt+2`, and `Alt+3`. Append explicit pane hints to the existing variant footer row; retain two-row clipping and hint visibility behavior.
- Extend popup-local per-view memory and manual refresh to all eight views, including independent memory for each pane scope.
- **BREAKING**: New default pane shortcuts can conflict with user-assigned Pickr actions or supersede inherited fzf bindings on those keys. Existing conflict diagnostics remain; users can remap or disable the new shortcuts.

## Capabilities

### New Capabilities

- `pane-picker`: Three pane scopes, launch context, eligible panes, stable ordering, pane metadata, exact-pane preview and focus.

### Modified Capabilities

- `picker-keybindings`: Add pane actions and extend switching and per-view memory from five to eight views.
- `picker-refresh`: Include pane variants and original-tab scoping in the manual refresh contract.
- `plugin-configuration`: Add pane prompts/columns and extend launch settings to eight views; reconcile legacy reset-on-switch wording with per-view memory.
- `picker-column-order`: Define the three pane layouts within the shared relative column order.
- `picker-footer-layout`: Append three explicitly scoped pane hints within the existing two-row footer.

## Impact

- Depends on implementing and synchronizing `remember-per-view-search-and-selection` first. This package's overlapping deltas target that resulting behavior; archive it after the memory change. It does not edit the earlier change's artifacts.
- Affects `herdr-plugin.toml`, `src/open.lua`, `src/main.lua`, `src/pickr/core.lua`, `runtime.lua`, `keymap.lua`, `columns.lua`, and `config.lua`.
- Extends Lua rendering, configuration, launch-context, focus, refresh, and real-fzf PTY fixtures, including the switching matrix from 25 to 64 routes.
- Updates README feature inventory, launch examples, defaults, columns, scope semantics, and view-memory usage during implementation.
- Uses Herdr 0.9.0's existing pane metadata, snapshot layouts, plugin invocation context, visible-screen read, and `pane.focus` API; no new runtime dependency or minimum-version increase is planned.
