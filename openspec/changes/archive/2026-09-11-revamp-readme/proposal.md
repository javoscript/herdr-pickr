## Why

The README mixes user setup and configuration with implementation details, migration history, and lengthy verification records. Refocus it on Pickr's features, a working installation path, and a complete but concise configuration reference.

## What Changes

- Lead with the five picker variants, visible-terminal previews, contextual search, agent status/worktree information, switching, refresh, and customization.
- Combine dependency installation, GitHub installation, and first launch into one macOS quick start. Treat https://github.com/javoscript/herdr-pickr as published and `herdr plugin install javoscript/herdr-pickr` as available.
- Distinguish Herdr launch keybindings in `config.toml` from popup customization in the Herdr-managed plugin `config.json`, with complete examples and clear instructions for applying edits.
- Provide all action mappings, popup dimensions, initial preview visibility, supported themes and color overrides, prompt settings, and fzf compatibility/options/keybinding limitations.
- Remove Development, Migrate from `local.pickr`, Picker behavior, Regression checks, Two-row footer live acceptance, and Compatibility verification, including their nested content. Relocate useful configuration material into the new reference and condense remaining behavior sections into user-facing highlights and notes.
- Revise the existing distribution documentation requirement so development linking, migration, regression instructions, and historical verification records are no longer required in the README.
- Depend on implementation of `configure-search-prompt` before rewriting and verifying prompt documentation.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `plugin-distribution`: Replace the historical installation/migration documentation contract with a concise user-facing installation and complete configuration contract.

## Impact

The implementation target is `README.md`, with the distribution documentation requirement updated through this delta. Existing documentation checks must continue to validate examples and complete public inventories. No runtime feature, dependency, action ID, or configuration behavior is introduced by this change; prompt behavior belongs to `configure-search-prompt`. Preserve a compact license and bundled-dependency attribution.
