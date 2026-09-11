## Context

See proposal.md for motivation and scope. `core.lua` combines row styling, a key-indexed variant table, hardcoded footer text, and fzf options. `runtime.lua` owns refresh control, hardcodes Enter/Ctrl+L unbinding and rebinding, and assumes the current `--expect` output protocol. `fzf_env()` removes `FZF_DEFAULT_OPTS`, `FZF_DEFAULT_OPTS_FILE`, and `FZF_API_KEY`. The vendored JSON decoder maps null to absent Lua values. Tests assert literal bindings and Rosé Pine ANSI sequences.

Herdr 0.9.0 provides `HERDR_PLUGIN_CONFIG_DIR`; its plugin path code uses `<config-dir>/plugins/config/<plugin-id>`. The plugin owns the filename and format. The documented `herdr plugin config-dir <id>` command locates this directory. Herdr's theme configuration declares 18 names, with `catppuccin` as the default. The inspected plugin environment and installed API schema expose no effective client palette. Client theme and host terminal colors are separate concepts.

## Goals / Non-Goals

**Goals:** Resolve configuration once into explicit keymap and theme data shared by initial rendering, variant switching, refresh, and hints. Keep action semantics independent of physical keys and styling independent of status ordering or candidate identity. Preserve relocatable, dependency-light distribution.

**Non-Goals:** A general fzf option compatibility layer, arbitrary command bindings in Pickr JSON, active-client-theme discovery, live reload, status glyph customization, and a new TOML dependency.

## Decisions

### 1. Launch-scoped JSON configuration

Introduce `pickr.config` with injectable environment/file/Herdr lookup for tests. Prefer a nonempty `HERDR_PLUGIN_CONFIG_DIR` belonging to Pickr; when absent or associated with another plugin, ask the running Herdr binary for `plugin config-dir javoscript.herdr-pickr`. Do not derive paths from checkout location, caller CWD, or an unconditional HOME path. Distinguish discovery failure, missing file, and unreadable file.

For Pickr action launches and `src/open.lua`, resolve configuration once in the launcher before creating the popup. Pass the validated settings snapshot to the picker owner through an explicit launch handoff; the owner uses that snapshot rather than rereading the file. For direct Herdr pane launches and `src/main.lua`, resolve once in the picker owner before fetching candidates or opening fzf. Pass the resolved configuration through `M.pick` and every `pick_once`; refresh rendering closes over it. Preview/control subprocesses do not independently reread user settings. No automatic file creation or edits are needed. Reopening adopts edits; switching and refreshing retain the launch snapshot.

Concrete schema with default values:

```json
{
  "keys": {
    "accept": ["enter"],
    "close": ["esc", "ctrl-c"],
    "toggle_preview": ["ctrl-p"],
    "refresh": ["ctrl-l"],
    "tabs_current": ["ctrl-r"],
    "tabs_all": ["ctrl-t"],
    "spaces": ["ctrl-s"],
    "agents_current": ["ctrl-a"],
    "agents_all": ["ctrl-g"]
  },
  "theme": { "name": "catppuccin", "custom": {} },
  "preview": { "enabled_by_default": true },
  "popup": { "width": "80%", "height": "70%" }
}
```

Omitted or null settings retain their defaults; a supplied action array replaces its default keys. Only `accept` and `close` require nonempty arrays. For preview toggling, refresh, and the five variant-switching actions, `[]` disables the shortcut and removes its hints. Disabling a variant shortcut does not remove its external Herdr action. Preserve the distinction between omitted/null settings and empty arrays when validating decoded JSON.

`preview.enabled_by_default` is a boolean, defaulting to `true` when omitted or null. Resolve it in the same launch snapshot as keys and theme, and use it to initialize preview visibility only when opening a new popup session (or a new direct `src/main.lua` invocation). The configured preview toggle remains available in either initial state. Keep the current shown/hidden state as mutable popup-session state, separate from the immutable configuration snapshot. Carry that state through `M.pick` and every `pick_once`, keeping it synchronized with configured preview toggles before handing it to the destination variant. Variant switches, refresh, and retry preserve the current visibility, including switches during loading or after failure; switching still resets the query and preserves the original workspace. Reject unknown preview fields and nonboolean values through the same file/field diagnostic path. Closing discards the session's visibility state; reopening initializes it from the configured default again and adopts configuration edits.

`popup.width` and `popup.height` default independently to `"80%"` and `"70%"` when omitted or null. Accept nonnegative finite integer terminal-cell counts, or canonical integer percentage strings from `"1%"` through `"100%"`. Cap cell counts above 65535 at 65535 during configuration resolution so the launch snapshot uses Herdr 0.9.0-compatible dimensions. Counts describe the outer popup including its border. Herdr clamps the requested dimensions to its minimum size and available terminal area. Reject wrong types, negative, non-finite or fractional numbers, malformed or out-of-range percentages, and unknown popup fields with a file/field diagnostic before opening a popup.

Herdr 0.9.0's `plugin pane open` CLI has no width/height flags. Change `src/open.lua` to request `plugin.pane.open` through the existing Unix-socket transport, supplying plugin identity, entrypoint, popup placement, width, height, original-workspace environment, and the launch configuration handoff. Preserve request/reply validation, timeouts, and cleanup. The five existing actions continue to launch through this script. Direct `herdr plugin pane open` calls create the popup before Pickr runs and retain the manifest's 80% × 70% defaults; `src/main.lua` uses the existing terminal and does not resize it. Variant switches and refreshes remain in the same popup without resizing. Reopening through the launcher adopts edited dimensions.

Reject unknown fields, wrong types, unsupported keys, duplicate effective keys across actions, empty `accept`/`close` arrays, unknown theme names, and invalid colors with an actionable file/field diagnostic before opening fzf. Missing config is silent; a discovered unreadable or invalid config fails explicitly rather than silently substituting unexpected acceptance keys. These behaviors, null semantics, and launch-scoped resolution were confirmed during review.

Alternative: partial recovery from invalid values. Rejected because reverting one key can create a conflict with another valid override and makes acceptance behavior surprising.

### 2. Actions are the source of truth

Introduce `pickr.keymap` to resolve action-to-key arrays and a reverse key-to-action map. Validate using the supported fzf key vocabulary, including equivalent terminal aliases where fzf treats them as the same key. Reject events and action expressions as key names; this is data, not a raw `--bind` escape hatch.

Generate variant `--expect` keys only for enabled shortcuts and decode them through the reverse map. Preserve an unambiguous acceptance output protocol even when every variant shortcut is disabled; verify fzf's empty-expect behavior rather than assuming it still emits a blank first line. Generate accept/close/toggle bindings and refresh helper bindings from the same map. All hints, including retry hints, use a shared display formatter; show every configured alias, omit disabled shortcuts, and allow footer wrapping rather than clipping away reachable controls.

Replace every hardcoded refresh `unbind`/`rebind` with action-key lists. Disable all accept and refresh keys during loading; restore only refresh keys on failure, then both sets on successful publication. Closing, enabled switching/preview shortcuts, and query editing stay available. Disabled actions remain absent during refresh, failure, and completion; never restore their default keys or advertise unavailable controls. With `refresh: []`, install no refresh shortcut or refresh hint. Preserve the session's identity validation as defense against stale acceptance.

Remove Pickr's old bindings when remapped; ensure fzf's built-in acceptance/cancellation aliases cannot bypass configured actions. A former Pickr key can regain an inherited general editing/navigation meaning if it is no longer assigned to a Pickr action.

Alternative: a user-supplied raw fzf bind string for Pickr actions. Rejected because it separates hints and refresh gating from the actual action map.

### 3. Import general fzf bindings, not arbitrary fzf options

Read `FZF_DEFAULT_OPTS_FILE` and `FZF_DEFAULT_OPTS` before constructing the sanitized child environment. Respect fzf 0.74.3's source ordering and tokenization. Parse `--bind VALUE` and `--bind=VALUE` without invoking a shell. Import only key-triggered navigation, query-editing, and preview-scrolling actions from an explicit documented allowlist. Preserve supported ordered action chains; skip an entire binding containing an unsupported action with a non-blocking diagnostic identifying the key/event and unsupported action, never execute only part of its chain. Excluded bindings do not prevent the picker from opening or other supported bindings from applying. Event bindings and command/lifecycle actions such as execute, become, reload, transform, accept, and abort belong outside this import boundary. Acceptance, closing, preview toggling, refresh, and variant switching remain Pickr actions, including when their optional shortcuts are disabled.

Other ambient options are not forwarded. This prevents inherited `--expect`, `--print-query`, `--read0`, `--multi`, preview commands, color choices, or listen settings from altering the protocol. Keep `FZF_API_KEY` excluded. Clear ambient option variables for the child and explicitly emit the imported binding map followed by resolved Pickr bindings and owner-controlled events. General fzf defaults still provide unconfigured navigation/editing behavior.

This deliberate import boundary follows the agreed scope: users configure general keys in fzf, while Pickr owns its actions and presentation. It is not a promise that every arbitrary fzf customization works inside the plugin. Publish the supported action list and unsupported-binding diagnostics.

Use fzf 0.74.3 source/documentation to characterize quoting, option-source precedence, special-key aliases, repeated binds, separator escaping, and action chains before implementing the parser. Validate representative cases against the installed real fzf. Do not use comma splitting or a shell to approximate its grammar. This is a bounded compatibility task under the chosen import approach, not a decision to broaden scope.

Alternative: forward the whole environment and append overrides. Rejected because inherited events and lifecycle bindings are additive and can bypass Pickr's refresh and selection invariants. Alternative: continue discarding all fzf options. Rejected because it loses the user-approved navigation/editing inheritance.

### 4. Versioned palette data and semantic rendering roles

Introduce `pickr.themes` and bundled palette data derived from Herdr v0.9.0, with upstream provenance and applicable license attribution. Support exactly the 18 canonical names listed in the theme spec; no runtime download. Treat future Herdr palette additions as explicit compatibility updates. Default to `catppuccin` regardless of the configured Herdr client theme.

Resolve each palette into these Pickr roles: `background`, `foreground`, `selected_background`, `selected_foreground`, `match`, `selected_match`, `info`, `marker`, `prompt`, `spinner`, `pointer`, `header`, `footer`, `border`, `label`, `preview_background`, `preview_foreground`, `preview_border`, `annotation`, `status_blocked`, `status_done`, `status_working`, `status_idle`, and `status_unknown`. `theme.custom` overrides these roles independently. Match Herdr 0.9.0's accepted color syntax: `#RGB`, `#RRGGBB`, `rgb(r,g,b)` with integer components in 0..255, ANSI names and their aliases, and `reset`/`default`/`none`/`transparent`. Match its case and surrounding-whitespace normalization. ANSI names are `black`, `red`, `green`, `yellow`, `blue`, `magenta`/`purple`, `cyan`, `white`, `gray`/`grey`, `darkgray`/`darkgrey`, `lightred`, `lightgreen`, `lightyellow`, `lightblue`, `lightmagenta`, and `lightcyan`.

Normalize to tagged RGB, ANSI, or default values before generating fzf or ANSI output. Reset aliases mean terminal-default colors, not alpha blending. Do not assume every role is truecolor. Match Herdr's valid input formats but reject invalid values through Pickr's configuration error path rather than copying Herdr's invalid-color fallback. Null role values retain the selected palette's defaults.

Map palette colors to roles centrally, using Herdr's semantic status mappings as the reference. Preserve the existing explicit `rose-pine` appearance, including annotation `#524f67`, as closely as the current role set allows. The default Catppuccin annotation color is palette-derived, not the old gray. `terminal` uses ANSI/default colors and host background/foreground rather than invented RGB constants. Test selected-row contrast in both light and dark themes.

Pass the same resolved role table to fzf option generation, candidate indicators, headers, and annotation rendering. Keep status priority and glyphs separate from color. Apply preview roles to chrome/default background only; preserve captured ANSI content, pane IDs, and preview messages. Palette overrides never affect filtering, width calculation, ordering, or focus IDs.

Alternative: override only fzf `--color`. Rejected because indicators and annotations already embed ANSI colors. Alternative: read Herdr config.toml. Rejected because client presentation can differ from server-local config and automatic appearance selection is not exposed by the inspected API.

## Risks / Trade-offs

- fzf grammar and key aliases are nontrivial -> pin compatibility work to the existing 0.74.3 baseline, test real fzf behavior, and explicitly document the supported binding import boundary.
- Imported bindings could accept during refresh -> import only navigation/editing/preview-scrolling actions, control lifecycle events, and test built-in aliases plus inherited acceptance attempts.
- More aliases lengthen hints -> render all configured aliases with wrapping and manually check the default popup size.
- Palette copies can drift from Herdr -> record the source version and verify the name inventory and semantic mappings during upgrades.
- ANSI resets and light themes can reduce contrast -> use typed color serialization and inspect representative light, dark, terminal, and custom combinations.
- Tests currently assert fixed Rosé Pine colors -> keep explicit rose-pine coverage, add Catppuccin default expectations, and test theme-independent row semantics separately.

## Migration Plan

Ship optional configuration with no setup file required. Document the Catppuccin visual default and the one-field `rose-pine` opt-back. Explain that external Herdr action launch bindings are still configured in Herdr and general fzf bindings stay in fzf configuration. Document supported imported actions, precedence, non-blocking exclusion diagnostics, blocking Pickr configuration errors, direct-launch lookup, and reopen-to-reload behavior. Include the distinction between omitted/null values and `[]`, the required accept/close shortcuts, hidden disabled-action hints, and Herdr-compatible color formats and aliases.

Run automated fixtures and real-fzf compatibility checks, then manual popup acceptance for all five variants, remapping, refresh failure/retry, both initial preview visibility settings, default/percentage/cell-count popup dimensions, and representative themes. Verify preservation of both shown and hidden preview states across all 25 source/destination routes, including empty lists, zero matches, switches during refresh, and switches after failure. Verify closing and reopening restores the configured preview default, along with the documented direct-launch distinction and reopen-to-adopt behavior. Record actual outcomes and versions. Rollback is a source/plugin-version rollback; the JSON file remains in Herdr's user config directory and the old plugin ignores it. No config migration or user-file deletion is required.
