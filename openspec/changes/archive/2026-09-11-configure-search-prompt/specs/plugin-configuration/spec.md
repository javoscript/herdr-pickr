## MODIFIED Requirements

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

## ADDED Requirements

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
