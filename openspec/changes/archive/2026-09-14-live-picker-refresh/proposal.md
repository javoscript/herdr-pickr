## Why

An open picker goes stale while agents work and terminal metadata changes, requiring repeated manual refreshes to see progress. Manual refresh currently clears usable results and disables acceptance, which would be disruptive for recurrent updates and is unnecessary for an explicit refresh too.

## What Changes

- Add opt-in automatic refresh across Spaces, Tabs, Panes, and Agents using one launch-stable `refresh.interval_ms` setting; omitted/null/zero disables scheduling.
- Refresh the complete scoped candidate set, including additions, removals, status text and indicators, titles, labels, counts, directories, ordering, and preview targets.
- **BREAKING**: Replace manual refresh's non-selectable loading/error behavior with the same background-refresh behavior used by automatic updates. Retain usable last-published results while fetching and after recoverable failures.
- Preserve the latest query and track highlighted entity identity through native fzf publication, retaining existing ordering and native fallback/no-selection behavior.
- Keep results usable while fetching, validate fzf's returned entity, and accept native input suspension during final replacement (keystrokes can be ignored). Discard cancelled or obsolete work without introducing a custom terminal/input layer.
- Update the selected visible terminal preview after successful refresh, including unchanged rows and changed tab/space focus targets. Hidden previews skip screen reads while list updates continue.
- Permit only one refresh at a time, skip overlapping triggers, and show compact refresh errors with manual or automatic recovery.

## Capabilities

### New Capabilities

None; extend the existing refresh and configuration capabilities.

### Modified Capabilities

- `picker-refresh`: Unify manual and periodic background refresh, usable retained results, publication-time identity preservation, retry/cancellation, and recurrent preview updates.
- `plugin-configuration`: Add validated `refresh.interval_ms` with disabled defaults and consistent launch-snapshot handoff semantics.

## Impact

- `src/pickr/core.lua`: Separate displayed candidate readiness from refresh progress and retain exact acceptance identity.
- `src/pickr/runtime.lua`: Schedule/cancel refresh work, coordinate fzf publication and live selection, and refresh previews without slow-capture starvation.
- `src/pickr/config.lua`: Resolve, validate, and hand off the interval for every launch path.
- Lua session/configuration tests and real-fzf PTY checks: Replace old clearing/error expectations and verify races, timing, visibility, and lifecycle behavior on the supported fzf baseline.
- `README.md`: Document live updates, full default configuration, interval semantics, and the new manual refresh/failure behavior.
- Reuse Lua/luv, the Herdr snapshot and pane-screen APIs, and fzf control facilities; no new dependency or launch action is planned. Type/scope entry restoration remains distinct from refreshing an already displayed view.
