## Why

Picker rows currently remain a launch-time snapshot, so agent status changes and other metadata become stale while the popup is open. An explicit refresh lets users retrieve current values without losing their search or selection context.

## What Changes

- Add `Ctrl+L` to refresh the complete candidate list in all five picker variants and advertise it in the footer.
- Replace results with a non-selectable loading state during fetching; disable acceptance until refreshed results are ready.
- Preserve the search query, preview visibility, and highlighted entity by stable ID while rebuilding rows and applying existing ordering rules.
- Fall back to the first matching result when the previous entity disappears or no longer matches; leave selection empty when there are no matches.
- Show a retryable error state on refresh failure rather than redisplaying stale candidates.
- Ignore overlapping refresh requests and cancel pending refresh work when closing or switching variants.

## Capabilities

### New Capabilities

- `picker-refresh`: Manual refresh, loading/error states, interaction continuity, and refresh lifecycle across all picker variants.

### Modified Capabilities

None. Existing column-order and pane-label requirements continue to apply to rebuilt rows.

## Impact

- `core.lua`: picker state, candidate rebuilding, fzf bindings, stable-ID selection validation, and footer messages.
- `runtime.lua` and `main.lua`: refresh subprocess/control integration and cancellation as needed.
- `lib/process.lua`: existing blocking process API may require a compatible extension or picker-local asynchronous companion for cancellable refresh work.
- `test.lua` and `README.md`: regression coverage and user-facing refresh documentation.
- Reuses Herdr's read-only snapshot API and the installed fzf; no periodic polling or new Herdr API is required. Exact fzf action integration and required version will be verified during implementation.
