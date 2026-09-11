## 1. Align tab headers and candidate rows

- [x] 1.1 Update the tab branch of `column_header` and tab candidate assembly in `core.lua` to append optional space before tab, calling `add_space` at its final index; verify fixture output shows `status · space · tab · panes · directory` for all-spaces tabs and the existing current-space order, with matching values and unchanged hidden selection/preview IDs.
- [x] 1.2 Update existing header and affected positional expectations in `test.lua` to match the specification; verify all five expected layouts remain represented and fixture space/tab values appear under the correct headings, including worktree annotation alignment.

## 2. Document and verify the shared order

- [x] 2.1 Update the `README.md` column-header table and document the canonical relative order, omitted columns, and retained `tabs`/`panes` count headings; verify the table matches all five scenarios in `specs/picker-column-order/spec.md`.
- [x] 2.2 Run `lua "$HOME/.config/herdr/plugins/pickr/test.lua"` and resolve any regressions; verify the suite passes for headers, alignment, worktree styling/grouping, independent-column matching, hidden IDs, selection, previews, empty lists, and switching, retaining existing agent pane-label coverage.
