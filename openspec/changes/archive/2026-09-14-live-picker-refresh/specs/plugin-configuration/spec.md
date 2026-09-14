## MODIFIED Requirements

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

## ADDED Requirements

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
