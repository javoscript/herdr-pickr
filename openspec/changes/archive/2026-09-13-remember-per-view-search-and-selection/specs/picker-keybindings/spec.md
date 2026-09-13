## MODIFIED Requirements

### Requirement: Configured actions retain lifecycle semantics

All configured variant keys SHALL work with empty lists and zero matches, preserve the original workspace, and open the destination with its own remembered query and selection and the current preview visibility from the source variant. First visits SHALL use an empty query and normal first-match selection. Each switch SHALL fetch fresh destination candidates using that variant's existing ordering, filtering, and resolved launch settings. These rules SHALL apply across all 25 source/destination routes, including shortcuts targeting the current variant. Preview visibility SHALL preserve both shown and hidden states, including toggles made since launch. `preview.enabled_by_default` SHALL initialize visibility only for a new popup session. Only configured acceptance keys SHALL focus a selected entity. Closing and switching SHALL not focus an entity. Remapped default acceptance/cancellation aliases SHALL NOT remain alternate routes around the configured action map.

#### Scenario: Configured switching without matches
- **WHEN** a configured variant shortcut is pressed with no matching entries
- **THEN** the source query is remembered and the destination opens in the same popup using the original workspace scope
- **AND** the destination restores its own memory or uses first-visit defaults, while the preview retains its current shown/hidden state
- **AND** no entity is focused

#### Scenario: Configured switching with an empty list
- **WHEN** a configured variant shortcut is pressed with no candidate entries
- **THEN** the source query is remembered and the destination opens using its own memory or first-visit defaults and the original workspace scope
- **AND** the preview retains its current shown/hidden state even if that differs from the configured launch default
- **AND** no entity is focused

#### Scenario: Remapped acceptance
- **WHEN** acceptance is moved away from Enter
- **THEN** Enter does not accept a selection through fzf's built-in binding
- **AND** the configured acceptance key focuses the selected underlying entity

#### Scenario: All optional shortcuts disabled
- **WHEN** all seven optional actions are configured as `[]`
- **THEN** the configured acceptance and closing keys still work in every directly opened variant
- **AND** selection output remains correctly interpreted even without variant-switching shortcuts

#### Scenario: Current variant shortcut
- **WHEN** the user invokes the configured shortcut for the variant already open
- **THEN** Pickr fetches fresh candidates for that variant and restores its current query and selection by identity
- **AND** the original scope and current preview visibility remain in effect without focusing an entity

## ADDED Requirements

### Requirement: Each view remembers its place within one popup

Pickr SHALL remember the exact query and optional highlighted entity ID independently for spaces, current-space tabs, all-spaces tabs, current-space agents, and all-spaces agents within a single open popup. A switch SHALL save the source's latest query and selection before restoring the destination. Query content SHALL be preserved literally, including whitespace, Unicode, quotes, and shell or fzf metacharacters, without evaluation. Ready views with no matching selection SHALL remember no selected entity. Memory SHALL be discarded when the popup closes and SHALL NOT be shared with other popup sessions. Preview visibility SHALL remain shared across views rather than stored separately per view.

#### Scenario: Independent round-trip memory
- **WHEN** the user searches current-space tabs for `server`, highlights a tab, switches to all-spaces agents, searches for `review`, highlights an agent, and switches between those views again
- **THEN** each view restores its own query and highlighted entity when still matched
- **AND** current-space and all-spaces variants do not overwrite one another's memory

#### Scenario: First visit does not inherit the source query
- **WHEN** the user switches from a searched view to a view not yet visited in the popup
- **THEN** the destination starts with an empty query and its normal first matching result, or no selection if empty
- **AND** the source's memory remains available for a later return

#### Scenario: Literal query round trip
- **WHEN** a query containing whitespace, Unicode, quotes, or shell or fzf metacharacters is saved by switching away and then returning
- **THEN** the exact query is restored as search text without trimming, interpretation, or execution

#### Scenario: Ready view has no matching selection
- **WHEN** a ready view has an empty candidate list or a query with zero matches and the user switches away and back
- **THEN** the query is restored against fresh candidates
- **AND** the first matching result is highlighted if any now match, otherwise no entity is highlighted
- **AND** a selection from before the zero-match state is not resurrected as its restoration target

#### Scenario: Closing clears memory
- **WHEN** a popup ends through acceptance, cancellation, or failure and a new popup is opened
- **THEN** all views in the new popup start with first-visit defaults regardless of the previous popup's memory

#### Scenario: Popups are independent
- **WHEN** two popup sessions visit and search the same variant
- **THEN** queries and selections saved in either session do not alter the other session's memory

### Requirement: Returning views restore identity against fresh matches

On a return to a view, Pickr SHALL restore its query against freshly fetched candidates and highlight the remembered entity ID only if it remains a matching candidate. Changed row text, order, or preview target SHALL NOT change the remembered identity. If the ID is absent or filtered out, Pickr SHALL select the first matching result or no entity when there are no matches. Acceptance and preview SHALL target the restored or fallback candidate's current underlying IDs. Restoration SHALL complete before acceptance is enabled and SHALL NOT subsequently override user navigation or query edits. Closing, configured switching, and enabled preview toggling SHALL remain available during restoration; switching away before restoration completes SHALL retain that view's latest query and pending restoration ID.

#### Scenario: Metadata and order change while away
- **WHEN** a remembered entity changes its label, position, or preview pane while another view is open and still matches its view's query on return
- **THEN** the highlight follows the same entity ID in the fresh matching order
- **AND** preview and acceptance use its current target

#### Scenario: Remembered entity is removed or stops matching
- **WHEN** the remembered entity is absent from fresh candidates or no longer matches the restored query
- **THEN** the first matching result is highlighted, or no entity if there are no matches
- **AND** no stale entity can be accepted

#### Scenario: Navigate after restoration
- **WHEN** restoration completes and the user moves to another result or edits the query
- **THEN** the picker follows ordinary navigation and matching behavior without forcing the old selection or query back
- **AND** the next switch saves the latest query and highlighted entity

#### Scenario: Switch again before restoration completes
- **WHEN** the user switches away from a returning view before its remembered selection is restored
- **THEN** the pending restoration ID and latest query are retained for that view
- **AND** unfinished restoration cannot alter the next destination or focus an entity
