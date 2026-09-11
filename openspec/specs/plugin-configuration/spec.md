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

Configuration SHALL be a JSON object with optional `keys`, `theme`, `preview`, `popup`, and `prompt` objects. Omitted or null settings SHALL retain their defaults, with omitted or null variant prompts inheriting the resolved global prompt. Missing files SHALL silently use defaults. Unreadable discovered files, malformed JSON, wrong types, unknown settings, invalid keymaps, invalid theme settings, and invalid prompt settings SHALL produce an actionable diagnostic identifying the location or setting and prevent opening a misconfigured picker. Directory-discovery failure SHALL produce an actionable diagnostic rather than reading an assumed path.

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
- **AND** every variant uses the prompt `"Search: "`

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

### Requirement: Search prompt supports a global default and variant overrides

Pickr SHALL accept `prompt.default` as global prompt text and `prompt.variants` as an object with optional `tabs_current`, `tabs_all`, `spaces`, `agents_current`, and `agents_all` prompt strings. The global default SHALL be exactly `"Search: "`, including its trailing space, when `prompt` or `prompt.default` is omitted or null. No variant SHALL have a built-in override. When `prompt.variants` or an individual override is omitted or null, that variant SHALL inherit the resolved global prompt. A non-null variant override SHALL take precedence over the global value.

Prompt values SHALL be strings, including empty strings, and SHALL preserve whitespace and Unicode without trimming or adding a separator. Strings containing NUL, carriage return, or newline SHALL be rejected. Wrong types and unknown prompt fields or variant names SHALL block launch with a file/field diagnostic, including invalid overrides for variants other than the initial one. Prompt text SHALL be passed as text rather than evaluated as shell commands or fzf actions. Prompt coloring SHALL continue to follow the existing theme's `prompt` role.

#### Scenario: Default prompt in every variant
- **WHEN** `prompt` is omitted, null, or an empty object
- **THEN** all five variants use exactly `"Search: "`

#### Scenario: Global customization
- **WHEN** `prompt.default` is `"Find: "` and `prompt.variants` is omitted or null
- **THEN** all five variants use exactly `"Find: "`

#### Scenario: Override precedence and inheritance
- **WHEN** the global prompt is `"Find: "`, `tabs_current` is `"Tabs: "`, `agents_all` is `"Agents: "`, and `spaces` is null in `prompt.variants`
- **THEN** current-space tabs and all-spaces agents use their respective overrides
- **AND** spaces, all-spaces tabs, and current-space agents use `"Find: "`

#### Scenario: Variant override without a global override
- **WHEN** `prompt.default` is omitted or null and `prompt.variants.spaces` is `"Spaces: "`
- **THEN** spaces uses `"Spaces: "` and the other four variants use `"Search: "`

#### Scenario: Empty strings and literal text
- **WHEN** a resolved prompt is an empty string or contains Unicode, quotes, shell metacharacters, or surrounding spaces
- **THEN** Pickr supplies that exact string as the prompt without executing its contents or adding whitespace
- **AND** an empty variant override does not fall back to the global prompt

#### Scenario: Invalid prompt configuration
- **WHEN** `prompt` or `prompt.variants` has a non-object non-null value, a prompt value has a non-string non-null value, a field or variant name is unknown, or a prompt contains NUL, carriage return, or newline
- **THEN** Pickr identifies the invalid file/field before popup creation for action launches or before fzf starts for direct launches
- **AND** no entity is focused

### Requirement: Prompt selection follows the launch configuration and active variant

All launch paths SHALL use prompts from the same resolved launch settings as other configuration. Switching variants SHALL select the destination variant's effective prompt from those settings, including empty candidate and zero-match states. Refresh loading, success, failure, and retry SHALL retain the active variant's prompt. Edits to prompt configuration SHALL take effect only on a subsequent launch, including edits made between launcher resolution and picker startup. Prompt customization SHALL NOT change existing query reset on switching or query preservation on refresh.

#### Scenario: Switch selects the destination prompt
- **WHEN** the user switches between any of the five variants with different effective prompts
- **THEN** the destination uses its own effective prompt and resets the query as before
- **AND** the same behavior applies with no candidates or no search matches

#### Scenario: Refresh retains the prompt
- **WHEN** a variant refreshes through loading, success, failure, or retry
- **THEN** its effective prompt stays unchanged and its query remains preserved

#### Scenario: Prompt edits apply on reopening
- **WHEN** the configuration is edited after launch settings resolve
- **THEN** initial picker startup, switches, and refreshes in that session use the original prompt settings
- **AND** closing and reopening adopts the edited global prompt and variant overrides
