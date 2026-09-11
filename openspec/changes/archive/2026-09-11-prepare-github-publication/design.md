## Context

See proposal.md for motivation. Three bootstraps (`main.lua`, `open.lua`, `test.lua`) prepend `../../lib` to Lua's search path. `runtime.lua` imports `process` and `json`; the process helper depends only on luv, while the JSON source is self-contained rxi/json.lua 0.1.2 with an embedded MIT notice. The runtime already constructs shell-quoted preview commands using its resolved script directory and the running Lua executable.

The manifest declares Herdr 0.9.0 and macOS/Linux support. Runtime context recognition and popup opening hard-code `local.pickr`, as do regression fixtures. Herdr runs plugin commands with the plugin root as working directory and supports GitHub installation independently of the manifest ID. Existing specs concern picker behavior, not packaging.

## Goals / Non-Goals

**Goals:** Keep installation independent of the author's filesystem, preserve existing picker semantics, and make the identity transition explicit and testable.

**Non-Goals:** Introduce a package manager or build pipeline, redesign module APIs or picker behavior, add Windows support, or automate changes to external shared libraries and user configuration. A screenshot and CI automation can be follow-ups rather than prerequisites for this focused preparation.

## Decisions

### Bundle the two source helpers directly

Copy the currently used `../../lib/process.lua` to `lib/process.lua` and `../../lib/vendor/json.lua` to `lib/vendor/json.lua`. Retain contents and JSON attribution so packaging does not also become a dependency upgrade. Record the JSON upstream URL and version in the README. Leave original shared files in place for other consumers.

Use these plugin-local locations in all three bootstraps, with their entries ahead of ambient `package.path`. Keep externally installed `luv` resolved through Lua's normal module mechanism. Preserve existing script-relative resolution and preview quoting; do not retain a fallback to `../../lib`, which would conceal incomplete packages. A shared-library installation or submodule would add an unnecessary installation dependency for two small source files.

### Adopt the public identity atomically

Set manifest ID to `javoscript.herdr-pickr` and name to `Herdr Pickr`; update runtime context checks, launcher targeting, fixtures, README title, and command examples together. Existing local action IDs and popup dimensions stay as defined. Short in-popup labels need not be expanded merely because the manifest display name changes.

Use one public ID without a legacy alias. This avoids duplicate registered actions and keeps the migration explicit. Keep historical OpenSpec artifacts as records of their original changes rather than globally rewriting all historical mentions of `local.pickr`.

### Document external dependencies instead of installing them implicitly

Herdr, Lua 5.3+, luv, and fzf remain user-installed. Provide macOS setup guidance and a check that `lua` can load `luv`; matching the interpreter matters because the manifest invokes `lua` from PATH. Support fzf 0.74.3 and later, using the currently installed 0.74.3 as the baseline. Verify the actual option set, especially `--footer`, `--with-shell`, and column matching semantics, at that baseline; determining the earliest compatible upstream release is not required. Record tested versions separately from the supported minimum.

Lead with native installation from `javoscript/herdr-pickr` and one action invocation. Include suggested `[[keys.command]]` bindings using qualified public action IDs, development clone/link instructions, relinking guidance, and a repository-relative regression command. Retain existing detailed usage information below the getting-started material.

### License project code and preserve third-party terms

Add root `LICENSE` containing the full MIT text and `Copyright (c) 2026 javoscript`. Keep rxi's existing notice in the vendored file and identify that dependency in the README. The project notice does not replace third-party attribution.

### Verify packaging independently of the local setup

Reuse the existing fixture/socket/fzf suite and update its identity assertions. Exercise it from an isolated copy containing only intended distributed files, nested beneath a parent without shared Lua helpers, with ambient Lua source search overrides excluded. Use a checkout path containing spaces and run the suite from another working directory. This detects the current failure mode that ordinary in-place testing would miss.

Verify all five actions, direct entrypoint context, preview loading, variant switching, and selection interactively on macOS with Herdr 0.9.0 or a documented compatible version. Record exact versions and outcomes. If an interactive environment is unavailable, leave that verification task incomplete and report the blocker rather than infer success. Existing socket-based agent focus makes real Herdr smoke checks important in addition to fixture tests.

### Publish for macOS and defer Linux support

Set the manifest to `platforms = ["macos"]` and document macOS as the only supported platform for this publication. Linux verification is unavailable, so Linux support is explicitly deferred rather than inferred from macOS results. A follow-up must run the isolated regression suite and the same interactive checks on Linux, record exact dependency versions and outcomes, and provide verified Linux setup instructions before adding Linux back to the manifest.

## Risks / Trade-offs

- Public ID changes invalidate old bindings -> Provide explicit unregister/register and binding migration steps.
- Vendored helpers may diverge from shared copies -> Treat repository copies as the plugin's dependency baseline and document JSON provenance; avoid silent fallback.
- The supported fzf baseline may exceed distro package versions -> Document the 0.74.3 minimum and give suitable dependency installation guidance.
- Passing tests locally can hide missing distribution files -> Verify an isolated package from another working directory with no parent helper files.
- macOS-only access cannot substantiate Linux support -> Publish for macOS only and defer Linux support until a separately verified follow-up.

## Migration Plan

1. Prepare and verify the self-contained source and updated manifest.
2. In user-facing instructions, unregister `local.pickr` with `herdr plugin unlink local.pickr`, preserving its source.
3. Link the updated checkout or install `javoscript/herdr-pickr` once the repository is published. Explain that an existing local registration under the new ID must be unlinked before a GitHub-managed installation can replace it.
4. Update users' qualified keybinding references and reload their Herdr configuration as needed. These are documented user actions, not automatic edits by this change.
5. For rollback, unregister the new identity, restore/link the prior checkout, and restore prior action references. The prior checkout still requires its old external helpers; bundling does not delete them.

Publishing the remote and proving the final GitHub install against that remote are release follow-ups. Before publication, local isolated-checkout verification establishes package completeness.
