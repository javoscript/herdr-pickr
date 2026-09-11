## Why

Agent pickers currently identify panes only by ID, omitting the human-readable labels users assign to them. Showing those labels alongside the IDs makes agents easier to recognize and find while matching the existing subdued annotation style.

## What Changes

- In current-space and all-spaces agent pickers, append a non-empty pane label to the `pane` column as `pane-id [label]`.
- Render the entire bracketed label in the same Rosé Pine gray (`#524f67`) used for worktree parent annotations.
- Keep labels searchable as part of the pane column and clean metadata using the existing single-row formatting rules.
- Keep unlabeled panes displayed as their pane ID alone, and preserve pane selection and preview targets.

## Capabilities

### New Capabilities

- `agent-pane-labels`: Conditional, muted pane-label annotations in both agent pickers, including search and stable pane targeting.

### Modified Capabilities

None. The project currently has no main specifications.

## Impact

- `core.lua`: join agent pane IDs to snapshot pane metadata and extend annotation rendering to support both space-parent and pane-label annotations on one row.
- `test.lua`: fixture-based rendering, search, and targeting regression coverage.
- `README.md`: describe the pane-label display and search behavior.
- Uses the existing single snapshot and current Lua/fzf dependencies; no new API calls or configuration are expected.
