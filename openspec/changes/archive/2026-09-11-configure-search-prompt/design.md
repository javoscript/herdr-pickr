## Context

See `proposal.md` for motivation. `src/pickr/config.lua` strictly validates optional JSON sections, resolves defaults, and serializes settings through `PICKR_SETTINGS_SNAPSHOT`. `src/pickr/core.lua` builds each variant's fzf arguments in `pick_once`, currently with `--prompt=◉/> `. The surrounding `M.pick` loop reuses the same settings when switching variants. Refresh operates within that fzf process. The existing `keymap.variants` maps configuration-style names to internal kind/scope pairs, including `spaces` to `workspaces/all`.

`tests/configuration.lua` covers strict JSON and snapshot/reopen behavior. `tests/test.lua` asserts the old prompt and exercises all 25 switching routes, including empty/zero-match states and refresh callbacks. `tests/documentation.lua` decodes README JSON examples. The main plugin-configuration spec currently excludes `prompt` from its accepted sections, so the delta explicitly updates that requirement.

## Goals / Non-Goals

**Goals:**
- Resolve inheritance once and carry complete effective prompt values through the established settings handoff.
- Keep variant selection consistent with the existing five-variant inventory.
- Verify observable prompt arguments, inheritance, and session stability with existing Lua fixtures.

**Non-Goals:**
- Prompt interpolation, per-session prompt editing, or changes to query matching and lifecycle controls.
- New prompt styling settings or importing ambient fzf `--prompt` options; the existing prompt color role remains authoritative.

## Decisions

### One object with a global default and explicit variant overrides

Use this public configuration shape:

```json
{
  "prompt": {
    "default": "Search: ",
    "variants": {
      "tabs_current": "Tabs: ",
      "agents_all": "Agents: "
    }
  }
}
```

The global default is `"Search: "`; unspecified variants inherit it. All five variant names use the existing underscore-style action configuration vocabulary. A string-or-object union for `prompt` was considered, but an object follows the existing configuration sections and provides one unambiguous shape for combining global and variant values. Flattening variant fields beside `default` was considered; the `variants` object keeps the namespace explicit.

### Resolve effective values during configuration decoding

Extend the root allowlist, validate `prompt` and `prompt.variants` with the strict object helper, and use the existing omitted/null convention. Build `settings.prompt` with the resolved `default` and a `variants` map containing all five effective strings. Populate the supported inventory from `keymap.variants` rather than maintaining a second unrelated list.

Empty strings are deliberate values, not omission. Preserve spaces and Unicode exactly; do not trim or append a space. Reject non-string non-null values and NUL/CR/LF with field diagnostics, because the prompt is a single-line subprocess argument. This is a plain-text setting, not a templating or formatting language. These string edge cases are planning assumptions chosen to make inheritance and argument handling predictable.

Serializing fully resolved values follows the current snapshot contract and avoids re-reading configuration or recalculating defaults in the owner. Extend owner snapshot validation to require the prompt structure and effective string values. The snapshot is an internal same-launch handoff, not a persisted user API; keep its existing version for this additive field and reject incomplete handoffs through its existing diagnostic. Runtime reload of an already-open picker is not required.

### Select the prompt when building each fzf invocation

Resolve the variant key from the existing kind/scope mapping and pass `"--prompt=" .. settings.prompt.variants[variant]` as a single argv entry in `pick_once`. This handles `workspaces/all` as `spaces` and prevents accidental lookup by the internal `workspaces` name. There are only five variants, so a small lookup over the shared mapping is sufficient; a new module is unnecessary.

Use argv directly, without shell quoting, interpolation, or `change-prompt` actions. The existing variant loop naturally selects the destination's value from the frozen settings, while refresh/retry leave the fzf prompt untouched. Introducing runtime prompt updates would add lifecycle complexity without enabling required behavior.

### Extend the established regression coverage

Add table-driven configuration cases for all variant keys, null/missing inheritance, partial overrides, empty strings, literal Unicode/metacharacters, invalid objects/types/names, and NUL/CR/LF. Extend snapshot fixtures to demonstrate that later file edits cannot change either the global value or effective variant values in the handed-off settings.

Replace the old default argument assertion and extend picker route fixtures to assert destination-specific prompts across the 25 routes, including the `spaces` mapping and empty/zero-match cases. Assert the original settings remain available during refresh rendering and retain existing query/preview checks. Use a focused real-fzf PTY check or live acceptance for displayed default/custom/empty prompts; do not infer visual acceptance solely from captured argv. Run `lua tests/test.lua`, which also validates README examples.

## Risks / Trade-offs

- [The new default changes a familiar visual marker] → Document `{"prompt":{"default":"◉/> "}}` to restore the old appearance.
- [Null and empty strings could accidentally share fallback handling] → Resolve through explicit omission checks and cover empty global and variant values in fixtures.
- [Internal kind names differ from public variant names] → Reuse `keymap.variants` and verify all five destinations.
- [Long or unusual text may be clipped by the terminal/fzf] → Preserve the supplied text and leave layout to fzf; do not invent a length cap or custom renderer.
- [A stale internal snapshot lacks newly required fields] → Report the existing snapshot diagnostic; close and reopen after updates rather than silently mixing old settings with new defaults.

## Migration Plan

Ship configuration resolution, picker selection, regression coverage, and README updates together. Existing `config.json` files remain valid and automatically receive `Search: ` at the next launch. Document global-only and mixed override examples, supported variant names, inheritance, literal/empty values, and reopen-to-adopt behavior; replace the README's hard-coded-prompt statement. Record actual automated and interactive outcomes when verified.

To retain the previous appearance, set `prompt.default` to `"◉/> "`. To roll back to code predating this feature, remove the `prompt` section first because the previous strict validator rejects it, then restore the earlier code and reopen Pickr.
