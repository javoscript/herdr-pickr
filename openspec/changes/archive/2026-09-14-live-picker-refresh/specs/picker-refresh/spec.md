## RENAMED Requirements

- FROM: `### Requirement: Loading replaces selectable results`
- TO: `### Requirement: Background refresh retains usable displayed results`
- FROM: `### Requirement: Refresh failure is retryable without stale candidates`
- TO: `### Requirement: Refresh failure retains usable results and supports retry`

## MODIFIED Requirements

### Requirement: Manual refresh is available in every picker

Every type at every supported effective scope SHALL use resolved refresh keys, default Ctrl+L, to rebuild its complete list from current Herdr data in the background without closing the popup. Disabled refresh shortcuts SHALL have no shortcut/hint and their defaults SHALL not return on transitions; disabling shortcuts SHALL NOT disable separately configured automatic refresh. Visible hints SHALL advertise effective keys. Manual and automatic refresh SHALL share publication, identity, failure, and cancellation behavior. Refresh SHALL retain type, chosen/effective scope, immutable workspace/tab origin, latest query, current preview visibility, and launch settings. It SHALL publish membership, metadata, status text and indicators, titles, labels, counts, directories, alignment, and preview targets together using resolved columns/theme. It SHALL NOT focus an entity or broaden/rebind scope when origin/candidates are missing.

#### Scenario: Refresh each variant
- **WHEN** refresh is invoked in Spaces, either Tabs scope, or any Panes/Agents scope
- **THEN** the same effective scope is refreshed under immutable origin, retaining chosen scope even during fallback
- **AND** no underlying workspace, tab, or pane is focused by refreshing

#### Scenario: Metadata and membership change
- **WHEN** statuses, labels, titles, counts, directories, preview targets, or candidate membership change before a successful refresh
- **THEN** the refreshed list reflects the current values, newly eligible entries, and removals for its scope
- **AND** column headers, formatting, and per-column search behavior remain consistent with the refreshed rows

#### Scenario: Empty picker receives new entries
- **WHEN** a picker with no entries or no search matches is refreshed
- **THEN** refresh remains available and rebuilds the list
- **AND** newly available candidates are evaluated against the preserved latest query

#### Scenario: Refresh shortcut disabled
- **WHEN** `keys.refresh` is `[]`
- **THEN** Ctrl+L does not trigger Pickr refresh and no refresh key hint appears
- **AND** switching variants does not restore a refresh shortcut, while a configured automatic interval still operates

### Requirement: Background refresh retains usable displayed results

Refreshing an already displayed view SHALL retain its last-published candidates, column headings, scope state, and current preview while fetching and preparing updates; it SHALL NOT replace them with loading placeholders. Configured acceptance, query editing, navigation, closing, enabled preview toggling, picker switches, and supported scope switches SHALL remain usable during that work and after recoverable failure. Final replacement SHALL use native fzf identity tracking and input behavior: input during replacement/tracking can be ignored and buffering is not guaranteed. Pickr SHALL NOT extend that native suspension to Herdr fetches, candidate preparation, or preview reads. One finite publication deadline SHALL bound stalled replacement/control work and SHALL NOT restart on partial progress. Disabled actions SHALL remain disabled and unsupported scope keys SHALL remain no-ops. Progress SHALL be non-selectable and confined to the existing status area. Completion SHALL NOT restore refresh-start query or selection. These semantics SHALL apply equally to manual and automatic refresh; entry restoration SHALL retain its separate readiness contract.

#### Scenario: Slow refresh
- **WHEN** either trigger starts a refresh whose results are not ready
- **THEN** the previous candidates remain visible and usable with their headings and scope state
- **AND** a hidden preview does not become visible and the list is not replaced by `Refreshing…`
- **AND** acceptance, typing, navigation, and enabled controls do not wait for fetching or candidate preparation

#### Scenario: Edit query during refresh
- **WHEN** the user edits the query and highlights another entity while refreshing
- **THEN** refreshed results are filtered using the latest query and restore the entity highlighted immediately before replacement if still matched
- **AND** completion does not restore the refresh-start query or selection or undo a preview visibility toggle

#### Scenario: Multiple acceptance aliases
- **WHEN** acceptance has two configured keys and a refresh is fetching or preparing candidates
- **THEN** either key accepts the entity highlighted in the displayed list and cancels pending work
- **AND** neither key waits for fetch/preparation or accepts a different pending result

#### Scenario: Native input behavior at publication boundary
- **WHEN** acceptance, typing, navigation, or other controls race with final result replacement
- **THEN** native fzf tracking/input semantics apply, including potentially ignored input while tracking is locked
- **AND** Pickr does not promise buffered replay or an atomic physical-keystroke selection guarantee beyond fzf's native behavior
- **AND** a returned selection is validated against registered candidate data and focuses only that returned entity, with exact-target failure if it has closed

#### Scenario: Interaction after publication
- **WHEN** replacement finishes and the user edits the query or navigates
- **THEN** normal interaction resumes without an owner-side restoration forcing an older query or selection
- **AND** repeated refresh triggers during busy publication still follow the skip-without-catch-up rule

#### Scenario: Publication deadline expires
- **WHEN** final publication cannot finish within its finite end-to-end deadline, including a stalled replacement or acknowledgement
- **THEN** Pickr reports a publication/control failure and terminates the session without an indefinite input wait
- **AND** partial progress does not restart the deadline
- **AND** it cancels owned work and performs no unconfirmed focus operation after shutdown

### Requirement: Refresh restores entity identity and existing ordering

On successful refresh, the picker SHALL apply its existing ordering and filtering rules and use native fzf identity tracking to follow the pane, tab, or workspace ID current when replacement is requested if still matched, regardless of changed row text or position. Agent ordering SHALL remain blocked, done, working, idle, unknown, then descending state-change sequence with original API layout order for exact ties. Other variants SHALL retain their existing ordering rules. Missing or filtered identities SHALL use native fzf fallback, with no selection for zero matches. Pickr SHALL NOT apply a later refresh-start position over subsequent navigation. Acceptance SHALL validate fzf's returned underlying entity ID; preview SHALL use the selected entry's pane target. The new selection, including fallback or absence, SHALL supersede earlier recovery identities for subsequent refreshes and transitions.

#### Scenario: Highlighted agent changes status and position
- **WHEN** the highlighted agent changes from working to blocked and either kind of refresh succeeds
- **THEN** its status text and indicator update and it moves according to the existing priority rules
- **AND** the highlight follows its pane ID and acceptance focuses that same pane

#### Scenario: Highlighted entity disappears or stops matching
- **WHEN** the highlighted entity is removed or its updated metadata no longer matches the latest query
- **THEN** native fzf fallback selects a matching refreshed entry, or none if there are no matches
- **AND** later refreshes or transitions use this current selection rather than resurrecting the removed selection

#### Scenario: Updated preview target
- **WHEN** a highlighted tab or workspace retains its ID but its preview pane changes in the refreshed data
- **THEN** the highlight remains on that tab or workspace
- **AND** its visible preview uses the updated pane ID without changing preview visibility

#### Scenario: Navigate after publication
- **WHEN** the user navigates after refreshed selection restoration completes
- **THEN** later matching or preview completion does not force the restoration target back

### Requirement: Refresh failure retains usable results and supports retry

A failed or timed-out background fetch or candidate preparation SHALL retain the complete last-successfully-published list and its acceptance eligibility, including an empty list. Pickr SHALL display a compact non-selectable refresh failure in the existing status area, with retry keys only when configured; it SHALL NOT imply retained data is fresh. Latest query, current highlighted identity, chosen/effective scope, origin, launch settings, and preview visibility SHALL remain. Closing, navigation, acceptance of matching displayed entries, manual retry, enabled preview/type actions, and supported scope actions SHALL remain usable without reviving disabled defaults. Automatic scheduling when enabled SHALL continue after recoverable failure. Successful retry SHALL publish against the then-current query/selection and clear the error. Preview read failures SHALL remain preview-local and SHALL NOT invalidate a successful candidate publication. Terminal/control failures that make displayed-generation consistency unknowable SHALL remain session failures rather than falsely claiming a recoverable data error.

#### Scenario: Failed fetch followed by retry
- **WHEN** refreshing fails or times out
- **THEN** the last published rows remain visible and selectable and the status area reports refresh failure with effective retry keys
- **AND** a manual retry can succeed using the query and highlighted ID current at publication, clearing the error

#### Scenario: Failure with optional controls disabled
- **WHEN** refresh fails with preview/type/scope or refresh shortcuts disabled
- **THEN** disabled shortcuts remain absent from bindings and hints and scope labels stay visible
- **AND** enabled acceptance/closing and any enabled manual or automatic retry remain usable

#### Scenario: Automatic failure recovery
- **WHEN** an automatic refresh fails and a later scheduled attempt succeeds
- **THEN** the retained list stays usable between attempts and success replaces it with current results and clears the failure message

#### Scenario: Failed empty-list refresh
- **WHEN** the last published list is empty and refresh fails
- **THEN** it remains empty and switchable with the latest query preserved
- **AND** retry can publish new entries without requiring reopening

### Requirement: Refresh work belongs to one active picker

At most one candidate refresh SHALL be active per popup, including preparation and publication; further manual or automatic triggers while busy SHALL be ignored without queued catch-up work. Closing, acceptance, or a type/effective-scope transition, when processed under native fzf input semantics, SHALL cancel source work and scheduling promptly without waiting for the fetch timeout. Late results SHALL be discarded. Transitions during refresh or recoverable failure SHALL save the latest query and displayed selection, not refresh-start recovery state. Type changes SHALL restore destination memory or first-visit defaults; scope changes SHALL carry source query/current identity. Destinations SHALL fetch fresh candidates under immutable origin and carried scope, preserving preview visibility and launch settings. Returning SHALL NOT resume old refresh/error state. Pending entry restoration SHALL retain its separate readiness and identity semantics.

#### Scenario: Repeated refresh key presses
- **WHEN** refresh keys and timer ticks occur repeatedly while a refresh is pending
- **THEN** only the original refresh runs and no additional refresh is queued

#### Scenario: Close during refresh
- **WHEN** the user closes or accepts the displayed selection while refreshing
- **THEN** pending refresh work and scheduling resources are cancelled without waiting for the fetch timeout
- **AND** closing performs no focus operation, while acceptance focuses only its confirmed displayed target

#### Scenario: Switch variants during refresh
- **WHEN** the user changes selection or query while refreshing and then switches types
- **THEN** the source saves the latest displayed query and selection and the destination restores its own memory or first-visit defaults
- **AND** both shown and hidden preview states are preserved, including toggles during refresh
- **AND** the source refresh is cancelled and cannot modify the destination

#### Scenario: Switch variants after refresh failure
- **WHEN** the user navigates after a refresh failure and switches away and back
- **THEN** the source's latest query and displayed identity are restored against fresh candidates
- **AND** no obsolete error, timer, or refresh-start selection is resumed

#### Scenario: Edit during refresh and return after switching away
- **WHEN** the user edits the query during a pending refresh or recoverable refresh failure, changes selection, switches away, and later returns
- **THEN** the source fetches fresh candidates and restores the edited query and identity highlighted at switch time if it still matches, otherwise first match or none
- **AND** cancelled refresh work cannot overwrite that restored view or revive the refresh-start selection

#### Scenario: Successful retry replaces recovery selection with current selection
- **WHEN** retry succeeds and the user later switches away and returns
- **THEN** memory uses the query and highlighted entity at switch time, including no selection for zero matches
- **AND** older refresh-start or pre-failure identities do not override it

#### Scenario: Change scope during refresh
- **WHEN** Panes refresh is pending and the user broadens scope
- **THEN** source work is cancelled and latest query/current displayed pane ID are used against fresh broader candidates
- **AND** late source results cannot replace the destination list

### Requirement: Pane refresh shares identity recovery and cancellation semantics

Panes at every scope SHALL share query/preview-preserving background refresh, usable retained results during fetch/failure, manual/automatic retry, native identity tracking/fallback and input behavior during publication, and cancellation. Successful refresh SHALL preserve workspace/tab/layout ordering and track the same pane if eligible and matched, otherwise use native fallback or no selection. Type/scope transitions SHALL use the single Panes memory slot with latest query/current displayed ID. Fresh candidates SHALL reflect additions, moves, metadata changes, and deletions under immutable origin without broadening narrow scopes.

#### Scenario: Pane moves outside the original tab
- **WHEN** the selected pane moves to another tab and panes-tab is refreshed manually or automatically
- **THEN** it disappears from panes-tab and native fzf fallback selects a match or none
- **AND** refreshing panes-all can still include it under its current tab

#### Scenario: Failed refresh and switch round trip
- **WHEN** pane refresh is pending or failed and the user edits the query, navigates, and changes scope
- **THEN** the same Panes latest query/current identity is evaluated against fresh destination candidates
- **AND** stale work cannot update another variant or become selectable

#### Scenario: Repeated refresh and close
- **WHEN** refresh keys and ticks recur while pane refresh is pending and the popup closes
- **THEN** only one refresh request runs and it is cancelled without waiting for the fetch timeout, with any final-publication input wait bounded by the publication deadline
- **AND** no pane is focused

## ADDED Requirements

### Requirement: Automatic refresh follows the configured session interval

A positive resolved `refresh.interval_ms` SHALL schedule recurrent background refresh for the active type/effective scope in every launch path. Zero SHALL disable periodic work without disabling manual refresh. The first scheduled attempt SHALL occur after one interval following view readiness, not during initial entry restoration. Ticks while busy SHALL be skipped without catch-up bursts; the interval SHALL describe attempt cadence rather than guarantee exact publication timing. Empty lists, zero matches, hidden previews, and disabled manual refresh shortcuts SHALL NOT suspend list scheduling. Type/effective-scope transitions SHALL start a fresh cadence after destination readiness. Each popup SHALL own independent scheduling, fixed to its launch settings.

#### Scenario: Default session stays manual
- **WHEN** the resolved interval is zero and no manual refresh is requested
- **THEN** the open view performs no periodic candidate or preview refresh work

#### Scenario: All views update without keypresses
- **WHEN** a positive interval is configured in any supported type/scope and the view becomes ready
- **THEN** repeated scheduled attempts update full candidate membership and fields without user input
- **AND** changes to configuration while open do not alter that session's cadence

#### Scenario: Hidden or empty picker continues updating
- **WHEN** previews are hidden, results are empty, or the query matches no entries
- **THEN** list refresh attempts continue at the configured cadence and can introduce newly matching entries
- **AND** no terminal-screen reads are requested for a hidden preview or absent selection

### Requirement: Successful refresh renews the selected visible preview

Every successful manual or automatic candidate refresh SHALL request fresh visible-screen content for the then-selected preview target even when row text and target ID did not change. Tabs SHALL use the refreshed layout's remembered focused pane; Spaces SHALL use the refreshed active tab's remembered focused pane; Panes and Agents SHALL use their exact selected pane. Missing targets SHALL show the existing no-pane message. Hidden previews or absent matching selections SHALL perform no preview reads; showing a preview or changing selection SHALL request current content without waiting for the next interval. Preview work SHALL NOT focus any entity. Automatic requests SHALL NOT accumulate overlapping captures or repeatedly cancel an unfinished same-target capture so it never completes. Selection/target changes, hiding, transitions, and close SHALL prevent obsolete captures from appearing. Closed/unreadable panes SHALL show the existing unavailable message, with later requests able to recover. Refreshed content SHALL preserve terminal colors and use native fzf preview scroll behavior, including returning to the top when the same target is refreshed; Pickr SHALL NOT promise scroll-offset preservation or add custom scroll tracking.

#### Scenario: Terminal output changes without row changes
- **WHEN** the selected pane produces new output while all candidate fields remain unchanged and refresh succeeds
- **THEN** the visible preview updates its terminal snapshot without requiring navigation

#### Scenario: Tab or space focus target changes
- **WHEN** refresh observes a new remembered focused pane or a space's new active tab
- **THEN** that selected tab/space previews its new resolved pane while retaining entity selection

#### Scenario: Slow capture outlasts the interval
- **WHEN** capture for the current target takes longer than the configured interval
- **THEN** periodic requests do not queue captures or continually restart the unfinished capture
- **AND** a completed current capture can appear, while navigation to a different target discards obsolete output

#### Scenario: Hide and show a preview
- **WHEN** the preview is hidden while refreshes continue and then shown
- **THEN** hidden refreshes perform no screen reads and showing requests fresh content for the current selection

#### Scenario: Preview read fails and recovers
- **WHEN** a selected pane cannot be read after candidate publication and later becomes readable
- **THEN** its preview reports unavailable without discarding the published rows or disabling acceptance
- **AND** a later preview request can replace that message with fresh content

#### Scenario: Scroll within a recurrent preview
- **WHEN** the user scrolls a selected preview and same-target refreshes succeed
- **THEN** native fzf refresh can return the preview to the top, with scrolling and short-content bounds handled by fzf
- **AND** Pickr documents that the prior scroll offset is not preserved
