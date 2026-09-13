## MODIFIED Requirements

### Requirement: Distribution is self-contained and relocatable

The repository SHALL contain all required Lua source except documented external Lua/luv dependencies. With documented dependencies installed, every supported picker action/pane preset, direct picker invocation, preview, and regression check SHALL work without outside source helpers or a prescribed checkout name/parent directory.

#### Scenario: Isolated checkout
- **WHEN** regression checks run without shared Lua helpers in parent directories
- **THEN** they use distributed sources and complete successfully

#### Scenario: Relocated plugin with spaces in its path
- **WHEN** a checkout with spaces in its path is linked and any supported type/scope preset or preview launches
- **THEN** all source resolves from that checkout independently of caller working directory

### Requirement: Public plugin identity is consistent

Pickr SHALL retain ID `javoscript.herdr-pickr` and display name `Herdr Pickr`. All twelve action/pane presets defined by the shared scope contract SHALL use that identity consistently in registration, popup creation, and invocation-context handling. `-current` registrations SHALL be removed, not retained as aliases. Type/scope transitions SHALL preserve originating workspace and available tab.

#### Scenario: Invoke a public action
- **WHEN** `javoscript.herdr-pickr.tabs-space` is invoked
- **THEN** Tabs opens with This space chosen and preserves its launch origin through transitions

#### Scenario: Open a plugin entrypoint directly
- **WHEN** a supported pane entrypoint opens with the Pickr plugin ID and valid invocation context
- **THEN** that context supplies immutable origin for both space and tab scoping where applicable

### Requirement: User-facing installation and configuration are documented

README SHALL prioritize feature discovery, installation, and complete configuration. Features SHALL describe four picker types, supported scopes, direct presets, visible-screen snapshot previews rather than streams, searchable contextual fields, agent priority/worktree grouping, in-popup type/scope switching, manual refresh, and appearance/control customization. It SHALL explain popup-local per-type query/selection memory, scope query continuity, chosen-scope fallback/restoration, origin-based rather than highlighted-item scoping, and first-match fallback.

Installation SHALL retain the published GitHub URL and `herdr plugin install javoscript/herdr-pickr`, supported dependency minimums, Herdr/Lua/luv/fzf/Git setup, matching Lua/luv and inherited PATH requirements, and a valid first launch from inside Herdr, without private directory assumptions or unperformed verification claims.

Configuration SHALL distinguish suggested Herdr `config.toml` launch bindings from managed Pickr `config.json`, explain that bindings are not automatically installed, Herdr reload versus reopening Pickr, `herdr plugin config-dir javoscript.herdr-pickr`, and partial config/default semantics. It SHALL list all twelve supported presets, explain unqualified all defaults and `-all`/`-space`/`-tab`, and provide working binding examples covering the four types and explicit scopes.

The reference SHALL document complete defaults/accepted values/replacement and inheritance/validation for all eleven actions, popup dimensions/hint visibility, preview default, named themes/semantic colors, global/four-type prompts, and four-type stable column lists. It SHALL explain scope state surviving hidden hints, remappable scope/type keys, Ctrl+C's new scope role and Esc closing, inherited fzf sources/precedence/supported action inventory, unsupported bindings/events diagnostics, and ignored unrelated options. Examples SHALL match implemented behavior and remain concise without duplicate setup/lifecycle explanations.

A concise user migration subsection SHALL explain removal of all `-current` launch names in favor of `-space`, manual consolidation of old scope-specific config into four type leaves, separate scope actions, and resolving Ctrl+C close/scope collisions. It SHALL not claim automatic migration or legacy aliases. Historical development, compatibility result tables, and implementation inventories SHALL remain outside the user guide; this scoped migration guidance SHALL not revive obsolete `local.pickr` migration instructions.

#### Scenario: First-time installation
- **WHEN** a user follows README
- **THEN** dependencies and installation precede a valid current first-launch action, without private paths or obsolete `-current` examples presented as supported

#### Scenario: Configure launch keys and popup settings
- **WHEN** a user wants Panes in This tab or Agents in This space
- **THEN** the action table/examples identify `panes-tab` and `agents-space`, the binding file, and reload instructions
- **AND** the guide explains that these choose initial state in the same four-type popup
- **AND** it explains discovering the managed config directory and creating partial config independently of Herdr launch bindings

#### Scenario: Migrate existing setup
- **WHEN** a user upgrades from scope-specific configuration and `-current` bindings
- **THEN** documentation supplies the replacement action/field names, manual conflict-resolution guidance, and new Ctrl+C/Esc behavior without suggesting old aliases still work

#### Scenario: Consult the full configuration reference
- **WHEN** a user consults default JSON, columns/prompts, hints, or inherited fzf preferences
- **THEN** documented values match the implementation, scopes do not create extra configuration types, and inherited-binding precedence/exclusions are explicit

#### Scenario: Reuse fzf preferences
- **WHEN** a user consults inherited fzf configuration guidance
- **THEN** supported actions, source precedence, Pickr key ownership, diagnostics/exclusions, ignored options, and supported baseline are documented without unperformed compatibility claims

#### Scenario: Read a focused user guide
- **WHEN** a user scans README
- **THEN** feature discovery leads into installation/configuration, with concise current migration guidance and no historical development/result inventories or obsolete local.pickr migration section
