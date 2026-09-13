# picker-keybindings Specification

## Purpose

Let users remap Pickr's popup actions while retaining their general fzf navigation and query-editing preferences without disrupting picker lifecycle behavior.

## Requirements

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

### Requirement: Hints describe the effective keymap

Footer action hints and retry messages SHALL be generated from the effective action keys. Footer hints SHALL expose configured aliases and SHALL NOT advertise removed default bindings or disabled shortcuts. Error-state hints SHALL only advertise enabled shortcuts.

#### Scenario: Custom refresh and acceptance hints
- **WHEN** the user overrides refresh and acceptance keys
- **THEN** footer hints show their configured keys
- **AND** a refresh failure advertises the configured refresh key or keys

#### Scenario: Disabled shortcuts are absent from hints
- **WHEN** preview toggling or a variant-switching shortcut is disabled
- **THEN** its hint is absent in the ready, refreshing, and failure states
- **AND** enabled action hints continue to show their effective keys

### Requirement: General fzf bindings coexist with Pickr actions

Pickr SHALL import supported key-triggered navigation, query-editing, and preview-scrolling bindings from `FZF_DEFAULT_OPTS_FILE` and `FZF_DEFAULT_OPTS`, respecting the supported fzf version's source precedence. Pickr SHALL document the supported action set. Pickr action keys SHALL take precedence over inherited bindings on the same effective keys. General fzf keybindings SHALL NOT be configured through Pickr's JSON action map.

#### Scenario: Inherit query editing
- **WHEN** fzf configuration binds an unclaimed key to a supported query-editing action
- **THEN** that key performs the editing action in Pickr, including during refresh

#### Scenario: Inherited key conflicts with Pickr
- **WHEN** fzf configuration binds a navigation action to Pickr's configured refresh key
- **THEN** the key performs Pickr refresh and not the inherited navigation action

#### Scenario: Config file and environment both bind a key
- **WHEN** both fzf configuration sources define supported actions for the same unclaimed key
- **THEN** the effective action follows fzf's source precedence

### Requirement: Ambient fzf configuration cannot replace picker protocols

Pickr SHALL retain control of candidate input/output format, acceptance, cancellation, variant switching, refresh events, preview toggling and commands, and resolved theme. Unrelated ambient options SHALL NOT replace those behaviors. Unsupported binding actions and event bindings SHALL be excluded with a non-blocking diagnostic identifying the key or event and unsupported action; a chain containing an unsupported action SHALL be excluded as a whole. Exclusion SHALL NOT prevent the picker from opening or other supported bindings from applying. Disabling an optional Pickr shortcut SHALL NOT allow an unsupported inherited binding to restore that action. Pickr SHALL NOT execute configuration text through a shell merely to parse it.

#### Scenario: Ambient lifecycle and output changes
- **WHEN** ambient fzf options request a different output format or add an accept/reload event binding
- **THEN** Pickr retains its output protocol and refresh lifecycle
- **AND** the unsupported binding is diagnosed and excluded

#### Scenario: Inherited mixed action chain
- **WHEN** an inherited binding combines supported navigation with an unsupported command action
- **THEN** the entire binding is excluded with a diagnostic
- **AND** Pickr does not execute a partial chain

#### Scenario: Unsupported binding does not block launch
- **WHEN** fzf configuration contains an unsupported execute binding alongside a supported navigation binding
- **THEN** Pickr opens and the supported navigation binding works
- **AND** a non-blocking diagnostic identifies the excluded key and execute action

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
