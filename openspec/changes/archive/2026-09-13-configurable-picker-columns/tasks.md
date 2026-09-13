## 1. Column configuration and launch settings

- [x] 1.1 Add a shared column catalog and resolve `columns` overrides in `src/pickr/config.lua`; extend configuration fixtures to verify all five default inventories, omitted/null/empty-object defaults, independent replacement arrays, single-column lists, and rejection of empty/duplicate/unknown/unavailable names, wrong types, invalid elements, and inactive-variant errors with field diagnostics.
- [x] 1.2 Include validated effective column lists in the launcher-to-owner settings snapshot and retain defaults for rendering entrypoints with omitted settings; verify snapshot round-tripping, edits between launcher and owner startup, and validation before popup creation or direct fzf startup using the existing launch/configuration fixtures.

## 2. Rendering and fuzzy matching

- [x] 2.1 Project candidate values and headers through the effective ordered list before alignment while retaining hidden selection and preview IDs; verify exact default output, reordered subsets and single-column output across all five variants, fixed empty headers, and unchanged grouping, scope, ordering, and targets in rendering fixtures.
- [x] 2.2 Bind status glyph/text and annotation styling to their respective projected cells; verify aligned status-first/middle/last/only/hidden layouts, worktree prefixes and suffixes, moved pane labels and their header, missing labels, Unicode/control-character cleaning, and coexisting annotations under representative dark/light/terminal/custom themes.
- [x] 2.3 Derive fzf search-field indexes from the effective layout; add real-fzf fixtures using production flags to verify retained-field matches, hidden status/directory/space/pane-label nonmatches, single-column matching, separate-term cross-column matching, rejection of single-term column-spanning matches, and hidden-ID exclusion while preserving selection/preview targets.

## 3. Session integration and documentation

- [x] 3.1 Extend session/launch regression fixtures to verify destination layouts and search fields through switching, empty and zero-match states, refresh success/failure/retry, original settings after config edits, and edited settings after reopening; assert existing query reset/preservation and preview behavior remain correct.
- [x] 3.2 Update README.md's full default configuration, configuration navigation, feature summary as needed, and a displayed-columns section with all supported names, ordered-subset examples, validation/default rules, visible-only search, attached glyphs/annotations, and reopen semantics; verify documented JSON examples against the decoder through the documentation checks.
- [x] 3.3 Run `lua tests/test.lua` for integrated regression coverage and `openspec validate configurable-picker-columns --strict` for artifact consistency; record any environmental blockers or remaining manual checks before marking the change complete.
