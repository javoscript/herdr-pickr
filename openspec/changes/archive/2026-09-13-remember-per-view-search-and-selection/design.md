## Context

See proposal.md for motivation. `core.pick` owns a popup-lifetime object containing preview visibility and loops over `pick_once`; each switch starts a fresh fzf process and snapshot. The current output protocol uses an optional `--expect` key record followed by a selected row and deliberately omits a query. Both core and runtime currently parse portions of that output.

`Session` owns a single view invocation's candidate IDs and refresh generation. Refresh clears its acceptance map and stores `saved_id`; runtime restores that ID against fzf's actual matching IDs at `result-final`, then acknowledges readiness before allowing acceptance. Closing a view invalidates that session and cancels pending work. The existing specs and switching tests explicitly require query resets, which this change intentionally replaces.

This design spans core's popup lifecycle and runtime's fzf protocol, so a design artifact is needed.

## Goals / Non-Goals

**Goals:**
- Capture the query and selection actually present at switch time, without asynchronous observations racing keyboard input.
- Keep view memory independent of rendered rows, candidate ordering, and short-lived refresh sessions.
- Restore selection only after matching the restored query against fresh data.

**Non-Goals:**
- Persistent history, shared memory between popups, per-view preview visibility, or cached candidate lists.
- Restoring query cursor position, scroll offset, or preview scroll position.
- New settings, bindings, view types, refresh scheduling, or changed snapshot failure policy on view entry.

## Decisions

### 1. Own memory in the popup and key it by the five existing variant names

Extend the popup-owned state with a map from `tabs_current`, `tabs_all`, `spaces`, `agents_current`, and `agents_all` to a query and optional selected entity ID. Absence means never visited. Create this map for each `core.pick` call and discard it when that call ends. Keep preview visibility shared in the existing popup field.

Save the source before looking up the destination, including a shortcut targeting the current view. This makes all 25 switch routes follow one rule. Each invocation still fetches fresh candidates using the original-space context and resolved launch settings.

Alternatives: Per-invocation Session storage would disappear during switching; module-global or disk storage would leak context between popups. Caching rows would hide membership and metadata changes.

### 2. Capture query and selected row through a single owned fzf exit protocol

Use fzf's `--print-query` with `--print0` to obtain NUL-delimited output records, retaining `--expect` only when configured view shortcuts exist. Parse once in runtime: query, optional expected-key record, and optional selected row. Return a structured result to core rather than maintaining two competing parsers. Candidate input remains newline-delimited; output framing is independent and preserves query whitespace, Unicode, and delimiter-like text without shell evaluation.

Capture switch memory before `session:close` clears the active candidate map. In a ready session, validate the selected row against the active IDs; no selected row means no remembered selection. During loading or refresh error, use `session.saved_id` instead of a placeholder or absent row. Only a recognized configured switch result commits memory; acceptance retains existing active-ID validation and closing never focuses an entity. Code 1 switches with empty/zero-match results still save the query.

Initialize a destination query through an argv `--query` option, never through shell interpolation or a constructed fzf action containing query text. Update fixtures and internal result consumers together, including the no-`--expect` path when optional actions are disabled.

Alternatives: An asynchronous fzf state request can lag the last edit; saving on every change adds unnecessary control traffic. Line-based output complicates literal query framing. Replacing all switch shortcuts with new control-helper bindings adds lifecycle machinery when fzf already emits exit state.

### 3. Reuse identity-based match completion for entry restoration

For revisits with a saved ID, extend the existing load/result-final/ready handshake to cover the initial candidate generation. Start matching with the destination's saved query and restore by ID in fzf's actual ordered match set. Use the first match if the ID is absent or filtered out. Do not compute positions from unfiltered Lua rows or rearrange candidates to force the remembered entity to the top.

Keep acceptance gated until positioning and preview targeting are acknowledged. Query edits, close, preview toggle, and configured switches remain available during restoration; later edits must not be overwritten with the saved query. Track the restoration target while entry restoration is pending so a rapid switch away does not save a transient first-row selection. On successful restoration, normal ready-state selection capture becomes authoritative; later user navigation replaces the old target. First visits and revisits without a saved ID use ordinary first-match behavior.

Restoration is one-shot per entry, not a continuous rule that moves the user's highlight on every query edit. Reuse the current refresh generation checks and release all view-owned resources on switching.

Alternatives: A fixed row number fails after sorting or membership changes; fzf focus tracking within one process cannot bridge the current separate-process switch architecture. Keeping one fzf process for all views would be a much broader rewrite.

### 4. Retain refresh recovery identity, but never retain stale candidates

When leaving a loading/error view, save the latest exit query with its pre-refresh saved ID. Revisit performs the normal fresh snapshot and restored-query match, not restoration of the old loading/error UI. Cancellation and generation invalidation still happen before the destination runs. After a successful refresh, save whichever refreshed entity is highlighted at the next switch, including the first-match fallback or no selection.

This preserves the recovery intent already present in Session while preventing stale rows from becoming selectable. Empty ready-state results save an absent ID; they do not resurrect an older selection on a later visit.

## Risks / Trade-offs

- [Changing fzf output framing affects acceptance as well as switching] -> Parse once and verify real fzf on the supported baseline for default/remapped keys, blank query records, code 1 switches, and no-expect launches.
- [Initial match events can race acceptance or a rapid second switch] -> Use the synchronous readiness handshake, one-shot restoration state, and identity fallback while restoration is pending; exercise real PTY interactions.
- [Restoring an ID into a reordered list can select the wrong row if matching state is stale] -> Resolve against `result-final` IDs, as refresh already does, and confirm previews target the refreshed pane.
- [Users accustomed to switching as a query reset see changed behavior] -> Document the new default and explain that ordinary query-clearing bindings remain available.
- [More state paths increase regressions in refresh teardown] -> Cover switching during loading/error, latest query edits, cancellation, and ignored late completions alongside existing retry checks.

## Migration Plan

Implement the result-protocol update and its consumers together, then add popup memory and entry restoration. Update switching assertions and README usage in the same implementation change. Run `lua tests/test.lua`, including its real-fzf PTY checks, and review the documented behavior. No user data or configuration migration is required. Rollback restores the previous switch/output behavior; popup-local memory leaves no persistent data to migrate.
