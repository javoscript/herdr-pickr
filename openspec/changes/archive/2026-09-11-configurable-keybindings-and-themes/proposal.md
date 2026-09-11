## Why

Publishing Pickr to the Herdr community requires users to adapt its popup shortcuts and appearance without editing installed source. Pickr currently hardcodes its actions and Rosé Pine colors and excludes the fzf configuration where users keep their navigation and query-editing preferences.

## What Changes

- Read optional, partial JSON configuration from `$HERDR_PLUGIN_CONFIG_DIR/config.json`, with equivalent location discovery for direct invocation.
- Make initial preview visibility configurable through `preview.enabled_by_default`, retaining visible previews by default and allowing the configured toggle shortcut in either initial state. Apply this default only when opening a new popup session; preserve the current shown/hidden state across variant switches, refreshes, and retries. Closing and reopening uses the configured default again.
- Configure action-launched popup dimensions through `popup.width` and `popup.height`, retaining `"80%"` and `"70%"` defaults. Support percentage strings and terminal-cell counts through Herdr's socket API; direct Herdr pane launches retain manifest defaults and `src/main.lua` uses its existing terminal.
- Make all nine Pickr actions configurable, retaining existing default shortcuts and supporting multiple keys per action. Generate hints and refresh key gating from the resolved keymap.
- Honor general fzf navigation and query-editing bindings from fzf configuration, with Pickr action bindings taking precedence. Preserve Pickr's selection protocol, preview, refresh lifecycle, and theme against unrelated inherited options.
- Support all 18 Herdr 0.9.0 native theme names, including `terminal`, with Pickr-specific semantic color overrides covering both fzf chrome and ANSI-rendered rows.
- **BREAKING (visual default):** use `catppuccin` (Mocha), Herdr's built-in default, instead of Rosé Pine. Users can explicitly choose `rose-pine`.
- Document configuration, precedence, diagnostics, theme compatibility, and the intentional default appearance change.

## Capabilities

### New Capabilities

- `plugin-configuration`: Optional JSON configuration discovery, partial defaults, validation, and launch-scoped configuration.
- `picker-keybindings`: Configurable Pickr actions, accurate hints, and coexistence with general fzf keybindings.
- `picker-themes`: Herdr-compatible named palettes and Pickr-specific semantic overrides.

### Modified Capabilities

- `picker-refresh`: Refresh, retry hints, and acceptance gating use resolved action keys; Ctrl+L and Enter remain defaults.
- `agent-pane-labels`: Pane and worktree annotations share a theme role rather than a fixed Rosé Pine gray.

## Impact

Expected implementation areas are `src/open.lua`, `src/main.lua`, `src/pickr/core.lua`, `src/pickr/runtime.lua`, new configuration/keymap/theme modules under `src/pickr/`, `tests/test.lua`, and `README.md`. Palette attribution must accompany any imported upstream palette data. User settings live outside the managed source checkout. The plugin identity, external launch bindings, platform support, and existing Herdr/Lua/luv/fzf minimums remain the compatibility baseline.

Automatic inheritance of the active Herdr client theme, live configuration reload inside an open popup, general fzf key configuration in Pickr JSON, and recoloring captured terminal output are outside this change.
