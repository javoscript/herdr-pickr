## MODIFIED Requirements

### Requirement: Footer hints use action and variant rows

When `popup.show_hints` is `true`, every picker SHALL place enabled switch, close, preview, and refresh hints on its first footer row, in that order. It SHALL place enabled tabs here, all tabs, spaces, agents here, all agents, panes in tab, panes in space, and all panes hints on its second footer row, in that order, including the current variant's shortcut. With default bindings and hints shown, the footer SHALL contain exactly these two rows. Hints SHALL retain lowercase labels and use ` · ` between hints on the same row. Footer generation SHALL NOT insert additional rows based on text length. Text wider than the available footer area SHALL use normal fzf clipping rather than additional hint rows. When `popup.show_hints` is `false`, the entire footer section SHALL be absent, with no blank rows or footer-only separator reserved for it.

#### Scenario: Default hints in every variant
- **WHEN** any of the eight picker variants opens with default bindings, hints shown, and a nonempty candidate list
- **THEN** its first footer row is `enter: switch · esc/ctrl+c: close · ctrl+p: preview · ctrl+l: refresh`
- **AND** its second footer row is `ctrl+r: tabs here · ctrl+t: all tabs · ctrl+s: spaces · ctrl+a: agents here · ctrl+g: all agents · alt+1: panes in tab · alt+2: panes in space · alt+3: all panes`
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

When hints are shown, grouped hints SHALL use the effective configured keys, retaining every alias in the generated text with the existing slash-separated display format. Disabled actions SHALL have no hint and SHALL NOT leave dangling separators. If all variant shortcuts are disabled, the footer SHALL omit the second row rather than render an empty row. For zero candidates with hints shown, `no entries` SHALL prefix the first row followed by ` · `, without adding a row. A nonempty list filtered to zero matches SHALL retain its normal footer. The same grouping SHALL apply on initial launch, variant switches, and successful refresh publication; loading and failure SHALL retain the grouped footer while status and retry messages remain in their existing status area. When hints are hidden, the footer SHALL remain absent in all these states, including its `no entries` prefix; status and retry messages SHALL remain visible in their existing status area.

#### Scenario: Remapped and disabled controls
- **WHEN** hints are shown, acceptance has multiple aliases, and preview or a variant shortcut is disabled
- **THEN** all acceptance aliases appear in the generated first-row switch hint
- **AND** the disabled hints and removed default keys are absent
- **AND** remaining hints keep their assigned row and relative order

#### Scenario: All variant controls disabled
- **WHEN** hints are shown and all eight variant shortcut arrays are empty
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
- **AND** refresh status and retry messages continue to appear in their existing status area
