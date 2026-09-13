## MODIFIED Requirements

### Requirement: Pane labels appear in the pane column

When their effective column list includes `pane`, both current-space and all-spaces agent pickers SHALL display a pane with a non-empty label as `pane-id [label]` in the `pane` column, separated by one space. Missing or empty labels, or unavailable pane metadata, SHALL leave the pane ID alone without brackets or a trailing annotation separator. Omitting `pane` SHALL hide the pane ID and attached label from the row; moving `pane` SHALL move both together.

#### Scenario: Labeled pane in either agent picker
- **WHEN** either agent picker includes the pane column and lists an agent on pane `w1:p1` whose label is `review`
- **THEN** its pane column displays `w1:p1 [review]`
- **AND** the label does not replace the agent name or terminal title

#### Scenario: Unlabeled or unavailable pane
- **WHEN** a displayed agent pane's label is absent, null, or empty, or its pane metadata is absent
- **THEN** its pane column displays only the pane ID

#### Scenario: Hidden pane column
- **WHEN** either agent picker omits pane from its column list
- **THEN** its row does not display the pane ID or label as a separate column or annotation elsewhere

#### Scenario: Reordered pane column
- **WHEN** pane is moved before other visible agent columns
- **THEN** its pane ID and attached label appear together under the `pane [label]` heading at that position

### Requirement: Labels are searchable without changing pane targeting

When the pane column is visible, its displayed label SHALL be searchable within that column under the picker's existing per-column matching rules. When pane is omitted, its ID and label SHALL NOT contribute matches. Pane labels SHALL preserve agent ordering, scope filtering, header alignment, and underlying pane IDs used for selection and previews regardless of column visibility or position.

#### Scenario: Search by pane label
- **WHEN** a user searches either agent picker with a visible pane column for a term matching only a displayed pane label
- **THEN** the corresponding agent remains a match
- **AND** matching results retain the existing agent priority order

#### Scenario: Preview and select a labeled pane
- **WHEN** the user previews or selects the agent displayed as `w1:p1 [review]`
- **THEN** the preview or focus operation targets `w1:p1` without the annotation

#### Scenario: Hidden pane label does not match
- **WHEN** pane is omitted and a query term occurs only in its pane ID or label
- **THEN** the agent does not match that term
- **AND** previewing or selecting the agent through another visible value still targets the original pane ID
