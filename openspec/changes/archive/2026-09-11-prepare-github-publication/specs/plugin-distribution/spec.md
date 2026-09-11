## Purpose

Allow users to install and run Herdr Pickr from a standalone repository without depending on the author's local configuration or unpublished source files.

## ADDED Requirements

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

### Requirement: Installation and migration are documented

The README SHALL document installation from `javoscript/herdr-pickr`, local development linking, required dependencies and compatibility versions, suggested keybindings with complete configuration examples, regression checks, and migration from `local.pickr`. It SHALL distinguish suggested keybindings from bindings automatically installed by the plugin and identify tested platform/version combinations without claiming unperformed verification.

#### Scenario: First-time installation
- **WHEN** a user follows the README on a supported platform
- **THEN** the instructions identify required Herdr, Lua, luv, and fzf dependencies and how to install them
- **AND** the user is shown `herdr plugin install javoscript/herdr-pickr`, a public action invocation, and usable suggested keybinding configuration
- **AND** no step requires the author's private directory layout

#### Scenario: Migrate a local installation
- **WHEN** a user follows the migration instructions for `local.pickr`
- **THEN** the instructions explain unregistering the old identity, registering the new one, and updating qualified action references
- **AND** they explain unlinking a local registration before replacing it with a GitHub-managed installation using the same new ID

### Requirement: Distribution includes license and dependency attribution

The repository SHALL include the MIT license for project code with `Copyright (c) 2026 javoscript`. Distributed third-party JSON source SHALL retain its existing copyright and MIT notice, and its upstream source and version SHALL be documented.

#### Scenario: Inspect a source distribution
- **WHEN** a user obtains the repository
- **THEN** a root `LICENSE` contains the project's MIT terms and copyright notice
- **AND** the bundled JSON source retains its rxi notice with documented upstream provenance
