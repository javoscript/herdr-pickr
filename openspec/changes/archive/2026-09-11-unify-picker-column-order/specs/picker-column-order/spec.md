## Purpose

Provide consistent column placement across Pickr's five picker variants so users can scan related information predictably when switching views.

## ADDED Requirements

### Requirement: Picker columns follow a shared relative order

Each picker SHALL display its existing visible columns in the relative order status, space, tab, agent, title, pane, directory, omitting columns not present in that picker. The count headings `tabs` and `panes` SHALL retain their names and values and occupy the tab and pane positions respectively. Headers and row values SHALL use the same order.

#### Scenario: Spaces picker
- **WHEN** the spaces picker is displayed
- **THEN** its columns are `status · space · tabs · directory`

#### Scenario: Current-space tabs picker
- **WHEN** the current-space tabs picker is displayed
- **THEN** its columns are `status · tab · panes · directory`

#### Scenario: All-spaces tabs picker
- **WHEN** the all-spaces tabs picker is displayed
- **THEN** its columns are `status · space · tab · panes · directory`
- **AND** each row's space value appears before its tab value under the corresponding headings

#### Scenario: Current-space agents picker
- **WHEN** the current-space agents picker is displayed
- **THEN** its columns are `status · tab · agent · title · pane`

#### Scenario: All-spaces agents picker
- **WHEN** the all-spaces agents picker is displayed
- **THEN** its columns are `status · space · tab · agent · title · pane`

#### Scenario: Empty picker
- **WHEN** any picker has no candidates
- **THEN** its fixed, non-selectable header still displays that picker's column order

### Requirement: Column reordering preserves picker behavior

Reordering columns SHALL preserve their values, alignment, status indicators, and worktree or pane annotations. All visible columns SHALL remain independently searchable under the existing matching rules. Scope filtering, candidate ordering, selection targets, and preview targets SHALL remain unchanged.

#### Scenario: Worktree tab row
- **WHEN** the all-spaces tabs picker displays a tab in a worktree with a parent annotation
- **THEN** the space column retains its tree prefix, padded parent annotation, and subdued styling before the tab column
- **AND** the header and row columns remain aligned

#### Scenario: Search and act on a reordered row
- **WHEN** a user filters all-spaces tabs by space and tab terms, then previews or selects a matching row
- **THEN** terms match their respective columns without spanning column boundaries
- **AND** matches retain the existing space grouping and tab order
- **AND** preview targets the tab's remembered focused pane and selection targets the original tab
