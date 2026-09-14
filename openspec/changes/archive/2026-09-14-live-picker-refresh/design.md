## Context

See `proposal.md` for motivation and the delta specs for the behavior contract. This change warrants a design because it crosses configuration, session identity, fzf publication, asynchronous work ownership, and preview subprocess lifetime.

Current integration points:

- `core.snapshot_candidates` already renders complete scoped rows from one snapshot, with stable entity IDs, a hidden preview pane field, configured columns, and existing ordering. `tab_directories` resolves remembered focused panes, and Spaces follows `active_tab_id`.
- `core.Session:begin_refresh` currently empties the acceptance map and marks the session loading; `runtime.run_picker` clears fzf rows before fetching and gates accept/refresh keys. Failures keep that empty state. Those behaviors are explicitly superseded by this change.
- `runtime.run_picker` owns a luv loop, a private owner socket, an fzf listen socket, and a cancellable asynchronous snapshot request. Its current load/result-final/ready acknowledgements restore identity before publishing acceptance state. View transitions start a new picker invocation in the same popup.
- Preview helpers currently run `core.preview` once, making separate pane metadata and visible-screen reads. fzf owns the preview command. Periodic blind `refresh-preview` requests could restart slow helpers repeatedly.
- `config.decode` has strict root/leaf validation, and configuration handoff uses a versioned resolved settings snapshot. All settings must remain fixed for one launch.
- Existing Lua and real-fzf PTY fixtures cover loading/error locks, identity restoration, literal queries, transitions, preview visibility, and cancellation. The loading/error expectations need intentional replacement; entry-restoration expectations remain applicable.

## Goals / Non-Goals

**Goals:**

- Separate the last usable display generation from an in-flight update so background work never invalidates an otherwise selectable row.
- Keep fetch/preparation interactive and use native fzf identity tracking and input behavior during final publication.
- Bound timer, snapshot, preview, and control resources to their owning view/session.
- Reuse the existing full-snapshot rendering pipeline and supported fzf 0.74.3+ baseline.

**Non-Goals:**

- Streaming terminal emulation, Herdr event subscriptions, or continuous captures for unselected panes.
- Per-type or per-field intervals, runtime live-mode keybindings, or persisted popup state.
- Reworking initial/type/scope entry readiness, ordering rules, origin anchoring, or inherited binding policy.

## Decisions

### 1. One explicit interval and one snapshot pipeline

Add `refresh = { interval_ms = 0 }` to resolved settings and the documented default configuration. Use `1000` as the enabling example. Resolve omitted/null values to zero and validate finite integers in `0..2147483647`; the upper bound is a conservative portable timer limit, not a UI preference. Accept positive values without silently clamping them. These numeric boundary choices are planning defaults; the agreed behavior is disabled-by-default, configurable recurrence.

Use one repeating owner timer beginning one interval after view readiness. Its callback and the manual helper invoke the same request path. Skip triggers while fetching/preparing/publishing; do not queue missed ticks. A manual refresh does not reset the periodic cadence. A type/effective-scope transition creates a fresh timer after entry readiness, while a chosen-scope change with unchanged effective scope does not restart it. Hidden previews and empty results do not pause list updates.

Resolve and validate the interval in action/direct launches and resolved handoffs. Version the changed handoff schema consistently rather than accepting a missing interval through a new owner silently.

Alternative: separate preview/status/list timers. Rejected because full snapshots already provide consistent metadata and target selection, while separate cadences introduce inconsistent status/count/membership displays and extra API traffic.

### 2. Display readiness and refresh progress are independent

Retain a published generation containing rows, header, and the acceptance map. Track refresh generation/progress/error separately. Beginning a refresh does not clear the published generation, change a ready view to entry-loading, or unbind acceptance. A failed fetch, decode, render, validation, or staging operation leaves the published generation intact.

Represent the lifecycle conceptually as:

```text
Ready display G --trigger--> Ready display G + fetch H
                                  |
                     +------------+------------+
                     |                         |
                   success                   failure
                     |                         |
               Publish display H       Display G + error
                     |                         |
                     +------------+------------+
                                  |
                       next permitted trigger
```

Use the existing status area for a compact progress/error message, keeping footer and scope layout stable. Failure text identifies failed refresh and only advertises configured retry keys; automatic mode can additionally indicate it will retry. Keep the failure visible until successful recovery, avoiding recurring blank-list states. Control/terminal failures remain fatal if the owner cannot establish which generation is displayed.

Alternative: reuse the current loading/error state machine and briefly restore old rows. Rejected because it couples acceptance to fetch readiness and risks losing navigation during every tick.

### 3. Use native fzf publication and identity tracking

The user selected native fzf behavior after the input-preserving alternatives required more terminal ownership than desired. This supersedes the earlier bounded-buffering decision. Use `--id-nth=1` and native tracking with `reload-sync` over fully prepared local rows. fzf may ignore input during its final replacement/tracking window; no custom input buffer, PTY transport, or replay protocol is introduced. See `verification.md` for the investigation.

Stage and validate complete candidate rows/header before requesting replacement. Snapshot fetching, decoding, rendering, and file preparation occur outside native tracking, with the old display usable. fzf captures the current identity when processing the reload and matches the replacement against its query. Do not save or restore refresh-start query/selection. Let fzf handle cross-reload tracking and fallback; entry restoration retains its existing explicit one-shot handshake. Preview reads remain asynchronous and do not extend publication.

Do not add a separate acceptance lock while fetching or after recoverable failure. Native suspension during replacement is accepted, including potentially ignored keystrokes. Existing fzf transition/closing semantics apply. Busy refresh triggers skip without catch-up. After replacement, normal navigation must not be overridden by an owner-side restoration callback.

Validate returned rows against registered published, pending, or retiring candidate data, including results emitted before replacement acknowledgement. Focus only the exact entity ID in a validated returned row; a closed target produces normal focus failure without substitution. The contract follows fzf's emitted selection rather than imposing an atomic physical-keystroke/display-generation guarantee beyond fzf's native behavior.

Bound publication with one owner-controlled deadline, independent of the interval and Herdr timeout. A stalled replacement/control acknowledgement remains a fatal control error, with cancellation and no unconfirmed focus. Partial acknowledgements must not reset the deadline. Measure normal publication latency separately from this failure budget.

Verify retained-results acceptance during delayed fetch/failure, native tracking through changed row text/order, native fallback, registration before replacement, one-shot entry restoration, and fatal publication timeout in real fzf. Record native ignored-input behavior rather than treating it as a failure or promising buffering. Verify normal publication latency before enabling periodic scheduling.

Alternatives rejected: strict nonblocking publication and whole-window input buffering require stronger fzf primitives or additional input/terminal ownership. Idle-only publication reduces collision likelihood but still needs the same native swap and can leave results stale during interaction. Preview-only automatic refresh does not update candidate membership/status. Native publication delivers full live updates with the explicitly accepted input-lock trade-off.

### 4. Refresh preview content independently of row-text changes

After a successful candidate publication, request a fresh preview for the currently selected target even when candidate bytes did not change. Continue ordinary selection/show-triggered preview reads. Use the newly published pane target: exact pane for Panes/Agents, remembered focused pane for Tabs, and active tab plus remembered focused pane for Spaces.

Coordinate helper start/completion with the owner using view/target/request tokens. Skip redundant periodic requests while a same-target preview is in flight rather than blindly restarting it. Selection or target changes supersede the old request; hiding and shutdown cancel/invalidate it. A helper completion from an old target or generation cannot publish into the current preview. All helper completion/error paths must release busy state, with bounded timeout recovery for killed helpers, so cancellation cannot suppress future captures forever. Keep the one-shot direct `preview <pane-id>` behavior usable independently of an owner.

Preview reads remain asynchronous relative to list publication: a slow/unavailable preview must not stall list updates or invalidate their success. Hidden/no-selection states request no reads. Screen and metadata reads retain existing timeouts and unavailable/no-pane messages. Preserve ANSI screen colors and use native fzf preview scrolling, including resetting to the top on same-target refresh. The user explicitly accepted that native scroll behavior to avoid custom scroll tracking. Preview snapshots and metadata are separate Herdr reads, so they are not claimed to be one atomic server snapshot.

Alternative: a permanent preview streaming loop. Rejected because it creates another scheduler/lifetime owner and diverges from the single refresh cadence. Alternative: unconditional periodic `refresh-preview`. Rejected because short intervals could starve slow captures.

### 5. Cancellation and view memory use displayed state

Keep generation checks for callbacks, but distinguish view identity from snapshot attempt identity. Close, acceptance, and effective transitions stop/close timers, cancel snapshot work, invalidate preview work, and release control resources promptly. Late callbacks cannot post actions or alter another view.

For ready views, transitions and acceptance capture current displayed query/selection even during fetch or after failure. Remove the old preference for refresh-start `saved_id` from those paths. Keep pending entry restoration semantics only for a view whose entry has not become ready. First-match and no-match publication results replace older selection memory.

## Risks / Trade-offs

- **Native input suspension** -> Keep all Herdr work and preparation outside replacement, measure its normal latency, and document that keystrokes during the native swap can be ignored. Do not promise buffering or custom atomic acceptance semantics.
- **Stuck publication** -> Enforce one end-to-end deadline with fatal control-error cleanup.
- **High configured frequency** -> Single-flight candidate work, skipped ticks, and same-target preview coalescing bound outstanding work. Document cadence as best-effort attempt timing; recommend 1000 ms rather than claiming a real-time guarantee.
- **Retained results can refer to closed entities** -> Show refresh failure explicitly; preserve exact-target focus failure instead of silently selecting another pane.
- **Agent priority changes move rows while browsing** -> Follow selected ID and existing sort semantics; opt-in scheduling lets users choose whether this happens automatically.
- **Broad state-machine regression surface** -> Keep entry restoration distinct and run existing scope, keybinding, hidden-footer, columns, memory, and cancellation checks alongside new refresh scenarios.
- **Stale preview or leaked busy state after cancellation** -> Token-check both helper start and completion and cover slow/killed/error helpers, hide/show, and target changes in real-fzf tests.

## Migration Plan

1. Land configuration, lifecycle/publication changes, preview coordination, and regression coverage together. Automatic refresh remains disabled for existing config files.
2. Update README defaults, enabling example, cadence/bounds, preview-target behavior, retained-results errors, and acceptance during manual refresh. Distinguish interactive fetch/preparation from native fzf replacement, which can ignore input; keep entry-restoration documentation accurate.
3. Users reopen Pickr to apply the new launch snapshot. No user configuration is rewritten. Manual refresh changes immediately for all newly opened sessions.
4. To roll back, close active popups, remove the new `refresh` object from user config before running an older strict-config version, and restore the previous plugin version. Existing files without the new object require no configuration rollback.
