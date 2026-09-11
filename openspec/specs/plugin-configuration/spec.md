# plugin-configuration Specification

## Purpose

Let community users configure Pickr independently of its installed source while retaining predictable defaults and consistent behavior for each popup session.

## Requirements

### Requirement: Configuration lives in Herdr's plugin config directory

Pickr SHALL read an optional `config.json` from its Herdr-managed plugin configuration directory, preferring the applicable `HERDR_PLUGIN_CONFIG_DIR`. Direct invocation without that environment SHALL discover the directory through Herdr for `javoscript.herdr-pickr`, independently of the checkout and caller working directory. Pickr SHALL NOT create or overwrite user configuration during normal launches.

#### Scenario: Managed or linked plugin launch
- **WHEN** Herdr launches Pickr with its plugin config directory environment
- **THEN** Pickr reads `config.json` from that directory
- **AND** relocating or updating the source checkout does not change the configuration location

#### Scenario: Direct invocation
- **WHEN** Pickr is invoked directly without its plugin config directory environment
- **THEN** it asks Herdr to resolve the config directory for `javoscript.herdr-pickr`
- **AND** it does not read configuration relative to the caller or checkout

### Requirement: Partial configuration preserves defaults and validates overrides

Configuration SHALL be a JSON object with optional `keys`, `theme`, `preview`, and `popup` objects. Omitted or null settings SHALL retain their defaults. Missing files SHALL silently use defaults. Unreadable discovered files, malformed JSON, wrong types, unknown settings, invalid keymaps, and invalid theme settings SHALL produce an actionable diagnostic identifying the location or setting and prevent opening a misconfigured picker. Directory-discovery failure SHALL produce an actionable diagnostic rather than reading an assumed path.

#### Scenario: Minimal override
- **WHEN** configuration changes only the refresh action
- **THEN** all other action defaults and the default theme remain effective

#### Scenario: Invalid setting
- **WHEN** a config contains an unknown theme or a misspelled action
- **THEN** Pickr reports the offending setting before starting fzf
- **AND** no entity is focused

#### Scenario: No configuration file
- **WHEN** the resolved config directory has no `config.json`
- **THEN** Pickr opens with its default actions and Catppuccin theme without creating a file

#### Scenario: Null retains defaults rather than disabling a shortcut
- **WHEN** `keys.refresh` is `null` and `theme.name` is `null`
- **THEN** refresh retains Ctrl+L and the theme remains Catppuccin
- **AND** a null color override retains the selected palette's value for that role

#### Scenario: Empty array differs from omission
- **WHEN** `keys.refresh` is `[]` and `keys.toggle_preview` is omitted
- **THEN** refresh has no shortcut or hint
- **AND** preview toggling retains Ctrl+P

#### Scenario: Malformed configuration blocks launch
- **WHEN** the discovered config file contains malformed JSON
- **THEN** Pickr reports the file and parsing error without starting fzf
- **AND** it does not silently open with fallback settings

### Requirement: Initial preview visibility is configurable

Pickr SHALL expose `preview.enabled_by_default` as a boolean defaulting to `true` when omitted or null. A new popup session, or a new direct `src/main.lua` invocation, SHALL start with this configured preview visibility regardless of its initial variant. Any enabled preview-toggle shortcut SHALL remain usable in either initial state. Variant switches, refresh, and retry SHALL preserve the current shown/hidden state, including changes made using that shortcut. The configured default SHALL NOT be reapplied on a variant switch. Closing SHALL discard the session's visibility state; reopening SHALL initialize visibility from the configured default again. Unknown preview settings and nonboolean non-null values SHALL block launch with a file/field diagnostic.

#### Scenario: Preview starts hidden
- **WHEN** `preview.enabled_by_default` is `false`
- **THEN** the preview is hidden when opening a new popup session with any of the five variants
- **AND** the configured preview-toggle shortcut can show and hide it
- **AND** variant switches, refresh, and retry preserve its current visibility

#### Scenario: Default and null preview configuration
- **WHEN** `preview`, or its `enabled_by_default` setting, is omitted or null
- **THEN** each new popup session starts with the preview visible

#### Scenario: Shown preview survives variant switching
- **WHEN** a session starts with `preview.enabled_by_default` set to `false`, the user shows the preview, and then switches variants
- **THEN** the destination variant keeps the preview shown
- **AND** subsequent switches preserve the current visibility until the user toggles it again

#### Scenario: Hidden preview survives variant switching
- **WHEN** a session starts with `preview.enabled_by_default` set to `true`, the user hides the preview, and then switches variants
- **THEN** the destination variant keeps the preview hidden
- **AND** subsequent switches preserve the current visibility until the user toggles it again

#### Scenario: Reopening resets preview visibility to the configured default
- **WHEN** the user changes preview visibility during a session, closes the popup, and reopens Pickr
- **THEN** the new popup initializes visibility from its configured default rather than the previous session's toggled state
- **AND** any edits to `preview.enabled_by_default` are adopted by the new launch

#### Scenario: Invalid preview configuration
- **WHEN** `preview.enabled_by_default` is a nonboolean non-null value or `preview` contains an unknown setting
- **THEN** Pickr reports the offending configuration field without opening fzf

### Requirement: Configuration is stable for one popup launch

Pickr SHALL resolve settings once per popup launch. Pickr action launches and `src/open.lua` SHALL resolve settings before popup creation and hand the same settings snapshot to the picker owner. Direct Herdr pane launches and `src/main.lua` SHALL resolve settings in the picker owner. Variant switches, refreshes, retry messages, and rendering SHALL use that same configuration until the popup closes. A subsequent launch SHALL read current settings.

#### Scenario: Edit while popup is open
- **WHEN** the user edits configuration and then refreshes or switches variants in an existing popup
- **THEN** that popup retains its original keymap and theme
- **AND** reopening Pickr applies the edited configuration

#### Scenario: Configuration changes between launcher and picker startup
- **WHEN** configuration is edited after `src/open.lua` resolves it but before the picker starts
- **THEN** popup dimensions and picker behavior use the launcher's single settings snapshot
- **AND** a subsequent launch adopts the edited configuration

### Requirement: Action-launched popup dimensions are configurable

Pickr SHALL expose `popup.width` and `popup.height`, defaulting independently to `"80%"` and `"70%"` when omitted or null. Each dimension SHALL accept a nonnegative finite integer terminal-cell count or an integer percentage string from `"1%"` through `"100%"`. Pickr SHALL cap cell counts above 65535 at 65535 during configuration resolution, including in the launch settings snapshot. Cell counts SHALL describe the outer popup including its border. Herdr SHALL perform minimum-size and available-screen clamping. Unknown popup settings, wrong types, malformed or out-of-range percentages, and negative, non-finite or fractional numbers SHALL block launch with a file/field diagnostic.

Pickr's five actions and `src/open.lua` SHALL supply configured dimensions when creating a popup through Herdr's `plugin.pane.open` socket API. Direct `herdr plugin pane open` calls SHALL retain the manifest's 80% width and 70% height defaults; `src/main.lua` SHALL use its existing terminal without resizing it. Variant switching and refresh SHALL retain the existing popup geometry. Reopening through Pickr's launcher SHALL adopt edited dimensions.

#### Scenario: Partial popup override
- **WHEN** `popup.width` is `"90%"` and height is omitted or null
- **THEN** each of the five Pickr actions requests a popup with width `"90%"` and height `"70%"`

#### Scenario: Terminal-cell dimensions
- **WHEN** `popup.width` is `120` and `popup.height` is `30`
- **THEN** the launcher requests an outer popup of 120 columns and 30 rows
- **AND** Herdr clamps the dimensions to its minimum size and available terminal area

#### Scenario: Direct launch dimensions
- **WHEN** a user launches an entrypoint directly with `herdr plugin pane open`
- **THEN** its popup uses the manifest's 80% × 70% defaults
- **AND** running `src/main.lua` directly does not resize the caller's terminal

#### Scenario: Invalid popup dimensions
- **WHEN** a popup dimension is `"0%"`, `"101%"`, a negative, non-finite or fractional number, or a non-null value of the wrong type
- **THEN** Pickr reports the offending field before creating a popup or starting fzf

#### Scenario: Oversized cell counts
- **WHEN** a popup dimension is configured as an integer cell count above 65535
- **THEN** the resolved setting and socket request use 65535 for that dimension
- **AND** Herdr clamps the popup to the available terminal area rather than Pickr blocking launch

#### Scenario: Reopen adopts edited dimensions
- **WHEN** popup dimensions are edited while a picker is open
- **THEN** switching variants and refreshing retain the current popup dimensions
- **AND** closing and reopening through a Pickr action uses the edited dimensions
