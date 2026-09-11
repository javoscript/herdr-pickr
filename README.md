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
`s`, `a`, or Shift+A. Popup dimensions come from the plugin manifest.
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

Herdr launches each picker in an 80% × 70% popup. The action passes its original
workspace through `PICKR_ORIGIN_WORKSPACE_ID`, which stays fixed when switching
variants. Direct plugin pane launches use `HERDR_PLUGIN_CONTEXT_JSON`; standalone
popup launches can still use `HERDR_ACTIVE_WORKSPACE_ID`.

- `herdr-plugin.toml`: five actions and popup entry points.
- `src/open.lua`: action launcher preserving the original workspace.
- `src/main.lua`: entry point and module paths (independent of current directory).
- `src/pickr/core.lua`: candidate lists, column alignment, Rosé Pine theme, selection.
- `src/pickr/runtime.lua`: Herdr calls, invocation context, and direct `pane.focus` socket requests. This avoids
  Herdr 0.9.0's `agent.focus` client-navigation issue.
- `src/pickr/process.lua`: bundled subprocess runner with timeouts, using external luv.
- `src/pickr/vendor/json.lua`: rxi/json.lua 0.1.2, bundled from
  <https://github.com/rxi/json.lua/blob/master/json.lua>, with its MIT license
  retained in the file. JSON null metadata decodes to absent Lua fields.
- `tests/test.lua`: fixture, socket, and real-subprocess regression checks.
- `LICENSE`: project MIT license, Copyright (c) 2026 javoscript.

Project code is MIT-licensed under `LICENSE`. The bundled JSON library retains
its separate Copyright (c) 2020 rxi and full MIT notice in `src/pickr/vendor/json.lua`.
Both helper files are distributed with this repository; no parent-directory
Lua source files are needed.

Global `FZF_DEFAULT_OPTS`, `FZF_DEFAULT_OPTS_FILE`, and `FZF_API_KEY` are excluded so these
pickers always start with search and the built-in preview enabled. Configuration reload
is only needed when changing bindings; Lua changes apply on the next launch.
The refresh control socket belongs to a unique private picker-session directory.

All pickers use the `◉/>` prompt. Agent pickers match Herdr 0.9.0's priority
order: blocked, done (unseen completion), working, idle, unknown. Within each
status, the latest `state_change_seq` comes first; exact ties keep the API's
workspace/tab/pane layout order. Missing sequences default to zero and missing
or unrecognized statuses use unknown priority. Fuzzy searching filters agents
without reordering them (`fzf --no-sort`).

All entries start with Herdr-style indicators in the picker's fixed Rosé Pine
palette: love/red `●` for blocked, foam/teal `●` for done, gold `●` for working,
pine `○` for idle, and muted `·` for unknown. Status text remains searchable.

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
Parent annotations and the `└─` prefix use a subdued Rosé Pine gray (`#524f67`).
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
The bracketed label, including `[label]` in the header, uses the same subdued gray (`#524f67`) as worktree parent
annotations. Panes with missing or empty labels show only their pane ID.
Labels remain searchable within the pane column; previews and selection target
the underlying pane ID.

The two bottom hint lines remain in the footer.

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
search query resets and the preview starts visible. Current-space variants use
the space where the popup was opened. Only Enter focuses a selected entry;
switching variants does not change the active space, tab, or pane.

Ctrl+T and Ctrl+G replace the originally proposed Ctrl+Shift+R and Ctrl+Shift+A,
which the installed fzf does not support. These are popup-local bindings.
Action and variant-switching hints appear in a muted, lowercase footer at the
bottom of every picker.

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
and opens the destination with its preview visible.

## Visible-screen preview

All five pickers show a bordered preview on the right, using half of the popup.
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

Tests use fixture data and a temporary local socket rather than focusing live
panes. They also exercise the installed `fzf` in noninteractive filter mode.

The Lua suite verifies all 25 source/destination routes, refresh session states,
captured-original-workspace scoping, and asynchronous subprocess cancellation.
Interactive refresh behavior requires separate acceptance checks in the picker;
the temporary PTY harness used during implementation has been removed.

For an isolated relocation check, copy `src/`, `tests/`, `herdr-plugin.toml`,
`LICENSE`, `README.md`, and `AGENTS.md` into a fresh `Herdr Pickr/` directory.
Create an empty sibling `caller/` directory; include no old root scripts or
parent Lua helpers. From `caller/`, run:

```sh
env -i HOME="$HOME" PATH="$PATH" TMPDIR=/tmp TERM=xterm-256color lua "../Herdr Pickr/tests/test.lua"
```

This excludes ambient Lua source-path and initialization overrides while checking
paths with spaces and an unrelated working directory.

## Compatibility verification

Supported minimums are listed under [Dependencies](#dependencies).

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
