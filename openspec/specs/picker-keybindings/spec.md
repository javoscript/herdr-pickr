# picker-keybindings Specification

## Purpose

Let users remap Pickr's popup actions while retaining their general fzf navigation and query-editing preferences without disrupting picker lifecycle behavior.

## Requirements

### Requirement: Every Pickr action has configurable keys

Pickr SHALL expose arrays of supported fzf key names for these actions and defaults: `accept: ["enter"]`, `close: ["esc"]`, `toggle_preview: ["ctrl-p"]`, `refresh: ["ctrl-l"]`, `spaces: ["ctrl-s"]`, `tabs: ["ctrl-t"]`, `panes: ["ctrl-r"]`, `agents: ["ctrl-a"]`, `scope_all: ["ctrl-z"]`, `scope_space: ["ctrl-x"]`, and `scope_tab: ["ctrl-c"]`. Arrays SHALL replace defaults; omitted/null values SHALL retain defaults. Accept and close SHALL require at least one key; the other nine actions SHALL accept `[]`. Unknown/unsupported keys and effective collisions, including aliases, SHALL block launch. Removed scope-specific action settings SHALL produce replacement diagnostics. Disabling popup actions SHALL NOT remove direct launch presets.

#### Scenario: Scope and type defaults
- **WHEN** the default picker and scope shortcuts are used
- **THEN** Ctrl+S/T/R/A select Spaces/Tabs/Panes/Agents and Ctrl+Z/X/C select supported All spaces/This space/This tab scopes
- **AND** Esc closes while Ctrl+C never closes through a built-in cancellation alias

#### Scenario: Remap an action with aliases
- **WHEN** refresh or a scope action has two valid nonconflicting configured keys
- **THEN** either key performs that action wherever applicable and the removed default is not restored

#### Scenario: Conflicting keys
- **WHEN** close is configured with Ctrl+C while scope_tab retains Ctrl+C
- **THEN** Pickr diagnoses the conflict before launching fzf rather than choosing an action silently

#### Scenario: Disable optional shortcuts
- **WHEN** an optional action is configured as `[]`
- **THEN** no key invokes that Pickr action and its default shortcut is not restored
- **AND** disabling a variant shortcut leaves its external Herdr action available

#### Scenario: Required action cannot be disabled
- **WHEN** either `accept` or `close` is configured as `[]`
- **THEN** Pickr reports that the action requires at least one key and does not open fzf

#### Scenario: New default conflicts with an existing user override
- **WHEN** close includes Ctrl+C and scope_tab retains its default
- **THEN** launch reports the conflict until the user remaps or disables one of those conflicting bindings

### Requirement: Configured actions retain lifecycle semantics

Configured picker and supported scope transitions SHALL work with empty lists and zero matches, preserve immutable origin and current preview visibility, and never focus an entity. Type transitions SHALL save source memory and restore destination type memory or first-visit defaults, using the carried chosen scope and effective fallback. Scope transitions SHALL preserve the active type's latest query and selection target. Effective transitions SHALL fetch fresh candidates with destination ordering, membership, and launch settings. The current-type shortcut SHALL refresh through a fresh transition using its current memory; scope no-ops SHALL obey the scope contract. Only configured acceptance keys SHALL focus an eligible selected entity. Remapped acceptance/cancellation aliases SHALL NOT bypass the effective keymap. Preview defaults SHALL apply only on a new popup.

#### Scenario: Configured switching without matches
- **WHEN** a configured variant shortcut is pressed with no matching entries
- **THEN** the source query is remembered and the destination opens in the same popup using the carried chosen scope and effective fallback
- **AND** the destination restores its own memory or uses first-visit defaults, while the preview retains its current shown/hidden state
- **AND** no entity is focused

#### Scenario: Configured switching with an empty list
- **WHEN** a configured variant shortcut is pressed with no candidate entries
- **THEN** the source query is remembered and the destination opens using its own memory or first-visit defaults under the carried scope
- **AND** the preview retains its current shown/hidden state even if that differs from the configured launch default
- **AND** no entity is focused

#### Scenario: Remapped acceptance
- **WHEN** acceptance is moved away from Enter
- **THEN** Enter does not accept a selection through fzf's built-in binding
- **AND** the configured acceptance key focuses the selected underlying entity

#### Scenario: All optional shortcuts disabled
- **WHEN** all nine optional actions are configured as `[]`
- **THEN** the configured acceptance and closing keys still work in every directly opened variant
- **AND** selection output remains correctly interpreted even without variant-switching shortcuts

#### Scenario: Current variant shortcut
- **WHEN** the user invokes the shortcut for the already open type
- **THEN** fresh candidates restore its current query/selection under the same chosen/effective scopes and preview visibility

#### Scenario: Switch between pane scopes and existing views
- **WHEN** Ctrl+R selects Panes and Ctrl+Z/X/C selects a supported scope
- **THEN** Panes uses the shared type/scope model and other picker shortcuts remain available

#### Scenario: Scope transition with no matches
- **WHEN** a searched picker with no matches broadens scope
- **THEN** the same query is matched against fresh broader candidates
- **AND** any resulting first-match fallback is selectable only after readiness

### Requirement: Hints describe the effective keymap

Footer and scope shortcut hints and retry messages SHALL use effective configured aliases, never removed defaults. Disabled shortcuts SHALL have no key hint. Unsupported scope choices SHALL retain their labels and, when shortcut hints are enabled, dimmed configured keys indicating unavailability. Scope labels/state SHALL remain visible when key hints are hidden or a scope shortcut is disabled. Error retry hints SHALL advertise only enabled refresh bindings.

#### Scenario: Custom refresh and acceptance hints
- **WHEN** scope_space, refresh, and acceptance are remapped
- **THEN** footer and scope hints show their configured keys rather than removed defaults
- **AND** a refresh failure advertises the configured refresh key or keys

#### Scenario: Disabled shortcuts are absent from hints
- **WHEN** preview toggling, a picker shortcut, or scope_tab is disabled
- **THEN** its hint is absent in the ready, refreshing, and failure states
- **AND** enabled action hints continue to show their effective keys
- **AND** the This tab label and effective/remembered state remain visible

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

Pickr SHALL remember exact query and optional highlighted entity ID independently for the four types Spaces, Tabs, Panes, and Agents, with no separate memory per scope or launch preset. Every transition SHALL save the source's latest state before destination restoration. Scope changes SHALL retain the current type query and use its selected identity; type switches SHALL use destination memory, with empty query and normal first-match selection on first visit. Query whitespace, Unicode, quotes, and shell/fzf metacharacters SHALL be preserved literally without evaluation. Ready zero-match/empty results SHALL record no selection. A ready fallback selection SHALL replace the previous selection for subsequent transitions, rather than resurrecting an old scope-specific target. Memory SHALL be popup-local and discarded on close; preview visibility SHALL be shared.

#### Scenario: Independent round-trip memory
- **WHEN** Panes uses `server`, Agents uses `review`, and the user switches between them
- **THEN** each restores its own query and eligible selection under the currently carried scope
- **AND** an agent pane appearing in both types does not couple their memories

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
- **THEN** queries, selections, and chosen scopes saved in either session do not alter the other session's memory

#### Scenario: Pane scopes and agent views have independent memory
- **WHEN** a pane appears in multiple Panes scopes and also Agents
- **THEN** Panes scopes now share one memory slot while Agents retains its own independent slot

#### Scenario: Scope is a filter on one query
- **WHEN** Panes searches `server` in This tab and broadens to This space then All spaces
- **THEN** each scope keeps `server` and retains the selected pane if eligible and matched, otherwise the first match or no selection

#### Scenario: Fallback becomes current selection
- **WHEN** narrowing excludes selected pane A, the ready list selects pane B, and the user broadens again
- **THEN** pane B remains selected if eligible and matched rather than resurrecting pane A

### Requirement: Returning views restore identity against fresh matches

On type or effective scope transitions, Pickr SHALL restore the destination type's query against fresh candidates and highlight its restoration ID only if still eligible and matched. Changed row text, order, or preview target SHALL NOT change identity. Missing or filtered-out IDs SHALL fall back to the first match or none. Acceptance and preview SHALL use current underlying IDs, with acceptance gated until restoration completes. Restoration SHALL be one-shot and SHALL NOT override later navigation or query edits. Closing, enabled preview toggling, picker switching, and applicable scope switching SHALL remain available while restoring. A rapid transition away SHALL retain the latest query and pending restoration ID; old restoration work SHALL NOT affect its destination.

#### Scenario: Metadata and order change while away
- **WHEN** a remembered entity changes its label, position, or preview pane while another view is open and still matches its view's query on return
- **THEN** the highlight follows the same entity ID in the fresh matching order
- **AND** preview and acceptance use its current target

#### Scenario: Remembered entity is removed or stops matching
- **WHEN** the remembered entity is absent from fresh candidates or excluded by scope/query
- **THEN** the first matching result is highlighted, or no entity if there are no matches
- **AND** no stale entity can be accepted

#### Scenario: Navigate after restoration
- **WHEN** restoration completes and the user moves to another result or edits the query
- **THEN** the picker follows ordinary navigation and matching behavior without forcing the old selection or query back
- **AND** the next switch saves the latest query and highlighted entity

#### Scenario: Switch again before restoration completes
- **WHEN** the user switches type or applicable scope before restoration finishes
- **THEN** the latest query and pending identity are retained for the source type without a transient first-row overwrite
- **AND** unfinished restoration cannot alter the next destination or focus an entity
