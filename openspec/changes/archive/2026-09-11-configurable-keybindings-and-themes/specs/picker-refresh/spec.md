## MODIFIED Requirements

### Requirement: Manual refresh is available in every picker

All five picker variants SHALL bind the resolved refresh action keys, defaulting to `Ctrl+L`, to refresh the current variant's complete candidate list from current Herdr data without closing the popup. With `keys.refresh: []`, every variant SHALL have no refresh shortcut or refresh hint, and the default refresh key SHALL NOT be restored. Otherwise, the footer SHALL advertise the resolved refresh bindings. Refresh SHALL retain the variant and original workspace scope and SHALL update membership, displayed metadata, statuses, counts, directories, column alignment, and preview targets together using the launch's resolved theme. Refresh SHALL NOT focus a workspace, tab, or pane or run periodically.

#### Scenario: Refresh each variant
- **WHEN** the user presses any configured refresh key in current-space tabs, all-spaces tabs, spaces, current-space agents, or all-spaces agents
- **THEN** that same variant fetches and displays its current candidates
- **AND** current-space variants remain scoped to the popup's original workspace
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

While a refresh is fetching or preparing refreshed results, the picker SHALL replace the previous candidate list with a visible, non-selectable `Refreshing…` indicator and retain its column header. No configured acceptance key, default fzf acceptance alias, or inherited binding SHALL accept an entry during this state or defer acceptance until after loading. The search query and preview visibility SHALL be preserved; query edits made while loading SHALL remain effective after completion. Configured closing and any enabled preview-toggling and variant-switching shortcuts SHALL remain available. Disabled optional shortcuts SHALL remain disabled and absent from hints throughout loading and completion.

#### Scenario: Slow refresh
- **WHEN** a refresh has started but its results are not ready
- **THEN** the previous rows are not displayed as candidates and `Refreshing…` is visible
- **AND** pressing any configured acceptance key causes no focus operation or deferred acceptance
- **AND** the query remains intact and a hidden preview does not become visible

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

A failed or timed-out refresh SHALL show a non-selectable error state with a retry hint containing the resolved refresh key or keys instead of restoring old candidates. The picker SHALL preserve its query and preview visibility and allow retry and closing through their configured keys, plus any enabled preview-toggling and variant-switching shortcuts. Error-state hints SHALL NOT advertise disabled actions, and failure or retry SHALL NOT restore their default bindings. Acceptance SHALL remain disabled after failure. A successful retry SHALL use the same identity-restoration rules, retaining the pre-refresh highlighted ID as the restoration target until successful completion or variant exit.

#### Scenario: Failed fetch followed by retry
- **WHEN** refreshing fails or times out
- **THEN** the picker displays a clear refresh failure and retry message using its configured refresh keys, with no selectable stale rows
- **AND** no acceptance key focuses an entry
- **AND** pressing any configured refresh key retries and restores the previous ID if it remains a match after success

#### Scenario: Failure with optional controls disabled
- **WHEN** refresh fails in a launch with preview-toggling and variant-switching shortcuts disabled
- **THEN** configured retry and closing remain available
- **AND** disabled preview and variant shortcuts remain absent from bindings and hints after failure and successful retry

### Requirement: Refresh work belongs to one active picker

The picker SHALL permit at most one active refresh request. Additional presses of any configured refresh key during loading SHALL be ignored rather than queued. Closing the picker or switching variants SHALL cancel pending refresh work and discard its results, so an old refresh cannot update a destination picker or delay closing until the fetch timeout.

#### Scenario: Repeated refresh key presses
- **WHEN** the user presses one or more configured refresh keys repeatedly while a refresh is pending
- **THEN** only the original refresh runs and no additional refresh is queued

#### Scenario: Close during refresh
- **WHEN** the user closes the picker while refreshing
- **THEN** pending refresh work is cancelled and its resources are released
- **AND** no focus operation occurs and closing does not wait for the fetch timeout

#### Scenario: Switch variants during refresh
- **WHEN** the user invokes a configured variant-switching shortcut while refreshing
- **THEN** the destination opens with a reset query, the original workspace scope, and the source variant's current preview visibility
- **AND** both shown and hidden states are preserved, including any preview toggle made while refreshing
- **AND** the source refresh is cancelled and cannot modify the destination list or selection

#### Scenario: Switch variants after refresh failure
- **WHEN** the user invokes a configured variant-switching shortcut after a refresh fails or times out
- **THEN** the destination opens with a reset query and the original workspace scope
- **AND** it preserves the source variant's current shown/hidden preview state, including any toggle made in the error state, rather than reapplying the configured launch default
