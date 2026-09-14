# Implementation verification

## Final verification summary

The native fzf implementation and its integrated regression checks are complete.
Automatic refresh remains opt-in (`refresh.interval_ms = 0` by default). Manual
and automatic refresh share retained-results fetching, recoverable errors,
native identity tracking/publication, and asynchronous selected-preview renewal.
The user explicitly accepted both native input suspension during replacement
and native preview scroll reset, avoiding custom input/terminal/scroll ownership.

Checks passed after the final implementation, documentation, and fixture changes:

- `lua tests/test.lua`, including the newly integrated `live_snapshots.lua` and
  `live_refresh.lua` subprocess fixtures.
- `openspec validate live-picker-refresh --strict`.
- `git diff --check`.

### Delta scenario review

| Contract/scenario group | Implementation and verification |
| --- | --- |
| Missing/null/empty/default configuration; strict root/leaf validation; interval boundaries; independent keys/visibility; launch snapshot and reopen | `config.lua`; `configuration.lua`, `unified_configuration.lua`, `pane_launch.lua`, `columns.lua`, and documentation defaults checks. v3 handoffs require the resolved interval; malformed/incompatible handoffs never reread settings. |
| Every type/scope; metadata/membership changes; empty and zero-match lists; disabled refresh shortcut | Full snapshot rendering remains shared. `snapshot_fixture.lua` changes workspace/tab/pane membership, moves panes, changes statuses/priority/labels/titles/counts/directories and remembered preview targets. `live_snapshots.lua` checks all nine effective views and reordered columns/custom colors; `live_refresh.lua` runs all nine through actual recurring fzf publication. |
| Slow fetch/preparation failure; edited query/current selection; acceptance aliases; native publication input behavior | Separate display and refresh state in `core.lua`; retained old/pending/retiring row validation. Focused PTY tests accept through both aliases during slow fetch and failure. Native tracking follows changed text/order; the historical probe demonstrates the explicitly accepted ignored-input behavior. |
| Highlighted identity reordering/deletion/filtering; native fallback/no-match; navigation after publication; exact closed-target failure | Native `track-current`/`--id-nth=1` plus `reload-sync`; no refresh-start position replay. Live and existing fzf memory/columns/pane fixtures cover fallback and later navigation. `live_snapshots.lua` verifies a closed displayed pane produces one exact-target focus failure, without substitution. |
| Failure/retry, disabled controls, automatic recovery, failed empty display | Retained display map and compact status survive fetch/preparation failure. Unit staging/error tests include empty displays; PTY failure/retry/empty/disabled-footer cases and automatic recovery pass. Error text uses only configured retry keys and identifies automatic retry when enabled. |
| Single flight, close/accept cancellation, type/scope switches during fetch/failure, literal queries, latest selection memory, late callbacks | Existing `fzf_actions.lua`, `unified_fzf.lua`, `panes.lua`, and lifecycle fixtures now use retained displayed state; unfinished entry restoration keeps its separate pending identity. Source callbacks are generation-checked and shutdown closes timers, captures, sockets, and fetch work. |
| Interval zero, first tick after readiness, skipped busy ticks, independent popups, fresh destination cadence, unchanged-effective-scope choice | `live_refresh.lua` checks request timestamps/counts, hidden previews and disabled manual refresh, empty/no-match recovery, overlap cancellation, effective transitions and state-only scope changes, and two simultaneously running popups with independent 500/700 ms cadences. |
| Unchanged-row preview renewal; exact pane/agent targets; changed tab/space focus; no-pane/unavailable recovery; ANSI; hidden/no-selection reads | All-view full-snapshot PTY matrix and direct asynchronous metadata/screen pipeline tests pass. Captures use exact pane IDs and preserve ANSI content. Missing targets perform no Herdr read; unreadable captures stay preview-local. Hidden/zero-match fixtures confirm no further captures. |
| Slow capture exceeds interval; killed/detached helper; target changes/hide/close; no obsolete output | `live_preview.lua` owns capture tokens and coalesces the current target independently of helper lifetime. Unit callbacks after cancellation cannot publish; PTY slow-capture and changed-target tests show current output without starvation or obsolete content. Metadata and screen subprocesses retain bounded timeouts. |
| Native preview scrolling, hide/show, selection changes, shrinking content | Real fzf scrolls capture 1 to the bottom, then shows capture 2 at the top as approved. The shrinking-content fixture shows the entire new short preview. No custom scroll tracking or offset-preservation promise remains. |
| Publication deadline | One 2000 ms production deadline covers prepared replacement through publication acknowledgement without resetting on partial progress. A deliberately stalled result acknowledgement exercises fatal cleanup with a 350 ms fixture deadline and no focus. |

### Environment and measurements

Verified on macOS with the installed fzf 0.74.4 and Lua/luv. The final integrated
run measured **61.7 ms** from prepared replacement to owner publication
acknowledgement for its small fixture. This is not a measurement of input-lock
duration, a maximum latency guarantee, or an estimate for all candidate counts.
Earlier passing focused samples ranged approximately 50–69 ms. The 2000 ms
deadline is a failure bound, not expected normal latency.

The PTY harness uses macOS `script`/`stty`; Linux PTY execution and an actual
fzf 0.74.3 binary were not tested. Baseline 0.74.3 source was reviewed during
the native-tracking investigation. Live fixtures explicitly retry only their
final exit key because native replacement is permitted to ignore that key;
the separate publication probe records this behavior directly.

After implementation verification completed, the user's Herdr-managed local
Pickr configuration was set to `refresh.interval_ms = 1000` and loaded through
the production configuration resolver. The existing theme, prompt, and key
overrides were verified unchanged. This does not change the plugin's global
default. OpenSpec apply instructions report `all_done` with 14/14 tasks complete.

## Historical checkpoints

The sections below record intermediate findings and superseded decisions. Their
pending-task/blocker statements describe those earlier checkpoints, not the
final implementation status above.

## Current decision: native fzf publication

The user selected native fzf refresh behavior to avoid custom input/terminal
ownership. This supersedes the earlier strict nonblocking and input-buffering
decisions recorded below. Fetch/preparation stays interactive; final local-file
replacement uses native identity tracking and can ignore keystrokes. Pickr
validates returned targets and bounds stalled publication, without promising
buffered replay or atomic physical-keystroke/display semantics. Historical
probe observations remain evidence of the accepted trade-off, not blockers.

## Native implementation checkpoint

Implemented retained display/acceptance state, pre-swap candidate validation,
native local-file reload and identity tracking, latest displayed transition
memory, a per-view repeating timer, and an owner-coordinated asynchronous preview
capture cache with target/request invalidation and same-target coalescing.
Metadata and visible-screen requests each retain their 10-second timeout and
are cancellable independently of fzf preview-helper lifetime. Direct one-shot
preview invocation remains available.

The complete existing `lua tests/test.lua` suite passed after the retained-results
and native-publication changes. Subsequent timer/preview changes were exercised
by `lua tests/live_refresh.lua`; the focused tests pass for retained fetch/error/
preparation results, malformed staging, old/pending row validation, entry-vs-
refresh memory, native ID tracking, first tick after readiness, disabled manual
refresh, hidden/empty/no-match views, automatic recovery, overlapping triggers,
transition cadence, shutdown, publication timeout, target changes, same-target
slow captures, detached helpers, and obsolete capture invalidation. The full
existing suite also passed after the timer, preview, and README changes, as did
strict OpenSpec validation and whitespace checks. Registering the focused live
fixture in the entrypoint and the remaining coverage review are still pending.

Measured normal publication samples on macOS/fzf 0.74.4 were 56.0, 56.2, and
63.5 ms (prepared rows to owner publication acknowledgement). These are small
fixture samples, not an input-lock duration measurement or performance promise.
The production publication deadline is 2000 ms; the fixture verifies stalled
acknowledgement cleanup using a shortened 350 ms deadline. Native ignored-input
behavior is accepted and remains demonstrated by the publication probe.

### Remaining preview-scroll decision

The real-fzf preview fixture scrolls to the bottom of capture 1 and refreshes the
same selected pane. Capture 2 appears at the top, not the previous offset.
Native `refresh-preview` resets the offset on the tested baseline, leaving task
4.3's scroll-preservation requirement unresolved. No custom scroll tracking has
been introduced and task 4.3 is not marked complete. A decision is needed on
accepting native preview scroll reset as well, or retaining that requirement
with additional preview controls. Remaining integration and coverage tasks stay
unchecked. The requested local 1000 ms setting is still pending completion.

The sections below retain the history of superseded publication investigations.

## Configuration and handoff

Tasks 1.1 and 1.2 are complete. Resolved settings include an independently
validated `refresh.interval_ms` in `0..2147483647`, defaulting to zero. Internal
launcher handoffs now use version 3 and require a valid resolved interval.
User configuration has no version field. Strict JSON numeric errors include
their field path, including `refresh.interval_ms` for overflow/non-finite input.

Verified with configuration/default/boundary/invalid-value fixtures, handoff
mutation and reopen fixtures, and all twelve action/direct launch entrypoints.
`lua tests/test.lua` passes on macOS with fzf 0.74.4. The first invocation reached
the command's 120-second timeout; the subsequent invocation with a 600-second
limit passed the complete suite, including real-fzf PTY checks. Those existing
refresh checks still describe the old runtime; passing them is not evidence
that live refresh is implemented.

## Publication investigation

The standalone `lua tests/refresh_publication_probe.lua` deliberately holds
replacement input or restoration acknowledgement. It investigates the mechanisms
proposed in design decision 3; it is not a completed implementation regression.
Initial selection is beta, and replacement moves beta after unrelated rows.

Results on fzf 0.74.4:

- Synchronous `result-final:transform(...)` acknowledgement held for 1200 ms:
  Enter arrives during the helper and eventually accepts beta, but waits until
  the helper completes. Observed total session duration was 2009 ms; Enter was
  sent at approximately 1000 ms.
- Replacement acknowledgement withheld while input remains available: Enter
  accepts unrelated replacement row `x` before beta is restored.
- Native `--track --id-nth=1` with `reload-sync` input delayed for 1200 ms:
  Enter during loading is ignored. A later Esc closes the picker with code 130.

The baseline source has corresponding mechanisms in
<https://github.com/junegunn/fzf/blob/v0.74.3/src/terminal.go>:
`UpdateList` replaces the merger and queues load/result events; the main loop
selects between input and event channels. Synchronous transforms execute in
that loop. Reload with ID tracking sets `trackBlocked`, which suppresses
acceptance actions until tracking finishes. The probe has not been run against
an actual 0.74.3 executable.

Further source review found that `--expect` can bypass the tracking lock for
acceptance but does not preserve typing, navigation, or preview controls. The
`untrack-current` action lifts the lock by clearing the restoration key. Row
generation tokens can validate output but do not prevent an intermediate
highlight, and asynchronous polling does not make selection capture and
replacement atomic. Upstream explicitly describes cross-reload tracking as
blocking the UI until the match is found:
<https://github.com/junegunn/fzf/issues/4718>.

Strict nonblocking publication was therefore judged not viable as a reliable
guarantee within the current Pickr architecture and unmodified supported fzf
control model. This is not a proof that every possible protocol is impossible:
a stronger fzf primitive or substantial input/rendering-ownership redesign
could change that conclusion, but is not selected for this change.

## Approved fallback: bounded publication wait

The user approved option 2 after the deeper option 1 investigation and confirmed
updating the design, refresh delta spec, tasks, and this verification record.
The revised contract permits input to wait only during final replacement,
matching, restoration, and acknowledgement. Fetch/preparation and recoverable
failure retain usable results without waiting; preview reads cannot extend the
publication window.

Acceptance already processed before publication retains its exact old displayed
target. Input buffered during publication is processed in order against a
coherent display after restoration, including legitimate first-match/no-match
fallback. Silent key loss, transient fallback acceptance, and obsolete source
input/work replay after close or transition remain prohibited. Busy refresh
triggers still skip rather than becoming queued catch-up requests.

Task 2.2 must establish and verify one finite end-to-end publication deadline,
fatal control-error cleanup on expiry, and normal measured publication latency.
The numeric budget and actual latency measurements are not yet established.
The existing probe's synchronous wait is now permitted in principle, but it does
not prove the complete bounded protocol or input-preservation contract. Native
tracking alone still fails that contract. The approved decision is not evidence
of implementation completion; tasks 2.1 onward remain unchecked.

Planning-only revision checks passed: `openspec validate live-picker-refresh --strict`
and `git diff --check`. Apply instructions report `ready`, with 2/14
tasks complete; this does not verify the revised runtime contract.

## Follow-up apply checkpoint: publication barrier blocked

The publication probe now also tests the two obvious ways to cover the entire
replacement window on fzf 0.74.4:

- `reload-sync(...) + transform(barrier)`: the barrier waits for 1200 ms and
  checks a marker written by the replacement command. The marker is absent:
  fzf has not started that command. Reload dispatch happens only after the
  current action chain returns, so holding this helper until reload completes
  would deadlock rather than form an input-preserving publication barrier.
- `reload-sync(...) + wait`: replacement input is delayed for 1200 ms. A `Q`
  and Enter sent during that delay do not survive; a later Enter closes with
  an empty query. This allows reload progress but discards input, violating
  the approved option 2 contract.

`lua tests/refresh_publication_probe.lua` reproduced both results and the three
earlier probe behaviors. It remains a diagnostic, not a passing implementation
regression. No runtime task was marked complete in this apply attempt.

The missing mechanism is input preservation across the entire replacement
window, not merely during a synchronous acknowledgement. A candidate next step
is an owner-controlled input buffer/private-terminal transport around fzf, with
an ordered boundary between previously forwarded input and publication. That
requires additional terminal ownership, lifecycle/resize handling, and PTY
support; the installed luv exposes TTY operations but no PTY allocation API.
The existing macOS test runner uses the system `script` command, which is not
currently a runtime dependency or a verified cross-platform runtime transport.
Neither that dependency nor the broader runtime architecture has been adopted.
Implementation is paused for approval of the added scope; silent input loss and
unbounded waits are not accepted as substitutes.

Scheduling and preview ownership are not implemented. The requested local
setting of 1000 ms is pending until implementation and verification finish,
as requested.
