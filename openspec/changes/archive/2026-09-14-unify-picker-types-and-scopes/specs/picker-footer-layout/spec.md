## MODIFIED Requirements

### Requirement: Footer hints use action and variant rows

When `popup.show_hints` is true, Pickr SHALL place enabled switch, close, preview, and refresh hints on its first footer row, and enabled Spaces, Tabs, Panes, and Agents shortcuts on the second, including the active type. Default rows SHALL be `enter: switch · esc: close · ctrl+p: preview · ctrl+l: refresh` and `ctrl+s: spaces · ctrl+t: tabs · ctrl+r: panes · ctrl+a: agents`. Labels SHALL remain lowercase with ` · ` separators. Scope hints SHALL appear near the prompt instead of adding footer rows. Long footer rows SHALL clip without wrapping or generating extra rows. Hidden hints SHALL remove the footer, blank footer rows, and footer-only separator.

#### Scenario: Default hints in every variant
- **WHEN** any type opens at any scope with default bindings and visible hints
- **THEN** the footer has the two specified rows and no scope-specific picker shortcuts

#### Scenario: Narrow popup or long aliases
- **WHEN** a visible footer row exceeds available width
- **THEN** it clips without wrapping and resizing wider reveals its retained text
- **AND** enabled keyboard actions retain their behavior

#### Scenario: Whole hints section hidden
- **WHEN** hints are hidden
- **THEN** the entire footer and footer-only space/separator are absent
- **AND** enabled keyboard actions retain their behavior

### Requirement: Grouped hints preserve configuration and empty-list behavior

Visible footer hints SHALL retain all effective aliases in slash-separated format and omit disabled actions without dangling separators. If all four picker shortcuts are disabled, the second row SHALL be omitted. Zero candidates SHALL prefix the first row with `no entries · `; a nonempty list with zero matches SHALL not. Initial launch, type/scope changes, and refresh publication SHALL use the same grouping. Loading/failure SHALL retain the footer and place messages near the scope/status area. Hidden hints SHALL remove the footer and its empty-list prefix in all states without hiding refresh/error messages or scope state.

#### Scenario: Remapped and disabled controls
- **WHEN** accept has multiple aliases and preview or a picker action is disabled
- **THEN** aliases appear in their assigned row, disabled hints are absent, and remaining hints keep their order

#### Scenario: All variant controls disabled
- **WHEN** all four picker shortcut arrays are empty with hints shown
- **THEN** only the control row appears without a trailing blank row

#### Scenario: Empty candidate list
- **WHEN** a visible-hints picker has zero candidates
- **THEN** `no entries` prefixes the control row and enabled picker hints remain on the second row

#### Scenario: No search matches
- **WHEN** a nonempty list is filtered to zero matches
- **THEN** footer grouping is unchanged and no `no entries` prefix is added

#### Scenario: Refresh lifecycle and switching
- **WHEN** Pickr changes type/scope or refreshes through loading, failure, and retry
- **THEN** footer grouping and configured visibility remain stable, with scope/status outside the footer

#### Scenario: Hidden footer stays absent through empty results and lifecycle changes
- **WHEN** hidden hints coexist with empty/zero-match results, transitions, refresh failure, or retry
- **THEN** no footer or reserved footer space appears while scope state and refresh/error messages remain visible

## ADDED Requirements

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
