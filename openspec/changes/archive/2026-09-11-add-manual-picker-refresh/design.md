## Context

See `proposal.md` for motivation and `specs/picker-refresh/spec.md` for the behavior contract.

`core.candidates` fetches one snapshot and derives all rows, headers, ordering, and preview targets. `pick_once` supplies that data to one blocking `runtime.run("fzf", ...)` call. Variant shortcuts exit fzf and start the destination variant in the same popup. Acceptance currently compares the complete returned row against the initial rows, which cannot support updated metadata.

`runtime.run` delegates to `lib/process.lua`; it collects subprocess output and runs the luv loop until completion, with no caller-facing cancellation handle. Calling this blocking wrapper from a refresh callback would entangle event-loop ownership. Refresh therefore needs asynchronous lifecycle ownership rather than another synchronous call inside the active picker loop.

Installed fzf 0.74.3 exposes reload actions, `--track`, `--id-nth`, and a Unix-socket control interface. These are useful primitives, but interactive restoration across a deliberately cleared list is not established by the existing noninteractive filter tests. The design is cross-cutting across picker state, subprocess management, and fzf interaction, so a design artifact is warranted.

## Goals / Non-Goals

**Goals:**
- Keep a single fzf session alive for each variant while refresh transitions occur.
- Give one picker-session controller ownership of refresh state, accepted candidate identities, cancellation, and completion ordering.
- Reuse candidate formatting and ordering rather than create a second rendering path.
- Make loading, failure, and selection restoration observable in realistic interactive tests.

**Non-Goals:**
- Periodic polling, event subscriptions, or continuously streaming terminal previews.
- Changes to status priority, column organization, workspace grouping, or variant-switch reset behavior.
- A general rewrite of the shared subprocess library or a new external service.

## Decisions

### 1. Model refresh as an explicit picker-session state machine

The controller owns `ready`, `loading`, `error`, and `closed` states, a session/generation token, the last highlighted entity ID, and the current successful candidate ID map. Only `ready` permits acceptance; both `ready` and `error` permit starting a refresh. `loading` ignores further refresh requests.

```text
ready -- Ctrl+L --> loading -- success --> ready
                       |
                     failure
                       v
                     error -- Ctrl+L --> loading

any state -- close/switch --> closed
```

Snapshot the highlighted ID before clearing results. Preserve it through failed attempts and retry. fzf continues to own the live query and preview visibility, so typing or toggling the preview while loading is not overwritten by completion.

Alternative: exit and relaunch fzf for refresh, as variant switching does today. Rejected because it complicates uninterrupted input, preview visibility, and an interactive loading state.

### 2. Separate fetching from snapshot-to-row construction

Extract the snapshot transformation behind `core.candidates` so initial loading and successful refreshes use the same formatting, current-origin scoping, headers, ordering, and preview mapping. Refresh fetches one complete snapshot, with the existing bounded Herdr request timeout, rather than issuing per-row requests.

Publish header and rows as one completed generation. Empty success is distinct from failure. Recompute footer state so a picker that began empty does not keep its old `no entries` hint after receiving entries.

Alternative: update only status cells. Rejected because membership, labels, counts, and preview targets could then describe different snapshots.

### 3. Coordinate fzf updates through a session-local control channel

Use a picker-local asynchronous runtime controller and fzf's local Unix-socket action interface to coordinate refresh events, result reloads, and completion. Any helper entry point in `main.lua` is noninteractive and reports only its control/data result. Use luv for process and socket operations, retaining the existing blocking API for unrelated callers.

At refresh start, disable acceptance, capture identity, clear candidates, and show `Refreshing…` in a non-selectable presentation area while retaining the column header. Do not encode the loader or error as a normal candidate with a fake selectable ID. The control channel and any transient candidate files belong to a unique picker session and are cleaned up on all exits. Quote command paths and keep metadata out of executable action strings.

Keep the preview area's visibility unchanged; while there is no current candidate it may display an empty or loading placeholder. After successful restoration, refresh the preview using the newly published preview ID, including when only a tab's remembered pane changed. This is a refresh-time update, not periodic preview polling.

Alternative: basic reload while retaining old rows. Rejected because the agreed UX replaces stale results with a loader. A synchronous key action that blocks fzf is also unsuitable because closing and switching must remain responsive.

### 4. Restore and validate stable identity explicitly

The hidden first field already contains a pane, tab, or workspace ID; keep that identity separate from display text and the hidden preview pane field. Use fzf identity/tracking support where applicable, but do not rely on it to remember an item through an empty loading list.

After the refreshed list has loaded and matching has completed, locate the saved ID in the current matching results and restore the highlight. If absent, select the first matching result or leave the list unselected. Keep acceptance disabled until this restoration is complete. Restoration must use the current query, including edits during loading, and must not apply a stale position calculated before a newer filter result.

Validate accepted IDs against the active successful generation and focus that ID; remove dependence on exact equality with launch-time row text. Reject header, loading/error, malformed, and unknown IDs. Preserve existing focus dispatch for agents, tabs, and workspaces.

Alternative: preserve the cursor's row number. Rejected because status reordering could make Enter focus a different entity. Native identity tracking alone is insufficient without verifying its behavior across the cleared list.

### 5. Cancellation and failures are controller responsibilities

Retain an explicit handle for the snapshot subprocess, its timeout, and any refresh helper. On close or variant switch, invalidate the session generation before cancelling processes and releasing pipes, timers, sockets, and temporary data. Late callbacks check the generation and closed state before publishing anything. The destination variant receives its own controller and follows existing query/preview initialization behavior.

Fetch, parse, timeout, and refresh-rendering failures transition to a non-selectable retry message and clear the active acceptance map. Retry preserves the saved pre-refresh identity. A terminal fzf/control-channel failure instead terminates that session with normal picker error reporting; a retry UI cannot be promised if the UI process is gone.

Alternative: merely ignore late output and wait for the existing timeout. Rejected because it leaves refresh work running and can delay popup closure.

## Risks / Trade-offs

- [fzf action ordering and identity restoration across an empty list are not covered by current tests] -> Add an interactive integration check on installed fzf 0.74.3 before completing the controller; verify loader visibility, restoration after filtering, and Enter suppression with delayed fixtures. Record and document the required fzf version for the actions actually used.
- [Clearing results causes more visual movement than retaining stale rows] -> This is the selected UX; keep the column header and popup geometry stable and publish complete generations.
- [Query changes can invalidate a computed restoration position] -> Restore against the current matching results and keep acceptance gated through the load/match/restore transition.
- [Callbacks race with close or variant switching] -> Pair cancellation with generation checks and test late completion explicitly.
- [Existing tests mock the blocking runner] -> Preserve meaningful candidate/focus coverage while adding controller-level lifecycle fixtures and real interactive fzf checks; filter-mode tests alone cannot prove the new UX.
- [The working tree contains publication changes and vendored process code] -> Implement against the current project-local `lib` layout and reconcile touched call sites without reverting publication work.

## Migration Plan

No persistent data migration is needed. Add the binding, controller, tests, and documentation together. Verify all five variants and existing switching behavior before release, and document any fzf minimum-version requirement established by the integration checks. Rollback restores the launch-time snapshot picker path and removes the new refresh-specific binding/controller integration.
