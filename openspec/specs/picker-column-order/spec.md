# picker-column-order Specification

## Purpose

Provide consistent column placement across Pickr's five picker variants so users can scan related information predictably when switching views.

## Requirements

### Requirement: Picker columns follow a shared relative order

Default columns SHALL be Spaces: `status`, `space`, `tabs`, `directory`; Tabs: `status`, `space`, `tab`, `panes`, `directory`; Panes: `status`, `space`, `tab`, `title`, `pane`, `directory`; Agents: `status`, `space`, `tab`, `agent`, `title`, `pane`. These lists SHALL be constant across each type's scopes. Count headings `tabs` and `panes` SHALL retain their values in tab/pane positions. A configured type list SHALL replace its entire default in exactly the configured order; headers and values SHALL agree, retaining the `pane [label]` heading. Empty lists SHALL retain fixed non-selectable column headings. Existing visible-column matching, attached annotations, status glyph/text grouping, hidden-ID targeting, candidate ordering, and preview semantics SHALL be preserved.

#### Scenario: Spaces picker
- **WHEN** the spaces picker is displayed with its default columns
- **THEN** its columns are `status · space · tabs · directory`

#### Scenario: Current-space tabs picker
- **WHEN** the current-space tabs picker is displayed with its default columns
- **THEN** its columns are `status · space · tab · panes · directory`

#### Scenario: All-spaces tabs picker
- **WHEN** the all-spaces tabs picker is displayed with its default columns
- **THEN** its columns are `status · space · tab · panes · directory`
- **AND** each row's space value appears before its tab value under the corresponding headings

#### Scenario: Current-space agents picker
- **WHEN** the current-space agents picker is displayed with its default columns
- **THEN** its columns are `status · space · tab · agent · title · pane`

#### Scenario: All-spaces agents picker
- **WHEN** the all-spaces agents picker is displayed with its default columns
- **THEN** its columns are `status · space · tab · agent · title · pane`

#### Scenario: Empty picker
- **WHEN** any picker has no candidates
- **THEN** its fixed, non-selectable header still displays that picker's effective column order

#### Scenario: Ordered subset
- **WHEN** `columns.tabs` is `["tab", "directory", "space"]`
- **THEN** both tab scopes' headers and rows display only tab, directory, and space, in that order
- **AND** omitted status and pane-count columns leave no empty columns or extra separators

#### Scenario: Single visible column
- **WHEN** `columns.agents` is `["title"]` and the active agent scope is empty
- **THEN** only the title heading is shown with no status prefix or extra column separators
- **AND** later candidates still preview and focus their underlying pane IDs

#### Scenario: Pane picker defaults
- **WHEN** a pane picker opens with default columns
- **THEN** every pane scope displays `status · space · tab · title · pane · directory`
- **AND** every pane column uses its `pane [label]` heading

#### Scenario: Stable defaults in every scope
- **WHEN** Tabs, Panes, or Agents narrows scope with default columns
- **THEN** its complete default list above remains visible and searchable, including space/tab context where present
- **AND** Spaces retains its specified default list

#### Scenario: Narrowing preserves context matching
- **WHEN** a query matches a visible space name and the user narrows Panes from All spaces to This tab within that space
- **THEN** remaining eligible panes still match the space term rather than losing it through automatic column hiding

### Requirement: Column reordering preserves picker behavior

Reordering or hiding columns SHALL preserve the retained columns' values and alignment. Status glyph and text SHALL belong to one `status` column and move or hide together. Worktree tree prefixes and parent annotations SHALL remain attached to `space`, and pane labels SHALL remain attached to `pane`, retaining their existing styling when visible. Only configured visible columns, including their attached annotations, SHALL be searchable under the existing independent per-column matching rules. Hidden column values and hidden selection/preview metadata SHALL NOT contribute matches. Scope filtering, candidate ordering, selection targets, and preview targets SHALL remain unchanged, including when status or identifying columns are hidden.

#### Scenario: Worktree tab row
- **WHEN** the all-spaces tabs picker displays a tab in a worktree with a parent annotation and includes the space column
- **THEN** the space column retains its tree prefix, padded parent annotation, and subdued styling at its configured position
- **AND** the header and row columns remain aligned

#### Scenario: Search and act on a reordered row
- **WHEN** a user filters all-spaces tabs by visible space and tab terms, then previews or selects a matching row
- **THEN** terms match their respective columns without spanning column boundaries
- **AND** matches retain the existing space grouping and tab order
- **AND** preview targets the tab's remembered focused pane and selection targets the original tab

#### Scenario: Moved status column
- **WHEN** status is configured between other columns or as the final column
- **THEN** its colored glyph and text appear together at that position
- **AND** its heading and values remain aligned with the other columns

#### Scenario: Hidden status column
- **WHEN** an agent picker omits status
- **THEN** neither the status glyph nor its text nor reserved status spacing appears
- **AND** agents retain their existing status-priority and tie-breaking order
- **AND** a term occurring only in hidden status text does not match

#### Scenario: Hidden directory or space
- **WHEN** a tab picker omits directory or space and a query term occurs only in that omitted column or its annotation
- **THEN** that term does not match the row
- **AND** a term occurring in a retained column can still match it

#### Scenario: Hidden identifying columns
- **WHEN** a user previews or accepts an entry whose identifying tab, space, or pane column is omitted
- **THEN** the same underlying entity is previewed or focused as with the default layout
- **AND** hidden selection and preview IDs do not become searchable
