## Purpose

Let users remap Pickr's popup actions while retaining their general fzf navigation and query-editing preferences without disrupting picker lifecycle behavior.

## ADDED Requirements

### Requirement: Every Pickr action has configurable keys

Pickr SHALL expose `keys.accept`, `keys.close`, `keys.toggle_preview`, `keys.refresh`, `keys.tabs_current`, `keys.tabs_all`, `keys.spaces`, `keys.agents_current`, and `keys.agents_all` as arrays of fzf key names. Defaults SHALL respectively be `["enter"]`, `["esc", "ctrl-c"]`, `["ctrl-p"]`, `["ctrl-l"]`, `["ctrl-r"]`, `["ctrl-t"]`, `["ctrl-s"]`, `["ctrl-a"]`, and `["ctrl-g"]`. An override SHALL replace that action's default keys. `accept` and `close` SHALL each require at least one key; every other action SHALL accept `[]` to disable its shortcut. Omitted or null settings SHALL retain defaults. Unknown or unsupported keys and conflicting effective keys across Pickr actions SHALL be rejected, including aliases interpreted as the same key by the supported fzf runtime.

#### Scenario: Remap an action with aliases
- **WHEN** refresh is configured with two valid nonconflicting keys
- **THEN** either key refreshes all five variants
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

### Requirement: Configured actions retain lifecycle semantics

All configured variant keys SHALL work with empty lists and zero matches, preserve the original workspace, reset the query, and open the destination with the current preview visibility from the source variant. This SHALL preserve both shown and hidden states, including toggles made since launch, across all 25 source/destination routes. `preview.enabled_by_default` SHALL initialize visibility only for a new popup session. Only configured acceptance keys SHALL focus a selected entity. Closing SHALL not focus an entity. Remapped default acceptance/cancellation aliases SHALL NOT remain alternate routes around the configured action map.

#### Scenario: Configured switching without matches
- **WHEN** a configured variant shortcut is pressed with no matching entries
- **THEN** its destination opens in the same popup using the original workspace scope
- **AND** the query resets while the preview retains its current shown/hidden state
- **AND** no entity is focused

#### Scenario: Configured switching with an empty list
- **WHEN** a configured variant shortcut is pressed with no candidate entries
- **THEN** its destination opens with a reset query and the original workspace scope
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
