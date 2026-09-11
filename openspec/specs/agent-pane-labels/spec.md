# agent-pane-labels Specification

## Purpose

Help users identify and search for agents by displaying human-readable pane labels alongside pane IDs in both agent picker variants.

## Requirements

### Requirement: Pane labels appear in the pane column

Both current-space and all-spaces agent pickers SHALL display a pane with a non-empty label as `pane-id [label]` in the existing `pane` column, separated by one space. Missing or empty labels, or unavailable pane metadata, SHALL leave the pane ID alone without brackets or a trailing annotation separator.

#### Scenario: Labeled pane in either agent picker
- **WHEN** either agent picker lists an agent on pane `w1:p1` whose label is `review`
- **THEN** its pane column displays `w1:p1 [review]`
- **AND** the label does not replace the agent name or terminal title

#### Scenario: Unlabeled or unavailable pane
- **WHEN** an agent's pane label is absent, null, or empty, or its pane metadata is absent
- **THEN** its pane column displays only the pane ID

### Requirement: Pane annotations use the existing subdued style

The label and both brackets SHALL use the same muted gray (`#524f67`) as worktree parent annotations. The pane ID SHALL retain its existing style. Pane annotations SHALL coexist with worktree parent annotations and preserve existing column alignment and single-row metadata cleaning, including replacement of control characters with spaces.

#### Scenario: Both annotations on an all-spaces agent row
- **WHEN** a labeled agent pane belongs to a worktree with a displayed parent annotation
- **THEN** both bracketed annotations use `#524f67`
- **AND** the pane ID and surrounding columns retain their existing styles and alignment

#### Scenario: Unicode and control characters in labels
- **WHEN** a pane label contains Unicode text and a newline or tab
- **THEN** Unicode text is preserved and control characters are replaced with spaces
- **AND** the label remains within one row and the existing pane column

### Requirement: Labels are searchable without changing pane targeting

The displayed label SHALL be searchable within the pane column under the picker's existing per-column matching rules. Adding labels SHALL preserve agent ordering, scope filtering, headers, and the underlying pane IDs used for selection and previews.

#### Scenario: Search by pane label
- **WHEN** a user searches either agent picker for a term matching only a displayed pane label
- **THEN** the corresponding agent remains a match
- **AND** matching results retain the existing agent priority order

#### Scenario: Preview and select a labeled pane
- **WHEN** the user previews or selects the agent displayed as `w1:p1 [review]`
- **THEN** the preview or focus operation targets `w1:p1` without the annotation
