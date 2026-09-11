## 1. Reorganize source and module loading

- [x] 1.1 Move launchers into `src/`, core/runtime/process modules into `src/pickr/`, JSON into `src/pickr/vendor/`, and the regression entrypoint into `tests/test.lua`; verify the resulting tree matches the design, old source locations are gone, and the vendored JSON contents and license are unchanged.
- [x] 1.2 Update launcher and test bootstraps to resolve an absolute source root from their own physical locations, use `pickr.*` imports throughout, and point test launcher fixtures at `src/open.lua`; verify project imports have no remaining generic internal module names and all Lua files pass syntax checking with the installed Lua toolchain.
- [x] 1.3 Update runtime preview and refresh-control commands to resolve `src/main.lua` from the parent of the runtime module directory while preserving interpreter selection and shell quoting; verify both command builders use the new launcher and the existing real preview subprocess check passes as part of `lua tests/test.lua`.

## 2. Update Herdr integration and developer documentation

- [x] 2.1 Change all five manifest action commands to `src/open.lua` and all five pane commands to `src/main.lua`; review the manifest diff to verify IDs, arguments, popup settings, platform, and minimum version are preserved and every script target exists.
- [x] 2.2 Update README project structure, current regression/development commands, direct invocation guidance, code references, vendor attribution path, and isolated-copy instructions; document relinking and new direct-script paths, and verify current instructions resolve to existing files while historical verification records remain clearly historical.

## 3. Verify relocatable execution and launch behavior

- [x] 3.1 Run `lua tests/test.lua` from the repository root; verify the full existing suite passes, including the five action-launcher fixtures, all 25 switching routes, preview subprocess, refresh-session, async-process, and socket scenarios.
- [x] 3.2 Place an isolated distribution copy containing `src/`, `tests/`, the manifest, and distribution documents in a path containing spaces, with no old root scripts or parent helpers; from a separate caller directory run `env -i HOME="$HOME" PATH="$PATH" TMPDIR=/tmp TERM=xterm-256color lua "../Herdr Pickr/tests/test.lua"` against that copy and verify the full suite passes without ambient Lua source-path/init overrides.
- [x] 3.3 Relink the development checkout with `herdr plugin link "$(pwd)"` and perform focused interactive acceptance: invoke all five existing qualified actions and direct pane entrypoints, verify current/all-space scope, preview and Ctrl+P, Ctrl+L refresh/control subprocesses, variant switching, and Enter/Escape behavior. Verify existing keybindings still invoke the same actions; record user-assisted results if interactive access requires the user.
- [x] 3.4 Record actual dependency versions and verification outcomes in the README, distinguishing automated and interactive results from earlier publication checks; review the final diff for unintended behavioral changes, stale active path references, and lost attribution, and run `git diff --check`.
