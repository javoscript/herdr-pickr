## Context

See `proposal.md` for motivation and `specs/picker-column-order/spec.md` for the layout contract. In `core.lua`, `column_header` and `M.candidates` build positional arrays separately. Only the all-spaces tabs branch currently places tab before space. `add_space` records the appended field's index in `parent_field` and `muted_suffixes`; `M.aligned_rows` uses those indices for annotation styling and measures headings together with rows.

Rows also carry hidden selection and preview IDs ahead of the display fields. Search field indices are derived from the header's column count. The existing `test.lua` suite checks all five headers, alignment, search isolation, worktree grouping, preview flags, selection, and variant switching. `README.md` documents the old all-spaces tab order. The working tree already includes pane-label edits associated with `show-agent-pane-labels`; this design accommodates them.

## Goals / Non-Goals

**Goals:**
- Keep header construction and candidate assembly consistent with minimal changes to the existing array-based design.
- Preserve correct positional styling metadata and hidden IDs when moving a visible field.

**Non-Goals:**
- Introduce a column configuration framework or rewrite all picker renderers.
- Add missing columns to any variant, rename count headings, or change metadata, sorting, focus, or preview behavior.

## Decisions

### Assemble tab rows in their final display order

Build the tab entry initially from its selection ID and status, append space with `add_space` for all-space scope, then append tab, pane count, and directory. Mirror this sequence in the tab branch of `column_header`. This ensures `add_space` records the final index without manual metadata remapping.

Alternative: reorder a finished array. Rejected because this requires synchronizing `parent_field` and `muted_suffixes`, creating unnecessary styling risk.

### Keep explicit layouts and existing count headings

Treat `tabs` and `panes` as the corresponding positions in the canonical order, preserving their count semantics. Keep the small explicit branches: four layouts already comply, and column count does not change, so neither the hidden-field protocol nor fzf field options need adjustment.

Alternative: centralize headers and row projection in a shared declarative column registry. This could prevent future drift but adds unnecessary machinery for a single pairwise move. Existing all-variant layout expectations provide proportionate protection.

### Verify through existing regression coverage

Update stale header and positional expectations in `test.lua`, using existing fixture rows to verify that actual space and tab values align with their headings. Run the documented suite, which already exercises installed fzf and targeting behavior. Update the README's table and explain the relative-order rule.

Alternative: add a separate layout test framework. Existing fixtures and checks already cover the affected behavior, so a new harness is unnecessary.

## Risks / Trade-offs

- [Header changes without matching row changes] → Update both construction sites together and verify distinct fixture space/tab values under their headings.
- [Worktree annotations style the wrong field] → Append space at its final position through `add_space` and retain existing annotation/alignment checks.
- [Overlapping working-tree edits] → Apply targeted edits to the tab branches and existing expectations, preserving pane-label behavior and its regressions.
- [Explicit layouts can drift in future] → Keep all five expected headers and the shared ordering documented together.

## Migration Plan

No data migration or relinking is required. Lua edits take effect on the next picker launch. Deploy the focused code, regression-expectation, and documentation updates together; rollback only this change's edits if needed, retaining the independent pane-label work.
