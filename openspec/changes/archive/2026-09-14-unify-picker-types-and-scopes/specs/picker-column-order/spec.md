## MODIFIED Requirements

### Requirement: Picker columns follow a shared relative order

Default columns SHALL be Spaces: `status`, `space`, `tabs`, `directory`; Tabs: `status`, `space`, `tab`, `panes`, `directory`; Panes: `status`, `space`, `tab`, `title`, `pane`, `directory`; Agents: `status`, `space`, `tab`, `agent`, `title`, `pane`. These lists SHALL be constant across each type's scopes. Count headings `tabs` and `panes` SHALL retain their values in tab/pane positions. A configured type list SHALL replace its entire default in exactly the configured order; headers and values SHALL agree, retaining the `pane [label]` heading. Empty lists SHALL retain fixed non-selectable column headings. Existing visible-column matching, attached annotations, status glyph/text grouping, hidden-ID targeting, candidate ordering, and preview semantics SHALL be preserved.

#### Scenario: Spaces picker
- **WHEN** Spaces opens with defaults
- **THEN** its columns are status, space, tabs, directory

#### Scenario: Current-space tabs picker
- **WHEN** Tabs opens in This space with defaults
- **THEN** its columns are status, space, tab, panes, directory

#### Scenario: All-spaces tabs picker
- **WHEN** Tabs opens in All spaces with defaults
- **THEN** its columns are status, space, tab, panes, directory with space before tab

#### Scenario: Current-space agents picker
- **WHEN** Agents opens in This space with defaults
- **THEN** its columns are status, space, tab, agent, title, pane

#### Scenario: All-spaces agents picker
- **WHEN** Agents opens in All spaces with defaults
- **THEN** its columns are status, space, tab, agent, title, pane

#### Scenario: Empty picker
- **WHEN** any type has no candidates
- **THEN** its fixed non-selectable header retains the effective configured columns

#### Scenario: Pane picker defaults
- **WHEN** Panes opens in any supported scope with defaults
- **THEN** its columns are status, space, tab, title, pane, directory with the pane [label] heading

#### Scenario: Stable defaults in every scope
- **WHEN** Tabs, Panes, or Agents narrows scope with default columns
- **THEN** its complete default list above remains visible and searchable, including space/tab context where present
- **AND** Spaces retains its specified default list

#### Scenario: Ordered subset
- **WHEN** `columns.tabs` is `["tab", "directory", "space"]`
- **THEN** both tab scopes show exactly those columns and matching fields without spacing reserved for omitted columns

#### Scenario: Single visible column
- **WHEN** `columns.agents` is `["title"]` and the active agent scope is empty
- **THEN** only the title heading is shown with no status prefix or extra column separators
- **AND** later candidates still preview and focus their underlying pane IDs

#### Scenario: Narrowing preserves context matching
- **WHEN** a query matches a visible space name and the user narrows Panes from All spaces to This tab within that space
- **THEN** remaining eligible panes still match the space term rather than losing it through automatic column hiding
