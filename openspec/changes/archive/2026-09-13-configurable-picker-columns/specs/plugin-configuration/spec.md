## MODIFIED Requirements

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

## ADDED Requirements

### Requirement: Column lists are configurable independently per variant

Pickr SHALL accept a `columns` object keyed by `spaces`, `tabs_current`, `tabs_all`, `agents_current`, and `agents_all`. Each non-null variant value SHALL be a nonempty JSON array of unique, case-sensitive column-name strings. Each array SHALL replace its variant's complete default list, with array order defining display order. Omitting or setting `columns` or a variant value to null SHALL retain the corresponding defaults; an empty `columns` object SHALL retain all defaults.

The allowed column names and default order SHALL be:

| Variant | Allowed names in default order |
| --- | --- |
| `spaces` | `status`, `space`, `tabs`, `directory` |
| `tabs_current` | `status`, `tab`, `panes`, `directory` |
| `tabs_all` | `status`, `space`, `tab`, `panes`, `directory` |
| `agents_current` | `status`, `tab`, `agent`, `title`, `pane` |
| `agents_all` | `status`, `space`, `tab`, `agent`, `title`, `pane` |

Unknown variants, unavailable or unknown column names, duplicate names, empty arrays, wrong container types, and non-string array elements including null SHALL block launch with a file/field diagnostic, including invalid values for inactive variants. Action launches SHALL validate before popup creation; direct launches SHALL validate before fzf starts.

#### Scenario: Partial column override
- **WHEN** `columns.tabs_all` is `["tab", "space", "directory"]` and other variants are omitted or null
- **THEN** all-spaces tabs uses exactly that order and subset
- **AND** every other variant retains its own default list

#### Scenario: Default containers
- **WHEN** `columns` is omitted, null, or an empty object
- **THEN** all five variants retain every existing column in its default order

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
- **WHEN** a spaces launch has valid spaces columns but an invalid `agents_all` column list
- **THEN** launch is blocked before popup creation for action launches or before fzf starts for direct launches
- **AND** no entity is focused

### Requirement: Column selection follows the launch configuration and active variant

All launch paths SHALL use column lists from the same resolved launch settings as other configuration. Switching variants SHALL select the destination's effective list from those settings, including empty candidate and zero-match states. Initial rendering, refresh success, and retry success SHALL keep headers, rows, and searchable fields consistent with the active variant's list. Refresh loading, failure, and retry SHALL NOT resolve configuration again. Edits to column settings SHALL take effect only on a subsequent launch, including edits made between launcher resolution and picker startup. Existing query reset on switching and query preservation on refresh SHALL remain unchanged.

#### Scenario: Switch selects destination columns
- **WHEN** a session switches between variants with different column lists
- **THEN** each destination uses its configured header, row order, and searchable subset and resets the query as before
- **AND** its configured header remains present with no candidates or no search matches

#### Scenario: Refresh and retry retain columns
- **WHEN** a variant refreshes through loading, success, failure, and retry
- **THEN** refreshed headers, rows, and searchable fields use the original session's column list
- **AND** its query remains preserved

#### Scenario: Reopen adopts edited columns
- **WHEN** column settings are edited after launcher resolution or while a picker is open
- **THEN** picker startup, switches, refreshes, and retries use the original resolved lists
- **AND** closing and reopening adopts the edited lists
