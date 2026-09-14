# picker-refresh Specification

## Purpose

Let users refresh open pickers on demand to see current statuses and metadata while retaining their search, preview visibility, and selection context.

## Requirements

### Requirement: Manual refresh is available in every picker

Every type at every supported effective scope SHALL use resolved refresh keys, default Ctrl+L, to rebuild its complete list from current Herdr data without closing the popup. Disabled refresh SHALL have no shortcut/hint and its default SHALL not return on transitions. Visible hints SHALL advertise effective keys. Refresh SHALL retain type, chosen/effective scope, immutable workspace/tab origin, query, current preview visibility, and launch settings. It SHALL publish membership, metadata, statuses, counts, directories, alignment, and preview targets together using resolved columns/theme. It SHALL not focus an entity, run periodically, or broaden/rebind scope when origin/candidates are missing.

#### Scenario: Refresh each variant
- **WHEN** refresh is invoked in Spaces, either Tabs scope, or any Panes/Agents scope
- **THEN** the same effective scope is refreshed under immutable origin, retaining chosen scope even during fallback
- **AND** no underlying workspace, tab, or pane is focused by refreshing

#### Scenario: Metadata and membership change
- **WHEN** statuses, labels, titles, counts, directories, preview targets, or candidate membership change before a successful refresh
- **THEN** the refreshed list reflects the current values and membership for its scope
- **AND** column headers, formatting, and per-column search behavior remain consistent with the refreshed rows

#### Scenario: Empty picker receives new entries
- **WHEN** a picker with no entries or no search matches is refreshed
- **THEN** refresh remains available and rebuilds the list
- **AND** newly available candidates are evaluated against the preserved query

#### Scenario: Refresh shortcut disabled
- **WHEN** `keys.refresh` is `[]`
- **THEN** Ctrl+L does not trigger Pickr refresh and no refresh hint appears
- **AND** switching variants does not restore a refresh shortcut

### Requirement: Loading replaces selectable results

While fetching/preparing refreshed results, Pickr SHALL replace old candidates with a visible non-selectable `Refreshing…` state, retaining column headings and scope state. Configured acceptance, built-in acceptance aliases, and inherited bindings SHALL NOT accept or defer acceptance. Query and preview visibility SHALL remain, including edits/toggles during loading. Configured closing, enabled preview toggling, picker switches, and supported scope switches SHALL remain available. Disabled actions SHALL remain disabled; unsupported scope keys SHALL remain no-ops. Loading completion SHALL not overwrite later query edits.

#### Scenario: Slow refresh
- **WHEN** a refresh has started but its results are not ready
- **THEN** the previous rows are not displayed as candidates and `Refreshing…` is visible
- **AND** pressing any configured acceptance key causes no focus operation or deferred acceptance
- **AND** the query remains intact and a hidden preview does not become visible
- **AND** scope/header state remains intact until publication

#### Scenario: Edit query during refresh
- **WHEN** the user edits the search query while refreshing
- **THEN** the refreshed results are filtered using the edited query
- **AND** completion does not restore an older query or undo a preview visibility toggle

#### Scenario: Multiple acceptance aliases
- **WHEN** acceptance has two configured keys and refresh is loading
- **THEN** neither key accepts
- **AND** both become available only after successful result publication

### Requirement: Refresh restores entity identity and existing ordering

On successful refresh, the picker SHALL apply its existing ordering and filtering rules and restore the highlight to the same pane, tab, or workspace ID if it is still a matching candidate, regardless of changed row text or position. Agent ordering SHALL remain blocked, done, working, idle, unknown, then descending state-change sequence with original API layout order for exact ties. Other variants SHALL retain their existing ordering rules. If the previous ID is absent or does not match the current query, the picker SHALL highlight the first matching result, or no entry when there are no matches. Acceptance through any configured acceptance key and preview SHALL target the refreshed entry's underlying IDs.

#### Scenario: Highlighted agent changes status and position
- **WHEN** the highlighted agent changes from working to blocked and the list is refreshed
- **THEN** the agent moves according to the existing priority rules
- **AND** the highlight follows its pane ID rather than remaining at the old row position
- **AND** a configured acceptance key after completion focuses that same pane

#### Scenario: Highlighted entity disappears or stops matching
- **WHEN** the highlighted entity is removed or its updated metadata no longer matches the current query
- **THEN** the first matching refreshed entry is highlighted
- **AND** no entry is highlighted if there are no matches

#### Scenario: Updated preview target
- **WHEN** a highlighted tab or workspace retains its ID but its preview pane changes in the refreshed data
- **THEN** the highlight remains on that tab or workspace
- **AND** its preview uses the updated pane ID without changing preview visibility

### Requirement: Refresh failure is retryable without stale candidates

A failed/timed-out refresh SHALL show a non-selectable failure and retry hint using effective enabled refresh keys, without restoring stale rows or erasing scope state. Query, chosen/effective scope, origin, and current preview visibility SHALL remain. Closing, retry, enabled preview/type actions, and supported scope actions SHALL remain usable without reviving disabled defaults. Acceptance SHALL stay disabled. Successful retry SHALL restore the pre-refresh identity if matched, otherwise first match or none, retaining recovery identity until successful completion or transition.

#### Scenario: Failed fetch followed by retry
- **WHEN** refreshing fails or times out
- **THEN** the picker displays a clear refresh failure and retry message using its configured refresh keys, with no selectable stale rows
- **AND** no acceptance key focuses an entry
- **AND** pressing any configured refresh key retries and restores the previous ID if it remains a match after success

#### Scenario: Failure with optional controls disabled
- **WHEN** refresh fails in a launch with preview/type/scope shortcuts disabled
- **THEN** configured retry and closing remain available
- **AND** disabled shortcuts remain absent from bindings and hints after failure and successful retry, while scope labels remain visible

### Requirement: Refresh work belongs to one active picker

At most one refresh SHALL be active; further refresh presses during loading SHALL be ignored. Closing or a type/effective-scope transition SHALL cancel source work and discard late results without waiting for the timeout. Transitions during loading/error SHALL save latest query and pre-refresh recovery ID in source type memory, not loading placeholders. Type changes SHALL restore destination type memory or first-visit defaults; scope changes SHALL carry source query/recovery identity into the new scope. Destinations SHALL fetch fresh candidates under immutable origin and current chosen/effective scope, preserving preview visibility. Returning SHALL not resume old refresh/error state. Successful ready fallback/no-match results SHALL supersede older recovery IDs for subsequent memory capture.

#### Scenario: Repeated refresh key presses
- **WHEN** the user presses one or more configured refresh keys repeatedly while a refresh is pending
- **THEN** only the original refresh runs and no additional refresh is queued

#### Scenario: Close during refresh
- **WHEN** the user closes the picker while refreshing
- **THEN** pending refresh work is cancelled and its resources are released
- **AND** no focus operation occurs and closing does not wait for the fetch timeout

#### Scenario: Switch variants during refresh
- **WHEN** the user invokes a configured variant-switching shortcut while refreshing
- **THEN** the source saves its latest query and recovery ID, and the destination opens with its own type memory or first-visit defaults under the carried scope
- **AND** both shown and hidden preview states are preserved, including any preview toggle made while refreshing
- **AND** the source refresh is cancelled and cannot modify the destination list or selection

#### Scenario: Switch variants after refresh failure
- **WHEN** the user invokes a configured variant-switching shortcut after a refresh fails or times out
- **THEN** the source saves its latest query and recovery ID, and the destination opens with its own type memory or first-visit defaults under the carried scope
- **AND** it preserves the source variant's current shown/hidden preview state, including any toggle made in the error state, rather than reapplying the configured launch default

#### Scenario: Edit during refresh and return after switching away
- **WHEN** the user edits the query during loading or refresh failure, switches away, and later returns
- **THEN** the source view fetches fresh candidates and restores the edited query
- **AND** it highlights the pre-refresh entity if it still matches, otherwise the first matching result or no entity for zero matches
- **AND** cancelled refresh results and loading/error placeholders do not become selectable candidates

#### Scenario: Successful retry replaces recovery selection with current selection
- **WHEN** a refresh retry succeeds, the user highlights a refreshed result, and then switches away and returns
- **THEN** view memory restores the query and entity highlighted at switch time rather than an older pre-refresh ID
- **AND** a successful refresh with no matches saves no selected entity

#### Scenario: Change scope during refresh
- **WHEN** Panes refresh is pending and the user broadens scope
- **THEN** source work is cancelled, the latest query and recovery pane ID are used against fresh broader candidates, and late source results cannot replace them

### Requirement: Pane refresh shares identity recovery and cancellation semantics

Panes at every scope SHALL share the query/preview-preserving, non-selectable loading/error, retry, identity-restoration, and cancellation behavior. Successful refresh SHALL preserve workspace/tab/layout ordering and select the same pane only if eligible and matched, otherwise first match or none. Type/scope transitions SHALL use the single Panes memory slot with latest query/recovery ID. Fresh candidates SHALL reflect moves/deletions under immutable origin without broadening narrow scopes.

#### Scenario: Pane moves outside the original tab
- **WHEN** the selected pane moves to another tab and panes-tab is refreshed
- **THEN** that pane disappears from panes-tab and selection falls back to the first match or none
- **AND** refreshing panes-all can still include the moved pane under its current tab

#### Scenario: Failed refresh and switch round trip
- **WHEN** a pane refresh is loading or failed, the user edits the query and changes scope
- **THEN** the same Panes query/recovery ID is evaluated against fresh destination candidates
- **AND** stale work cannot update another variant or make a placeholder selectable

#### Scenario: Repeated refresh and close
- **WHEN** refresh keys are pressed repeatedly while a pane refresh is pending and the popup is then closed
- **THEN** only one refresh request runs and it is cancelled without waiting for its timeout
- **AND** no pane is focused
