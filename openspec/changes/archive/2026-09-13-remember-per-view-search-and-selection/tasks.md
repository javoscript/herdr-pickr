## 1. Capture reliable switch state

- [x] 1.1 Update the owned fzf output protocol in core/runtime to use `--print-query` and `--print0`, parse it once into a structured result, and adapt existing result consumers and mocks; verify default/remapped acceptance, cancellation, blank query records, empty/zero-match switches, and launches without `--expect` using protocol assertions and real-fzf PTY cases.
- [x] 1.2 Capture a validated selected ID before session teardown, using the pre-refresh ID during loading/error and no ID for ready zero-match results; verify loading/error placeholders cannot be saved or accepted and existing cancellation/active-ID checks still hold.

## 2. Remember and restore each view

- [x] 2.1 Add popup-local memory keyed by all five existing variants, save source state before destination lookup, and pass remembered queries as literal argv values; verify independent round trips, first visits, same-view shortcuts, and memory isolation across new popup calls in `tests/test.lua`.
- [x] 2.2 Extend the runtime's matching/readiness handshake to restore a saved ID on view entry against fresh matching candidates, with first-match/empty fallback and acceptance gating; verify reorder, rename, filtered-out/deleted IDs, zero matches, current preview targets, and one-shot behavior after later navigation in real-fzf tests.
- [x] 2.3 Preserve the pending restoration ID and latest query during a rapid switch away from entry restoration; verify switches and closing remain responsive and unfinished entry work cannot affect the destination.
- [x] 2.4 Integrate loading/error switch memory with refresh cancellation and retry state; verify edits made during loading/failure survive a round trip, pre-refresh identity is recovered only if still matched, successful retry uses the latest highlight, and late refresh completions cannot modify the destination.

## 3. Verify lifecycle compatibility and document usage

- [x] 3.1 Update the existing 25-route switching expectations and extend `tests/fzf_actions.lua` PTY coverage for per-view round trips, same-view routes, literal whitespace/Unicode/metacharacter queries, and zero-match returns; verify original-space scope, shared shown/hidden preview state, configured columns/prompts, remapped keys, and disabled optional actions remain correct.
- [x] 3.2 Update `README.md` to replace reset-on-switch language with popup-local memory, first-visit defaults, missing-selection fallback, and closing/reopening behavior; verify examples and existing documentation checks agree with the new specs and explain ordinary query clearing without adding a setting.
- [x] 3.3 Run `lua tests/test.lua` for the integrated Lua and real-fzf regression suite and `openspec validate remember-per-view-search-and-selection --strict`; verify both pass and review the implementation against every scenario in the two delta specs before declaring the change complete.
