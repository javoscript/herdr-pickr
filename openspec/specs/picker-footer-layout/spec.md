# picker-footer-layout Specification

## Purpose

Keep bottom shortcut hints predictable and compact by separating picker actions from variant navigation into stable rows.

## Requirements

### Requirement: Footer hints use action and variant rows

Every picker SHALL place enabled switch, close, preview, and refresh hints on its first footer row, in that order. It SHALL place enabled tabs here, all tabs, spaces, agents here, and all agents hints on its second footer row, in that order, including the current variant's shortcut. With default bindings, the footer SHALL contain exactly these two rows. Hints SHALL retain lowercase labels and use ` · ` between hints on the same row. Footer generation SHALL NOT insert additional rows based on text length. Text wider than the available footer area SHALL use normal fzf clipping rather than additional hint rows.

#### Scenario: Default hints in every variant
- **WHEN** any of the five picker variants opens with default bindings and a nonempty candidate list
- **THEN** its first footer row is `enter: switch · esc/ctrl+c: close · ctrl+p: preview · ctrl+l: refresh`
- **AND** its second footer row is `ctrl+r: tabs here · ctrl+t: all tabs · ctrl+s: spaces · ctrl+a: agents here · ctrl+g: all agents`
- **AND** no third footer row is generated

#### Scenario: Narrow popup or long aliases
- **WHEN** either hint group is wider than the available footer area
- **THEN** the group remains on its assigned row with excess text clipped by fzf
- **AND** resizing wider reveals the retained text without changing the grouping

### Requirement: Grouped hints preserve configuration and empty-list behavior

Grouped hints SHALL use the effective configured keys, retaining every alias in the generated text with the existing slash-separated display format. Disabled actions SHALL have no hint and SHALL NOT leave dangling separators. If all variant shortcuts are disabled, the footer SHALL omit the second row rather than render an empty row. For zero candidates, `no entries` SHALL prefix the first row followed by ` · `, without adding a row. A nonempty list filtered to zero matches SHALL retain its normal footer. The same grouping SHALL apply on initial launch, variant switches, and successful refresh publication; loading and failure SHALL retain the grouped footer while status and retry messages remain in their existing status area.

#### Scenario: Remapped and disabled controls
- **WHEN** acceptance has multiple aliases and preview or a variant shortcut is disabled
- **THEN** all acceptance aliases appear in the generated first-row switch hint
- **AND** the disabled hints and removed default keys are absent
- **AND** remaining hints keep their assigned row and relative order

#### Scenario: All variant controls disabled
- **WHEN** all five variant shortcut arrays are empty
- **THEN** only the action row is generated, without a trailing newline

#### Scenario: Empty candidate list
- **WHEN** a picker opens or successfully refreshes with zero candidates
- **THEN** `no entries` precedes the first-row action hints
- **AND** enabled variant hints remain on the second row

#### Scenario: No search matches
- **WHEN** a nonempty candidate list is filtered to zero matches
- **THEN** shortcut grouping stays unchanged and the footer does not add `no entries`

#### Scenario: Refresh lifecycle and switching
- **WHEN** a picker refreshes, encounters a failure, retries successfully, or switches variants
- **THEN** action and variant hints retain their assigned groups
- **AND** successful refresh updates the empty-list prefix for the published candidate count
- **AND** refresh status and retry messages do not create a third shortcut row
