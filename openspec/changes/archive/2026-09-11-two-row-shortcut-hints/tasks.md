## 1. Footer grouping

- [x] 1.1 Replace the 70-character wrapping in `src/pickr/keymap.lua:M.footer` with explicit action and variant groups, retaining effective aliases, label order, separators, first-row `no entries`, and omission of an empty variant row. Verify generated output against the default, remapped, disabled, long-alias, and empty-list scenarios in `specs/picker-footer-layout/spec.md`; leave shared key resolution order intact.

## 2. Documentation and integration verification

- [x] 2.1 Update `README.md` footer descriptions under Popup action keys, Column headers, and Switching picker variants to explain the two groups, the disabled-variant one-row exception, and narrow-width clipping. Verify no current-behavior statement still promises extra alias/wrapping rows, and add the focused live acceptance procedure to Regression checks.
- [x] 2.2 Run `lua tests/test.lua` to verify the existing configured-alias, disabled-hint, switching, and refresh regressions still pass; confirm the initial `--footer` path in `src/pickr/core.lua` and the refresh footer callback in `src/pickr/runtime.lua` continue to use the same renderer.
- [x] 2.3 Perform live checks with fzf 0.74.3+ across all five variants: two default rows at sufficient width, clipping and recovery on resize, long/remapped aliases, disabled optional actions, all variant shortcuts disabled, empty candidates, and zero search matches. Exercise refresh through loading, success, failure/retry, and empty/nonempty transitions plus variant switching; verify grouping remains stable and messages stay in the status area. Record environment and actual outcomes in the README regression notes.

Completion: user sign-off received on 2026-09-11 with the request to mark done, archive, and sync specs.
