## Why

The all-spaces tabs picker displays tab before space, while the all-spaces agents picker displays space before tab. A consistent relative column order makes switching among pickers easier to scan.

## What Changes

- Establish the shared visible-column order: status, space, tab, agent, title, pane, directory, including only columns already present in each picker.
- Move space before tab in the all-spaces tabs header and candidate rows.
- Retain the existing plural count headings: `tabs` occupies the tab position and `panes` occupies the pane position. Other picker layouts already follow the requested order.
- Update the documented layouts and existing regression expectations while preserving column values, styling, search behavior, row ordering, selection, and previews.

## Capabilities

### New Capabilities
- `picker-column-order`: Consistent relative ordering of visible columns and matching headers across all five picker variants.

### Modified Capabilities

None; there are no main specifications yet.

## Impact

- `core.lua`: tab header and candidate construction, including positional worktree annotation metadata.
- `test.lua`: existing layout expectations and picker regressions.
- `README.md`: column-header table and shared-order documentation.
- No API, dependency, or manifest changes are needed. The in-flight `show-agent-pane-labels` change and its existing working-tree edits remain compatible: pane annotations stay within the pane column.
