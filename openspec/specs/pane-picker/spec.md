# pane-picker Specification

## Purpose

Let users find, preview, and focus ordinary terminal panes within the originating tab, originating space, or all spaces without first navigating their containing tabs.

## Requirements

### Requirement: Three pane scopes are directly launchable

Pickr SHALL expose actions and pane entrypoints `panes-tab`, `panes-current`, and `panes-all` under plugin ID `javoscript.herdr-pickr`, titled Panes in this tab, Panes in this space, and Panes in all spaces respectively. Each SHALL open the corresponding picker and SHALL be reachable through its configured in-popup variant shortcut. `panes-tab` SHALL include only panes in the original tab and workspace; `panes-current` SHALL include panes across tabs in the original workspace; `panes-all` SHALL include eligible panes across all workspaces. The five existing actions SHALL retain their names and scopes.

#### Scenario: Tab scope
- **WHEN** panes-tab opens from a tab with three split panes while other tabs also contain panes
- **THEN** only eligible panes in the originating tab appear

#### Scenario: Space scope
- **WHEN** panes-current opens from a workspace containing multiple tabs
- **THEN** eligible panes from every tab in that workspace appear and panes in other workspaces do not

#### Scenario: Global scope
- **WHEN** panes-all opens
- **THEN** eligible panes from every workspace and tab appear, including inactive workspaces

#### Scenario: Direct and internal navigation
- **WHEN** a pane action is launched directly or its configured shortcut is invoked from another Pickr view
- **THEN** the requested pane scope opens with its resolved settings
- **AND** opening or switching the view does not focus an underlying terminal

### Requirement: Narrow pane scopes retain launch origin

Every popup SHALL capture its originating workspace and available tab once, including popups initially opened in non-pane views. Applicable launch context SHALL take precedence over later focus changes. Switching, refresh, and retry SHALL NOT change these origin identities or use the highlighted tab/space as a new origin. If an origin tab or workspace no longer exists, its narrow view SHALL have no candidates rather than broaden or retarget. If no originating tab can be resolved at launch, the tab-scoped pane view SHALL remain empty and switchable; missing tab context SHALL NOT prevent other valid views from opening.

#### Scenario: Switch from an existing view
- **WHEN** Pickr opens in tabs-all from tab A, the user highlights tab B, and switches to panes-tab
- **THEN** panes-tab remains scoped to tab A
- **AND** its scope is not tab B or a tab activated by another client

#### Scenario: Launch context changes before owner startup
- **WHEN** the active tab changes after the action launcher captures tab A but before the popup owner starts
- **THEN** panes-tab still uses captured tab A on first entry and subsequent refreshes

#### Scenario: Origin disappears
- **WHEN** the original tab or space is removed before its narrow view is refreshed or revisited
- **THEN** the refreshed or revisited narrow view has no candidates
- **AND** switching to broader views remains available

#### Scenario: Missing tab context
- **WHEN** a launch has a valid workspace but no tab can be resolved there
- **THEN** panes-tab has no candidates and retains normal close and variant shortcuts
- **AND** the existing views and broader pane scopes remain usable

### Requirement: Pane membership and order follow tab layouts

Pane views SHALL list each eligible pane ID once, including ordinary shells, editors, agent panes, and plugin terminals embedded in normal tab layouts. An eligible pane SHALL have matching pane metadata and membership in a known workspace/tab's full layout. Transient popup overlays, including Pickr's popup, and orphan metadata SHALL NOT appear. The originating focused terminal SHALL remain eligible. Ordering SHALL follow existing workspace/worktree grouping, tab order within each workspace, and pane order within each tab's layout. Status SHALL NOT reorder pane views, and search SHALL filter without changing this relative order. Zooming a tab SHALL NOT exclude its other layout panes solely because they are not currently visible.

#### Scenario: Mixed pane types
- **WHEN** a tab layout contains an editor, an ordinary shell, an agent, and an embedded plugin terminal
- **THEN** all four appear once in the tab pane picker
- **AND** its originally focused pane remains listed

#### Scenario: Popup and orphan exclusion
- **WHEN** metadata includes a popup overlay or a pane without a matching known tab-layout entry
- **THEN** those entries are absent from all pane views

#### Scenario: Stable grouped order
- **WHEN** panes-all contains multiple worktree-related spaces and agent statuses change
- **THEN** parent/worktree grouping, tab order, and layout pane order are retained
- **AND** blocked agents do not jump ahead of other panes

#### Scenario: Zoomed tab
- **WHEN** a multi-pane tab is zoomed to one pane
- **THEN** panes-tab still lists every eligible pane in its full layout

### Requirement: Pane rows expose searchable terminal context

Pane views SHALL use each pane's own status, title, pane ID with optional label, and directory, plus scope-appropriate tab and space columns. The title SHALL use the first nonempty value among stripped terminal title, terminal title, and title, falling back to `-`. Directory SHALL use nonempty foreground cwd then cwd with the existing home abbreviation, truncation, and missing-value behavior. A nonempty pane label SHALL be displayed as `pane-id [label]` under `pane [label]`; empty labels SHALL leave the ID alone. Pane-label and worktree annotations SHALL use the existing annotation theme role. Status SHALL use existing glyph/text/color mappings with unknown fallback. Metadata SHALL retain existing single-row control-character cleaning. Only effective visible columns and their annotations SHALL match queries; hidden IDs SHALL remain available for targeting without contributing matches.

#### Scenario: Labeled shell without an agent
- **WHEN** a shell pane has label `test watcher`, no agent, and a foreground directory
- **THEN** its visible pane column includes `[test watcher]`, its status uses the supplied pane status or unknown fallback, and its directory uses that pane's foreground directory
- **AND** searching a visible label or directory can match the shell

#### Scenario: Metadata fallback
- **WHEN** stripped title and foreground cwd are missing or empty
- **THEN** the row uses terminal title or title and cwd respectively
- **AND** missing title becomes `-` and an empty label adds no brackets

#### Scenario: Reordered or hidden columns
- **WHEN** a pane view shows only `directory` and `pane`, in that order
- **THEN** rows and header follow that order and search ignores hidden title/status/tab/space data
- **AND** selection and preview still target the correct pane ID

### Requirement: Preview and acceptance target the exact pane

Highlighting a pane candidate with previews enabled SHALL show that pane's visible terminal snapshot through the existing ANSI-preserving preview behavior. Acceptance SHALL focus that exact pane, including when its containing tab or workspace was inactive, using confirmed pane identity. It SHALL NOT instead focus the containing tab's remembered pane. A closed or unreadable preview target SHALL show the existing unavailable-preview message. If the selected pane disappears before focus succeeds, Pickr SHALL report focus failure without substituting another pane. Closing, switching, refreshing, and previewing SHALL NOT focus a pane.

#### Scenario: Non-focused split in another space
- **WHEN** the user highlights then accepts a non-focused split pane in an inactive tab in another workspace
- **THEN** preview shows that split's screen and acceptance focuses that same pane

#### Scenario: Duplicate labels
- **WHEN** multiple panes have the same displayed label or title
- **THEN** the selected row's underlying pane ID determines preview and focus

#### Scenario: Pane closes before action
- **WHEN** a pane closes after listing but before preview or acceptance
- **THEN** preview reports unavailable or focus reports failure as appropriate
- **AND** no fallback terminal is focused
