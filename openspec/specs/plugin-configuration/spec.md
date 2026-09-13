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

Configuration SHALL be a JSON object with optional `keys`, `theme`, `preview`, `popup`, `prompt`, and `columns` objects. Omitted or null settings SHALL retain their defaults, with omitted or null variant prompts inheriting the resolved global prompt and omitted or null variant column lists retaining that variant's default columns. Missing files SHALL silently use defaults. Unreadable discovered files, malformed JSON, wrong types, unknown settings, invalid keymaps, invalid theme settings, invalid prompt settings, and invalid column settings SHALL produce an actionable diagnostic identifying the location or setting and prevent opening a misconfigured picker. Directory-discovery failure SHALL produce an actionable diagnostic rather than reading an assumed path.

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
- **AND** every variant uses the prompt `"Search: "` and all its existing columns in their default order

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

Pickr SHALL accept `prompt.default` as global prompt text and `prompt.variants` as an object with optional `tabs_current`, `tabs_all`, `spaces`, `agents_current`, `agents_all`, `panes_tab`, `panes_current`, and `panes_all` prompt strings. The global default SHALL be exactly `"Search: "`, including its trailing space, when `prompt` or `prompt.default` is omitted or null. No variant SHALL have a built-in override. When `prompt.variants` or an individual override is omitted or null, that variant SHALL inherit the resolved global prompt. A non-null variant override SHALL take precedence over the global value.

Prompt values SHALL be strings, including empty strings, and SHALL preserve whitespace and Unicode without trimming or adding a separator. Strings containing NUL, carriage return, or newline SHALL be rejected. Wrong types and unknown prompt fields or variant names SHALL block launch with a file/field diagnostic, including invalid overrides for variants other than the initial one. Prompt text SHALL be passed as text rather than evaluated as shell commands or fzf actions. Prompt coloring SHALL continue to follow the existing theme's `prompt` role.

#### Scenario: Default prompt in every variant
- **WHEN** `prompt` is omitted, null, or an empty object
- **THEN** all eight variants use exactly `"Search: "`

#### Scenario: Global customization
- **WHEN** `prompt.default` is `"Find: "` and `prompt.variants` is omitted or null
- **THEN** all eight variants use exactly `"Find: "`

#### Scenario: Override precedence and inheritance
- **WHEN** the global prompt is `"Find: "`, `tabs_current` is `"Tabs: "`, `agents_all` is `"Agents: "`, and `spaces` is null in `prompt.variants`
- **THEN** current-space tabs and all-spaces agents use their respective overrides
- **AND** spaces, all-spaces tabs, current-space agents, and all three pane variants use `"Find: "`

#### Scenario: Variant override without a global override
- **WHEN** `prompt.default` is omitted or null and `prompt.variants.spaces` is `"Spaces: "`
- **THEN** spaces uses `"Spaces: "` and the other seven variants use `"Search: "`

#### Scenario: Empty strings and literal text
- **WHEN** a resolved prompt is an empty string or contains Unicode, quotes, shell metacharacters, or surrounding spaces
- **THEN** Pickr supplies that exact string as the prompt without executing its contents or adding whitespace
- **AND** an empty variant override does not fall back to the global prompt

#### Scenario: Invalid prompt configuration
- **WHEN** `prompt` or `prompt.variants` has a non-object non-null value, a prompt value has a non-string non-null value, a field or variant name is unknown, or a prompt contains NUL, carriage return, or newline
- **THEN** Pickr identifies the invalid file/field before popup creation for action launches or before fzf starts for direct launches
- **AND** no entity is focused

#### Scenario: Independent pane prompts
- **WHEN** `prompt.variants.panes_tab` is `"Splits: "`, `panes_current` is `"Project: "`, and `panes_all` is null
- **THEN** the first two pane scopes use their overrides and all-spaces panes inherits the global prompt

### Requirement: Prompt selection follows the launch configuration and active variant

All launch paths SHALL use prompts from the same resolved launch settings as other configuration. Switching variants SHALL select the destination variant's effective prompt from those settings, including empty candidate and zero-match states. Refresh loading, success, failure, and retry SHALL retain the active variant's prompt. Edits to prompt configuration SHALL take effect only on a subsequent launch, including edits made between launcher resolution and picker startup. Prompt customization SHALL NOT change per-view query/selection memory on switching or query preservation on refresh.

#### Scenario: Switch selects the destination prompt
- **WHEN** the user switches between any of the eight variants with different effective prompts
- **THEN** the destination uses its own effective prompt and remembered query and selection, or first-visit defaults
- **AND** the same behavior applies with no candidates or no search matches

#### Scenario: Refresh retains the prompt
- **WHEN** a variant refreshes through loading, success, failure, or retry
- **THEN** its effective prompt stays unchanged and its query remains preserved

#### Scenario: Prompt edits apply on reopening
- **WHEN** the configuration is edited after launch settings resolve
- **THEN** initial picker startup, switches, and refreshes in that session use the original prompt settings
- **AND** closing and reopening adopts the edited global prompt and variant overrides

### Requirement: Popup keyboard hint visibility is configurable

Pickr SHALL expose `popup.show_hints` as a boolean defaulting to `true` when omitted or null, including when `popup` is omitted or null or the configuration file is missing. A value of `false` SHALL hide the entire keyboard hints footer in all five picker variants. Nonboolean non-null values SHALL block launch with a file/field diagnostic. Existing popup dimension defaults and validation SHALL remain unchanged.

All launch paths SHALL use the resolved hint visibility from the same launch settings snapshot as other configuration. Switching variants, refresh loading, success, failure, and retry SHALL retain that visibility. Configuration edits SHALL take effect on the next launch, including edits made between launcher resolution and picker startup. Hiding hints SHALL NOT disable or remap keyboard actions.

#### Scenario: Default and explicit visible hints
- **WHEN** `popup.show_hints` is `true`, omitted, or null, or `popup` is omitted or null, or the configuration file is missing
- **THEN** each picker variant displays its normal grouped footer
- **AND** popup dimensions retain their independently resolved values

#### Scenario: Hidden hints across launch paths
- **WHEN** `popup.show_hints` is `false` and Pickr opens through an action, a direct Herdr pane launch, or direct picker invocation
- **THEN** the initial variant has no hints section
- **AND** configured keyboard shortcuts retain their normal behavior

#### Scenario: Visibility is stable until reopening
- **WHEN** hint visibility configuration is edited after launch settings resolve
- **THEN** picker startup, switches, refresh loading, success, failure, and retry use the original visibility
- **AND** closing and reopening Pickr adopts the edited value

#### Scenario: Invalid hint visibility
- **WHEN** `popup.show_hints` contains a number, string, array, or object
- **THEN** Pickr identifies `popup.show_hints` in a configuration diagnostic before popup creation for action launches or before fzf starts for direct launches
- **AND** no entity is focused

### Requirement: Column lists are configurable independently per variant

Pickr SHALL accept a `columns` object keyed by `spaces`, `tabs_current`, `tabs_all`, `agents_current`, `agents_all`, `panes_tab`, `panes_current`, and `panes_all`. Each non-null variant value SHALL be a nonempty JSON array of unique, case-sensitive column-name strings. Each array SHALL replace its variant's complete default list, with array order defining display order. Omitting or setting `columns` or a variant value to null SHALL retain the corresponding defaults; an empty `columns` object SHALL retain all defaults.

The allowed column names and default order SHALL be:

| Variant | Allowed names in default order |
| --- | --- |
| `spaces` | `status`, `space`, `tabs`, `directory` |
| `tabs_current` | `status`, `tab`, `panes`, `directory` |
| `tabs_all` | `status`, `space`, `tab`, `panes`, `directory` |
| `agents_current` | `status`, `tab`, `agent`, `title`, `pane` |
| `agents_all` | `status`, `space`, `tab`, `agent`, `title`, `pane` |
| `panes_tab` | `status`, `title`, `pane`, `directory` |
| `panes_current` | `status`, `tab`, `title`, `pane`, `directory` |
| `panes_all` | `status`, `space`, `tab`, `title`, `pane`, `directory` |

Unknown variants, unavailable or unknown column names, duplicate names, empty arrays, wrong container types, and non-string array elements including null SHALL block launch with a file/field diagnostic, including invalid values for inactive variants. Action launches SHALL validate before popup creation; direct launches SHALL validate before fzf starts.

#### Scenario: Partial column override
- **WHEN** `columns.tabs_all` is `["tab", "space", "directory"]` and other variants are omitted or null
- **THEN** all-spaces tabs uses exactly that order and subset
- **AND** every other variant retains its own default list

#### Scenario: Default containers
- **WHEN** `columns` is omitted, null, or an empty object
- **THEN** all eight variants retain every allowed column in its default order

#### Scenario: Empty and duplicate arrays
- **WHEN** a column list is `[]` or `["status", "status"]`
- **THEN** launch is blocked with a diagnostic identifying the invalid column setting

#### Scenario: Invalid variant or unavailable name
- **WHEN** configuration contains `columns.tabs_here`, uses `space` in `tabs_current`, uses `directory` in an agent variant, or uses a misspelled or differently cased column name
- **THEN** launch is blocked with a diagnostic identifying the offending setting or element

#### Scenario: Invalid types
- **WHEN** `columns` is an array, a variant value is an object or string, or an array contains a number, boolean, object, array, or null
- **THEN** launch is blocked with a diagnostic identifying the offending setting or element

#### Scenario: Invalid inactive variant
- **WHEN** a spaces launch has valid spaces columns but an invalid `agents_all` or pane variant column list
- **THEN** launch is blocked before popup creation for action launches or before fzf starts for direct launches
- **AND** no entity is focused

#### Scenario: Pane subset and scope-specific columns
- **WHEN** `columns.panes_all` is `["pane", "directory", "space"]`
- **THEN** all-spaces panes displays exactly those columns in that order
- **AND** `tab` or `space` in `panes_tab`, or `space` in `panes_current`, remains an invalid column setting

### Requirement: Column selection follows the launch configuration and active variant

All launch paths SHALL use column lists from the same resolved launch settings as other configuration. Switching variants SHALL select the destination's effective list from those settings, including empty candidate and zero-match states. Initial rendering, refresh success, and retry success SHALL keep headers, rows, and searchable fields consistent with the active variant's list. Refresh loading, failure, and retry SHALL NOT resolve configuration again. Edits to column settings SHALL take effect only on a subsequent launch, including edits made between launcher resolution and picker startup. Per-view query/selection memory on switching and query preservation on refresh SHALL remain unchanged.

#### Scenario: Switch selects destination columns
- **WHEN** a session switches between variants with different column lists
- **THEN** each destination uses its configured header, row order, and searchable subset and restores its own remembered query and selection or first-visit defaults
- **AND** its configured header remains present with no candidates or no search matches

#### Scenario: Refresh and retry retain columns
- **WHEN** a variant refreshes through loading, success, failure, and retry
- **THEN** refreshed headers, rows, and searchable fields use the original session's column list
- **AND** its query remains preserved

#### Scenario: Reopen adopts edited columns
- **WHEN** column settings are edited after launcher resolution or while a picker is open
- **THEN** picker startup, switches, refreshes, and retries use the original resolved lists
- **AND** closing and reopening adopts the edited lists

### Requirement: Pane views share all resolved popup settings

All three pane variants SHALL use the same managed configuration discovery, validation, launch snapshot, theme roles, popup dimensions, initial preview visibility, and hint visibility semantics as the existing views. Pane action launches SHALL validate before creating a popup and use configured dimensions. Direct Herdr pane launches SHALL use the manifest's 80% width and 70% height defaults; direct picker invocation SHALL not resize its terminal. Pane switches and refresh/retry SHALL retain launch settings and current preview visibility without rereading configuration. Omitted pane-specific keys, prompts, and columns SHALL resolve to their defaults or existing inheritance rules, without writing user configuration.

#### Scenario: Existing configuration gains pane defaults
- **WHEN** a valid existing config omits all pane variant settings and has no new key conflicts
- **THEN** the three pane views open with their default keys/columns and inherited global prompt
- **AND** Pickr does not add settings to the user's config file

#### Scenario: Pane launch settings handoff
- **WHEN** a pane action launches with configured dimensions, theme, hidden hints, and hidden preview and configuration changes before owner startup
- **THEN** the popup and picker retain the launcher's resolved settings
- **AND** switches and refresh/retry preserve those settings and any later preview toggle

#### Scenario: Direct pane launch
- **WHEN** a pane picker is launched directly through a Herdr pane entrypoint
- **THEN** it uses manifest dimensions and resolves picker configuration in the owner
- **AND** direct picker invocation uses its existing terminal dimensions
