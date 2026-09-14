## Context

See proposal.md for motivation. The manifest and entrypoints currently enumerate five launch views; `keymap.variants` couples a shortcut to kind/scope, and `columns.variant` uses that pair to select columns and prompts. `core.pick` owns popup state and starts a fresh fzf process/snapshot on transitions. The working tree already contains partial memory implementation in core/runtime and tests; task counts in the active change still show incomplete work. Treat those edits as ongoing prerequisite work rather than assuming a clean baseline or reverting them.

The memory plan provides exact NUL-framed exit query/selection capture and acceptance-gated identity restoration. The pane plan adds tab-layout candidates and immutable workspace/tab origin captured before popup creation. Both plans currently key presentation and memory by scope-specific variant. This cross-module migration needs a design artifact.

## Goals / Non-Goals

**Goals:**
- Represent picker identity, requested scope, and effective scope independently in one popup-owned model.
- Reuse the tested refresh/restoration protocol for both type and scope transitions.
- Keep launch presets thin: all routes resolve to the same four picker types and configuration.
- Make the configuration break explicit and diagnosable, without guessing which old setting wins.

**Non-Goals:**
- Persistent history, drill-down into highlighted spaces/tabs, new sorting policy, or live previews.
- Automatic configuration rewriting, legacy launch aliases, or scope-specific configuration overrides.
- A single-process fzf rewrite, responsive footer wrapping, new terminal key protocols, or platform changes.

## Decisions

### 1. Share a registry but separate type, origin, and scope state

Introduce a small shared Lua picker registry consumed by entrypoint validation, keymap, configuration, and rendering. Public type names are `spaces`, `tabs`, `panes`, and `agents`; `workspaces` may remain an internal Herdr adapter detail. Canonical scope names are `all`, `space`, and `tab`; Spaces has no effective scope.

Popup state owns immutable origin, current type, chosen scope, shared preview visibility, and four memory slots. Derive effective scope with one pure function:

| Type | chosen all | chosen space | chosen tab |
| --- | --- | --- | --- |
| spaces | none | none | none |
| tabs | all | space | space |
| panes | all | space | tab |
| agents | all | space | tab |

Type changes do not mutate chosen scope. A supported explicit scope key replaces the choice even when it equals a temporary effective fallback: choosing This space in Tabs after a tab fallback intentionally clears the remembered tab preference. Unsupported scope keys are no-ops and do not change the hidden preference. Missing/deleted origin is an empty supported scope, not an unsupported scope: never broaden because data or origin is missing.

Alternative: Store only effective scope, which loses tab intent through Tabs/Spaces. Per-type scopes would contradict the confirmed carryover behavior.

### 2. Use one launch resolver for twelve public presets

Register matching action and pane-entrypoint IDs:

| Type | IDs |
| --- | --- |
| spaces | `spaces` |
| tabs | `tabs`, `tabs-all`, `tabs-space` |
| panes | `panes`, `panes-all`, `panes-space`, `panes-tab` |
| agents | `agents`, `agents-all`, `agents-space`, `agents-tab` |

Unqualified scoped types choose `all`; Spaces starts with a latent `all` preference for a later type switch. Explicit preset scopes initialize chosen scope. Remove all `-current` registrations and reject them in `src/open.lua`; direct invocation rejects the legacy `current` scope with a `space` replacement diagnostic. Normalize direct `src/main.lua` syntax to `spaces` or `tabs|panes|agents [all|space|tab]`, rejecting invalid type/scope pairs rather than falling back at launch. Interactive fallback is only for carried choices.

Reuse the pane prerequisite's pre-popup workspace/tab handoff on every route, including Spaces. Capture once; do not recapture active focus on a switch or refresh. Preserve configured action dimensions and owner settings snapshots, plus manifest dimensions for direct Herdr pane entrypoints.

Alternative: Parameterized Herdr action invocations would require a new public calling convention. Named presets fit the current manifest architecture and existing `-all` actions.

### 3. Generalize transitions without replacing the fzf lifecycle

Have picker actions produce a type transition and scope actions produce a scope transition. Reuse `--expect`, the exact `--print-query --print0` result protocol, save-before-restore, and fresh destination snapshot per effective transition. Save memory by type; a scope change immediately reads the same slot, carrying query and identity. A type change reads the destination's slot. Keep pane and agent slots independent even for the same pane ID.

The current-type shortcut retains the prerequisite's fresh-snapshot/self-switch behavior. Re-selecting the already chosen scope is a no-op; choosing a fallback scope that is already effective updates chosen scope without restarting the list. Bind unavailable scope keys explicitly to ignore so Ctrl+C cannot abort in Spaces/Tabs and inherited actions cannot leak through.

Only scope keys that change effective scope belong in the current session's `--expect` inventory. Use the existing synchronous owner control-helper channel for the fallback-to-explicit choice that changes only remembered preference: update popup choice and composed header without exiting fzf or touching query/selection/refresh work. Repeated use of that action then returns no change. Exclude unsupported and already-chosen scope keys from `--expect` and bind them to ignore; a later type transition rebuilds the applicable inventory. This preserves true no-op behavior rather than accidentally turning ignored keys into refreshes.

Reapply selection once after fzf matches fresh rows. Preserve a pending restoration/pre-refresh identity if switching during restoration/loading/error, but once a ready result falls back, the fallback becomes the current selection. Broadening later does not resurrect a separate scope-specific selection. A ready zero-match state records no selection. Preserve literal queries via argv, never interpolate them into shell/action text.

Cancel old generation work before the next session, including scope-only transitions. Keep accept gating, latest loading-time edits, close, and preview toggles; no transition focuses an underlying entity. This can reuse the existing short-lived fzf process model rather than demanding an in-place filter implementation.

### 4. Filter candidates before rendering; keep all type columns

Separate scope membership from row projection. Narrow tab rows must now include space metadata; narrow pane/agent rows must include space/tab metadata even when redundant. Configure each type once, defaulting to its widest existing/planned layout:

| Type | Allowed columns, in default order |
| --- | --- |
| spaces | status, space, tabs, directory |
| tabs | status, space, tab, panes, directory |
| panes | status, space, tab, title, pane, directory |
| agents | status, space, tab, agent, title, pane |

Reuse `space` and worktree annotations, pane labels, status styling, and independent visible-column matching at every scope. Membership changes, not column suppression, narrow results. Preserve existing scope-appropriate tab ordering (space-scoped tabs may use existing fuzzy ordering); retain global grouping, pane layout order, and agent priority/tie-breaking.

For agents-tab, validate the agent pane's containing workspace/tab against the immutable origin using snapshot identity/layout data, not labels or pane-ID parsing. Reuse agent eligibility, ordering, preview, and exact-pane acceptance; scope does not turn the Agents picker into a second ordinary-pane picker.

Alternative: Auto-hide redundant columns, which changes searchable fields while carrying a query and was explicitly rejected.

### 5. Keep stable scope state near the query and four type hints below

Use a non-selectable header/status area below the reverse-layout prompt, ahead of column headings and candidates. Render All spaces, This space, This tab in fixed order on one clipping row, emphasize effective scope, and dim unsupported labels and their configured shortcut hints. Spaces has none selected. For fallback, put a short explicit remembered-choice note, e.g. `This tab remembered`, on its own non-selectable line immediately below the scope row. This uses one additional line during fallback and keeps the note visible with preview shown rather than clipping it off the end of the choices. Refresh/error status follows on a separate line. Exact padding and emphasis are presentation details for PTY verification.

Use fzf's separate header text for scope/status while preserving the existing input-derived column header. Refresh loading/error currently replaces `--header`; centralize header composition so these messages cannot erase the scope row. Reuse semantic theme roles plus bold/dim attributes rather than introducing a palette dependency.

Keep the footer's first control row and replace its second row with Spaces/Tabs/Panes/Agents. Retain alias formatting, disabled-action omission, and clipping rather than wrapping. Proposed display default: `popup.show_hints=false` removes footer and shortcut text from the scope row, but leaves scope labels, effective/remembered state, and refresh/error status visible. Likewise `keys.scope_*=[]` removes only that shortcut hint, not the scope label/state. The scope row is state as well as help.

Alternative: Put scopes in the footer, which separates them from the query and mixes navigation axes. Hiding the complete scope row with hints would conceal the active candidate filter.

### 6. Unify settings with explicit migration diagnostics

Keys are `accept`, `close`, `toggle_preview`, `refresh`, `spaces`, `tabs`, `panes`, `agents`, `scope_all`, `scope_space`, `scope_tab`. Defaults are Enter, Esc, Ctrl+P, Ctrl+L, Ctrl+S, Ctrl+T, Ctrl+R, Ctrl+A, Ctrl+Z, Ctrl+X, Ctrl+C respectively. Keep replacement arrays, null/default inheritance, required accept/close, optional `[]`, effective alias collision validation, and supported inherited-fzf binding precedence. Explicitly overriding scope_tab while assigning Ctrl+C back to close remains possible, provided no collision exists.

Keep `prompt.default` and the existing `prompt.variants` container, but accept only four type keys within it. `columns` also accepts only those four keys. This reduces migration to leaf names rather than adding an unrelated container rename. Reject old `tabs_current`, `tabs_all`, `agents_current`, `agents_all`, `panes_tab`, `panes_current`, and `panes_all` in keys/columns/prompts, even when null, with the corresponding type replacement and an explanation that scope now has separate actions. Reject unknown names as before. Do not merge conflicting old lists/prompts or reinterpret old composite shortcuts as simple type changes.

Resolve once before action popup creation and keep the settings snapshot immutable. Advance the private snapshot format version because resolved key/column/prompt inventories change; an old handoff must fail clearly rather than partly validate. No on-disk state migration is needed.

Alternative: Compatibility aliases would require precedence between incompatible scope-specific settings and silently change shortcut meaning. The user chose explicit migration and removal of `-current` actions.

### 7. Sequence after the two prerequisite changes

Apply and synchronize memory first, then panes, then this change. `pane-picker`, the memory/restoration requirements, and pane-specific shared-settings/refresh requirements are future-baseline modifications in these deltas. Do not synchronize this change into today's main specs before those requirements exist. Recheck the actual completed baseline at apply time because current working edits already diverge from the older plans. Keep any reconciliation within the new change's implementation; do not silently rewrite prerequisite planning artifacts.

Durable distribution documentation still contains five-view/query-reset claims and an unrelated macOS-only requirement, while the current manifest/README enable Linux. This change updates the action/documentation contracts it affects and leaves the unrelated platform discrepancy outside its scope.

## Risks / Trade-offs

- [Ctrl+C previously closed and Ctrl+Z is a conventional suspend key] -> Document new defaults prominently; test raw PTY keys, cancellation aliases, no-match states, and disabled/unavailable scope keys.
- [Scope transitions race refresh/restoration] -> Reuse generation ownership, synchronous state capture, and acceptance gating; exercise rapid type/scope changes with delayed snapshot responses.
- [A carried tab preference is invisible while effective scope is broader] -> Display effective scope plus a concise remembered-choice note; test explicit fallback selection clearing the preference.
- [Wider default columns consume space in narrow scopes] -> Keep the agreed stable searchable schema and existing configurable subsets/preview toggle.
- [Legacy user configuration prevents launch after updating] -> Targeted migration diagnostics and README examples; no silent selection between conflicting settings.
- [Scope header could disappear during refresh or clip at small widths] -> Compose scope/status together and validate narrow/resized/hidden-hints/themed PTY layouts. Retain deterministic clipping.
- [Older overlapping deltas can restore obsolete behavior] -> Enforce documented prerequisite synchronization order and validate the composed final requirements before archive.

## Migration Plan

1. Complete and synchronize memory and pane-picker prerequisites, preserving their exact-identity and origin behavior.
2. Ship the registry, launch names, state transitions, unified configuration, scope UI, and updated tests together.
3. Update README's feature inventory, complete defaults, launch action table/examples, query/selection behavior, and a concise user migration subsection. Rename `*-current` bindings to `*-space`; consolidate legacy config leaves manually; remove the old Ctrl+C close alias when retaining the new default scope_tab key. Review README rather than editing it during planning.
4. Run `lua tests/test.lua`, including real-fzf PTY and relocation checks, and validate configuration/documentation inventories against all twelve presets. Record actual interactive verification rather than claiming it from pure unit tests.
5. Synchronize/archive this change last. Rollback requires restoring the prior release's config leaves and `-current` launch names; popup-only memory is discarded and needs no migration. Do not mutate user config automatically in either direction.
