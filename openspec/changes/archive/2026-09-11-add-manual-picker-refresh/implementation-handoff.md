# Implementation handoff

## Implementation

- `core.lua`: shared snapshot transformation, explicit ready/loading/error/closed
  session state, saved identity and generation checks, Ctrl+L hints, captured
  original-workspace rendering, and active-generation acceptance.
- `runtime.lua`: asynchronous cancellable jobs, bounded snapshot decoding,
  session-local owner/fzf sockets and candidate file, ordered clear/fetch/reload/
  match/restore acknowledgements, retry handling, and close/switch cleanup.
- `main.lua`: noninteractive control-helper dispatch alongside preview dispatch.
- `test.lua`: session, cancellation, original-scope, and candidate fixtures.
- Temporary `test-refresh.py` / `test-refresh-fixture.lua`: used real interactive
  fzf in a PTY with controlled snapshots and recorded focus calls; removed at the
  user's request after acceptance was completed.
- `README.md`: shortcuts, loading/retry semantics, fallback, refreshed preview
  targeting, supported fzf baseline, and regression commands.

Existing publication edits were present before implementation and were retained.

## Commands and outcomes

Verified on macOS with fzf `0.74.3 (Homebrew)` and Python `3.14.7`.

The commands below record historical acceptance results. The two PTY harness
files were subsequently removed at the user's request, so their Python commands
are no longer available in this checkout. `test.lua` remains available.

| Command | Outcome |
| --- | --- |
| `lua "$HOME/.config/herdr/plugins/pickr/test.lua"` | Passed. Existing formatting, column matching, worktree annotations, ordering, preview IDs, focus dispatch, all 25 switch routes, plus session transitions, retry identity, late-generation rejection, captured workspace scope, asynchronous success, timeout, cancellation, and cleanup. |
| `python3 -u test-refresh.py` | Passed: all 75 controlled PTY scenarios, including real fzf actions and the production asynchronous controller. |
| `python3 -u test-refresh.py --switch-only` | Passed: 15 ready/loading/error source-to-destination checks across all five variants. Also included in the successful full run. |
| `git diff --check` | Passed. |

The Lua picker flag/filter fixtures substitute `runtime.run_picker`; the removed
PTY suite exercised the real controller and helper entry point. No test focused live
Herdr entities. These checks establish controlled macOS/fzf refresh behavior;
they do not replace the separate publication change's live Herdr/Linux checks.

## Interactive coverage

Each of the five variants passed:

- Refresh clears candidates, retains the column header, and displays a
  non-selectable loader; delayed Enter does not focus or become deferred.
- Live query edits survive completion. Duplicate Ctrl+L is ignored.
- Stable IDs survive changed labels and agent status-driven reordering;
  accepting the refreshed row dispatches the same entity ID.
- Hidden previews stay hidden, toggles remain usable during loading, and
  reopening the preview uses the refreshed remembered tab/workspace pane.
- Initial empty lists, removed entities, entities no longer matching, preserved
  zero matches, zero-to-new-matches, and successful empty snapshots behave as
  specified; empty-to-populated lists update the footer.
- Fetch failure, JSON parse failure, timeout, and rendering failure show retry
  text with no stale rows. Enter is inert. Retry retains identity, query, and
  preview visibility and fetches exactly one new snapshot.
- Closing during a delayed fetch completes in under 0.6 seconds and removes
  the source session directory.
- Switching from ready, loading, and error states removes source resources in
  under 0.6 seconds; the destination resets the query, starts with preview
  visible, and is unchanged after the source's original completion deadline.

## fzf support and ordering

The supported baseline remains **fzf 0.74.3+**. Verified primitives:
`--listen=<path>.sock`, `reload`, `load`, `result-final`, synchronous `transform`,
`{1}` and `{*f1}`, `pos`, `refresh-preview`, `change-header`, `change-footer`,
`unbind`, and `rebind`. Native tracking is not needed across the cleared list.

The owner starts fetching only after fzf acknowledges the cleared list. Once
new data loads, `result-final` supplies the matching ID list for the current
query. A synchronous transform restores the position and updates the preview
target; a following acknowledgement publishes the active acceptance map and
re-enables Enter/Ctrl+L. No old query or asynchronous GET-derived position is
reapplied. No blocking subprocess runner is called inside controller callbacks.

## Resolved diagnostic issues

- The first probe used HTTP/1.0/GET content-length framing rejected by fzf with
  `400 invalid content length`. The harness now uses HTTP/1.1, sends length only
  for POST, and posts actions to `/` without GET query parameters.
- The harness drains PTY output while awaiting HTTP responses and answers
  cursor-position/bracketed-paste queries so terminal startup cannot deadlock.
- Position updates are asynchronous relative to HTTP POST acknowledgement;
  tests wait for the actual position before capturing a saved ID.
- Final acceptance found the controller's ready state could precede fzf's
  restored highlight. The added post-position acknowledgement removes that
  ordering race; the final full PTY run passed.
