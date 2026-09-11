## Why

Pickr currently depends on Lua helpers outside its repository and documentation tailored to one local Herdr configuration. Preparing a self-contained package with a stable public identity will let others install and use it directly from GitHub.

## What Changes

- Bundle `lib/process.lua` and `lib/vendor/json.lua` and resolve them relative to the plugin in every launcher and the regression suite.
- **BREAKING**: Replace plugin ID `local.pickr` with `javoscript.herdr-pickr` and use display name `Herdr Pickr`. Document migration of the existing local registration and keybindings.
- Target GitHub repository `javoscript/herdr-pickr` and document Herdr's native GitHub installation flow, development linking, dependencies, and suggested keybindings.
- Add an MIT project license with `Copyright (c) 2026 javoscript`; preserve the JSON library's upstream attribution and MIT notice.
- Establish dependency compatibility information and verify isolated-checkout operation plus macOS interactive behavior before publication.
- Publish with macOS-only platform support. Defer Linux support to a follow-up requiring Linux regression and interactive verification before enabling it in the manifest.

## Capabilities

### New Capabilities

- `plugin-distribution`: Self-contained, relocatable plugin packaging with a stable public identity, licensing, and reproducible installation instructions.

### Modified Capabilities

None. Existing picker column and pane-label requirements remain applicable.

## Impact

Implementation affects `main.lua`, `open.lua`, `runtime.lua`, `test.lua`, `herdr-plugin.toml`, `README.md`, new bundled library files, and a new root `LICENSE`. Lua, luv, fzf, and Herdr remain externally installed dependencies. Existing local users must update action references and replace their old plugin registration.

This change prepares the repository; creating the GitHub repository, pushing commits, publishing releases, marketplace submission, automated dependency installation, and changes to users' external Herdr configuration are outside its implementation scope. Migration instructions cover the external configuration steps.
