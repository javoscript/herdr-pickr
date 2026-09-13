## 1. Configuration and launch snapshot

- [x] 1.1 Add `popup.show_hints` resolution in `src/pickr/config.lua`, defaulting to true for omission/null and validating booleans separately from width/height; extend `tests/configuration.lua` to verify true/false, missing-file and null defaults, invalid types with field diagnostics, and unchanged dimension validation.
- [x] 1.2 Preserve and validate hint visibility in the resolved launcher/owner settings handoff; verify snapshot round trips retain false and fixtures for edits after resolution retain the old value until a subsequent launch, including direct owner configuration loading.

## 2. Conditional footer rendering

- [x] 2.1 Make the footer callback and startup `--footer` argument conditional in `src/pickr/core.lua`; extend picker fixtures in `tests/test.lua` to verify all five initial views and switching retain hidden hints for nonempty, empty, and zero-match states while configured accept, close, preview, refresh, and variant actions remain functional.
- [x] 2.2 Update `src/pickr/runtime.lua` to omit footer publication when the callback is absent, preserving header status and action gating; verify hidden-footer refresh success with empty/nonempty results, loading, failure, and retry, and retain existing visible-footer grouping and alias assertions.

## 3. Documentation and integrated verification

- [x] 3.1 Update `README.md`'s complete default configuration and hint guidance with `popup.show_hints`, a false example, boolean/null validation, whole-footer removal including `no entries`, and reopen-to-apply behavior; verify documented JSON examples decode successfully and agree with resolved defaults.
- [x] 3.2 Extend the existing real-fzf/PTY coverage with a focused hidden-footer lifecycle case; verify no footer rows or footer-only separator are allocated, refresh cannot recreate the section, and loading/failure/retry messages remain visible on the supported fzf baseline.
- [x] 3.3 Run `lua tests/test.lua` after implementation and documentation updates; verify the complete regression suite passes and record the fzf version used for the integrated layout check.

Verification: `lua tests/test.lua` passed with fzf `0.74.4 (Homebrew)` on macOS, within the supported 0.74.3+ range. The PTY layout check confirmed three additional visible candidate rows with hints hidden; lifecycle checks covered failure, empty retry publication, nonempty publication, and acceptance.
