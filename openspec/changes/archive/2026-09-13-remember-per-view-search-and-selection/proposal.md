## Why

Switching Pickr views currently discards the search and highlighted selection, making a quick detour to another view interrupt the user's navigation. Remembering each view's place within an open popup makes the five views useful as connected working contexts.

## What Changes

- Remember each of the five views' query and highlighted entity independently for the lifetime of one popup.
- On returning to a view, fetch fresh candidates, restore its query, and highlight its remembered entity if still present and matched; otherwise highlight the first match or nothing for zero matches.
- Start first visits with an empty query and discard all view memory when the popup closes. Invoking the current view's shortcut follows the same save-and-restore behavior.
- Preserve the latest query when switching during refresh or after refresh failure, retaining the pre-refresh selection identity as that view's restoration target.
- Keep original-space scoping, shared preview visibility, existing ordering, configured shortcuts, and manual refresh semantics.
- **BREAKING**: View switching no longer unconditionally clears the query; this intentionally replaces the documented reset-on-switch behavior. No configuration migration is needed.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `picker-keybindings`: Replace reset-on-switch lifecycle behavior with popup-local, per-view query and selection memory, including first visits, revisits, same-view shortcuts, and empty results.
- `picker-refresh`: Preserve source-view memory when switching during refresh or failure while retaining cancellation, retry, and identity-restoration guarantees.

## Impact

- `src/pickr/core.lua`: Popup-owned view memory, destination initialization, and switch result handling.
- `src/pickr/runtime.lua`: Capture the actual fzf query and selected ID at switch time, restore matching selection on entry, and preserve loading/error restoration identity through teardown.
- `tests/test.lua` and `tests/fzf_actions.lua`: Update reset assumptions and cover round trips and real-fzf output/restoration behavior.
- `README.md`: Document per-view memory, fallback, and popup lifetime.
- Uses existing Lua/luv/fzf dependencies and Herdr snapshot/focus APIs. No persistent history, new views, new settings, or automatic refresh.
