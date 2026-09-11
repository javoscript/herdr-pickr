## 1. Candidate and session foundations

- [x] 1.1 Separate snapshot acquisition from candidate transformation in `core.lua`, reusing the same transformation for initial and refreshed data; verify fixtures for all five variants preserve headers, scoping, annotations, ordering, and preview IDs.
- [x] 1.2 Add a picker-session state model with ready/loading/error/closed states, a saved entity ID, generation token, and active candidate ID map; verify transitions, duplicate-refresh rejection, and retry identity retention using deterministic fixtures.
- [x] 1.3 Add picker-local cancellable asynchronous subprocess/control support in `runtime.lua` without nesting the blocking process runner inside callbacks; verify delayed success, timeout, cancellation, and resource cleanup against local subprocess fixtures.

## 2. fzf refresh interaction

- [x] 2.1 Wire a session-local fzf control channel and any required noninteractive `main.lua` helper entry points; verify with installed fzf that a delayed fixture can clear results, show a non-selectable loader, reload rows, and restore a saved ID after matching, and record the required action/version support.
- [x] 2.2 Bind `Ctrl+L` across all variants to capture identity, enter loading, and fetch one fresh snapshot; add footer hints and dynamic empty-state messages, verifying refresh works from populated, empty, and zero-match lists without resetting the query or original workspace scope.
- [x] 2.3 Preserve the live query and preview visibility throughout loading, and suppress Enter until refreshed matching and highlight restoration finish; verify query edits, preview toggles, and Enter during a delayed refresh with real interactive fzf.
- [x] 2.4 Publish complete refreshed headers and rows, restore the saved matching ID or the first matching result, and refresh the selected preview target; verify status-driven reordering, changed labels, removed/nonmatching entities, no matches, and changed tab/workspace preview panes.
- [x] 2.5 Replace initial-row text equality with active-generation ID validation for acceptance; verify updated rows focus the correct entity and malformed, unknown, header, loading, and error selections cannot trigger focus.

## 3. Failure and lifecycle handling

- [x] 3.1 Show a non-selectable retryable error state for fetch, parse, timeout, and rendering failures; verify stale candidates are absent, Enter is inert, and `Ctrl+L` retry preserves query, preview visibility, and the saved identity.
- [x] 3.2 Cancel pending work and clean up session resources on close and variant switch, discarding late generations; verify prompt close before the fetch timeout, ignored repeated refresh presses, and source completions that cannot affect a destination picker.
- [x] 3.3 Preserve existing variant-switch behavior during ready, loading, and error states; verify original-workspace scoping, query reset, initially visible destination preview, and absence of focus operations until an actual selection.

## 4. Regression coverage and documentation

- [x] 4.1 Extend `test.lua` with refresh fixtures and run `lua "$HOME/.config/herdr/plugins/pickr/test.lua"`; verify existing candidate formatting, column matching, priority ordering, focus dispatch, and all 25 variant-switch routes still pass alongside new lifecycle cases.
- [x] 4.2 Complete interactive acceptance checks for all five variants using controlled delayed/failing snapshots, covering loader/error presentation, stable-ID restoration, live query edits, preview visibility, and close/switch cancellation; record commands and outcomes in the implementation handoff.
- [x] 4.3 Update `README.md` with `Ctrl+L`, loading/retry behavior, identity fallback, refresh-time preview targeting, and the verified fzf requirement and regression procedure; verify the documented shortcuts and lifecycle match the completed acceptance checks.
