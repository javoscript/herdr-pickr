## MODIFIED Requirements

### Requirement: Three pane scopes are directly launchable

Pickr SHALL expose `panes`, `panes-all`, `panes-space`, and `panes-tab` actions and matching pane entrypoints under `javoscript.herdr-pickr`. They SHALL open the single Panes type with All spaces, All spaces, This space, and This tab chosen respectively. `panes-current` SHALL be removed. Panes SHALL use the shared picker/scope controls rather than a separate internal shortcut per preset. All spaces SHALL list eligible panes across spaces; This space across all tabs of the original space; This tab only in the original tab and space. Launching or transitioning SHALL not focus an underlying terminal.

#### Scenario: Direct and internal navigation
- **WHEN** any supported pane preset opens
- **THEN** it initializes the stated scope with Panes' shared columns/prompt and first-visit memory
- **AND** type/scope shortcuts are available according to configuration

#### Scenario: Tab scope
- **WHEN** panes-tab opens from a tab with three eligible splits and other tabs contain panes
- **THEN** only the originating tab's eligible splits appear

#### Scenario: Space scope
- **WHEN** panes-space opens from a space with multiple tabs
- **THEN** eligible panes across those tabs appear and other spaces' panes do not

#### Scenario: Global scope
- **WHEN** panes or panes-all opens
- **THEN** eligible panes across all spaces/tabs appear, including inactive spaces

#### Scenario: Space rename
- **WHEN** a user migrates a pane launch binding from `panes-current` to `panes-space`
- **THEN** it retains originating-space membership through the new public name without a legacy alias

### Requirement: Pane rows expose searchable terminal context

Panes SHALL use the pane's own status, title, pane ID with optional label, and directory, plus space/tab context available at every scope. The configured per-type list SHALL determine visible/searchable columns without scope-based hiding. Title SHALL prefer nonempty stripped terminal title, terminal title, then title, otherwise `-`. Directory SHALL prefer nonempty foreground cwd then cwd with existing home abbreviation, truncation, and missing-value behavior. Nonempty labels SHALL render as `pane-id [label]` under `pane [label]`; empty labels SHALL add no brackets. Pane-label/worktree annotations SHALL retain annotation styling, status SHALL retain existing glyph/text/color mappings and unknown fallback, and metadata SHALL retain single-row control-character cleaning. Only visible columns/annotations SHALL match queries; hidden targeting IDs SHALL not contribute matches.

#### Scenario: Labeled shell without an agent
- **WHEN** a shell has a pane label but no stripped title or foreground cwd
- **THEN** it uses terminal title or title, then `-` if unavailable, and cwd, with its label searchable when pane is visible
- **AND** no agent is required for eligibility and status uses the existing unknown fallback when absent

#### Scenario: Metadata fallback
- **WHEN** stripped title and foreground cwd are empty/missing
- **THEN** terminal title/title and cwd supply fallback values, missing title becomes `-`, and empty labels add no brackets

#### Scenario: Stable narrow context
- **WHEN** Panes uses This tab and includes space/tab columns
- **THEN** those columns render the containing identities and remain searchable

#### Scenario: Reordered or hidden columns
- **WHEN** `columns.panes` is `["directory", "pane"]`
- **THEN** every pane scope uses that order, ignores hidden title/status/space/tab data during search, and targets the correct pane ID
