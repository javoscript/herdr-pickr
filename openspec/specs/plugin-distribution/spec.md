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

The repository SHALL contain all Lua source required by the plugin except the documented externally installed Lua runtime and luv dependency. With documented dependencies installed, all five picker actions, direct picker launches, previews, and regression checks SHALL work without source files outside the checkout or a prescribed checkout name or parent directory.

#### Scenario: Isolated checkout
- **WHEN** the regression suite is run from a checkout with no shared Lua helpers in its parent directories
- **THEN** it uses the distributed helpers and completes successfully

#### Scenario: Relocated plugin with spaces in its path
- **WHEN** a checkout located in a path containing spaces is linked to Herdr and its actions or previews are launched
- **THEN** all required plugin source is resolved from that checkout
- **AND** invocation does not depend on the caller's working directory

### Requirement: Public plugin identity is consistent

The plugin SHALL declare ID `javoscript.herdr-pickr` and display name `Herdr Pickr`. Its five existing actions SHALL be invocable under that plugin ID, and popup creation and invocation-context handling SHALL use that identity consistently.

#### Scenario: Invoke a public action
- **WHEN** `javoscript.herdr-pickr.tabs-current` is invoked from a workspace
- **THEN** the plugin opens its current-space tabs popup
- **AND** switching picker variants preserves the originating workspace

#### Scenario: Open a plugin entrypoint directly
- **WHEN** a pane entrypoint is opened with `HERDR_PLUGIN_ID=javoscript.herdr-pickr` and valid plugin invocation context
- **THEN** the plugin recognizes that context for current-space selection

### Requirement: User-facing installation and configuration are documented

The README SHALL prioritize feature discovery, installation, and complete user configuration. It SHALL highlight all five picker variants, visible-screen previews, searchable contextual information, agent statuses and worktree grouping, in-popup switching and manual refresh, and appearance/control customization. Behavior descriptions SHALL remain concise and distinguish screen snapshots from streaming previews and query-preserving refresh from query-resetting variant switches.

Installation SHALL present https://github.com/javoscript/herdr-pickr as the published distribution and `herdr plugin install javoscript/herdr-pickr` as the installation command without pre-publication caveats. The README SHALL identify macOS support and required Herdr, Lua, luv, fzf, and Git dependencies, state compatibility minimums, include dependency installation steps, explain the matching Lua/luv and Herdr PATH requirements, and show a public action invocation from inside Herdr.

Configuration SHALL distinguish suggested Herdr launch keybindings in Herdr's `config.toml` from Pickr customization in its Herdr-managed `config.json`. It SHALL provide complete launch-binding examples for all five actions, state that bindings are not installed automatically, explain Herdr config reload, show `herdr plugin config-dir javoscript.herdr-pickr`, and explain creating the optional file and reopening Pickr to adopt edits.

The configuration reference SHALL document every supported setting and its defaults, accepted values, inheritance or replacement rules, and relevant validation constraints. This SHALL include all popup action mappings, popup width and height, initial preview visibility, all named themes and semantic color roles with accepted color formats, and the global and five per-variant prompt settings delivered by `configure-search-prompt`. Prompt documentation SHALL match implemented behavior before publication. The reference SHALL explain fzf compatibility, inherited-binding sources and precedence, the complete supported action inventory, unsupported bindings/events and their diagnostics, and the limitation that unrelated ambient fzf options are ignored.

The README SHALL omit the Development, Migrate from `local.pickr`, Picker behavior, Regression checks, Two-row footer live acceptance, and Compatibility verification sections and their development, migration, implementation-inventory, and historical verification material. Useful user configuration previously nested under Picker behavior SHALL be retained in the configuration reference. The README SHALL avoid repeated setup instructions and repeated configuration lifecycle explanations. It SHALL NOT claim unperformed compatibility verification. Development linking, migration guidance, regression procedures, and historical platform/version result tables are not required README content.

#### Scenario: First-time installation
- **WHEN** a user follows the README on macOS
- **THEN** dependency versions and installation steps precede the GitHub installation and first launch commands
- **AND** the instructions require no private directory layout or unpublished-distribution workaround

#### Scenario: Configure launch keys and popup settings
- **WHEN** a user follows the configuration instructions
- **THEN** complete examples identify all five Herdr actions and the file used for launch bindings
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
- **AND** the removed sections, historical result tables, and development/migration procedures do not interrupt the guide
- **AND** user-facing configuration previously nested in removed sections remains discoverable

### Requirement: Distribution includes license and dependency attribution

The repository SHALL include the MIT license for project code with `Copyright (c) 2026 javoscript`. Distributed third-party JSON source SHALL retain its existing copyright and MIT notice, and its upstream source and version SHALL be documented.

#### Scenario: Inspect a source distribution
- **WHEN** a user obtains the repository
- **THEN** a root `LICENSE` contains the project's MIT terms and copyright notice
- **AND** the bundled JSON source retains its rxi notice with documented upstream provenance
