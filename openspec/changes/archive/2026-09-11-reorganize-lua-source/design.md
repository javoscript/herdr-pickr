## Context

See `proposal.md` for motivation and scope. The manifest currently invokes root-level `open.lua` and `main.lua`. Both launchers and `test.lua` prepend root, `lib`, and `lib/vendor` search patterns to `package.path`. Modules use generic names (`core`, `runtime`, `process`, `json`).

`runtime.lua` resolves its own physical location with luv and assumes `main.lua` is a sibling when constructing both preview and refresh-control commands. The regression suite executes `open.lua` directly and patches the imported runtime table. These relationships must move together. Existing `plugin-distribution` scenarios require operation from an isolated checkout, an unrelated working directory, and paths containing spaces.

This design is warranted because the move crosses launchers, module loading, subprocess execution, manifest integration, and the regression harness.

## Goals / Non-Goals

**Goals:**
- Establish one production source search root with namespaced internal modules.
- Preserve script-relative resolution and shell quoting throughout parent and child Lua processes.
- Keep tests and production launchers loading the same module identities so fixture patches still work.

**Non-Goals:**
- Publishing a reusable Lua API or introducing LuaRocks, a build step, or an `init.lua` facade.
- Splitting existing modules, changing picker behavior, or restructuring the regression suite beyond its location and path dependencies.
- Providing compatibility aliases for old generic module names or root-level scripts.

## Decisions

### 1. Separate launchers, modules, and tests

Use this layout:

```text
pickr/
|-- herdr-plugin.toml
|-- README.md
|-- LICENSE
|-- AGENTS.md
|-- src/
|   |-- main.lua
|   |-- open.lua
|   |-- pickr/
|       |-- core.lua
|       |-- runtime.lua
|       |-- process.lua
|       |-- vendor/
|           |-- json.lua
|-- tests/
|   |-- test.lua
|-- openspec/
```

`process.lua` is an internal helper, while the third-party JSON source remains explicitly separated under `vendor`. Preserve the vendored file contents and license. Keep the existing regression filename as a minor naming default.

Alternative: retaining generic modules directly inside `src/` would require fewer import edits, but would not provide the library-oriented namespace selected during exploration. `lua/pickr/` adds no host-specific benefit here because Herdr executes Lua scripts rather than supplying a Neovim-style module loader.

### 2. Bootstrap the source root, then use qualified module names

Each executable launcher resolves its own physical path using the already-required luv dependency and prepends the absolute `src/?.lua` pattern to `package.path`, retaining the existing external search patterns. The test entrypoint resolves its own physical path, finds sibling `src/` through the repository root, and prepends that same pattern.

Imports become `pickr.core`, `pickr.runtime`, `pickr.process`, and `pickr.vendor.json`. Lua's normal dot-to-directory mapping resolves these through the single source pattern. External `require("luv")` is unchanged; `package.cpath` does not need modification. No `?/init.lua` pattern is necessary for this layout.

Use small bootstrap code in the three executable scripts rather than adding a bootstrap module that itself needs a search path. Avoid CWD-relative `./src/?.lua` patterns or environment-dependent `LUA_PATH` setup: either would weaken the existing relocatability contract.

### 3. Resolve child launchers from the new runtime location

`src/pickr/runtime.lua` derives the source directory from the parent of its resolved module directory and locates `src/main.lua` there. Use that resolved launcher path consistently for preview and refresh-control commands. Preserve the current Lua interpreter selection via `uv.exepath()`, shell quoting, arguments, and fzf placeholders.

Alternative: continuing to derive `main.lua` as a sibling would target a nonexistent `src/pickr/main.lua`. Passing a launcher path through all runtime callers would add configuration and call-site complexity for a fixed checkout relationship.

### 4. Keep Herdr's public action contract stable

Change only script-path arguments in the manifest: action commands use `src/open.lua`, and pane commands use `src/main.lua`. Preserve plugin identity, all five action and entrypoint IDs, arguments, popup settings, platform declaration, and minimum version. Existing `type = "plugin_action"` keybindings continue to use `javoscript.herdr-pickr.<action-id>`.

Document `lua src/main.lua ...` and `lua tests/test.lua` as the new direct invocation paths and retain the existing instruction to relink after manifest changes. Root-level wrappers were considered, but would defeat the clean-root goal and maintain two launch surfaces for a project whose Herdr action interface already provides stability.

### 5. Verify path behavior through existing regressions and targeted integration checks

Adapt existing launcher fixtures and imports rather than adding tests that merely assert directory names. Run the suite from the repository root and from an unrelated caller directory against an isolated copy in a path containing spaces, with ambient Lua path/init overrides excluded. Include `src/`, `tests/`, the manifest, and distribution documents in that isolated copy, with no old root scripts or parent Lua helpers.

Use the existing real preview subprocess regression to exercise namespaced loading in a new Lua process. Verify refresh-control subprocess resolution through focused interactive refresh acceptance, since the suite's picker fixture replaces the interactive controller. Relink and smoke-test all five manifest actions and direct pane entrypoints; cover preview, Ctrl+L refresh, variant switching, and selection/cancellation. Record actual outcomes separately from historical compatibility results in the README.

## Risks / Trade-offs

- [A missed generic import loads a different module or fails] --> Update all project imports together, including test imports, and run isolated regressions without old source paths.
- [Preview or refresh still targets the old sibling launcher] --> Derive one source-relative launcher path in runtime and verify both child-process routes.
- [A stale Herdr registration invokes removed root scripts] --> Relink after updating the manifest and document the direct-command migration.
- [Relocation works only from the repository root] --> Resolve physical script/module paths and repeat isolated path-with-spaces verification from another working directory.
- [Documentation implies earlier compatibility checks covered the new layout] --> Preserve historical outcomes as historical and record new commands, versions, and results only after verification.

## Migration Plan

1. Move files and update imports, path bootstrap, runtime subprocess paths, and manifest commands together.
2. Update current README structure, commands, source references, and attribution path; clearly distinguish historical verification records from new checks.
3. Run `lua tests/test.lua`, then repeat in an isolated checkout with spaces in its path and a clean environment from an unrelated directory.
4. Relink the development checkout with `herdr plugin link "$(pwd)"` and perform the focused interactive checks. Existing user keybindings require no edits.
5. If rollback is needed, restore the prior source layout and manifest together and relink the checkout. There is no persistent-data migration.
