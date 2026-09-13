## MODIFIED Requirements

### Requirement: Every Pickr action has configurable keys

Pickr SHALL expose `keys.accept`, `keys.close`, `keys.toggle_preview`, `keys.refresh`, `keys.tabs_current`, `keys.tabs_all`, `keys.spaces`, `keys.agents_current`, `keys.agents_all`, `keys.panes_tab`, `keys.panes_current`, and `keys.panes_all` as arrays of fzf key names. Defaults SHALL respectively be `["enter"]`, `["esc", "ctrl-c"]`, `["ctrl-p"]`, `["ctrl-l"]`, `["ctrl-r"]`, `["ctrl-t"]`, `["ctrl-s"]`, `["ctrl-a"]`, `["ctrl-g"]`, `["alt-1"]`, `["alt-2"]`, and `["alt-3"]`. An override SHALL replace that action's default keys. `accept` and `close` SHALL each require at least one key; every other action SHALL accept `[]` to disable its shortcut. Omitted or null settings SHALL retain defaults. Unknown or unsupported keys and conflicting effective keys across Pickr actions SHALL be rejected, including aliases interpreted as the same key by the supported fzf runtime.

#### Scenario: Remap an action with aliases
- **WHEN** refresh is configured with two valid nonconflicting keys
- **THEN** either key refreshes all eight variants
- **AND** Ctrl+L no longer performs Pickr refresh unless explicitly included

#### Scenario: Conflicting keys
- **WHEN** acceptance and a variant switch resolve to the same effective key
- **THEN** Pickr diagnoses the conflict before launching fzf rather than choosing an action silently

#### Scenario: Disable optional shortcuts
- **WHEN** an optional action is configured as `[]`
- **THEN** no key invokes that Pickr action and its default shortcut is not restored
- **AND** disabling a variant shortcut leaves its external Herdr action available

#### Scenario: Required action cannot be disabled
- **WHEN** either `accept` or `close` is configured as `[]`
- **THEN** Pickr reports that the action requires at least one key and does not open fzf

#### Scenario: New default conflicts with an existing user override
- **WHEN** a user assigns another Pickr action to Alt+1 while panes-tab retains its default
- **THEN** launch reports the key conflict
- **AND** explicitly remapping or disabling `keys.panes_tab` resolves that conflict

### Requirement: Configured actions retain lifecycle semantics

All configured variant keys SHALL work with empty lists and zero matches, preserve the original workspace and available original tab, and open the destination with its own remembered query and selection and the current preview visibility from the source variant. First visits SHALL use an empty query and normal first-match selection. Each switch SHALL fetch fresh destination candidates using that variant's existing ordering, filtering, and resolved launch settings. These rules SHALL apply across all 64 source/destination routes among the eight variants, including shortcuts targeting the current variant. Preview visibility SHALL preserve both shown and hidden states, including toggles made since launch. `preview.enabled_by_default` SHALL initialize visibility only for a new popup session. Only configured acceptance keys SHALL focus a selected entity. Closing and switching SHALL not focus an entity. Remapped default acceptance/cancellation aliases SHALL NOT remain alternate routes around the configured action map.

#### Scenario: Configured switching without matches
- **WHEN** a configured variant shortcut is pressed with no matching entries
- **THEN** the source query is remembered and the destination opens in the same popup using its original scope
- **AND** the destination restores its own memory or uses first-visit defaults, while the preview retains its current shown/hidden state
- **AND** no entity is focused

#### Scenario: Configured switching with an empty list
- **WHEN** a configured variant shortcut is pressed with no candidate entries
- **THEN** the source query is remembered and the destination opens using its own memory or first-visit defaults and its original scope
- **AND** the preview retains its current shown/hidden state even if that differs from the configured launch default
- **AND** no entity is focused

#### Scenario: Remapped acceptance
- **WHEN** acceptance is moved away from Enter
- **THEN** Enter does not accept a selection through fzf's built-in binding
- **AND** the configured acceptance key focuses the selected underlying entity

#### Scenario: All optional shortcuts disabled
- **WHEN** all ten optional actions are configured as `[]`
- **THEN** the configured acceptance and closing keys still work in every directly opened variant
- **AND** selection output remains correctly interpreted even without variant-switching shortcuts

#### Scenario: Current variant shortcut
- **WHEN** the user invokes the configured shortcut for the variant already open
- **THEN** Pickr fetches fresh candidates for that variant and restores its current query and selection by identity
- **AND** the original scope and current preview visibility remain in effect without focusing an entity

#### Scenario: Switch between pane scopes and existing views
- **WHEN** the user invokes Alt+1, Alt+2, or Alt+3 with default bindings from any view
- **THEN** panes-tab, panes-current, or panes-all opens respectively
- **AND** existing configured view shortcuts remain available from the destination

### Requirement: Each view remembers its place within one popup

Pickr SHALL remember the exact query and optional highlighted entity ID independently for spaces, current-space tabs, all-spaces tabs, current-space agents, all-spaces agents, current-tab panes, current-space panes, and all-spaces panes within a single open popup. A switch SHALL save the source's latest query and selection before restoring the destination. Query content SHALL be preserved literally, including whitespace, Unicode, quotes, and shell or fzf metacharacters, without evaluation. Ready views with no matching selection SHALL remember no selected entity. Memory SHALL be discarded when the popup closes and SHALL NOT be shared with other popup sessions. Preview visibility SHALL remain shared across views rather than stored separately per view.

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

#### Scenario: Pane scopes and agent views have independent memory
- **WHEN** the same pane is eligible in multiple pane scopes and an agent view and the user searches or highlights it differently in each view
- **THEN** each of those views retains its own query and selected ID without overwriting another view's state
