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

Configuration SHALL be a JSON object with optional `keys`, `theme`, `preview`, `refresh`, `popup`, `prompt`, and `columns` objects. Omitted/null settings SHALL retain defaults; omitted/null type prompts SHALL inherit the global prompt and type column lists SHALL retain that type's defaults. Missing files SHALL silently use defaults. Unreadable discovered files, malformed JSON, wrong types, unknown settings, and invalid keymap/theme/prompt/column/refresh values SHALL identify the file/setting and prevent a misconfigured launch. Directory-discovery failure SHALL report an actionable diagnostic rather than reading an assumed path. Removed scope-specific settings SHALL use migration diagnostics without silently choosing between old overrides.

#### Scenario: Minimal override
- **WHEN** configuration changes only the refresh action or interval
- **THEN** all other action defaults and the default theme remain effective

#### Scenario: Invalid setting
- **WHEN** a config contains an unknown theme or a misspelled action
- **THEN** Pickr reports the offending setting before starting fzf
- **AND** no entity is focused

#### Scenario: No configuration file
- **WHEN** the resolved config directory has no `config.json`
- **THEN** Pickr opens with its default actions and Catppuccin theme without creating a file
- **AND** every type uses the prompt `"Search: "` and its complete default columns at every scope, with automatic refresh disabled

#### Scenario: Null retains defaults rather than disabling a shortcut
- **WHEN** `keys.refresh` is `null` and `theme.name` is `null`
- **THEN** refresh retains Ctrl+L and the theme remains Catppuccin
- **AND** a null color override retains the selected palette's value for that role

#### Scenario: Empty array differs from omission
- **WHEN** `keys.refresh` is `[]` and `keys.toggle_preview` is omitted
- **THEN** refresh has no shortcut or hint and preview toggling retains Ctrl+P
- **AND** the refresh interval independently determines whether automatic refresh runs

#### Scenario: Malformed configuration blocks launch
- **WHEN** the discovered config file contains malformed JSON
- **THEN** Pickr reports the file and parsing error without starting fzf
- **AND** it does not silently open with fallback settings

### Requirement: Initial preview visibility is configurable

`preview.enabled_by_default` SHALL be a boolean defaulting to true when omitted/null. Every new popup/direct picker session SHALL initialize from it, regardless of initial type/scope/preset. Enabled preview toggling SHALL work in either state; type/scope changes, refresh, and retry SHALL preserve the current visibility rather than reapplying the default. Closing SHALL discard this state and reopening SHALL use current configuration. Unknown preview settings and nonboolean non-null values SHALL block launch with a file/field diagnostic.

#### Scenario: Preview starts hidden
- **WHEN** `preview.enabled_by_default` is `false`
- **THEN** the preview is hidden when opening a new popup session with any type/preset
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

Pickr SHALL resolve settings once per popup launch. Action launches and `src/open.lua` SHALL resolve before popup creation and hand the same settings snapshot to the owner. Direct Herdr pane launches and direct picker invocation SHALL resolve in the owner. Type/scope changes, refresh/retry, messages, and rendering SHALL use the same settings until closing. A later launch SHALL read current settings. Incompatible settings handoffs SHALL fail clearly rather than mixing old and new schemas or rereading config silently.

#### Scenario: Edit while popup is open
- **WHEN** the user edits configuration and then refreshes or switches variants in an existing popup
- **THEN** that popup retains its original keymap and theme
- **AND** reopening Pickr applies the edited configuration

#### Scenario: Configuration changes between launcher and picker startup
- **WHEN** configuration is edited after `src/open.lua` resolves it but before the picker starts
- **THEN** popup dimensions and picker behavior use the launcher's single settings snapshot
- **AND** a subsequent launch adopts the edited configuration

#### Scenario: Incompatible settings handoff
- **WHEN** the owner receives a settings snapshot from the old scope-specific schema
- **THEN** it reports an incompatible handoff rather than partially launching

### Requirement: Action-launched popup dimensions are configurable

`popup.width` and `popup.height` SHALL independently default to `80%` and `70%` when omitted/null. Each SHALL accept a nonnegative finite integer cell count or integer percentage string from `1%` to `100%`; cell counts above 65535 SHALL cap at 65535 in resolution and handoff. Counts SHALL include the outer border, with Herdr applying minimum/available-screen clamping. Wrong types, unknown popup fields, malformed/out-of-range percentages, and negative/non-finite/fractional counts SHALL block launch with a file/field diagnostic. All twelve action presets and `src/open.lua` SHALL use configured dimensions through the popup API. Direct Herdr pane entrypoints SHALL retain manifest 80%/70% defaults and direct picker invocation SHALL not resize its terminal. Transitions/refresh SHALL keep existing geometry; reopening SHALL adopt edits.

#### Scenario: Partial popup override
- **WHEN** `popup.width` is `"90%"` and height is omitted or null
- **THEN** each of the twelve Pickr actions requests a popup with width `"90%"` and height `"70%"`

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

Pickr SHALL accept `prompt.default` and `prompt.variants` keyed only by `spaces`, `tabs`, `panes`, and `agents`. Global default SHALL be exactly `Search: ` including its trailing space when omitted/null. No type SHALL have a built-in override; omitted/null containers or leaves SHALL inherit the resolved global prompt. A non-null type override, including an empty string, SHALL take precedence and apply at every scope. Strings SHALL preserve whitespace/Unicode literally without evaluation or added separators. NUL/CR/LF, wrong types, and unknown fields/type names SHALL block launch with a file/field diagnostic even for inactive types. Prompt color SHALL use the existing prompt theme role.

#### Scenario: Default prompt in every variant
- **WHEN** `prompt` is omitted, null, or an empty object
- **THEN** all four types use exactly `"Search: "` at every scope

#### Scenario: Global customization
- **WHEN** `prompt.default` is `"Find: "` and `prompt.variants` is omitted or null
- **THEN** all four types use exactly `"Find: "` at every scope

#### Scenario: Override precedence and inheritance
- **WHEN** the global prompt is `"Find: "`, tabs is `"Tabs: "`, and spaces is null in `prompt.variants`
- **THEN** every tab scope uses `"Tabs: "`
- **AND** Spaces and other unconfigured types use `"Find: "`

#### Scenario: Variant override without a global override
- **WHEN** `prompt.default` is omitted or null and `prompt.variants.spaces` is `"Spaces: "`
- **THEN** Spaces uses `"Spaces: "` and the other three types use `"Search: "`

#### Scenario: Empty strings and literal text
- **WHEN** a resolved prompt is an empty string or contains Unicode, quotes, shell metacharacters, or surrounding spaces
- **THEN** Pickr supplies that exact string as the prompt without executing its contents or adding whitespace
- **AND** an empty variant override does not fall back to the global prompt

#### Scenario: Invalid prompt configuration
- **WHEN** `prompt` or `prompt.variants` has a non-object non-null value, a prompt value has a non-string non-null value, a field or variant name is unknown, or a prompt contains NUL, carriage return, or newline
- **THEN** Pickr identifies the invalid file/field before popup creation for action launches or before fzf starts for direct launches
- **AND** no entity is focused

#### Scenario: Independent pane prompts
- **WHEN** prompt.variants.panes is `Splits: `
- **THEN** all pane scopes use that one type prompt; old independent pane-scope overrides require migration

### Requirement: Prompt selection follows the launch configuration and active variant

All launch paths SHALL use the resolved type prompt from the launch settings. Type changes SHALL select the destination's prompt; scope changes SHALL keep the type prompt. Empty results, refresh loading/success/failure/retry SHALL retain it. Prompt edits SHALL apply only on a subsequent launch. Prompt customization SHALL preserve the agreed per-type query/selection memory, scope-change query continuity, and refresh query preservation.

#### Scenario: Switch selects the destination prompt
- **WHEN** a session changes type and then scope
- **THEN** the type transition selects the destination prompt and its remembered query/selection or first-visit defaults
- **AND** the scope transition preserves that prompt and query
- **AND** the same behavior applies with no candidates or no search matches

#### Scenario: Refresh retains the prompt
- **WHEN** a variant refreshes through loading, success, failure, or retry
- **THEN** its effective prompt stays unchanged and its query remains preserved

#### Scenario: Prompt edits apply on reopening
- **WHEN** the configuration is edited after launch settings resolve
- **THEN** initial picker startup, switches, and refreshes in that session use the original prompt settings
- **AND** closing and reopening adopts the edited global prompt and variant overrides

### Requirement: Popup keyboard hint visibility is configurable

`popup.show_hints` SHALL be a boolean defaulting to true when omitted/null, including missing config or omitted/null popup. False SHALL hide the keyboard footer and scope shortcut text in all four types, but not scope labels, effective/remembered state, or refresh/error messages. Nonboolean non-null values SHALL block launch with a file/field diagnostic. Dimensions SHALL retain independent defaults/validation. All launch paths and subsequent type/scope transitions or refresh/retry SHALL retain launch-snapshot visibility. Edits SHALL take effect on the next launch. Hiding hints SHALL NOT disable/remap actions.

#### Scenario: Default and explicit visible hints
- **WHEN** `popup.show_hints` is `true`, omitted, or null, or `popup` is omitted or null, or the configuration file is missing
- **THEN** each picker type displays its normal grouped footer and enabled scope key hints
- **AND** popup dimensions retain their independently resolved values

#### Scenario: Hidden hints across launch paths
- **WHEN** `popup.show_hints` is `false` and Pickr opens through an action, a direct Herdr pane launch, or direct picker invocation
- **THEN** the footer and scope key text remain absent while scope state and refresh/error messages remain visible
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

Pickr SHALL accept `columns` keyed only by `spaces`, `tabs`, `panes`, and `agents`. Each non-null value SHALL be a nonempty array of unique case-sensitive column strings replacing that type's whole list in array order. Omitted/null containers/leaves and an empty columns object SHALL retain defaults.

The allowed column names and default order SHALL be:

| Type | Allowed names in default order |
| --- | --- |
| `spaces` | `status`, `space`, `tabs`, `directory` |
| `tabs` | `status`, `space`, `tab`, `panes`, `directory` |
| `panes` | `status`, `space`, `tab`, `title`, `pane`, `directory` |
| `agents` | `status`, `space`, `tab`, `agent`, `title`, `pane` |

The same list and allowed names SHALL apply at every scope, without automatic hiding. Unknown type/column names, unavailable names, duplicates, empty lists, wrong containers, and non-string/null elements SHALL block all launch paths with a file/field diagnostic, including invalid inactive types. Actions SHALL validate before popup creation; direct launches before fzf.

#### Scenario: Partial column override
- **WHEN** `columns.tabs` is `["tab", "space", "directory"]` and other values are omitted or null
- **THEN** both tab scopes use exactly that order and subset
- **AND** the other three types retain their default lists

#### Scenario: Default containers
- **WHEN** `columns` is omitted, null, or an empty object
- **THEN** all four types retain every allowed column in its default order at every scope

#### Scenario: Empty and duplicate arrays
- **WHEN** a column list is `[]` or `["status", "status"]`
- **THEN** launch is blocked with a diagnostic identifying the invalid column setting

#### Scenario: Invalid variant or unavailable name
- **WHEN** configuration contains `columns.tabs_here`, uses `directory` in Agents, or uses a misspelled or differently cased column name
- **THEN** launch is blocked with a diagnostic identifying the offending setting or element

#### Scenario: Invalid types
- **WHEN** `columns` is an array, a variant value is an object or string, or an array contains a number, boolean, object, array, or null
- **THEN** launch is blocked with a diagnostic identifying the offending setting or element

#### Scenario: Invalid inactive variant
- **WHEN** a Spaces launch has valid Spaces columns but an invalid Agents or Panes column list
- **THEN** launch is blocked before popup creation for action launches or before fzf starts for direct launches
- **AND** no entity is focused

#### Scenario: Pane subset and scope-specific columns
- **WHEN** Panes or Agents uses This tab
- **THEN** space and tab remain valid and visible if included, rather than producing a scope-specific validation error

### Requirement: Column selection follows the launch configuration and active variant

All launch paths SHALL use the active type's resolved column list from the launch settings. Type changes SHALL select destination columns; scope changes SHALL retain the same list. Headers, rows, and searchable fields SHALL agree during initial display, refreshed/retried publication, and empty/zero-match states. Loading/failure/retry SHALL not reread configuration. Edits SHALL take effect only on subsequent launches. Type changes SHALL restore per-type query/selection memory and scope changes SHALL preserve query and eligible identity; refresh SHALL preserve query.

#### Scenario: Switch selects destination columns
- **WHEN** a session changes to Panes with a custom column subset, then narrows scope
- **THEN** Panes uses that same header, order, and searchable subset at both scopes
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

All pane presets SHALL resolve to the same Panes type settings, using managed config discovery/validation, theme, dimensions, initial preview and hint visibility, and launch-snapshot lifetime shared by all types. Action launches SHALL validate before popup creation and request configured dimensions; direct Herdr pane launches SHALL use manifest 80%/70% dimensions and direct picker invocation SHALL not resize the terminal. Type/scope changes and refresh/retry SHALL retain settings and current preview visibility. Omitted Panes keys/prompts/columns SHALL use defaults/inheritance without writing configuration; legacy scope-specific leaves SHALL require migration.

#### Scenario: Existing configuration gains pane defaults
- **WHEN** a valid config omits Panes settings and launches any pane preset, then changes after launcher resolution
- **THEN** Panes uses its default key/columns and inherited prompt with the original launch dimensions/theme/hint/preview settings
- **AND** Pickr does not add settings to the user's config file

#### Scenario: Pane launch settings handoff
- **WHEN** a pane action launches with configured dimensions, theme, hidden hints, and hidden preview and configuration changes before owner startup
- **THEN** the popup and picker retain the launcher's resolved settings
- **AND** switches and refresh/retry preserve those settings and any later preview toggle

#### Scenario: Direct pane launch
- **WHEN** a pane picker is launched directly through a Herdr pane entrypoint
- **THEN** it uses manifest dimensions and resolves picker configuration in the owner
- **AND** direct picker invocation uses its existing terminal dimensions

### Requirement: Legacy scope-specific settings require explicit migration

Pickr SHALL reject `tabs_current`, `tabs_all`, `agents_current`, `agents_all`, `panes_tab`, `panes_current`, and `panes_all` leaves under keys, columns, and prompt.variants, including null values. Diagnostics SHALL name the old field and replacement type field. Key migration diagnostics SHALL explain separate type and scope actions rather than treating old composite shortcuts as equivalent type shortcuts. Conflicting legacy settings SHALL NOT be silently merged or given precedence, even if unified settings also exist. Pickr SHALL NOT rewrite user configuration. Existing unrelated valid settings SHALL retain their semantics; users SHALL explicitly resolve new effective key conflicts such as Ctrl+C on both close and scope_tab.

#### Scenario: Conflicting old lists
- **WHEN** config contains different tabs_current and tabs_all column arrays
- **THEN** launch reports migration to columns.tabs and chooses neither list automatically

#### Scenario: Legacy null or mixed new and old settings
- **WHEN** a removed prompt/action/column leaf is null or coexists with its new type field
- **THEN** the old field still produces a replacement diagnostic without rewriting config

### Requirement: Automatic refresh interval is configurable independently of preview visibility

`refresh.interval_ms` SHALL default to zero when omitted/null, including an omitted/null/empty `refresh` object or missing configuration file. It SHALL accept finite integer JSON numbers from 0 through 2147483647 milliseconds inclusive; zero SHALL disable automatic refresh and positive values SHALL enable it. Negative, fractional, out-of-range, non-finite, boolean, string, array, and object leaf values SHALL block launch with a file/field diagnostic. Non-object non-null `refresh` containers and unknown refresh fields SHALL also block launch. The same interval SHALL govern list updates and refresh-driven visible previews in all four types and supported scopes. Preview visibility and `keys.refresh` SHALL retain independent semantics. All launch paths SHALL resolve the interval once and preserve the resolved value through settings handoff, type/scope transitions, refresh, and retry; edits SHALL apply only after reopening. Incompatible or malformed settings handoffs SHALL fail clearly rather than silently using another interval or rereading configuration.

#### Scenario: Defaults and disabled automatic refresh
- **WHEN** configuration is missing, `refresh` is omitted/null/empty, or `refresh.interval_ms` is omitted/null/zero
- **THEN** the resolved interval is zero in every launch path
- **AND** configured manual refresh remains available with background-refresh behavior

#### Scenario: Enable live updates with one setting
- **WHEN** `refresh.interval_ms` is `1000`
- **THEN** the popup schedules list refresh attempts every 1000 milliseconds after readiness, skipping busy ticks
- **AND** successful updates refresh the selected visible preview while hidden previews skip reads

#### Scenario: Boundary values
- **WHEN** the interval is `1` or `2147483647`
- **THEN** it is accepted without silent clamping and the resolved launch snapshot retains that value

#### Scenario: Invalid interval
- **WHEN** the interval is `-1`, `1.5`, `2147483648`, a non-finite number, `true`, `"1000"`, an array, or an object
- **THEN** launch fails with a diagnostic identifying `refresh.interval_ms`

#### Scenario: Invalid refresh container or field
- **WHEN** `refresh` is a non-null scalar or array, or contains an unknown field
- **THEN** launch fails with a diagnostic identifying the invalid refresh setting

#### Scenario: Independent controls
- **WHEN** a positive interval is configured with `keys.refresh: []` and previews initially hidden
- **THEN** automatic list refresh operates without a manual refresh key or preview reads
- **AND** showing the preview enables fresh screen reads without changing list scheduling

#### Scenario: Launch handoff and reopening
- **WHEN** configuration changes after an action launcher resolves settings or while any picker launch is open
- **THEN** the original resolved interval is used at owner startup and through switches and retries
- **AND** reopening adopts the edited interval

#### Scenario: Invalid settings handoff
- **WHEN** a settings handoff is incompatible or carries an invalid resolved interval
- **THEN** the owner reports a handoff diagnostic before starting fzf rather than applying fallback scheduling
