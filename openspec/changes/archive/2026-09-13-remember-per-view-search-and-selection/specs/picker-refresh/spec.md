## MODIFIED Requirements

### Requirement: Refresh work belongs to one active picker

The picker SHALL permit at most one active refresh request. Additional presses of any configured refresh key during loading SHALL be ignored rather than queued. Closing the picker or switching variants SHALL cancel pending refresh work and discard its results, so an old refresh cannot update a destination picker or delay closing until the fetch timeout. Switching during refresh loading or after refresh failure SHALL save the source variant's latest query and pre-refresh highlighted ID as its view memory, rather than saving the non-selectable loading/error state. The destination SHALL restore its own remembered query and selection, or first-visit defaults, against fresh candidates under the original workspace scope, preserving the source's current preview visibility. Returning to the source SHALL restore its memory against fresh candidates rather than resume the cancelled refresh or restore its old loading/error state.

#### Scenario: Repeated refresh key presses
- **WHEN** the user presses one or more configured refresh keys repeatedly while a refresh is pending
- **THEN** only the original refresh runs and no additional refresh is queued

#### Scenario: Close during refresh
- **WHEN** the user closes the picker while refreshing
- **THEN** pending refresh work is cancelled and its resources are released
- **AND** no focus operation occurs and closing does not wait for the fetch timeout

#### Scenario: Switch variants during refresh
- **WHEN** the user invokes a configured variant-switching shortcut while refreshing
- **THEN** the source saves its latest query and pre-refresh highlighted ID, and the destination opens with its own remembered query and selection or first-visit defaults and the original workspace scope
- **AND** both shown and hidden preview states are preserved, including any preview toggle made while refreshing
- **AND** the source refresh is cancelled and cannot modify the destination list or selection

#### Scenario: Switch variants after refresh failure
- **WHEN** the user invokes a configured variant-switching shortcut after a refresh fails or times out
- **THEN** the source saves its latest query and pre-refresh highlighted ID, and the destination opens with its own remembered query and selection or first-visit defaults and the original workspace scope
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
