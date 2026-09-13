## MODIFIED Requirements

### Requirement: Partial configuration preserves defaults and validates overrides

Configuration SHALL be a JSON object with optional `keys`, `theme`, `preview`, `popup`, `prompt`, and `columns` objects. Omitted/null settings SHALL retain defaults; omitted/null type prompts SHALL inherit the global prompt and type column lists SHALL retain that type's defaults. Missing files SHALL silently use defaults. Unreadable discovered files, malformed JSON, wrong types, unknown settings, and invalid keymap/theme/prompt/column values SHALL identify the file/setting and prevent a misconfigured launch. Directory-discovery failure SHALL report an actionable diagnostic rather than reading an assumed path. Removed scope-specific settings SHALL use migration diagnostics without silently choosing between old overrides.

#### Scenario: Minimal override
- **WHEN** only refresh is overridden or the config file is absent
- **THEN** omitted settings retain their defaults, including Catppuccin, `Search: `, and each type's default columns
- **AND** Pickr creates no config file

#### Scenario: Null retains defaults rather than disabling a shortcut
- **WHEN** refresh is null or `[]`
- **THEN** it retains Ctrl+L or has no shortcut/hint respectively, without changing omitted settings

#### Scenario: Invalid setting
- **WHEN** a setting is invalid, a theme/action is unknown, JSON is malformed, or discovery/read fails
- **THEN** Pickr reports the offending location before starting fzf and does not focus an entity or silently use fallback settings

#### Scenario: No configuration file
- **WHEN** the resolved config file is absent
- **THEN** all defaults apply without creating a file, including Catppuccin, `Search: `, and the four type column lists

#### Scenario: Empty array differs from omission
- **WHEN** refresh is `[]` and preview toggling is omitted
- **THEN** refresh has no key/hint while preview retains Ctrl+P

#### Scenario: Malformed configuration blocks launch
- **WHEN** config JSON is malformed
- **THEN** its file/parsing diagnostic blocks launch without silently using defaults

### Requirement: Initial preview visibility is configurable

`preview.enabled_by_default` SHALL be a boolean defaulting to true when omitted/null. Every new popup/direct picker session SHALL initialize from it, regardless of initial type/scope/preset. Enabled preview toggling SHALL work in either state; type/scope changes, refresh, and retry SHALL preserve the current visibility rather than reapplying the default. Closing SHALL discard this state and reopening SHALL use current configuration. Unknown preview settings and nonboolean non-null values SHALL block launch with a file/field diagnostic.

#### Scenario: Shown preview survives variant switching
- **WHEN** a popup starts shown or hidden, is toggled, and changes type/scope or refreshes/retries
- **THEN** it retains the toggled state throughout

#### Scenario: Reopening resets preview visibility to the configured default
- **WHEN** Pickr reopens after a visibility toggle
- **THEN** it uses the configured default again
- **AND** invalid preview settings block launch while omitted/null settings start shown

#### Scenario: Preview starts hidden
- **WHEN** preview.enabled_by_default is false
- **THEN** any new type/preset starts hidden and configured toggles work across later transitions

#### Scenario: Default and null preview configuration
- **WHEN** preview or its default visibility is omitted/null
- **THEN** a new popup starts shown

#### Scenario: Hidden preview survives variant switching
- **WHEN** the user hides preview then switches type/scope or refreshes/retries
- **THEN** it stays hidden until explicitly toggled

#### Scenario: Invalid preview configuration
- **WHEN** preview contains unknown settings or nonboolean non-null visibility
- **THEN** launch fails with a file/field diagnostic

### Requirement: Configuration is stable for one popup launch

Pickr SHALL resolve settings once per popup launch. Action launches and `src/open.lua` SHALL resolve before popup creation and hand the same settings snapshot to the owner. Direct Herdr pane launches and direct picker invocation SHALL resolve in the owner. Type/scope changes, refresh/retry, messages, and rendering SHALL use the same settings until closing. A later launch SHALL read current settings. Incompatible settings handoffs SHALL fail clearly rather than mixing old and new schemas or rereading config silently.

#### Scenario: Edit while popup is open
- **WHEN** config changes after launcher resolution or while a popup is open
- **THEN** dimensions, startup, transitions, rendering, and refresh retain that launch's settings
- **AND** the next launch adopts the edits

#### Scenario: Configuration changes between launcher and picker startup
- **WHEN** config changes between launcher resolution and owner startup
- **THEN** geometry and all picker settings use the single original handoff until reopening

#### Scenario: Incompatible settings handoff
- **WHEN** the owner receives a settings snapshot from the old scope-specific schema
- **THEN** it reports an incompatible handoff rather than partially launching

### Requirement: Action-launched popup dimensions are configurable

`popup.width` and `popup.height` SHALL independently default to `80%` and `70%` when omitted/null. Each SHALL accept a nonnegative finite integer cell count or integer percentage string from `1%` to `100%`; cell counts above 65535 SHALL cap at 65535 in resolution and handoff. Counts SHALL include the outer border, with Herdr applying minimum/available-screen clamping. Wrong types, unknown popup fields, malformed/out-of-range percentages, and negative/non-finite/fractional counts SHALL block launch with a file/field diagnostic. All twelve action presets and `src/open.lua` SHALL use configured dimensions through the popup API. Direct Herdr pane entrypoints SHALL retain manifest 80%/70% defaults and direct picker invocation SHALL not resize its terminal. Transitions/refresh SHALL keep existing geometry; reopening SHALL adopt edits.

#### Scenario: Partial popup override
- **WHEN** width is `90%` and height omitted/null
- **THEN** each action preset requests 90% width and 70% height

#### Scenario: Terminal-cell dimensions
- **WHEN** action dimensions are 120 by 30 cells, or a pane entrypoint is launched directly
- **THEN** the action requests those outer dimensions subject to Herdr clamping, while the direct pane launch uses manifest defaults
- **AND** direct picker invocation does not resize its terminal

#### Scenario: Invalid popup dimensions
- **WHEN** a dimension is invalid or an integer count above 65535
- **THEN** invalid values block launch, while oversized integer counts resolve and are sent as 65535

#### Scenario: Reopen adopts edited dimensions
- **WHEN** dimensions are edited while open
- **THEN** transitions and refresh retain geometry and reopening through an action uses the edited dimensions

#### Scenario: Direct launch dimensions
- **WHEN** a user opens a pane preset directly through Herdr
- **THEN** it uses manifest 80%/70% dimensions while direct picker invocation does not resize its terminal

#### Scenario: Oversized cell counts
- **WHEN** a configured dimension is an integer cell count above 65535
- **THEN** both resolved value and popup request use 65535 subject to Herdr clamping

### Requirement: Search prompt supports a global default and variant overrides

Pickr SHALL accept `prompt.default` and `prompt.variants` keyed only by `spaces`, `tabs`, `panes`, and `agents`. Global default SHALL be exactly `Search: ` including its trailing space when omitted/null. No type SHALL have a built-in override; omitted/null containers or leaves SHALL inherit the resolved global prompt. A non-null type override, including an empty string, SHALL take precedence and apply at every scope. Strings SHALL preserve whitespace/Unicode literally without evaluation or added separators. NUL/CR/LF, wrong types, and unknown fields/type names SHALL block launch with a file/field diagnostic even for inactive types. Prompt color SHALL use the existing prompt theme role.

#### Scenario: Default prompt in every variant
- **WHEN** prompt config is omitted/null/empty, or only the global prompt is `Find: `
- **THEN** all four types use `Search: ` or `Find: ` respectively

#### Scenario: Override precedence and inheritance
- **WHEN** the global prompt is `Find: `, tabs is `Tabs: `, and spaces is null
- **THEN** every tab scope uses `Tabs: ` and Spaces and other unconfigured types use `Find: `

#### Scenario: Empty strings and literal text
- **WHEN** a type prompt is empty or contains Unicode, quotes, metacharacters, or surrounding spaces
- **THEN** that exact string is displayed without execution, trimming, or fallback for the empty string

#### Scenario: Invalid prompt configuration
- **WHEN** a prompt value/container/name is invalid or contains NUL/CR/LF
- **THEN** action launch fails before popup creation or direct launch before fzf, identifying the setting without focusing an entity

#### Scenario: Global customization
- **WHEN** prompt.default is `Find: ` and type overrides are omitted/null
- **THEN** all four types use exactly `Find: ` at every scope

#### Scenario: Variant override without a global override
- **WHEN** only prompt.variants.spaces is `Spaces: `
- **THEN** Spaces uses that override and other types use `Search: `

#### Scenario: Independent pane prompts
- **WHEN** prompt.variants.panes is `Splits: `
- **THEN** all pane scopes use that one type prompt; old independent pane-scope overrides require migration

### Requirement: Prompt selection follows the launch configuration and active variant

All launch paths SHALL use the resolved type prompt from the launch settings. Type changes SHALL select the destination's prompt; scope changes SHALL keep the type prompt. Empty results, refresh loading/success/failure/retry SHALL retain it. Prompt edits SHALL apply only on a subsequent launch. Prompt customization SHALL preserve the agreed per-type query/selection memory, scope-change query continuity, and refresh query preservation.

#### Scenario: Switch selects the destination prompt
- **WHEN** a session changes type and then scope
- **THEN** the type transition selects the destination prompt and its remembered query/selection or first-visit defaults
- **AND** the scope transition preserves that prompt and query, including with zero results

#### Scenario: Prompt edits apply on reopening
- **WHEN** prompt configuration changes after launch resolution and the popup refreshes/retries
- **THEN** it retains its original prompt settings until closing and reopening

#### Scenario: Refresh retains the prompt
- **WHEN** a type refreshes through loading, success, failure, or retry
- **THEN** its resolved prompt and latest query persist

### Requirement: Popup keyboard hint visibility is configurable

`popup.show_hints` SHALL be a boolean defaulting to true when omitted/null, including missing config or omitted/null popup. False SHALL hide the keyboard footer and scope shortcut text in all four types, but not scope labels, effective/remembered state, or refresh/error messages. Nonboolean non-null values SHALL block launch with a file/field diagnostic. Dimensions SHALL retain independent defaults/validation. All launch paths and subsequent type/scope transitions or refresh/retry SHALL retain launch-snapshot visibility. Edits SHALL take effect on the next launch. Hiding hints SHALL NOT disable/remap actions.

#### Scenario: Default and explicit visible hints
- **WHEN** hints are true, omitted, or null
- **THEN** every type uses the normal grouped footer and enabled scope key hints

#### Scenario: Hidden hints across launch paths
- **WHEN** any launch path uses false and transitions or refreshes through loading/failure/retry
- **THEN** footer and scope key text remain absent while scope state, statuses, and keyboard actions remain available

#### Scenario: Visibility is stable until reopening
- **WHEN** hint visibility is edited after resolution or supplied with an invalid type
- **THEN** edits apply only on reopening, while invalid values fail before popup creation or direct fzf startup

#### Scenario: Invalid hint visibility
- **WHEN** popup.show_hints is a nonboolean non-null value
- **THEN** launch diagnoses that field before popup creation or direct fzf startup

### Requirement: Column lists are configurable independently per variant

Pickr SHALL accept `columns` keyed only by `spaces`, `tabs`, `panes`, and `agents`. Each non-null value SHALL be a nonempty array of unique case-sensitive column strings replacing that type's whole list in array order. Omitted/null containers/leaves and an empty columns object SHALL retain defaults. Allowed names, in default order, SHALL be:

| Type | Columns |
| --- | --- |
| spaces | status, space, tabs, directory |
| tabs | status, space, tab, panes, directory |
| panes | status, space, tab, title, pane, directory |
| agents | status, space, tab, agent, title, pane |

The same list and allowed names SHALL apply at every scope, without automatic hiding. Unknown type/column names, unavailable names, duplicates, empty lists, wrong containers, and non-string/null elements SHALL block all launch paths with a file/field diagnostic, including invalid inactive types. Actions SHALL validate before popup creation; direct launches before fzf.

#### Scenario: Partial column override
- **WHEN** `columns.tabs` is `["tab", "space", "directory"]` and other values omitted/null
- **THEN** both tab scopes use that subset/order and the other three types retain their defaults

#### Scenario: Pane subset and scope-specific columns
- **WHEN** Panes or Agents uses This tab
- **THEN** space and tab remain valid and visible if included, rather than producing a scope-specific validation error

#### Scenario: Empty and duplicate arrays
- **WHEN** any type list is empty, duplicated, incorrectly typed, contains invalid/null elements, or requests an unavailable column such as directory for Agents
- **THEN** launch fails with the offending field/element even when another type was initially requested

#### Scenario: Default containers
- **WHEN** columns is omitted, null, or empty
- **THEN** all four types retain their complete default lists at every scope

#### Scenario: Invalid variant or unavailable name
- **WHEN** an unknown type, misspelled/case-mismatched column, or directory in Agents is configured
- **THEN** launch reports the offending setting/element, while space/tab in narrow pane scopes are valid

#### Scenario: Invalid types
- **WHEN** columns is an array, a type list is a non-array, or an element is non-string/null
- **THEN** launch reports the invalid container/element

#### Scenario: Invalid inactive variant
- **WHEN** a Spaces launch has an invalid Agents or Panes column list
- **THEN** launch fails before popup creation or direct fzf startup without focusing an entity

### Requirement: Column selection follows the launch configuration and active variant

All launch paths SHALL use the active type's resolved column list from the launch settings. Type changes SHALL select destination columns; scope changes SHALL retain the same list. Headers, rows, and searchable fields SHALL agree during initial display, refreshed/retried publication, and empty/zero-match states. Loading/failure/retry SHALL not reread configuration. Edits SHALL take effect only on subsequent launches. Type changes SHALL restore per-type query/selection memory and scope changes SHALL preserve query and eligible identity; refresh SHALL preserve query.

#### Scenario: Switch selects destination columns
- **WHEN** a session changes to Panes with a custom column subset, then narrows scope
- **THEN** Panes uses that same header, order, and searchable subset at both scopes
- **AND** the header remains with no candidates or matches

#### Scenario: Reopen adopts edited columns
- **WHEN** columns are edited after launcher resolution and the picker switches, refreshes, or retries
- **THEN** it uses the original lists and only a subsequent launch adopts edits

#### Scenario: Refresh and retry retain columns
- **WHEN** a picker refreshes through loading, failure, and successful retry
- **THEN** header, rows, and matching fields retain the type's resolved launch list and latest query

### Requirement: Pane views share all resolved popup settings

All pane presets SHALL resolve to the same Panes type settings, using managed config discovery/validation, theme, dimensions, initial preview and hint visibility, and launch-snapshot lifetime shared by all types. Action launches SHALL validate before popup creation and request configured dimensions; direct Herdr pane launches SHALL use manifest 80%/70% dimensions and direct picker invocation SHALL not resize the terminal. Type/scope changes and refresh/retry SHALL retain settings and current preview visibility. Omitted Panes keys/prompts/columns SHALL use defaults/inheritance without writing configuration; legacy scope-specific leaves SHALL require migration.

#### Scenario: Existing configuration gains pane defaults
- **WHEN** a valid config omits Panes settings and launches any pane preset, then changes after launcher resolution
- **THEN** Panes uses its default key/columns and inherited prompt with the original launch dimensions/theme/hint/preview settings
- **AND** transitions and refresh/retry preserve those settings and later preview toggles

#### Scenario: Pane launch settings handoff
- **WHEN** a pane preset launches with custom dimensions/theme and hidden hints/preview and config changes before owner startup
- **THEN** startup and later transitions retain original settings and subsequent preview toggles

#### Scenario: Direct pane launch
- **WHEN** a pane preset is opened directly as a Herdr pane entrypoint or direct picker invocation
- **THEN** the former uses manifest dimensions and owner-resolved config, while the latter uses its existing terminal geometry

## ADDED Requirements

### Requirement: Legacy scope-specific settings require explicit migration

Pickr SHALL reject `tabs_current`, `tabs_all`, `agents_current`, `agents_all`, `panes_tab`, `panes_current`, and `panes_all` leaves under keys, columns, and prompt.variants, including null values. Diagnostics SHALL name the old field and replacement type field. Key migration diagnostics SHALL explain separate type and scope actions rather than treating old composite shortcuts as equivalent type shortcuts. Conflicting legacy settings SHALL NOT be silently merged or given precedence, even if unified settings also exist. Pickr SHALL NOT rewrite user configuration. Existing unrelated valid settings SHALL retain their semantics; users SHALL explicitly resolve new effective key conflicts such as Ctrl+C on both close and scope_tab.

#### Scenario: Conflicting old lists
- **WHEN** config contains different tabs_current and tabs_all column arrays
- **THEN** launch reports migration to columns.tabs and chooses neither list automatically

#### Scenario: Legacy null or mixed new and old settings
- **WHEN** a removed prompt/action/column leaf is null or coexists with its new type field
- **THEN** the old field still produces a replacement diagnostic without rewriting config
