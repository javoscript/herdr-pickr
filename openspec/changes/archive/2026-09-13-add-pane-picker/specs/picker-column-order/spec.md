## MODIFIED Requirements

### Requirement: Picker columns follow a shared relative order

By default, each picker SHALL display its existing visible columns in the relative order status, space, tab, agent, title, pane, directory, omitting columns not present in that picker. The count headings `tabs` and `panes` SHALL retain their names and values and occupy the tab and pane positions respectively. A configured column list SHALL replace the corresponding variant's default with exactly the listed columns in the listed order. Headers and row values SHALL use the same effective order. The `pane` column SHALL retain its `pane [label]` heading.

#### Scenario: Spaces picker
- **WHEN** the spaces picker is displayed with its default columns
- **THEN** its columns are `status · space · tabs · directory`

#### Scenario: Current-space tabs picker
- **WHEN** the current-space tabs picker is displayed with its default columns
- **THEN** its columns are `status · tab · panes · directory`

#### Scenario: All-spaces tabs picker
- **WHEN** the all-spaces tabs picker is displayed with its default columns
- **THEN** its columns are `status · space · tab · panes · directory`
- **AND** each row's space value appears before its tab value under the corresponding headings

#### Scenario: Current-space agents picker
- **WHEN** the current-space agents picker is displayed with its default columns
- **THEN** its columns are `status · tab · agent · title · pane`

#### Scenario: All-spaces agents picker
- **WHEN** the all-spaces agents picker is displayed with its default columns
- **THEN** its columns are `status · space · tab · agent · title · pane`

#### Scenario: Empty picker
- **WHEN** any picker has no candidates
- **THEN** its fixed, non-selectable header still displays that picker's effective column order

#### Scenario: Ordered subset
- **WHEN** `columns.tabs_all` is `["tab", "directory", "space"]`
- **THEN** the all-spaces tabs header and rows display only tab, directory, and space, in that order
- **AND** omitted status and pane-count columns leave no empty columns or extra separators

#### Scenario: Single visible column
- **WHEN** `columns.agents_current` is `["title"]`
- **THEN** the current-space agents header and rows display only the title column without column separators or a status prefix

#### Scenario: Pane picker defaults
- **WHEN** a pane picker opens with default columns
- **THEN** panes-tab displays `status · title · pane · directory`
- **AND** panes-current displays `status · tab · title · pane · directory`
- **AND** panes-all displays `status · space · tab · title · pane · directory`
- **AND** every pane column uses its `pane [label]` heading
