## MODIFIED Requirements

### Requirement: Manual refresh is available in every picker

Every type at every supported effective scope SHALL use resolved refresh keys, default Ctrl+L, to rebuild its complete list from current Herdr data without closing the popup. Disabled refresh SHALL have no shortcut/hint and its default SHALL not return on transitions. Visible hints SHALL advertise effective keys. Refresh SHALL retain type, chosen/effective scope, immutable workspace/tab origin, query, current preview visibility, and launch settings. It SHALL publish membership, metadata, statuses, counts, directories, alignment, and preview targets together using resolved columns/theme. It SHALL not focus an entity, run periodically, or broaden/rebind scope when origin/candidates are missing.

#### Scenario: Refresh each variant
- **WHEN** refresh is invoked in Spaces, either Tabs scope, or any Panes/Agents scope
- **THEN** the same effective scope is refreshed under immutable origin, retaining chosen scope even during fallback
- **AND** no entity is focused

#### Scenario: Metadata and membership change
- **WHEN** labels, statuses, titles, counts, directories, targets, or candidate membership change
- **THEN** successful refresh publishes those changes consistently in headers, rows, and matching fields

#### Scenario: Empty picker receives new entries
- **WHEN** enabled refresh runs with no entries/matches
- **THEN** new candidates are evaluated against the preserved query
- **AND** disabling refresh instead removes its key/hint across all transitions

#### Scenario: Refresh shortcut disabled
- **WHEN** refresh is disabled
- **THEN** its default key and hints stay absent after type/scope transitions

### Requirement: Loading replaces selectable results

While fetching/preparing refreshed results, Pickr SHALL replace old candidates with a visible non-selectable `Refreshing…` state, retaining column headings and scope state. Configured acceptance, built-in acceptance aliases, and inherited bindings SHALL NOT accept or defer acceptance. Query and preview visibility SHALL remain, including edits/toggles during loading. Configured closing, enabled preview toggling, picker switches, and supported scope switches SHALL remain available. Disabled actions SHALL remain disabled; unsupported scope keys SHALL remain no-ops. Loading completion SHALL not overwrite later query edits.

#### Scenario: Slow refresh
- **WHEN** a refresh is pending and any configured acceptance alias is pressed
- **THEN** no focus or deferred acceptance occurs and stale rows are absent
- **AND** scope/header state and preview visibility remain intact until publication

#### Scenario: Edit query during refresh
- **WHEN** a user edits the query or toggles preview while refreshing
- **THEN** completion uses the latest query/visibility rather than saved older values

#### Scenario: Multiple acceptance aliases
- **WHEN** acceptance has multiple aliases during refresh
- **THEN** all are gated until successful publication, without deferred acceptance

### Requirement: Refresh failure is retryable without stale candidates

A failed/timed-out refresh SHALL show a non-selectable failure and retry hint using effective enabled refresh keys, without restoring stale rows or erasing scope state. Query, chosen/effective scope, origin, and current preview visibility SHALL remain. Closing, retry, enabled preview/type actions, and supported scope actions SHALL remain usable without reviving disabled defaults. Acceptance SHALL stay disabled. Successful retry SHALL restore the pre-refresh identity if matched, otherwise first match or none, retaining recovery identity until successful completion or transition.

#### Scenario: Failed fetch followed by retry
- **WHEN** refresh fails then a configured retry succeeds
- **THEN** failure presents no selectable stale candidates, retains scope/query/preview, and successful retry restores identity against fresh matches

#### Scenario: Failure with optional controls disabled
- **WHEN** failure occurs with preview/type/scope shortcuts disabled
- **THEN** retry and close remain usable, disabled hints/default bindings remain absent, and scope labels remain visible

### Requirement: Refresh work belongs to one active picker

At most one refresh SHALL be active; further refresh presses during loading SHALL be ignored. Closing or a type/effective-scope transition SHALL cancel source work and discard late results without waiting for the timeout. Transitions during loading/error SHALL save latest query and pre-refresh recovery ID in source type memory, not loading placeholders. Type changes SHALL restore destination type memory or first-visit defaults; scope changes SHALL carry source query/recovery identity into the new scope. Destinations SHALL fetch fresh candidates under immutable origin and current chosen/effective scope, preserving preview visibility. Returning SHALL not resume old refresh/error state. Successful ready fallback/no-match results SHALL supersede older recovery IDs for subsequent memory capture.

#### Scenario: Repeated refresh key presses
- **WHEN** refresh is pressed repeatedly while pending and then the popup closes
- **THEN** only one request runs and is cancelled promptly without focusing any entity

#### Scenario: Close during refresh
- **WHEN** the popup closes during pending refresh
- **THEN** source resources are cancelled promptly without focus or waiting for timeout

#### Scenario: Switch variants during refresh
- **WHEN** a picker shortcut is invoked during refresh
- **THEN** source latest query/recovery ID are saved, destination type memory is restored under the carried scope, and source work is cancelled
- **AND** current preview visibility persists

#### Scenario: Change scope during refresh
- **WHEN** Panes refresh is pending and the user broadens scope
- **THEN** source work is cancelled, the latest query and recovery pane ID are used against fresh broader candidates, and late source results cannot replace them

#### Scenario: Switch variants after refresh failure
- **WHEN** a user edits a failed refresh query, switches type, and later returns
- **THEN** destination and source each restore their own type memory against fresh candidates under the carried scope
- **AND** both preserve the shared preview state without reviving stale placeholders

#### Scenario: Successful retry replaces recovery selection with current selection
- **WHEN** retry succeeds and the user selects another result or reaches a ready zero-match state before transitioning
- **THEN** the next transition saves that new selection or none rather than an older pre-refresh ID

#### Scenario: Edit during refresh and return after switching away
- **WHEN** a loading/error query is edited before leaving and returning to its type
- **THEN** fresh candidates restore the edited query and eligible recovery ID or fallback, never stale placeholders

### Requirement: Pane refresh shares identity recovery and cancellation semantics

Panes at every scope SHALL share the query/preview-preserving, non-selectable loading/error, retry, identity-restoration, and cancellation behavior. Successful refresh SHALL preserve workspace/tab/layout ordering and select the same pane only if eligible and matched, otherwise first match or none. Type/scope transitions SHALL use the single Panes memory slot with latest query/recovery ID. Fresh candidates SHALL reflect moves/deletions under immutable origin without broadening narrow scopes.

#### Scenario: Pane moves outside the original tab
- **WHEN** the selected pane moves to another tab and This tab refreshes
- **THEN** that pane disappears and selection falls back, while a later All spaces refresh can include it at its current location

#### Scenario: Failed refresh and switch round trip
- **WHEN** a pane refresh fails and the user changes scope
- **THEN** the same Panes query/recovery ID is evaluated against fresh destination candidates and stale source work cannot update them

#### Scenario: Repeated refresh and close
- **WHEN** refresh is repeatedly invoked during a pending pane refresh and the popup closes
- **THEN** only one request runs and is cancelled without waiting or focusing a pane
