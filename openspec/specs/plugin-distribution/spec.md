# plugin-distribution Specification

## Purpose

Allow users to install and run Herdr Pickr from a standalone repository without depending on the author's local configuration or unpublished source files.

## Requirements

### Requirement: Publication supports macOS only

The plugin SHALL declare `platforms = ["macos"]` and document macOS as its only supported platform for this publication. Linux support SHALL be deferred to a follow-up requiring isolated regression and interactive verification, recorded dependency versions and outcomes, and Linux setup documentation before Linux is enabled in the manifest.

#### Scenario: Inspect supported platforms
- **WHEN** a user reads the manifest and README
- **THEN** both identify macOS as the only supported platform
- **AND** Linux is documented as deferred, not verified or supported by this publication

### Requirement: Distribution is self-contained and relocatable

The repository SHALL contain all required Lua source except documented external Lua/luv dependencies. With documented dependencies installed, every supported picker action/pane preset, direct picker invocation, preview, and regression check SHALL work without outside source helpers or a prescribed checkout name/parent directory.

#### Scenario: Isolated checkout
- **WHEN** the regression suite is run from a checkout with no shared Lua helpers in its parent directories
- **THEN** it uses the distributed helpers and completes successfully

#### Scenario: Relocated plugin with spaces in its path
- **WHEN** a checkout located in a path containing spaces is linked to Herdr and its actions or previews are launched
- **THEN** all required plugin source is resolved from that checkout
- **AND** invocation does not depend on the caller's working directory

### Requirement: Public plugin identity is consistent

Pickr SHALL retain ID `javoscript.herdr-pickr` and display name `Herdr Pickr`. All twelve action/pane presets defined by the shared scope contract SHALL use that identity consistently in registration, popup creation, and invocation-context handling. `-current` registrations SHALL be removed, not retained as aliases. Type/scope transitions SHALL preserve originating workspace and available tab.

#### Scenario: Invoke a public action
- **WHEN** `javoscript.herdr-pickr.tabs-space` is invoked
- **THEN** Tabs opens with This space chosen and preserves its launch origin through transitions

#### Scenario: Open a plugin entrypoint directly
- **WHEN** a pane entrypoint is opened with `HERDR_PLUGIN_ID=javoscript.herdr-pickr` and valid plugin invocation context
- **THEN** that context supplies immutable origin for both space and tab scoping where applicable

### Requirement: User-facing installation and configuration are documented

README SHALL prioritize feature discovery, installation, and complete configuration. Features SHALL describe four picker types, supported scopes, direct presets, visible-screen snapshot previews rather than streams, searchable contextual fields, agent priority/worktree grouping, in-popup type/scope switching, manual refresh, and appearance/control customization. It SHALL explain popup-local per-type query/selection memory, scope query continuity, chosen-scope fallback/restoration, origin-based rather than highlighted-item scoping, and first-match fallback.

Installation SHALL retain the published GitHub URL and `herdr plugin install javoscript/herdr-pickr`, supported dependency minimums, Herdr/Lua/luv/fzf/Git setup, matching Lua/luv and inherited PATH requirements, and a valid first launch from inside Herdr, without private directory assumptions or unperformed verification claims.

Configuration SHALL distinguish suggested Herdr `config.toml` launch bindings from managed Pickr `config.json`, explain that bindings are not automatically installed, Herdr reload versus reopening Pickr, `herdr plugin config-dir javoscript.herdr-pickr`, and partial config/default semantics. It SHALL list all twelve supported presets, explain unqualified all defaults and `-all`/`-space`/`-tab`, and provide working binding examples covering the four types and explicit scopes.

The reference SHALL document complete defaults/accepted values/replacement and inheritance/validation for all eleven actions, popup dimensions/hint visibility, preview default, named themes/semantic colors, global/four-type prompts, and four-type stable column lists. It SHALL explain scope state surviving hidden hints, remappable scope/type keys, Ctrl+C's new scope role and Esc closing, inherited fzf sources/precedence/supported action inventory, unsupported bindings/events diagnostics, and ignored unrelated options. Examples SHALL match implemented behavior and remain concise without duplicate setup/lifecycle explanations.

A concise user migration subsection SHALL explain removal of all `-current` launch names in favor of `-space`, manual consolidation of old scope-specific config into four type leaves, separate scope actions, and resolving Ctrl+C close/scope collisions. It SHALL not claim automatic migration or legacy aliases. Historical development, compatibility result tables, and implementation inventories SHALL remain outside the user guide; this scoped migration guidance SHALL not revive obsolete `local.pickr` migration instructions.

#### Scenario: First-time installation
- **WHEN** a user follows the README on macOS
- **THEN** dependency versions and installation steps precede the GitHub installation and first launch commands
- **AND** the instructions require no private directory layout or unpublished-distribution workaround

#### Scenario: Configure launch keys and popup settings
- **WHEN** a user follows the configuration instructions
- **THEN** the action table and examples identify all twelve presets and the file used for launch bindings, including `panes-tab` and `agents-space`
- **AND** the user can discover the plugin configuration directory and create a valid partial `config.json`
- **AND** the instructions distinguish reloading Herdr bindings from reopening Pickr after customization

#### Scenario: Consult the full configuration reference
- **WHEN** a user wants to change action keys, popup dimensions, preview visibility, themes, colors, or prompts
- **THEN** the README describes all supported settings, defaults, accepted values, and applicable validation and inheritance rules
- **AND** JSON examples are accepted by the implementation including the completed prompt feature

#### Scenario: Reuse fzf preferences
- **WHEN** a user wants to reuse their fzf options and keybindings
- **THEN** the README lists supported imported actions and source precedence, explains Pickr key precedence, and describes excluded bindings and ignored options
- **AND** it states the supported fzf baseline without implying every later version was tested

#### Scenario: Read a focused user guide
- **WHEN** a user scans the README
- **THEN** feature highlights lead into installation and configuration
- **AND** concise current migration guidance is provided without historical development/result inventories or obsolete local.pickr migration sections
- **AND** user-facing configuration previously nested in removed sections remains discoverable

#### Scenario: Migrate existing setup
- **WHEN** a user upgrades from scope-specific configuration and `-current` bindings
- **THEN** documentation supplies the replacement action/field names, manual conflict-resolution guidance, and new Ctrl+C/Esc behavior without suggesting old aliases still work

### Requirement: Distribution includes license and dependency attribution

The repository SHALL include the MIT license for project code with `Copyright (c) 2026 javoscript`. Distributed third-party JSON source SHALL retain its existing copyright and MIT notice, and its upstream source and version SHALL be documented.

#### Scenario: Inspect a source distribution
- **WHEN** a user obtains the repository
- **THEN** a root `LICENSE` contains the project's MIT terms and copyright notice
- **AND** the bundled JSON source retains its rxi notice with documented upstream provenance
