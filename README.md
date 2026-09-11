# Pickr

Local Herdr plugin using Lua 5.3+, `luv`, and `fzf` from PATH. Shared process
and JSON libraries live in `../../lib`; keep this plugin at `plugins/pickr`.
Herdr launches each picker in an 80% × 70% popup. The action passes its original
workspace through `PICKR_ORIGIN_WORKSPACE_ID`, which stays fixed when switching
variants. Direct plugin pane launches use `HERDR_PLUGIN_CONTEXT_JSON`; standalone
popup launches can still use `HERDR_ACTIVE_WORKSPACE_ID`.

```sh
herdr plugin link "$HOME/.config/herdr/plugins/pickr"
herdr plugin action invoke local.pickr.tabs-current
herdr plugin action invoke local.pickr.tabs-all
herdr plugin action invoke local.pickr.spaces
herdr plugin action invoke local.pickr.agents-current
herdr plugin action invoke local.pickr.agents-all
```

Configured shortcuts (after Ctrl+B): `r` for current-space tabs, Shift+R for
all-space tabs, `s` for spaces, `a` for current-space agents, and Shift+A for
all-space agents. They invoke plugin actions; popup dimensions live in the manifest.
After changing the manifest, relink the plugin. Lua edits apply on the next launch.
Disable with `herdr plugin disable local.pickr`; unregister without deleting source
files with `herdr plugin unlink local.pickr`.

- `herdr-plugin.toml`: five actions and popup entry points.
- `open.lua`: action launcher preserving the original workspace.
- `main.lua`: entry point and module paths (independent of current directory).
- `core.lua`: candidate lists, column alignment, Rosé Pine theme, selection.
- `runtime.lua`: Herdr calls, invocation context, and direct `pane.focus` socket requests. This avoids
  Herdr 0.9.0's `agent.focus` client-navigation issue.
- `../../lib/process.lua`: shared subprocess runner with timeouts.
- `../../lib/vendor/json.lua`: rxi/json.lua 0.1.2, bundled from
  <https://github.com/rxi/json.lua/blob/master/json.lua>, with its MIT license
  retained in the file. JSON null metadata decodes to absent Lua fields.

Global `FZF_DEFAULT_OPTS` and `FZF_DEFAULT_OPTS_FILE` are excluded so these
pickers always start with search and the built-in preview enabled. Configuration reload
is only needed when changing bindings; Lua changes apply on the next launch.

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
`DIRECTORY_LIMIT` in `core.lua` to change the cap.

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
| All-spaces tabs | status · tab · space · panes · directory |
| Current-space agents | status · tab · agent · title · pane |
| All-spaces agents | status · space · tab · agent · title · pane |

The two bottom hint lines remain in the footer.

## Searching

Each space-separated search term fuzzy-matches within an individual column.
A term cannot start in one column and finish in another. Different terms can
match different columns: with `alpha` and `beta` in separate columns, `abt`
does not match, but `alp bet` does. All visible columns remain searchable,
including status text, parent-space annotations, and the displayed directory.
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
refreshes on selection changes; it is not a continuously streaming terminal.

Rows contain two hidden tab-separated fields: the selection ID and preview pane
ID. fzf displays the remaining columns and searches each independently, passing the shell-quoted preview
ID to `main.lua preview <pane-id>`. The preview uses read-only `pane get` and
`pane read --source visible --ansi --raw` calls. Preview targets come from the
same initial snapshot as the list.

Run the regression checks with:

```sh
lua "$HOME/.config/herdr/plugins/pickr/test.lua"
```

Tests use fixture data and a temporary local socket rather than focusing live
panes. They also exercise the installed `fzf` in noninteractive filter mode.
