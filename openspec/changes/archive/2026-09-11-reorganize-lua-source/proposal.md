## Why

Pickr's production Lua, launchers, and regression script currently share the repository root with documentation and the plugin manifest. A library-oriented source layout will make these roles clearer and give internal modules an explicit `pickr` namespace as the project grows.

## What Changes

- Move executable launchers to `src/main.lua` and `src/open.lua`.
- Move internal modules to `src/pickr/core.lua`, `src/pickr/runtime.lua`, and `src/pickr/process.lua`; move the bundled JSON library to `src/pickr/vendor/json.lua` with its license intact.
- Load internal modules through `pickr.*` names and resolve the source search path relative to each launcher rather than the caller's working directory.
- Move the regression entrypoint to `tests/test.lua` and update its source/launcher resolution.
- Update manifest commands, preview/control subprocess paths, and documentation for the new layout.
- **BREAKING** for direct script callers: replace root-level `main.lua`, `open.lua`, and `test.lua` paths with their new paths. No root-level compatibility wrappers are planned. Public Herdr action IDs and keybindings remain stable.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a source-layout refactor with updated developer commands, not a change to picker capabilities. The existing `plugin-distribution` requirements for self-contained, relocatable execution, public identity, documentation, and attribution remain the acceptance contract. Change metadata sets `skip_specs: true`.

## Impact

- Affected implementation: the five root-level Lua files and both bundled helpers, including bootstrap imports and subprocess path construction.
- Affected integration: all five action commands and five pane commands in `herdr-plugin.toml`; locally linked installations need relinking after the manifest changes.
- Affected documentation: project structure, direct launch and regression commands, source references, vendor attribution path, and isolated-checkout verification instructions in `README.md`.
- No new dependencies, packaging/build step, LuaRocks publication, or public Lua library API is introduced. Supported platforms, runtime requirements, picker behavior, and Herdr configuration syntax remain the same.
