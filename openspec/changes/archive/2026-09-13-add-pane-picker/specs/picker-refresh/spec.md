## MODIFIED Requirements

### Requirement: Manual refresh is available in every picker

All eight picker variants SHALL bind the resolved refresh action keys, defaulting to `Ctrl+L`, to refresh the current variant's complete candidate list from current Herdr data without closing the popup. With `keys.refresh: []`, every variant SHALL have no refresh shortcut or refresh hint, and the default refresh key SHALL NOT be restored. Otherwise, the footer SHALL advertise the resolved refresh bindings when hints are shown. Refresh SHALL retain the variant and original workspace scope, plus the original tab for panes-tab, and SHALL update membership, displayed metadata, statuses, counts, directories, column alignment, and preview targets together using the launch's resolved theme. Refresh SHALL NOT focus a workspace, tab, or pane or run periodically.

#### Scenario: Refresh each variant
- **WHEN** the user presses any configured refresh key in current-space tabs, all-spaces tabs, spaces, current-space agents, all-spaces agents, current-tab panes, current-space panes, or all-spaces panes
- **THEN** that same variant fetches and displays its current candidates
- **AND** current-space variants remain scoped to the popup's original workspace and panes-tab to its original tab
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

## ADDED Requirements

### Requirement: Pane refresh shares identity recovery and cancellation semantics

All three pane variants SHALL use the existing query/preview-preserving, non-selectable loading/error, retry, identity-restoration, and cancellation behavior. Successful refresh SHALL preserve the pane view's workspace/tab/layout order and restore the selected pane ID only if still eligible and matched, otherwise the first match or no selection. Switching during refresh or failure SHALL save the latest query and recovery pane ID in that pane variant's independent memory, cancel pending work, and restore the destination's own memory or first-visit defaults. Returning SHALL fetch fresh candidates under the original scope without reviving the old loading/error state.

#### Scenario: Pane moves outside the original tab
- **WHEN** the selected pane moves to another tab and panes-tab is refreshed
- **THEN** that pane disappears from panes-tab and selection falls back to the first match or none
- **AND** refreshing panes-all can still include the moved pane under its current tab

#### Scenario: Failed refresh and switch round trip
- **WHEN** a pane refresh is loading or failed, the user edits the query, switches away, and returns
- **THEN** its edited query and recovery pane ID are restored against fresh eligible candidates
- **AND** stale work cannot update another variant or make a placeholder selectable

#### Scenario: Repeated refresh and close
- **WHEN** refresh keys are pressed repeatedly while a pane refresh is pending and the popup is then closed
- **THEN** only one refresh request runs and it is cancelled without waiting for its timeout
- **AND** no pane is focused
