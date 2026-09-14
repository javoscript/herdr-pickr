# picker-scopes Specification

## Purpose

Separate what users search from where they search, providing consistent scope controls and direct scoped entry into four picker types.

## Requirements

### Requirement: Four picker types share a scope matrix

Pickr SHALL expose exactly four in-popup picker types: Spaces, Tabs, Panes, and Agents. Scope SHALL be a mutually exclusive choice among All spaces (`all`), This space (`space`), and This tab (`tab`). Spaces SHALL have no effective scope; Tabs SHALL support all/space; Panes and Agents SHALL support all/space/tab. All SHALL include eligible candidates across spaces; space SHALL include eligible candidates across all tabs of the originating space; tab SHALL include only eligible candidates in the originating tab and space. Agent filtering SHALL preserve existing agent eligibility, status priority, descending state-change sequence, and original layout order for exact ties. Scope filtering SHALL NOT change entity identities or preview/acceptance targets.

#### Scenario: Agents in this tab
- **WHEN** Agents uses This tab and agents exist in multiple tabs of the originating space
- **THEN** only eligible agents belonging to the originating tab appear, in existing agent priority order
- **AND** accepting one focuses that exact agent pane

#### Scenario: Broader pane scopes
- **WHEN** Panes changes from This tab to This space and then All spaces
- **THEN** membership expands to all eligible panes across the originating space's tabs and then across all spaces respectively
- **AND** pane layout ordering and exact-pane targeting are preserved

### Requirement: Chosen scope survives temporary fallback

Each popup SHALL retain one chosen scope independently of picker type. Type switching SHALL use that scope if supported, otherwise the nearest broader supported scope; Spaces SHALL use none. Fallback SHALL NOT overwrite chosen scope. An enabled supported scope action SHALL replace chosen scope even if it is already the effective fallback. Unsupported scope actions SHALL be no-ops without changing choice, query, selection, or popup lifetime. Selecting the already chosen scope SHALL be a no-op. A supported scope with missing origin or zero candidates SHALL NOT trigger broader fallback. New unqualified launches SHALL initialize chosen scope to all, including Spaces for a subsequent type switch; explicit scoped launches SHALL initialize it to their named scope. Closing SHALL discard the choice.

#### Scenario: Carry tab intent through unsupported types
- **WHEN** Panes in This tab switches to Tabs, Spaces, and Agents in sequence without a scope action
- **THEN** effective scopes are This space, none, and This tab respectively
- **AND** the chosen scope remains This tab throughout

#### Scenario: Explicitly choose a fallback scope
- **WHEN** Tabs effectively shows This space with This tab remembered and the user invokes This space
- **THEN** chosen scope becomes This space without changing its current query or selection
- **AND** a later switch to Agents uses This space

#### Scenario: Unsupported scope key
- **WHEN** This tab is invoked in Tabs, or any scope action is invoked in Spaces
- **THEN** the action does nothing and does not close the popup or replace its remembered scope

#### Scenario: Empty supported scope
- **WHEN** Agents in This tab has no eligible agents
- **THEN** it remains in This tab with an empty list rather than showing agents elsewhere

### Requirement: Narrow scopes use immutable launch origin

Every launch path SHALL capture originating workspace and available tab before popup focus can replace their context, including launches into Spaces. Type changes, scope changes, refresh, retry, and highlighted candidates SHALL NOT recapture or change those identities. Supplied tab membership SHALL be validated against its originating workspace. Deleted origin identities SHALL yield empty narrow results, not a different active space/tab or broader scope. If tab origin cannot be resolved at launch, tab scope SHALL remain supported but empty; broader pickers SHALL remain usable.

#### Scenario: Highlight and external focus do not retarget scope
- **WHEN** a popup launched from tab A highlights tab B and another client changes active focus before Panes or Agents enters This tab
- **THEN** that picker still uses tab A in the originating workspace

#### Scenario: Missing or deleted origin
- **WHEN** the origin tab was unavailable at launch or is deleted before a tab-scoped refresh or transition
- **THEN** tab-scoped Panes and Agents have no candidates
- **AND** explicit broader scope actions remain usable without rebinding origin

### Requirement: Direct launches initialize type and scope

Under plugin ID `javoscript.herdr-pickr`, Pickr SHALL register matching public actions and pane entrypoints `spaces`; `tabs`, `tabs-all`, `tabs-space`; `panes`, `panes-all`, `panes-space`, `panes-tab`; and `agents`, `agents-all`, `agents-space`, `agents-tab`. Unqualified Tabs/Panes/Agents SHALL be equivalent to their `-all` presets. Explicit suffixes SHALL initialize the chosen scope without creating separate in-popup types or memory/configuration slots. `*-current` actions and entrypoints SHALL be removed with no compatibility aliases. Direct picker invocation SHALL support `spaces` or `tabs|panes|agents [all|space|tab]` with the same supported-pair validation and default all scope; legacy `current` SHALL be rejected with guidance to use `space`. Invalid explicit pairs SHALL fail rather than silently apply interactive fallback.

#### Scenario: Scoped action followed by type switch
- **WHEN** `javoscript.herdr-pickr.panes-tab` opens and the user switches to Agents
- **THEN** Agents uses This tab and the same immutable origin
- **AND** the preset has not created an additional picker type

#### Scenario: Unqualified and explicit global entry
- **WHEN** `tabs` and `tabs-all` are launched in separate new popups
- **THEN** each starts Tabs with All spaces and first-visit query/selection defaults

#### Scenario: Legacy or unsupported launch
- **WHEN** a user tries an old `tabs-current` registration, legacy direct `current` scope, or explicit `tabs-tab`/`spaces-space` launch
- **THEN** it is not accepted as a supported launch
- **AND** Pickr-owned legacy argument diagnostics identify the replacement while README documents Herdr binding renames
