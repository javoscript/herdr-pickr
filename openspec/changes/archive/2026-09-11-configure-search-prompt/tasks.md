## 1. Configuration and settings handoff

- [x] 1.1 Extend `src/pickr/config.lua` with the `prompt.default` and `prompt.variants` schema, resolving all five effective prompts from a global `"Search: "` default; verify in `tests/configuration.lua` that missing/null sections and values inherit correctly, all variant names work, and partial overrides preserve other defaults.
- [x] 1.2 Validate prompt objects, field names, variant names, string types, and NUL/CR/LF while preserving empty strings, spaces, Unicode, and literal metacharacters; verify table-driven configuration fixtures report the offending field, including invalid overrides for inactive variants, and load-level errors include the config path.
- [x] 1.3 Include resolved prompts in the existing launch snapshot and extend owner validation; verify snapshot fixtures preserve global and variant values after file edits, reject incomplete prompt handoffs, avoid owner rereads, and adopt new values on a subsequent direct launch.

## 2. Picker integration

- [x] 2.1 Replace the hard-coded fzf prompt in `src/pickr/core.lua` with the active variant's effective string using the existing kind/scope mapping; update the default argument assertion and verify default, global-only, variant-specific, empty, and literal-string argv values for all five variants, including `workspaces/all` as `spaces`.
- [x] 2.2 Extend the existing switching and session fixtures in `tests/test.lua` to verify destination prompt selection across all 25 routes and empty/zero-match cases, with one frozen settings snapshot; verify refresh rendering retains those settings and existing query/preview lifecycle regressions pass.

## 3. Documentation and acceptance

- [x] 3.1 Update `README.md` with the new default, global-only and per-variant JSON examples, all five supported names, precedence/null/empty semantics, validation, and reopen-to-adopt behavior; replace the old universal-prompt statement and document restoring `"◉/> "`. Verify the delivered documentation matches the delta spec and its JSON examples pass `tests/documentation.lua` through the main suite.
- [x] 3.2 Run `lua tests/test.lua` after the integrated changes and resolve failures; verify the complete existing configuration, switching, refresh, real-fzf, and documentation checks pass, and record the actual result.
- [x] 3.3 Perform focused interactive acceptance with supported fzf inside Herdr: verify the default on all five variants, mixed overrides and inheritance on switching, exact trailing spaces and an empty prompt, unchanged prompt through refresh/failure/retry, and edits applying only after reopening. Verify query reset/preservation still follows existing behavior and record environment and actual outcomes in the README compatibility section.
