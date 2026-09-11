## Context

See proposal.md for motivation and the distribution delta for the documentation contract. The existing README interleaves configuration with sections being removed. `tests/documentation.lua` decodes every fenced JSON example and requires at least five examples plus explicit inventories of all Pickr actions, theme names, color roles, and supported imported fzf actions. Prompt customization is currently a separate planned change.

This design resolves the ambiguity between reducing prose and retaining an exhaustive reference, and defines sequencing against the prompt feature before implementation.

## Goals / Non-Goals

**Goals:** Make first launch linear, make the two configuration layers unmistakable, and keep exhaustive inventories easy to find without repeating behavior descriptions.

**Non-Goals:** Runtime changes, implementing the prompt feature, adding developer documentation elsewhere, or recording new interactive compatibility results.

## Decisions

### Organize around the reader's next action

Use this outline:

```text
Herdr Pickr: introduction and feature highlights
Installation: requirements, dependencies, install, first launch
Configuration
  Herdr keybindings
  Pickr configuration file and starter example
  Popup action keys
  Popup size
  Initial preview visibility
  Themes and custom colors
  Search prompt
  fzf compatibility and inherited bindings
License and attribution
```

Retain short operational notes where they help users: previews are snapshots; refresh preserves the query; switching resets it and keeps the original current-space scope. Consolidate the old column/search/switch/refresh/preview sections rather than maintaining a second behavior manual. An alternative of only deleting the requested headings would strand configuration and leave duplicated prose.

### Keep installation contiguous and publication-ready

State macOS support and minimums (Herdr 0.9.0+, Lua 5.3+, fzf 0.74.3+, matching luv, Git), show Homebrew dependency installation followed by the published plugin install and one first-launch command. Link Homebrew for the package-manager prerequisite. Keep the Lua/luv compatibility and Herdr PATH explanation brief. Treat GitHub availability as the user's confirmed premise; remove publication caveats rather than adding local linking as a fallback.

### Separate launch bindings from popup configuration

Provide complete TOML bindings for the five qualified Herdr action IDs, explain the default prefix and config reload, and state that suggested bindings are not automatic. Discover Pickr's directory once with the CLI and tell users to create `config.json` there. Describe omitted/null defaults, strict validation, and reopen-to-apply behavior once near the starter example.

### Use examples for common edits and tables/lists for inventories

Keep at least five useful JSON examples: a starter configuration, action aliases/disabling, popup dimensions, initial preview visibility, theme selection/custom colors, and prompts. Validate them against the actual parser. Use a nine-action table with default keys and meanings, plus focused rules for required actions, replacement arrays, alias collisions, and supported key syntax. Avoid confusing Herdr prefix bindings with fzf key names, including unsupported Ctrl+Shift+letter combinations.

List all theme names and 24 semantic roles, grouping roles for readability, and retain all accepted color formats and aliases. Distinguish prompt text from `theme.custom.prompt` color. A single enormous full-default JSON object would duplicate tables and obscure partial configuration, so prefer the small examples with complete references.

### Document the implemented prompt contract after its dependency

Before rewriting, confirm `configure-search-prompt` is implemented and re-read its resulting code/specs. Document `prompt.default`, the five `prompt.variants` keys, the `Search: ` default, inheritance, empty strings, preserved whitespace, validation, and reopen/switch behavior. Do not publish unsupported prompt examples or implement that feature here. If its accepted interface changes, reconcile the reference with the final implementation before proceeding.

### Put practical fzf limitations before the long inventory

Start with the supported baseline, imported binding categories, ignored unrelated options, and Pickr precedence. Then explain file-before-environment precedence, replacement/append chains, whole-binding exclusion, events and unsupported actions, and non-blocking diagnostics. Keep every supported imported action explicitly listed; a collapsible inventory can reduce scrolling without moving required reference content out of the README. Avoid the current internal protocol and historical PTY-verification narrative.

### Preserve attribution and existing verification value

Keep a compact MIT license section with rxi/json.lua version/upstream attribution and the bundled Herdr palette attribution/license link. Use the existing documentation checks rather than weakening inventory coverage to shorten the README. Retaining several useful small JSON examples satisfies the current minimum naturally. No test implementation changes are planned.

## Risks / Trade-offs

- [Prompt examples get ahead of runtime support] -> Make the completed prompt feature an explicit first implementation prerequisite; validate every example against that implementation.
- [Section removal loses valid customization details] -> Audit against config, keymap, themes, and inherited-action inventories, not just the old headings.
- [Complete inventories still add length] -> Use tables, grouped lists, and an optional collapsible fzf action inventory; remove repeated lifecycle and implementation prose rather than settings.
- [Existing links target deleted headings] -> Review all README anchors and external references, including repository references to removed sections; report any follow-up outside the approved README scope.
- [A published install example is mistaken for a tested installation] -> Present the confirmed distribution command without adding claims of a new installation or interactive verification run.

## Migration Plan

After the prompt dependency is implemented, rewrite the README, run the existing documentation check, and review links and inventories. Archive/sync this change through the normal OpenSpec workflow to replace the old documentation contract. No user configuration migration is required. A documentation rollback can restore the prior README if necessary, without changing runtime behavior.
