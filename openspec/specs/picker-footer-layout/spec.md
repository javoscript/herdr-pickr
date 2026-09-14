# picker-footer-layout Specification

## Purpose

Keep bottom shortcut hints predictable and compact by separating picker actions from variant navigation into stable rows.

## Requirements

### Requirement: Footer hints use action and variant rows

When `popup.show_hints` is true, Pickr SHALL place enabled switch, close, preview, and refresh hints on its first footer row, and enabled Spaces, Tabs, Panes, and Agents shortcuts on the second, including the active type. Default rows SHALL be `enter: switch · esc: close · ctrl+p: preview · ctrl+l: refresh` and `ctrl+s: spaces · ctrl+t: tabs · ctrl+r: panes · ctrl+a: agents`. Labels SHALL remain lowercase with ` · ` separators. Scope hints SHALL appear near the prompt instead of adding footer rows. Long footer rows SHALL clip without wrapping or generating extra rows. Hidden hints SHALL remove the footer, blank footer rows, and footer-only separator.

#### Scenario: Default hints in every variant
- **WHEN** any type opens at any scope with default bindings, hints shown, and a nonempty candidate list
- **THEN** its first footer row is `enter: switch · esc: close · ctrl+p: preview · ctrl+l: refresh`
- **AND** its second footer row is `ctrl+s: spaces · ctrl+t: tabs · ctrl+r: panes · ctrl+a: agents`
- **AND** no third footer row is generated

#### Scenario: Narrow popup or long aliases
- **WHEN** hints are shown and either hint group is wider than the available footer area
- **THEN** the group remains on its assigned row with excess text clipped by fzf
- **AND** resizing wider reveals the retained text without changing the grouping

#### Scenario: Whole hints section hidden
- **WHEN** any picker variant opens with `popup.show_hints` set to `false`
- **THEN** neither hint row nor blank footer space or a footer-only separator is displayed
- **AND** configured shortcuts remain available

### Requirement: Grouped hints preserve configuration and empty-list behavior

Visible footer hints SHALL retain all effective aliases in slash-separated format and omit disabled actions without dangling separators. If all four picker shortcuts are disabled, the second row SHALL be omitted. Zero candidates SHALL prefix the first row with `no entries · `; a nonempty list with zero matches SHALL not. Initial launch, type/scope changes, and refresh publication SHALL use the same grouping. Loading/failure SHALL retain the footer and place messages near the scope/status area. Hidden hints SHALL remove the footer and its empty-list prefix in all states without hiding refresh/error messages or scope state.

#### Scenario: Remapped and disabled controls
- **WHEN** hints are shown, acceptance has multiple aliases, and preview or a variant shortcut is disabled
- **THEN** all acceptance aliases appear in the generated first-row switch hint
- **AND** the disabled hints and removed default keys are absent
- **AND** remaining hints keep their assigned row and relative order

#### Scenario: All variant controls disabled
- **WHEN** hints are shown and all four picker shortcut arrays are empty
- **THEN** only the action row is generated, without a trailing newline

#### Scenario: Empty candidate list
- **WHEN** a picker with hints shown opens or successfully refreshes with zero candidates
- **THEN** `no entries` precedes the first-row action hints
- **AND** enabled variant hints remain on the second row

#### Scenario: No search matches
- **WHEN** hints are shown and a nonempty candidate list is filtered to zero matches
- **THEN** shortcut grouping stays unchanged and the footer does not add `no entries`

#### Scenario: Refresh lifecycle and switching
- **WHEN** a picker with hints shown refreshes, encounters a failure, retries successfully, or switches variants
- **THEN** action and variant hints retain their assigned groups
- **AND** successful refresh updates the empty-list prefix for the published candidate count
- **AND** refresh status and retry messages do not create a third shortcut row

#### Scenario: Hidden footer stays absent through empty results and lifecycle changes
- **WHEN** a picker with hints hidden has zero candidates or zero search matches, switches variants, or refreshes through loading, failure, and successful retry
- **THEN** no footer, `no entries` prefix, or reserved footer space appears
- **AND** scope state, refresh status and retry messages continue to appear in their existing status area

### Requirement: Scope state remains visible near the query

Pickr SHALL display one non-selectable scope row near/below the prompt and before candidate results, containing All spaces, This space, and This tab in that order in every type. The effective scope SHALL be visually distinguished; unsupported choices SHALL be muted with none active in Spaces. When a chosen scope is temporarily unsupported, visible text SHALL identify the remembered choice separately from the effective selection. Availability SHALL reflect the type's scope matrix rather than current result count or origin existence. With hints shown, every enabled scope action SHALL display its configured aliases, dimmed when unavailable. Hidden hints or disabled shortcuts SHALL suppress shortcut text, not scope labels/state. The row SHALL remain visible with empty results, during refresh/restoration/errors, and with hidden preview; it SHALL not become a searchable or selectable candidate. Long scope text SHALL clip rather than wrap.

#### Scenario: Effective fallback and remembered intent
- **WHEN** chosen scope is This tab and Tabs is active
- **THEN** This space is highlighted, This tab is muted, and visible text identifies This tab as remembered
- **AND** the remembered-choice text occupies its own non-selectable line immediately below the scope row, remaining visible with the preview shown

#### Scenario: Spaces shows no active scope
- **WHEN** Spaces opens
- **THEN** all three scope choices are muted and none is active

#### Scenario: Hidden hints preserve filter awareness
- **WHEN** hints are hidden or scope shortcuts disabled
- **THEN** scope labels, effective selection, and any remembered choice remain visible without the corresponding key hints

#### Scenario: Refresh and narrow layout
- **WHEN** refresh fails in a narrow popup with zero results
- **THEN** the scope row remains non-selectable alongside the failure/retry state, uses clipping, and is not replaced by the status message
- **AND** any remembered-choice line remains separate from the scope choices and the failure/retry message
