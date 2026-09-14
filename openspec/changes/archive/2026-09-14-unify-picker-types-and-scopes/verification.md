# Implementation verification

## Environment

- Platform: macOS.
- Interpreter: Lua 5.5.
- libuv: 1.52.1, loaded through luv.
- fzf: 0.74.4 (Homebrew).
- Interactive checks used real fzf in the Lua PTY runner, with synthetic Herdr
  snapshots and fixture focus targets. The normal PTY geometry was 100 × 30;
  narrow/resize cases exercised 55 and 220 columns.

## Completed checks

| Command | Result |
| --- | --- |
| `lua tests/test.lua` | Passed the integrated configuration, candidate, protocol, launch, rendering, documentation, and real-fzf suites. |
| `lua tests/relocation.lua` | Passed the complete suite again using distributed files only, a checkout named `Herdr Pickr`, an unrelated caller directory, and a clean environment; temporary checkout removed. |
| `openspec validate unify-picker-types-and-scopes --strict` | Passed before and after main-spec synchronization. |
| `openspec validate --specs --strict` | All 10 main specs passed after synchronization; informational long-requirement notices only. |
| `git diff --check` | Passed. |

## Requirement evidence

- `tests/pickers.lua` checks all twelve chosen-scope/type combinations, all twelve
  presets, invalid explicit scopes, carried fallback, and session-specific
  expected-key inventories.
- `tests/configuration.lua`, `tests/unified_configuration.lua`, and
  `tests/fzf_bindings.lua` cover the eleven action defaults, aliases, required and
  disabled actions, Ctrl+C collisions, four-type prompts/columns, every removed
  leaf including null/mixed settings, inherited bindings, and version-2 handoffs
  with launch-snapshot lifetime preserved.
- `tests/pane_launch.lua` checks all twelve action and owner routes, manifest
  geometry versus configured action geometry, changed startup focus, legacy
  scope diagnostics, and unsupported pairs. The relocation run repeats these
  checks from a path containing spaces.
- `tests/origin.lua` and `tests/panes.lua` cover origin precedence, explicit absent
  tab, invalid workspace/tab membership, deleted origin, and a Spaces → Panes →
  This tab transition without recapturing changed ambient context.
- `tests/columns.lua` and `tests/themed_rendering.lua` exercise all nine effective
  type/scope combinations, default/reversed/single-column layouts, empty headers,
  annotations, stable space/tab matching in narrow scopes, and dark/light/terminal/
  custom theme behavior. Candidate text, ordering, and targeting remain stable.
- `tests/panes.lua` verifies Agents in This tab against pane metadata and known
  tab layouts, excluding cross-tab, ordinary, popup, orphan, and mismatched rows.
  Priority and exact-tie ordering are retained. Preview and acceptance target the
  exact agent pane through fixture Herdr calls.
- `tests/test.lua` covers all sixteen type-switch routes, independent type memory,
  literal queries, self-type transitions, popup isolation, preview sharing,
  acceptance maps, refresh generations, and subprocess/socket failure handling.
- `tests/fzf_actions.lua` and `tests/unified_fzf.lua` exercise real terminal keys,
  scope transitions, remaps, disabled actions, empty/zero matches, restoration,
  refresh/retry, cancellation, and controlled late callbacks.
- `tests/documentation.lua` validates every README JSON example, complete defaults,
  all twelve preset table entries, and confinement of removed names to migration
  guidance.

## Observed interactive outcomes

- Panes/This tab → Tabs → Spaces → Agents retained chosen This tab throughout,
  with effective This space, none, then This tab, and focused fixture pane `b`
  only on the final acceptance key.
- Selecting This space during Tabs' fallback changed the remembered preference
  without another list session. Repeated, already-chosen, and unsupported scope
  keys caused no list restart; Ctrl+C/Z/X in Spaces did not abort or suspend.
- Narrowing away from selected pane `a` selected `b`; broadening retained `b`.
  Ready zero matches cleared the previous restoration ID while preserving query.
- Loading/error transitions carried the latest query and recovery ID, preserved
  hidden preview state, cancelled old work, and rejected late callback results.
  Pending entry restoration gated acceptance until the fresh matching selection
  was ready. State-only fallback choices also worked while refresh was pending.
- With preview shown, vertical cursor tracking confirmed the actual screen order:
  scope choices, separate remembered-choice line, column heading, candidates.
  The remembered line remained visible at 100 columns. Long choice/footer rows
  clipped; widening revealed retained footer text without wrapping.
- Hidden hints removed footer/key text while retaining scope and remembered state.
  Header text never matched or became an acceptance target, including empty lists.
  Refresh failure/retry retained header state and restored exact preview targets.
- Punctuation key aliases survived combined header/footer refresh updates. Custom
  Ctrl+C closing worked only when its scope binding was explicitly disabled.

## Spec composition and limits

The memory prerequisite was synchronized before the pane prerequisite. This
change was synchronized last across its eight capabilities, adding `picker-scopes`
and preserving unrelated main requirements and existing scenarios. The changed
contracts agree with the four-type implementation and the approved separate
remembered-choice line.

These checks are automated real-fzf interactive runs, not a manual live-Herdr
session. Herdr focus/context behavior was checked with snapshots and socket
fixtures. Linux and the exact minimum Lua/fzf versions were not separately run.
The pre-existing macOS-only publication requirement versus the already-enabled
Linux manifest remains outside this change, as specified in its design.
