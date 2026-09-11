## 1. Self-contained Lua distribution

- [x] 1.1 Bundle the currently used helpers at `lib/process.lua` and `lib/vendor/json.lua`; verify their contents match the source copies and the JSON copyright/MIT notice is retained.
- [x] 1.2 Update `main.lua`, `open.lua`, and `test.lua` to load plugin-local libraries; verify no executable bootstrap references `../../lib` and `lua test.lua` passes with the bundled modules.

## 2. Public identity and license

- [x] 2.1 Set manifest ID `javoscript.herdr-pickr` and display name `Herdr Pickr`, and update launcher, runtime, and identity fixtures together; verify launcher/context regression assertions pass for all five entrypoints and runtime code no longer targets `local.pickr`.
- [x] 2.2 Add root `LICENSE` with the full MIT text and `Copyright (c) 2026 javoscript`; verify the project notice and bundled rxi notice are both present and distinct.

## 3. Installation and usage documentation

- [x] 3.1 Verify the actual option set and column-filter behavior with fzf 0.74.3; document support for fzf 0.74.3+, distinguishing the tested version from the supported minimum, along with Lua 5.3+, interpreter-compatible luv, Herdr compatibility, and macOS dependency setup instructions in the README.
- [x] 3.2 Update the README title to Herdr Pickr and add GitHub installation from `javoscript/herdr-pickr`, first invocation, development clone/link instructions, and repository-relative regression commands; verify examples use the public ID and require no personal checkout layout.
- [x] 3.3 Provide complete suggested Herdr keybinding examples and migration instructions from `local.pickr`, including local-to-GitHub registration replacement and configuration reload guidance; verify configuration syntax against Herdr 0.9.0 documentation and all action references against the manifest.
- [x] 3.4 Update the README structure/dependency references to the bundled libraries and document the JSON upstream URL/version and MIT licensing; verify each documented repository path exists and retain the detailed picker usage documentation.

## 4. Distribution and integration verification

- [x] 4.1 Run the regression suite from an isolated distribution copy in a path containing spaces, invoked from another working directory with no parent shared helpers or ambient Lua source overrides; record the command, dependency versions, and successful result, including launcher/context and preview-command coverage.
- [x] 4.2 On macOS, link the isolated checkout and verify all five qualified actions, direct entrypoint context, previews, variant switching with preserved origin, cancellation, and selection; record Herdr/Lua/luv/fzf versions and outcomes in the README compatibility section, leaving this task pending if interactive verification is unavailable.
- [x] 4.3 Restrict the manifest and README to macOS support and document Linux support as deferred to a follow-up requiring isolated regression, interactive checks, recorded versions/outcomes, and Linux setup instructions before enabling the platform.
- [x] 4.4 Review the final distribution against `specs/plugin-distribution/spec.md`; verify required source/license files are included, current installation instructions are internally consistent, and remaining `local.pickr` or external-helper references are limited to intentional migration or historical documentation.
