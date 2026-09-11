# Herdr Pickr

Fuzzy tab, space, and agent pickers for Herdr, with visible-terminal previews.
The plugin bundles its Lua source dependencies and can live in any checkout directory.

**Supported platform: macOS only.** Linux support is deferred until a follow-up
verifies isolated regressions and interactive behavior on Linux, records dependency
versions and outcomes, and supplies Linux setup instructions before enabling it
in the manifest.

## Install and launch

Install the [dependencies](#dependencies), then install the plugin from GitHub:

```sh
herdr plugin install javoscript/herdr-pickr
```

The GitHub command becomes available once this repository is published. For a
pre-publication checkout, use [development linking](#development) below.

From a terminal inside Herdr, open the current-space tabs picker:

```sh
herdr plugin action invoke javoscript.herdr-pickr.tabs-current
```

All five actions are available explicitly:

```sh
herdr plugin action invoke javoscript.herdr-pickr.tabs-current
herdr plugin action invoke javoscript.herdr-pickr.tabs-all
herdr plugin action invoke javoscript.herdr-pickr.spaces
herdr plugin action invoke javoscript.herdr-pickr.agents-current
herdr plugin action invoke javoscript.herdr-pickr.agents-all
```

Move through entries to preview them, press Enter to focus the selection, or
Escape/Ctrl+C to cancel. Ctrl+P toggles the preview. **Ctrl+L** refreshes the
open picker while preserving your search and highlighted entity.

## Suggested keybindings

The plugin does not install keybindings automatically. Add or merge these entries
into `~/.config/herdr/config.toml` (or the config path shown by `herdr --help`),
replacing any existing bindings on the same keys:

```toml
[[keys.command]]
key = "prefix+r"
type = "plugin_action"
command = "javoscript.herdr-pickr.tabs-current"
description = "pick tabs in current space"

[[keys.command]]
key = "prefix+shift+r"
type = "plugin_action"
command = "javoscript.herdr-pickr.tabs-all"
description = "pick tabs in all spaces"

[[keys.command]]
key = "prefix+s"
type = "plugin_action"
command = "javoscript.herdr-pickr.spaces"
description = "pick spaces"

[[keys.command]]
key = "prefix+a"
type = "plugin_action"
command = "javoscript.herdr-pickr.agents-current"
description = "pick agents in current space"

[[keys.command]]
key = "prefix+shift+a"
type = "plugin_action"
command = "javoscript.herdr-pickr.agents-all"
description = "pick agents in all spaces"
```

With the default Ctrl+B prefix, these mean Ctrl+B followed by `r`, Shift+R,
`s`, `a`, or Shift+A. Popup dimensions can be configured in Pickr's `config.json`.
Reload after editing bindings:

```sh
herdr server reload-config
```

You can also choose **reload config** in Herdr's global menu; this reloads
client settings and the selected server's config, including when working remotely.
The examples follow Herdr 0.9.0's
[plugin keybinding documentation](https://raw.githubusercontent.com/herdrdev/herdr/v0.9.0/docs/next/website/src/content/docs/plugins.mdx)
and [configuration documentation](https://raw.githubusercontent.com/herdrdev/herdr/v0.9.0/docs/next/website/src/content/docs/configuration.mdx).

## Development

Clone into any directory and link the checkout:

```sh
git clone https://github.com/javoscript/herdr-pickr.git
herdr plugin link "$(pwd)/herdr-pickr"
lua ./herdr-pickr/tests/test.lua
```

For an existing checkout, run these from its repository root:

```sh
herdr plugin link "$(pwd)"
lua tests/test.lua
```

Relink after changing the manifest or moving the checkout. Lua edits apply on the
next launch. Disable with `herdr plugin disable javoscript.herdr-pickr`; unregister
without deleting source files with `herdr plugin unlink javoscript.herdr-pickr`.
For a GitHub-managed installation, repeat the install command to update it.

### Source-layout migration and direct invocation

Relink existing development installations after updating to the `src/` layout:
run `herdr plugin link "$(pwd)"` from the checkout root. Existing qualified action
IDs and keybindings still work without edits.

Direct script callers must replace `main.lua`, `open.lua`, and `test.lua` with
`src/main.lua`, `src/open.lua`, and `tests/test.lua`, respectively. The old paths
have no compatibility wrappers. From the repository root inside Herdr:

```sh
lua src/open.lua tabs-current
lua src/main.lua tabs current
lua src/main.lua tabs all
lua src/main.lua workspaces all
lua src/main.lua agents current
lua src/main.lua agents all
```

`src/open.lua` opens the named plugin popup and captures the caller's workspace;
`src/main.lua` runs the picker in the current terminal. From another directory,
use an absolute or caller-relative path to the script, quoting paths with spaces.
Source imports and preview/refresh subprocesses resolve from physical script
locations, independently of the caller's working directory.

## Migrate from `local.pickr`

1. Unregister the old local plugin; this preserves its source directory:

   ```sh
   herdr plugin unlink local.pickr
   ```

2. Link the updated checkout with `herdr plugin link "$(pwd)"` from its root,
   or install the published repository:

   ```sh
   herdr plugin install javoscript/herdr-pickr
   ```

   If you already linked a checkout under the **new** ID, unlink that local
   registration before replacing it with a GitHub-managed install:

   ```sh
   herdr plugin unlink javoscript.herdr-pickr
   herdr plugin install javoscript/herdr-pickr
   ```

3. Replace `local.pickr.` with `javoscript.herdr-pickr.` in your action references
   and keybindings. The five action suffixes are unchanged; use the complete
   examples above. There is no legacy-ID alias.
4. Run `herdr server reload-config` or choose **reload config** in Herdr's global
   menu, then invoke `javoscript.herdr-pickr.tabs-current` from inside Herdr.

To roll back, unregister the new ID, restore and link the prior checkout, restore
the old action references, and reload configuration. A GitHub-managed checkout can
be removed with `herdr plugin uninstall javoscript.herdr-pickr`; for a local checkout,
use `herdr plugin unlink javoscript.herdr-pickr`. The prior version still needs its
original external helpers, which this change does not remove.

## Dependencies

- **Herdr 0.9.0+** on macOS, as declared in the manifest. The plugin
  uses 0.9.0's snapshot, plugin popup/context, visible-screen, and pane-focus APIs.
- **Lua 5.3+**, available as `lua` on the PATH inherited by Herdr.
- **luv**, built for that same Lua interpreter and discoverable by `require("luv")`.
  A module built for another Lua version (or LuaJIT) is not interchangeable.
- **fzf 0.74.3+**, available as `fzf` on PATH. This is the supported baseline;
  older versions are outside the support range. Version 0.74.3 has been tested
  with the production options, including `--footer`, `--with-shell`, and
  independent-column filtering. Manual refresh also uses its Unix-socket
  `--listen` interface, `reload`, `load`/`result-final` events, `transform`,
  matching-ID file placeholders (`{*f1}`), `pos`, `unbind`/`rebind`,
  `change-header`/`change-footer`, and `refresh-preview` actions. These were
  verified with real interactive fzf 0.74.3. Later versions have not all been tested.
- **Git** for Herdr's GitHub installation and development cloning.

### macOS setup

With [Homebrew](https://brew.sh/) installed:

```sh
brew install herdr lua luv fzf git
```

Keep Homebrew's `lua` and `luv` together on PATH. If you use a different Lua
installation, install luv for that interpreter instead and run the load check below.

### Check the runtime

Run these in the environment from which you launch Herdr:

```sh
herdr --version
lua -v
lua -e 'local uv = require("luv"); print("luv loaded; libuv " .. uv.version_string())'
fzf --version
git --version
```

Herdr launches the manifest's `lua` command directly; installing dependencies
only in an unrelated shell environment will not make them available to the plugin.

## Picker behavior

Shortcut names in the behavior descriptions below are the defaults; configured
action keys replace them throughout the popup.

Herdr launches each picker in an 80% × 70% popup by default. The action passes its original
workspace through `PICKR_ORIGIN_WORKSPACE_ID`, which stays fixed when switching
variants. Direct plugin pane launches use `HERDR_PLUGIN_CONTEXT_JSON`; standalone
popup launches can still use `HERDR_ACTIVE_WORKSPACE_ID`.

- `herdr-plugin.toml`: five actions and popup entry points.
- `src/open.lua`: action launcher preserving the original workspace.
- `src/main.lua`: entry point and module paths (independent of current directory).
- `src/pickr/core.lua`: candidate lists, column alignment, themed rendering, selection.
- `src/pickr/config.lua`: configuration discovery, strict optional JSON loading,
  and launch-scoped settings handoff. Uses `HERDR_PLUGIN_CONFIG_DIR` when `HERDR_PLUGIN_ID` identifies
  Pickr; otherwise asks `HERDR_BIN_PATH` (or `herdr` on PATH) for
  `plugin config-dir javoscript.herdr-pickr`.
- `src/pickr/keymap.lua`: action defaults, replacement arrays, and key validation.
- `src/pickr/fzf_bindings.lua`: non-shell ambient option parsing and bounded
  navigation/editing/preview-scrolling binding import.
- `src/pickr/themes.lua` and `src/pickr/palettes.lua`: bundled Herdr 0.9.0 palettes
  and semantic RGB/ANSI/default color resolution; upstream attribution and license
  are included in the palette source and `src/pickr/vendor/HERDR-LICENSE`.
- `src/pickr/runtime.lua`: Herdr calls, invocation context, and direct `pane.focus` socket requests. This avoids
  Herdr 0.9.0's `agent.focus` client-navigation issue.
- `src/pickr/process.lua`: bundled subprocess runner with timeouts, using external luv.
- `src/pickr/vendor/json.lua`: rxi/json.lua 0.1.2, bundled from
  <https://github.com/rxi/json.lua/blob/master/json.lua>, with its MIT license
  retained in the file. JSON null metadata decodes to absent Lua fields; opt-in
  strict configuration decoding preserves null and array/object distinctions.
- `tests/configuration.lua`: isolated configuration, keymap, and theme fixtures,
  loaded by `tests/test.lua` without reading the user's settings.
- `tests/test.lua`: fixture, socket, and real-subprocess regression checks.
- `tests/fzf_bindings.lua` and `tests/themed_rendering.lua`: importer and shared
  theme rendering fixtures, loaded by the main Lua suite.
- `tests/documentation.lua`: configuration example and public inventory checks.
- `tests/relocation.lua`: automated distribution-only relocation regression.
- `tests/fzf_actions.lua`, `tests/fzf_compat.lua`, and `tests/pty_runner.lua`:
  Lua PTY checks against real fzf, using macOS's built-in `/usr/bin/script` and
  `/bin/stty` with luv. `tests/pty_runner_test.lua` checks terminal geometry,
  raw input/output, exit status, early exits, and failure/timeout cleanup.
  `tests/FZF_COMPATIBILITY.md` records the pinned grammar, source references,
  and supported action inventory. The main suite runs all these checks.
- `LICENSE`: project MIT license, Copyright (c) 2026 javoscript.

Project code is MIT-licensed under `LICENSE`. The bundled JSON library retains
its separate Copyright (c) 2020 rxi and full MIT notice in `src/pickr/vendor/json.lua`.
All Lua source dependencies are distributed with this repository; no parent-directory
Lua source files are needed.

The optional plugin `config.json` is read once by `src/open.lua`, before popup
creation, or by the picker owner for direct launches. The launcher passes resolved
settings through `PICKR_SETTINGS_SNAPSHOT`; variant switches and refresh rendering
receive the same settings. Preview/control helpers do not load the file. Missing
files use defaults; unreadable or invalid files block launch with a file/setting
diagnostic. Pickr never creates or edits this file. Close and reopen to adopt edits.

### Search prompt

All five variants default to exactly `"Search: "`, including the trailing space.
Set a global prompt in the optional plugin `config.json`:

```json
{ "prompt": { "default": "Find: " } }
```

Combine a global default with per-variant overrides:

```json
{
  "prompt": {
    "default": "Find: ",
    "variants": {
      "tabs_current": "Tabs: ",
      "tabs_all": null,
      "spaces": "Spaces: ",
      "agents_current": "",
      "agents_all": "Agents: "
    }
  }
}
```

The five supported names are `tabs_current`, `tabs_all`, `spaces`,
`agents_current`, and `agents_all`. A non-null variant override takes precedence
over the global value. Omitted or null `prompt`/`prompt.default` uses `"Search: "`;
omitted or null `prompt.variants` or individual variants inherit the resolved
global prompt. There are no built-in variant overrides. An empty string is an
intentional blank prompt, even when the global value is nonempty.

Text preserves all spaces, Unicode, quotes, and metacharacters exactly: no trimming,
added separator, shell evaluation, or fzf action evaluation. NUL, carriage return,
and newline are rejected. Wrong object/string types and unknown fields or variant
names block launch with a file/field diagnostic, including invalid settings for
inactive variants. Prompt color still follows the theme's `prompt` role.

Switching selects the destination's prompt from the same launch settings and
resets the query. Refresh loading, success, failure, and retry retain the active
prompt and preserve the query. Close and reopen to adopt configuration edits,
including edits made between popup launch and picker startup.

To restore the previous appearance globally:

```json
{ "prompt": { "default": "◉/> " } }
```

### Popup action keys

The optional `keys` object maps actions to arrays of fzf key names:

| Action | Default keys |
| --- | --- |
| `accept` | `["enter"]` |
| `close` | `["esc", "ctrl-c"]` |
| `toggle_preview` | `["ctrl-p"]` |
| `refresh` | `["ctrl-l"]` |
| `tabs_current` | `["ctrl-r"]` |
| `tabs_all` | `["ctrl-t"]` |
| `spaces` | `["ctrl-s"]` |
| `agents_current` | `["ctrl-a"]` |
| `agents_all` | `["ctrl-g"]` |

For example:

```json
{
  "keys": {
    "accept": ["alt-v", "alt-w"],
    "close": ["alt-x"],
    "refresh": ["alt-r", "alt-t"]
  }
}
```

Arrays replace the corresponding defaults. Omitted or null settings keep defaults.
`accept` and `close` require at least one key. An empty array disables any other
action's shortcut and removes its hints; external Herdr actions remain available.
Unsupported keys, events, action expressions, and conflicting effective aliases
(such as `enter` and `ctrl-m`) block launch with a setting diagnostic.
Footer hints show configured aliases in two groups: switch, close, preview, and
refresh on the first row; variant shortcuts on the second. Disabled actions are
omitted, and disabling all variant shortcuts removes the second row. Long rows
are clipped by fzf at the available width rather than wrapped; widening the popup
reveals the retained text. Empty candidate lists prefix `no entries` to the first
row; a search with zero matches does not add that prefix. Refresh
disables every acceptance and refresh alias while loading, restores refresh after
failure, and restores both after successful publication. Close and enabled
preview/variant controls remain available. Reopen to adopt key edits.

### Popup dimensions

In the `config.json` directory printed by
`herdr plugin config-dir javoscript.herdr-pickr`, configure dimensions independently:

```json
{
  "popup": { "width": "90%", "height": 30 }
}
```

`popup.width` defaults to `"80%"` and `popup.height` to `"70%"`.
Omitted or null values retain the corresponding default. Each accepts an integer
percentage string from `"1%"` through `"100%"`, or a nonnegative integer cell count.
Pickr caps cell counts above 65535 at 65535 before sending them to Herdr.
Cell counts include the outer border; Herdr clamps requests to its minimum size
and available terminal area. Unknown fields, wrong types, negative, non-finite or
fractional counts, and malformed or out-of-range percentages block launch with a
field diagnostic.

All five actions and `src/open.lua` send these dimensions through the
`plugin.pane.open` socket API. Herdr attaches the popup to its active pane; the
original workspace and settings snapshot are passed through the popup environment.
Switching and refreshing keep the same popup geometry; close and reopen to adopt
edits. Direct `herdr plugin pane open` launches retain the manifest's 80% × 70%
defaults, and direct `src/main.lua` invocations use the existing terminal without
resizing it. Automated socket and validation checks pass. The user confirmed live
default, percentage, cell-count, and oversized-count clamping behavior passes,
along with switching/refresh geometry preservation and reopening to adopt edits.

### Initial preview visibility

To start each variant with its preview hidden, put this partial configuration in
`config.json` inside the directory printed by
`herdr plugin config-dir javoscript.herdr-pickr`:

```json
{
  "preview": { "enabled_by_default": false },
  "keys": { "toggle_preview": ["ctrl-p", "f2"] }
}
```

`preview.enabled_by_default` defaults to `true`; omitted or null values retain
that default. Nonboolean values and unknown preview settings are errors. Every
new popup session starts with the configured visibility. Variant switches,
refresh, and retry preserve the current toggled visibility. Closing discards that
session state; reopening starts from the configured default again.
`keys.toggle_preview` replaces the default `["ctrl-p"]`; every alias appears in
the footer. An empty array disables the toggle and removes its hint. Close and
reopen to adopt edits. User-verified live Herdr acceptance passed for both initial
states, toggled-state preservation across switches (including empty/zero-match
lists, loading, and failure), refresh/retry, and resetting on reopen.

### Inherited fzf bindings

Pickr reads `--bind VALUE` and `--bind=VALUE` from `FZF_DEFAULT_OPTS_FILE` first,
then `FZF_DEFAULT_OPTS`. Later assignments replace earlier bindings on the same
effective key; a leading `+` appends to its earlier explicit chain. Pickr's action
keys and owner-controlled events take precedence. A released Pickr key may regain
an inherited editing/navigation binding.

The following argument-free actions and their ordered chains are supported:

- Navigation: `up`, `down`, `up-match`, `down-match`, `first`, `top`, `last`,
  `best`, `page-up`, `page-down`, `half-page-up`, `half-page-down`, `offset-up`,
  `offset-down`, `offset-middle`.
- Query editing: `beginning-of-line`, `end-of-line`, `backward-char`,
  `forward-char`, `backward-word`, `forward-word`, `backward-subword`,
  `forward-subword`, `backward-delete-char`, `delete-char`, `clear-query`,
  `kill-line`, `kill-word`, `kill-subword`, `backward-kill-word`,
  `backward-kill-subword`, `unix-line-discard`, `line-discard`,
  `unix-word-rubout`, `word-rubout`, `yank`.
- Preview scrolling: `preview-top`, `preview-bottom`, `preview-up`,
  `preview-down`, `preview-page-up`, `preview-page-down`,
  `preview-half-page-up`, `preview-half-page-down`.
- No-op: `ignore`.

For example, an existing fzf option `--bind 'alt-j:down,alt-k:up'` works in Pickr
when those keys are unclaimed. General fzf bindings belong in these ambient
sources; the Pickr JSON `keys` object configures Pickr actions only.

Quoting, comments, separator keys, and action-chain parsing follow fzf 0.74.3;
configuration text is never evaluated through a shell. A whole effective binding
is excluded if it contains an unsupported action or uses an event. This includes
`execute`, `accept`, `abort`, `reload`, `transform`, preview visibility changes,
and `/eof` editing actions. An excluded later assignment does not revive an older
assignment. Other supported bindings still apply. Malformed bindings, malformed
option sources, and unreadable option files also produce non-blocking diagnostics.
Malformed sources are skipped; other sources can still contribute bindings.

Unrelated ambient options (including output format, preview commands, color,
selection, and listen settings) are ignored. `FZF_DEFAULT_OPTS`,
`FZF_DEFAULT_OPTS_FILE`, and `FZF_API_KEY` are removed from the fzf child's
environment; imported bindings are passed explicitly. This preserves Pickr's
search, configured preview visibility, selection protocol, and refresh lifecycle.

Bindings are imported once into the launch settings snapshot. Close and reopen
to adopt edits to either ambient source. `Pickr fzf:` diagnostics identify the
source and excluded key/event/action; blocking Pickr configuration errors use
`Pickr:` and identify the file/setting. Action-launch diagnostics are available via:

```sh
herdr plugin log list --plugin javoscript.herdr-pickr --limit 5
```

### Themes and semantic color overrides

**The default is now Catppuccin (Mocha)**, independently of the active Herdr
client theme. To retain the previous Rosé Pine appearance:

```json
{ "theme": { "name": "rose-pine" } }
```

The bundled Herdr 0.9.0 theme names are `catppuccin`, `catppuccin-latte`,
`terminal`, `tokyo-night`, `tokyo-night-day`, `dracula`, `nord`, `gruvbox`,
`gruvbox-light`, `one-dark`, `one-light`, `solarized`, `solarized-light`,
`kanagawa`, `kanagawa-lotus`, `rose-pine`, `rose-pine-dawn`, and `vesper`.
They require no runtime network access. `terminal` uses ANSI colors and terminal
foreground/background defaults rather than a fixed RGB palette.

Override individual roles while retaining the rest of the selected palette:

```json
{
  "theme": {
    "name": "catppuccin",
    "custom": {
      "annotation": "#abc",
      "status_blocked": "rgb(255, 120, 140)",
      "preview_border": "lightblue"
    }
  }
}
```

Supported roles: `background`, `foreground`, `selected_background`,
`selected_foreground`, `match`, `selected_match`, `info`, `marker`, `prompt`,
`spinner`, `pointer`, `header`, `footer`, `border`, `label`, `preview_background`,
`preview_foreground`, `preview_border`, `annotation`, `status_blocked`,
`status_done`, `status_working`, `status_idle`, and `status_unknown`.

Color values support `#RGB`, `#RRGGBB`, and `rgb(r,g,b)` with integer components
from 0 through 255. ANSI names are `black`, `red`, `green`, `yellow`, `blue`,
`magenta`/`purple`, `cyan`, `white`, `gray`/`grey`, `darkgray`/`darkgrey`,
`lightred`, `lightgreen`, `lightyellow`, `lightblue`, `lightmagenta`, and
`lightcyan`. Case and surrounding whitespace are normalized. `reset`, `default`,
`none`, and `transparent` all mean terminal-default color, not alpha blending.
Omitted or null roles retain the selected palette's value; unknown names/roles or
invalid colors block launch with a file/setting diagnostic.

Initial and refreshed rows share the same roles, including status dots, headers,
and pane/worktree annotations. Preview chrome uses its corresponding roles while
captured terminal ANSI colors are preserved. Themes do not affect text, alignment,
ordering, filtering, or focus/preview targets. Close and reopen to adopt edits.

Lua changes apply on the next launch. Herdr configuration reload is needed only
when changing external Herdr launch bindings.
The refresh control socket belongs to a unique private picker-session directory.

Agent pickers match Herdr 0.9.0's priority
order: blocked, done (unseen completion), working, idle, unknown. Within each
status, the latest `state_change_seq` comes first; exact ties keep the API's
workspace/tab/pane layout order. Missing sequences default to zero and missing
or unrecognized statuses use unknown priority. Fuzzy searching filters agents
without reordering them (`fzf --no-sort`).

All entries start with Herdr-style indicators using the resolved status roles:
`●` for blocked, done, and working, `○` for idle, and `·` for unknown.
Status text remains searchable.

Each launch reads one `herdr api snapshot`. Workspace and tab indicators use
Herdr's server-computed `agent_status`: the highest-attention pane across all
tabs in a workspace, or all panes in a tab, respectively. Unseen idle panes count
as done; an empty/all-unknown collection is unknown. Workspace and tab ordering
is independent of status.

Spaces follow Herdr's expanded-sidebar order with all worktree groups expanded.
Spaces sharing `worktree.repo_key` are grouped when the parent checkout is
present: the group appears at its first member's original position, with the
parent first and children in their original relative order. Spaces without a
parent present retain their original ordering.
Worktree space names include their parent in brackets wherever a space name
is displayed, provided their parent space is present: `release [subscription-api]`.
Parent annotations and the `└─` prefix use the `annotation` role (`#524f67`
with explicit `rose-pine`).
Spaces and all-spaces tabs also keep the `└─` prefix. All-spaces agents omit
the prefix because priority sorting can separate children from their parents.
Parent spaces and orphan worktrees keep their original names.
Sibling worktree names are padded so their `[parent]` annotations align within
each repository group, consistently wherever space names are displayed.

The all-spaces tabs picker follows that same space order, preserving tab order
within each space. Both spaces and all-spaces tabs use `--no-sort`, so searching
filters entries without rearranging the groups. Matching worktree children
remain selectable even if their parent does not match. The current-space tabs
picker keeps its original tab order and normal fuzzy relevance sorting.

The directory column for tabs uses the remembered focused pane from the tab's
layout, including inactive tabs. Spaces use that directory from their active
tab. Foreground CWD takes precedence over shell CWD; unavailable paths show `—`.
Home paths are abbreviated to `~`. Paths longer than 48 Unicode characters are
left-truncated with `…`, keeping their last 47 characters. Adjust
`DIRECTORY_LIMIT` in `src/pickr/core.lua` to change the cap.

## Column headers

Each list has a fixed, muted, lowercase header (`fzf --header-lines=1`). Headings
participate in the same width calculation as entries, so columns align even when
a heading is wider than its values. The header is not searchable or selectable,
and remains present for empty lists. Hidden ID placeholders keep the preview and
selection fields consistent.

| Picker | Columns |
| --- | --- |
| Spaces | status · space · tabs · directory |
| Current-space tabs | status · tab · panes · directory |
| All-spaces tabs | status · space · tab · panes · directory |
| Current-space agents | status · tab · agent · title · pane [label] |
| All-spaces agents | status · space · tab · agent · title · pane [label] |

Columns follow the shared relative order: status, space, tab, agent, title, pane,
directory. Each picker includes only its existing columns; the count headings
`tabs` and `panes` retain their names and occupy the tab and pane positions.

Both agent pickers show labeled panes as `pane-id [label]` in the `pane [label]` column.
The bracketed label, including `[label]` in the header, uses the same `annotation`
role as worktree parent annotations. Panes with missing or empty labels show only their pane ID.
Labels remain searchable within the pane column; previews and selection target
the underlying pane ID.

Action hints remain on the first footer row and variant hints on the second,
using the grouping described under [Popup action keys](#popup-action-keys).

## Searching

Each space-separated search term fuzzy-matches within an individual column.
A term cannot start in one column and finish in another. Different terms can
match different columns: with `alpha` and `beta` in separate columns, `abt`
does not match, but `alp bet` does. All visible columns remain searchable,
including status text, parent-space annotations, pane labels, and the displayed directory.
Standard fzf extended-search syntax (exact matches, negation, and OR) still works.

The column separators are included in fzf's delimiter, and `--nth` lists each
displayed field individually; a range would combine fields for matching.

## Switching picker variants

These shortcuts work inside every picker, including when there are no entries
or no search matches:

| Shortcut | Destination |
| --- | --- |
| Ctrl+R | Tabs in the current space |
| Ctrl+T | Tabs in all spaces |
| Ctrl+S | Spaces |
| Ctrl+A | Agents in the current space |
| Ctrl+G | Agents in all spaces |

Switching stays within the same Herdr popup and fetches fresh candidates. The
search query resets and the preview retains its current visibility. Current-space variants use
the space where the popup was opened. Only configured acceptance keys (Enter by
default) focus a selected entry;
switching variants does not change the active space, tab, or pane.

Ctrl+T and Ctrl+G replace the originally proposed Ctrl+Shift+R and Ctrl+Shift+A,
which the installed fzf does not support. These are popup-local bindings.
Hints appear in a muted, lowercase footer at the bottom of every picker. The first
row contains switch, close, preview, and refresh. The second contains tabs here,
all tabs, spaces, agents here, and all agents, including the current variant.
Disabled shortcuts are omitted; if all variant shortcuts are disabled, only the
first row remains. Configured aliases stay in their assigned row, with long rows
clipped rather than wrapped.

## Refreshing an open picker

Press **Ctrl+L** in any of the five variants, including an empty list or a search
with no matches. Each refresh fetches one complete `herdr api snapshot`, keeping
the current variant and the popup's original workspace scope. Membership, labels,
statuses, counts, directories, column widths, and preview targets update together
using the same formatting and ordering as the initial list. Refresh never focuses
an entity and does not run periodically.

During fetching and preparation:

- Old candidates are cleared and **Refreshing…** appears above the column header.
- Enter is disabled; pressing it does not accept later when results arrive.
- Your query stays editable, Ctrl+P still toggles the preview, and completion
  preserves the current query and preview visibility.
- Escape/Ctrl+C and all variant shortcuts remain available. Closing or switching
  cancels the pending request and removes the source session's temporary resources.
- Additional Ctrl+L presses are ignored until the current attempt finishes.

Once matching completes, the highlight returns to the same pane, tab, or workspace
ID if it still matches, even if its label or priority position changed. Otherwise
the first matching result is highlighted, or no result if nothing matches. Enter
then focuses the refreshed entity. Tab and space previews use their refreshed
remembered pane, even when the selected tab/space ID stays the same.

A failed fetch, invalid response, 10-second fetch timeout, or row-rendering failure
shows **Refresh failed — Ctrl+L to retry**, with no stale selectable candidates.
Enter remains disabled. Retry keeps the query, preview visibility, and the entity
ID saved before the failed attempt. Switching variants still resets the query
and opens the destination with its current preview visibility preserved.

## Visible-screen preview

When enabled, all five pickers show a bordered preview on the right, using half of the popup.
Move the highlighted selection to fetch a fresh visible-screen snapshot in ANSI
color. **Ctrl+P** toggles the preview. Long screen lines are clipped rather than
wrapped; this preview does not resize or focus the underlying pane.

- Agents preview their own pane.
- Tabs preview their remembered focused pane.
- Spaces preview the focused pane in their active tab.

The header shows the pane ID and full directory (without the list's truncation).
Empty screens and unavailable/closed panes display a short message. The preview
refreshes on selection changes and successful manual refresh; it is not a continuously streaming terminal.

Rows contain two hidden tab-separated fields: the selection ID and preview pane
ID. fzf displays the remaining columns and searches each independently, passing the shell-quoted preview
ID to `src/main.lua preview <pane-id>`. The preview uses read-only `pane get` and
`pane read --source visible --ansi --raw` calls. Preview targets come from the
same successful snapshot generation as the list.

## Regression checks

From the repository root, run:

```sh
lua tests/test.lua
```

Tests use fixture data and temporary local sockets rather than focusing live
panes. They exercise the installed `fzf` in filter mode and keyboard-driven
pseudo-terminal sessions. All test code is Lua; no Python installation is needed.
The PTY checks use macOS's built-in `/usr/bin/script` and `/bin/stty` to provide
a controlling terminal, with luv driving the input, output, and timeouts.

The Lua suite verifies all 25 source/destination routes, refresh session states,
captured-original-workspace scoping, and asynchronous subprocess cancellation.
Live Herdr integration and visual appearance require separate acceptance checks
in the picker. The real-fzf checks run as part of `lua tests/test.lua`, or can be
run individually:

```sh
lua tests/pty_runner_test.lua
lua tests/fzf_actions.lua
lua tests/fzf_compat.lua
```

This checks remapped acceptance aliases and closing across all five variants with
all optional actions disabled, including guards against built-in lifecycle keys.
It uses fixture candidates and never focuses live Herdr panes.

For an isolated relocation check, copy `src/`, `tests/`, `herdr-plugin.toml`,
`LICENSE`, `README.md`, and `AGENTS.md` into a fresh `Herdr Pickr/` directory.
Create an empty sibling `caller/` directory; include no old root scripts or
parent Lua helpers. From `caller/`, run:

```sh
env -i HOME="$HOME" PATH="$PATH" TMPDIR=/tmp TERM=xterm-256color lua "../Herdr Pickr/tests/test.lua"
```

This excludes ambient Lua source-path and initialization overrides while checking
paths with spaces and an unrelated working directory.

The automated equivalent creates and removes its own temporary distribution copy:

```sh
lua tests/relocation.lua
```

### Search prompt live acceptance

With fzf 0.74.3+ inside Herdr:

1. Reopen without a prompt override and check `"Search: "` in all five variants.
2. Reopen with mixed global/variant overrides and null inheritance. Switch between
   variants, including empty lists and zero matches; confirm each destination's
   prompt and query reset.
3. Check exact trailing spaces and an empty variant prompt using the example above.
4. Refresh through loading, success, failure, and retry. Confirm the active prompt
   remains unchanged and the query is preserved.
5. Edit the global prompt and a variant while open. Confirm switching and refreshing
   retain the original settings, then close/reopen and confirm both edits apply.

Record environment and actual outcomes under Compatibility verification.

### Two-row footer live acceptance

With fzf 0.74.3+ inside Herdr, reopen the picker after code or configuration edits:

1. Open all five variants at sufficient width. Confirm switch, close, preview, and
   refresh occupy the first footer row and all five variant shortcuts the second.
2. Narrow and widen the popup/terminal. Confirm clipping without additional rows
   and recovery of the full hints at sufficient width.
3. Reopen with long/remapped alias arrays and disabled optional controls. Confirm
   every alias remains in its assigned group, removed defaults and disabled hints
   are absent, and disabling all variant shortcuts leaves one row.
4. Check empty candidate lists (`no entries` on row one) and a nonempty list with
   zero search matches (no added prefix).
5. Refresh through loading, success, failure/retry, and empty/nonempty transitions;
   switch variants as well. Confirm stable hint grouping, an updated empty-list
   prefix after publication, and refresh/retry messages in the status area.

Record the environment and actual outcomes under Compatibility verification;
automated Lua checks alone do not establish live visual acceptance.

## Compatibility verification

Supported minimums are listed under [Dependencies](#dependencies).

### Configurable search prompt checks (2026-09-11)

Environment: macOS 26.6.2 (25G83); Herdr 0.9.0; Lua 5.5.1;
fzf 0.74.3 (Homebrew).

| Check | Result |
| --- | --- |
| `lua tests/test.lua` | Passed: prompt defaults/inheritance, exact empty/literal argv, all five variants and 25 switching routes (including empty/zero-match fixtures), validation diagnostics, frozen snapshots/reopening, refresh failure/retry settings, existing configuration/preview/socket/subprocess regressions, real-fzf PTY checks, and README JSON examples. |
| `git diff --check` | Passed. |
| Live search prompt acceptance | User-confirmed pass on 2026-09-11 for the [search prompt checklist](#search-prompt-live-acceptance): defaults in all five variants, mixed overrides/inheritance, trailing spaces and empty prompts, switching with query reset, refresh/failure/retry with prompt and query preservation, and reopening to adopt edits. |

### Two-row footer checks (2026-09-11)

Environment: macOS 26.6.2 (25G83); Herdr 0.9.0; Lua 5.5.1; fzf 0.74.3.

| Check | Result |
| --- | --- |
| Direct Lua footer checks | Passed: exact default rows, empty-list prefix, long/remapped aliases, disabled hints, and one-row fallback with all optional controls disabled. |
| `lua tests/test.lua` | Passed: existing configuration, aliases, disabled controls, all 25 switching routes, refresh, rendering, socket/subprocess, and documentation checks. |
| Shared rendering paths | Confirmed initial `--footer` and successful refresh publication use the same keymap footer renderer. |
| Live footer acceptance | User sign-off received on 2026-09-11 after the [live acceptance checklist](#two-row-footer-live-acceptance) was provided; user requested completion and archival. |

### Configurable keys and themes checks (2026-09-11)

Environment: macOS 26.6.2 (25G83); Herdr 0.9.0; Lua 5.5.1;
Homebrew luv 1.52.1-0 (libuv 1.52.1); fzf 0.74.3;
Git 2.50.1 (Apple Git-155).

| Check | Result |
| --- | --- |
| `lua tests/test.lua` | Passed: configuration/discovery/snapshots, keymaps/importer, palettes/roles, themed rows and refreshes, JSON documentation examples, existing socket/subprocess/filter/ordering/label scenarios. |
| `lua tests/fzf_compat.lua` | Passed against real fzf: source precedence, replacement/append behavior, tokenization, supported action inventory, aliases, separators, and chains. |
| `lua tests/fzf_actions.lua` | Passed against real fzf: both remapped acceptance aliases and closing across five variants with optional actions disabled; lifecycle guards, released Enter navigation, inherited editing and preview scrolling, Pickr precedence, and ambient output/event isolation. |
| `lua tests/pty_runner_test.lua` | Passed: Lua-only controlling-terminal harness, 30 × 100 geometry, raw stdin/stdout, command exit status, early-exit detection, launch failure, timeout cleanup, and recovery. |
| Isolated relocation | Passed via `tests/relocation.lua`, copying only the distributed files to `Herdr Pickr/`, running the suite from sibling `caller/` under `env -i`, and removing the temporary copy. No parent source files or runtime network access were required. |
| Live preview and popup geometry | User-confirmed pass, including preview state across switches/refresh/retry and reopening, percentage/cell dimensions, and oversized-count clamping. |
| Live configured action keys | User-confirmed pass for alias hints, remapped controls, refresh gating, close/switch during refresh, and failure/retry preservation. |
| Final inherited-binding and theme inspection | User sign-off received after the final checklist covering inherited controls, contrast, annotations, captured preview ANSI colors, and reopen-to-adopt edits. |

### Source reorganization checks (2026-09-11)

Environment: macOS 26.6.2 (25G83), arm64; Herdr 0.9.0; Lua 5.5.1;
Homebrew luv 1.52.1-0 (libuv 1.52.1); fzf 0.74.3 (Homebrew);
Git 2.50.1 (Apple Git-155).

| Check | Result |
| --- | --- |
| Syntax checking with `luac -p` | All seven relocated Lua files passed. |
| Repository-root `lua tests/test.lua` | Full suite passed: five action-launcher fixtures, all 25 switching routes, preview subprocess, refresh-session, async-process, and socket scenarios. |
| Isolated `Herdr Pickr/` distribution copy, launched from sibling `caller/` | Full suite passed with the clean-environment command under Regression checks, using only `src/`, `tests/`, the manifest, and distribution documents. |
| Vendored JSON | Git blob hash matches the pre-move file exactly, preserving its copyright and MIT notice. |
| `herdr plugin link "$(pwd)"` | Succeeded; registered all five actions with `src/open.lua` and all five panes with `src/main.lua`. |
| Interactive Herdr acceptance | User-verified pass: all five qualified actions and direct pane entrypoints, existing keybindings, current/all-space scope, previews/Ctrl+P, Ctrl+L refresh/control subprocesses, variant switching with preserved origin, and Enter/Escape behavior. |

Interactive refresh/control subprocess behavior was verified by the user separately
from the automated fixtures. The historical results below belong to the earlier layout.

### Historical publication checks (before source reorganization)

These are the observed results from publication preparation on 2026-09-11, using
the former root-level source layout. They do not verify the reorganized layout:

| Environment | Dependencies | Result |
| --- | --- | --- |
| macOS 26.6.2, arm64, working checkout | Herdr 0.9.0; Lua 5.5.1; Homebrew luv 1.52.1-0 (libuv 1.52.1); fzf 0.74.3 | `lua test.lua` passed, including production fzf options and column filtering. |
| Same macOS environment, isolated source copy in a path with spaces | Same dependencies; clean environment | Full regression suite passed, including all five launcher assertions, invocation context, column filtering, all 25 switching routes, preview subprocess, refresh-session/async-process checks, and pane-focus socket scenarios. |
| macOS 26.6.2, isolated checkout with spaces in its path, interactive Herdr checks | Herdr 0.9.0; Lua 5.5.1; Homebrew luv 1.52.1-0; fzf 0.74.3 | User-verified pass: all five qualified actions, current/all-space scoping, previews and Ctrl+P, Escape/Ctrl+C cancellation without focus changes, Enter selection for tabs/spaces/agents, variant switching with preserved origin (including another space highlighted and no matches), and direct current-space tabs/agents entrypoint context. |
| Linux | Unsupported; not tested | Support deferred to a follow-up with a suitable Linux environment, isolated regressions, the same interactive checks as macOS, recorded versions/outcomes, and setup instructions. |

That historical isolated copy contained `main.lua`, `open.lua`, `core.lua`, `runtime.lua`,
`test.lua`, `herdr-plugin.toml`, `LICENSE`, `README.md`, and `lib/`. It was placed
in `Herdr Pickr/` alongside an empty `caller/` directory under a fresh temporary
parent, with no parent shared helpers. From `caller/`, the successful command was:

```sh
env -i HOME="$HOME" PATH="$PATH" TMPDIR=/tmp TERM=xterm-256color lua "../Herdr Pickr/test.lua"
```

This excludes ambient Lua source-path and initialization overrides. The fixture
socket uses a short, unique `/tmp/pickr-test-XXXXXX/` directory, removed after the
socket scenarios, so long checkout paths do not exceed Unix-socket path limits.
This resolves the initial isolated-run socket binding failure. Fixture checks do
not establish interactive Herdr compatibility or Linux compatibility.
