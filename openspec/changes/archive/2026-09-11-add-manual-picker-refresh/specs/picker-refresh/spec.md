## Purpose

Let users refresh open pickers on demand to see current statuses and metadata while retaining their search, preview visibility, and selection context.

## ADDED Requirements

### Requirement: Manual refresh is available in every picker

All five picker variants SHALL bind `Ctrl+L` to refresh the current variant's complete candidate list from current Herdr data without closing the popup. The footer SHALL advertise the refresh binding. Refresh SHALL retain the variant and original workspace scope and SHALL update membership, displayed metadata, column alignment, and preview targets together. Refresh SHALL NOT focus a workspace, tab, or pane or run periodically.

#### Scenario: Refresh each variant
- **WHEN** the user presses `Ctrl+L` in current-space tabs, all-spaces tabs, spaces, current-space agents, or all-spaces agents
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

### Requirement: Loading replaces selectable results

While a refresh is fetching or preparing refreshed results, the picker SHALL replace the previous candidate list with a visible, non-selectable `Refreshing…` indicator and retain its column header. Enter SHALL NOT accept an entry during this state or be deferred into an acceptance after loading. The search query and preview visibility SHALL be preserved; query edits made while loading SHALL remain effective after completion. Closing, preview toggling, and variant-switching shortcuts SHALL remain available.

#### Scenario: Slow refresh
- **WHEN** a refresh has started but its results are not ready
- **THEN** the previous rows are not displayed as candidates and `Refreshing…` is visible
- **AND** pressing Enter causes no focus operation or deferred acceptance
- **AND** the query remains intact and a hidden preview does not become visible

#### Scenario: Edit query during refresh
- **WHEN** the user edits the search query while refreshing
- **THEN** the refreshed results are filtered using the edited query
- **AND** completion does not restore an older query or undo a preview visibility toggle

### Requirement: Refresh restores entity identity and existing ordering

On successful refresh, the picker SHALL apply its existing ordering and filtering rules and restore the highlight to the same pane, tab, or workspace ID if it is still a matching candidate, regardless of changed row text or position. Agent ordering SHALL remain blocked, done, working, idle, unknown, then descending state-change sequence with original API layout order for exact ties. Other variants SHALL retain their existing ordering rules. If the previous ID is absent or does not match the current query, the picker SHALL highlight the first matching result, or no entry when there are no matches. Acceptance and preview SHALL target the refreshed entry's underlying IDs.

#### Scenario: Highlighted agent changes status and position
- **WHEN** the highlighted agent changes from working to blocked and the list is refreshed
- **THEN** the agent moves according to the existing priority rules
- **AND** the highlight follows its pane ID rather than remaining at the old row position
- **AND** Enter after completion focuses that same pane

#### Scenario: Highlighted entity disappears or stops matching
- **WHEN** the highlighted entity is removed or its updated metadata no longer matches the current query
- **THEN** the first matching refreshed entry is highlighted
- **AND** no entry is highlighted if there are no matches

#### Scenario: Updated preview target
- **WHEN** a highlighted tab or workspace retains its ID but its preview pane changes in the refreshed data
- **THEN** the highlight remains on that tab or workspace
- **AND** its preview uses the updated pane ID without changing preview visibility

### Requirement: Refresh failure is retryable without stale candidates

A failed or timed-out refresh SHALL show a non-selectable error state with a `Ctrl+L` retry hint instead of restoring old candidates. The picker SHALL preserve its query and preview visibility and allow retry, closing, and variant switching. A successful retry SHALL use the same identity-restoration rules, retaining the pre-refresh highlighted ID as the restoration target until successful completion or variant exit.

#### Scenario: Failed fetch followed by retry
- **WHEN** refreshing fails or times out
- **THEN** the picker displays `Refresh failed — Ctrl+L to retry` or an equivalent clear retry message and no selectable stale rows
- **AND** Enter does not focus an entry
- **AND** pressing `Ctrl+L` retries and restores the previous ID if it remains a match after success

### Requirement: Refresh work belongs to one active picker

The picker SHALL permit at most one active refresh request. Additional `Ctrl+L` presses during loading SHALL be ignored rather than queued. Closing the picker or switching variants SHALL cancel pending refresh work and discard its results, so an old refresh cannot update a destination picker or delay closing until the fetch timeout.

#### Scenario: Repeated refresh key presses
- **WHEN** the user presses `Ctrl+L` repeatedly while a refresh is pending
- **THEN** only the original refresh runs and no additional refresh is queued

#### Scenario: Close during refresh
- **WHEN** the user closes the picker while refreshing
- **THEN** pending refresh work is cancelled and its resources are released
- **AND** no focus operation occurs and closing does not wait for the fetch timeout

#### Scenario: Switch variants during refresh
- **WHEN** the user invokes an existing variant-switching shortcut while refreshing
- **THEN** the destination opens using the existing switching behavior, including a reset query and initially visible preview
- **AND** the source refresh is cancelled and cannot modify the destination list or selection
