## 1. Prerequisite baseline and shared model

- [x] 1.1 Confirm `remember-per-view-search-and-selection` and then `add-pane-picker` are implemented and synchronized before applying this change; verify their memory/restoration, pane identity, and immutable-origin requirements exist in the resulting specs and retain any ongoing working-tree edits.
- [x] 1.2 Add a shared picker/type/scope/preset registry and chosen-to-effective resolver; verify all twelve type/chosen-scope combinations, the twelve valid launch presets, invalid explicit pairs, and temporary fallback without changing the chosen scope using Lua fixtures.

## 2. Configuration and launch migration

- [x] 2.1 Replace scope-specific key actions with the four picker and three scope actions, using the specified defaults and Esc-only closing; verify aliases, null/omission, optional disabled actions, required actions, Ctrl+C collisions, and inherited-binding precedence in configuration/keymap tests.
- [x] 2.2 Consolidate columns and `prompt.variants` to four type leaves, retaining the existing prompt container and widest-layout column defaults; verify every scope shares its type's columns/prompt and invalid inactive-type overrides still block launch.
- [x] 2.3 Add actionable diagnostics for every removed scope-specific config leaf, including null and mixed legacy/new settings, and version the resolved settings handoff; verify no silent merges/config writes, incompatible handoff failure, and unchanged launch-snapshot lifetime in configuration tests.
- [x] 2.4 Register all twelve action/pane presets in `herdr-plugin.toml` and route both entrypoints through shared validation; remove `-current`, adopt `space` direct scope syntax and unqualified defaults, and verify the exact registration inventory, rejection/replacement diagnostics, configured versus manifest geometry, and unchanged plugin identity in launch/relocation tests.
- [x] 2.5 Carry prerequisite origin capture through every new launch route, including Spaces and agents-tab; verify context precedence, handoff timing, explicit missing tab, invalid tab/workspace membership, deleted origin, and no recapture on transitions using launch/snapshot fixtures.

## 3. Candidates and stable searchable presentation

- [x] 3.1 Decouple scope filtering from row projection in core/columns; supply full space/tab context in narrow rows and verify all nine effective type/scope combinations, default/reordered/single-column layouts, empty headers, annotations, hidden-field non-matching, and stable space/tab-term matching across scopes in column/rendering tests.
- [x] 3.2 Add agent membership filtering for the immutable origin tab using snapshot pane/tab/workspace identities; verify cross-tab exclusion, missing/mismatched origin, original agent priority/ties, ordinary-pane exclusion, and exact preview/focus targets in candidate fixtures.

## 4. Popup transitions and memory

- [x] 4.1 Generalize picker exits into type and effective-scope transitions with four per-type memory slots and one popup-wide chosen scope; verify query continuity, literal text, independent type memory, pane/agent identity isolation, carried fallback/restoration, fallback-selection replacement, zero matches, and popup isolation.
- [x] 4.2 Build session-specific transition bindings and synchronous state-only scope handling; verify unavailable/already-chosen scope no-ops, explicit fallback selection clearing remembered tab preference without list restart, self-type fresh transitions, and no-expect launches with all transitions disabled.
- [x] 4.3 Extend readiness/restoration and refresh ownership to scope transitions, preserving pending/recovery IDs and latest queries; verify cancellation and late-result rejection, no stale/deferred acceptance, preview persistence, retry recovery, and rapid type/scope transitions during loading/error/restoration with controlled delayed snapshot responses.

## 5. Scope row and compact footer

- [x] 5.1 Compose the persistent scope row with effective highlight, muted unavailable labels, configured key aliases, and remembered-choice text near the prompt; verify it precedes candidates, is never searchable/selectable, and persists through empty/zero-match states and hidden preview in real-fzf rendering checks.
- [x] 5.2 Centralize header/status composition so refresh/loading/error updates retain scope state, and reduce the footer to control and four-picker rows; verify remapped/disabled aliases, empty-list prefixes, hidden footer/key text with visible scope state, themes, long-row clipping, and resize behavior in themed/PTY tests.

## 6. Integration and user documentation

- [x] 6.1 Extend real-fzf PTY coverage for Ctrl+S/T/R/A and Ctrl+Z/X/C across type/scope states, including Ctrl+C in unsupported contexts, Esc closing, remaps, disabled actions, empty matches, scope/query/selection round trips, and restoration/refresh races; verify no unintended abort, suspend, or underlying focus operation.
- [x] 6.2 Update README's four-type feature summary, full defaults, scope/selection behavior, twelve-preset table/binding examples, hidden-hint behavior, and explicit configuration/`-current` migration instructions; verify documentation tests accept all current examples and old names appear only as migration inputs.
- [x] 6.3 Run `lua tests/test.lua` for the integrated implementation, including relocation and real-fzf checks, and record actual interactive scope/header/preview outcomes and any environment limitations; verify the resulting implementation and composed specs agree before synchronizing this change last.

Verification outcomes, environment, and spec-composition notes are recorded in [verification.md](verification.md).
