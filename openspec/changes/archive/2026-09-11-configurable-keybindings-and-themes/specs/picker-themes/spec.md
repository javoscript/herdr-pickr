## Purpose

Provide consistent Herdr-compatible theme choices and user-defined color refinements throughout Pickr's interface and candidate annotations.

## ADDED Requirements

### Requirement: Named themes match the supported Herdr theme inventory

Pickr SHALL support `catppuccin`, `catppuccin-latte`, `terminal`, `tokyo-night`, `tokyo-night-day`, `dracula`, `nord`, `gruvbox`, `gruvbox-light`, `one-dark`, `one-light`, `solarized`, `solarized-light`, `kanagawa`, `kanagawa-lotus`, `rose-pine`, `rose-pine-dawn`, and `vesper` through `theme.name`, using palette mappings based on Herdr 0.9.0. The default SHALL be `catppuccin` (Mocha), independently of the active Herdr client theme. Theme selection SHALL require no network access.

#### Scenario: Default appearance
- **WHEN** no theme name is configured
- **THEN** all five pickers use Catppuccin rather than the previous Rosé Pine default
- **AND** changing the Herdr client's selected theme does not implicitly change Pickr

#### Scenario: Explicit named palette
- **WHEN** any supported canonical theme name is configured
- **THEN** initial rendering, variant switching, and refresh use that palette's Pickr role mapping

### Requirement: Semantic overrides cover chrome and candidate styling

`theme.custom` SHALL accept independently optional overrides for `background`, `foreground`, `selected_background`, `selected_foreground`, `match`, `selected_match`, `info`, `marker`, `prompt`, `spinner`, `pointer`, `header`, `footer`, `border`, `label`, `preview_background`, `preview_foreground`, `preview_border`, `annotation`, `status_blocked`, `status_done`, `status_working`, `status_idle`, and `status_unknown`. Values SHALL accept Herdr 0.9.0's color formats and aliases: `#RGB`, `#RRGGBB`, `rgb(r,g,b)` with integer components from 0 through 255, ANSI color names and aliases, and `reset`/`default`/`none`/`transparent`. ANSI names SHALL include `black`, `red`, `green`, `yellow`, `blue`, `magenta`/`purple`, `cyan`, `white`, `gray`/`grey`, `darkgray`/`darkgrey`, `lightred`, `lightgreen`, `lightyellow`, `lightblue`, `lightmagenta`, and `lightcyan`. Case and surrounding-whitespace normalization SHALL match Herdr's accepted syntax. Invalid values SHALL be configuration errors rather than silently substituted colors. Overrides SHALL layer over the selected named palette and affect the corresponding roles consistently across all variants and refresh results. Omitted or null overrides SHALL retain the selected palette's role values.

#### Scenario: Override one status and annotation role
- **WHEN** the user overrides `status_blocked` and `annotation`
- **THEN** blocked indicators in tabs, spaces, and agents use the status override
- **AND** pane labels and worktree annotations use the annotation override
- **AND** other roles retain their named-palette values

#### Scenario: Explicit Rosé Pine compatibility
- **WHEN** `rose-pine` is selected without overrides
- **THEN** annotations use the former `#524f67` color and the picker retains its former Rosé Pine palette mapping

#### Scenario: Reuse Herdr color values
- **WHEN** a role is configured as `rgb(170, 187, 204)` or `#abc`
- **THEN** both forms resolve to the same RGB color as `#aabbcc`
- **AND** named aliases such as `purple`/`magenta` and `grey`/`gray` resolve equivalently

#### Scenario: Invalid RGB override
- **WHEN** an RGB override has an out-of-range component or a color name is unrecognized
- **THEN** Pickr reports the offending configuration field and does not open fzf

### Requirement: Terminal colors preserve terminal semantics

The `terminal` theme SHALL use ANSI/default colors rather than substituting a fixed RGB palette. All reset aliases (`reset`, `default`, `none`, and `transparent`) SHALL preserve terminal-default foreground or background behavior for the applicable role rather than imply alpha blending.

#### Scenario: Terminal palette selection
- **WHEN** the user selects `terminal`
- **THEN** the picker uses terminal foreground/background defaults and ANSI role colors
- **AND** custom RGB overrides can still replace individual roles

#### Scenario: Equivalent reset aliases
- **WHEN** a background role is set to any of `reset`, `default`, `none`, or `transparent`
- **THEN** each value uses the same terminal-default background behavior

### Requirement: Styling does not change picker data or captured colors

Theme changes SHALL preserve status priorities and glyphs, candidate identity, ordering, filtering, column alignment, and focus targets. Preview chrome SHALL follow resolved roles, while captured terminal ANSI content SHALL retain its original colors.

#### Scenario: Same candidates in two themes
- **WHEN** the same snapshot is rendered with two different themes
- **THEN** candidate identities, searchable text, ordering, and preview targets remain equivalent

#### Scenario: Preview contains ANSI output
- **WHEN** a previewed terminal screen contains colored text
- **THEN** the screen's ANSI colors are preserved independently of Pickr's selected theme
