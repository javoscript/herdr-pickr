## MODIFIED Requirements

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

## ADDED Requirements

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
