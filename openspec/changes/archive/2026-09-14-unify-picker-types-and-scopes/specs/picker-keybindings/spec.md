## MODIFIED Requirements

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
- **THEN** launch reports the effective conflict rather than selecting one action

#### Scenario: Disable optional shortcuts
- **WHEN** optional actions are `[]`
- **THEN** they have no shortcuts or shortcut hints and their defaults are not restored
- **AND** setting accept or close to `[]` instead blocks launch with a required-action diagnostic

#### Scenario: Required action cannot be disabled
- **WHEN** accept or close is configured as `[]`
- **THEN** launch reports that the required action needs at least one key

#### Scenario: New default conflicts with an existing user override
- **WHEN** close includes Ctrl+C and scope_tab retains its default
- **THEN** launch reports the conflict until the user remaps or disables one of those conflicting bindings

### Requirement: Configured actions retain lifecycle semantics

Configured picker and supported scope transitions SHALL work with empty lists and zero matches, preserve immutable origin and current preview visibility, and never focus an entity. Type transitions SHALL save source memory and restore destination type memory or first-visit defaults, using the carried chosen scope and effective fallback. Scope transitions SHALL preserve the active type's latest query and selection target. Effective transitions SHALL fetch fresh candidates with destination ordering, membership, and launch settings. The current-type shortcut SHALL refresh through a fresh transition using its current memory; scope no-ops SHALL obey the scope contract. Only configured acceptance keys SHALL focus an eligible selected entity. Remapped acceptance/cancellation aliases SHALL NOT bypass the effective keymap. Preview defaults SHALL apply only on a new popup.

#### Scenario: Configured switching without matches
- **WHEN** a picker action is invoked from an empty list or zero-match query
- **THEN** the source query is saved and the destination restores its own memory or first-visit defaults under the carried scope
- **AND** preview visibility is preserved without focusing any entity

#### Scenario: Configured switching with an empty list
- **WHEN** a picker shortcut is invoked with zero candidates
- **THEN** source memory is saved and destination type memory or first-visit defaults are restored under the carried scope
- **AND** original context and preview visibility persist without focus

#### Scenario: Scope transition with no matches
- **WHEN** a searched picker with no matches broadens scope
- **THEN** the same query is matched against fresh broader candidates
- **AND** any resulting first-match fallback is selectable only after readiness

#### Scenario: Remapped acceptance
- **WHEN** acceptance is moved away from Enter
- **THEN** Enter cannot accept through its built-in binding and the configured acceptance key targets the selected underlying entity

#### Scenario: All optional shortcuts disabled
- **WHEN** all nine optional actions are disabled
- **THEN** acceptance and closing work in every direct launch preset, including correct output interpretation without transition shortcuts

#### Scenario: Current variant shortcut
- **WHEN** the user invokes the shortcut for the already open type
- **THEN** fresh candidates restore its current query/selection under the same chosen/effective scopes and preview visibility

#### Scenario: Switch between pane scopes and existing views
- **WHEN** Ctrl+R selects Panes and Ctrl+Z/X/C selects a supported scope
- **THEN** Panes uses the shared type/scope model and other picker shortcuts remain available

### Requirement: Each view remembers its place within one popup

Pickr SHALL remember exact query and optional highlighted entity ID independently for the four types Spaces, Tabs, Panes, and Agents, with no separate memory per scope or launch preset. Every transition SHALL save the source's latest state before destination restoration. Scope changes SHALL retain the current type query and use its selected identity; type switches SHALL use destination memory, with empty query and normal first-match selection on first visit. Query whitespace, Unicode, quotes, and shell/fzf metacharacters SHALL be preserved literally without evaluation. Ready zero-match/empty results SHALL record no selection. A ready fallback selection SHALL replace the previous selection for subsequent transitions, rather than resurrecting an old scope-specific target. Memory SHALL be popup-local and discarded on close; preview visibility SHALL be shared.

#### Scenario: Scope is a filter on one query
- **WHEN** Panes searches `server` in This tab and broadens to This space then All spaces
- **THEN** each scope keeps `server` and retains the selected pane if eligible and matched, otherwise the first match or no selection

#### Scenario: Independent round-trip memory
- **WHEN** Panes uses `server`, Agents uses `review`, and the user switches between them
- **THEN** each restores its own query and eligible selection under the currently carried scope
- **AND** an agent pane appearing in both types does not couple their memories

#### Scenario: First visit does not inherit the source query
- **WHEN** a user leaves a query containing whitespace, Unicode, quotes, or metacharacters for a never-visited type and later returns
- **THEN** the new type starts with an empty query and first-match selection
- **AND** returning restores the original exact text without interpretation

#### Scenario: Literal query round trip
- **WHEN** a literal query containing whitespace, Unicode, quotes, or metacharacters is saved and restored
- **THEN** the same exact text returns without trimming or evaluation

#### Scenario: Fallback becomes current selection
- **WHEN** narrowing excludes selected pane A, the ready list selects pane B, and the user broadens again
- **THEN** pane B remains selected if eligible and matched rather than resurrecting pane A

#### Scenario: Ready view has no matching selection
- **WHEN** a ready picker has zero matches and transitions away then returns
- **THEN** its query is restored but no pre-zero-match ID is resurrected; fresh matches use the first result or no selection

#### Scenario: Closing clears memory
- **WHEN** a popup closes through acceptance, cancellation, or failure, or another popup searches the same type
- **THEN** remembered queries/selections do not leak into the other or newly opened popup

#### Scenario: Popups are independent
- **WHEN** two popups search the same type
- **THEN** their queries, selected identities, and chosen scopes remain independent

#### Scenario: Pane scopes and agent views have independent memory
- **WHEN** a pane appears in multiple Panes scopes and also Agents
- **THEN** Panes scopes now share one memory slot while Agents retains its own independent slot

### Requirement: Returning views restore identity against fresh matches

On type or effective scope transitions, Pickr SHALL restore the destination type's query against fresh candidates and highlight its restoration ID only if still eligible and matched. Changed row text, order, or preview target SHALL NOT change identity. Missing or filtered-out IDs SHALL fall back to the first match or none. Acceptance and preview SHALL use current underlying IDs, with acceptance gated until restoration completes. Restoration SHALL be one-shot and SHALL NOT override later navigation or query edits. Closing, enabled preview toggling, picker switching, and applicable scope switching SHALL remain available while restoring. A rapid transition away SHALL retain the latest query and pending restoration ID; old restoration work SHALL NOT affect its destination.

#### Scenario: Metadata and order change while away
- **WHEN** a remembered entity changes row position or preview target but still matches on return
- **THEN** selection follows its identity and preview/acceptance use its current targets

#### Scenario: Remembered entity is removed or stops matching
- **WHEN** a remembered entity is absent or excluded by scope/query
- **THEN** restoration selects the first match or none and cannot accept a stale entity

#### Scenario: Navigate after restoration
- **WHEN** restoration completes and the user navigates or edits the query
- **THEN** the old query/selection is not forced back and the next transition saves the new state

#### Scenario: Switch again before restoration completes
- **WHEN** the user switches type or applicable scope before restoration finishes
- **THEN** the latest query and pending identity are retained for the source type without a transient first-row overwrite
- **AND** unfinished source work cannot change destination selection or focus an entity

### Requirement: Hints describe the effective keymap

Footer and scope shortcut hints and retry messages SHALL use effective configured aliases, never removed defaults. Disabled shortcuts SHALL have no key hint. Unsupported scope choices SHALL retain their labels and, when shortcut hints are enabled, dimmed configured keys indicating unavailability. Scope labels/state SHALL remain visible when key hints are hidden or a scope shortcut is disabled. Error retry hints SHALL advertise only enabled refresh bindings.

#### Scenario: Custom refresh and acceptance hints
- **WHEN** scope_space and refresh are remapped
- **THEN** the scope row and refresh/retry hints use those aliases rather than Ctrl+X/Ctrl+L
- **AND** remapped acceptance aliases likewise replace default acceptance hints

#### Scenario: Disabled shortcuts are absent from hints
- **WHEN** scope_tab is disabled
- **THEN** its key hint is absent while the This tab label and effective/remembered state remain visible
