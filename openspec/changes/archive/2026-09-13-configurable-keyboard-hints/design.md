## Context

See `proposal.md` for motivation. Configuration is strictly decoded in `src/pickr/config.lua`; `popup` currently contains only dimensions, and its validation loop treats every field as a dimension. Resolved settings are serialized by the launcher and reused by the picker owner.

`src/pickr/core.lua` always supplies `--footer` using a local callback around `keymap.footer`. That callback is also passed to `runtime.run_picker`, whose successful refresh publication always emits `change-footer`. Loading and failure messages use the header independently. `keymap.footer` owns the two-row layout and the empty-list prefix.

The existing footer requirements are unconditional. The delta explicitly limits that contract to visible hints while adding complete section removal for hidden hints. This design spans configuration, startup rendering, and refresh publication, so a design artifact is useful despite the small scope.

## Goals / Non-Goals

**Goals:**
- Resolve visibility once and consume it consistently at both footer output sites.
- Remove footer layout allocation as well as text when hidden.
- Keep visible-footer formatting and action binding construction independent of visibility.

**Non-Goals:**
- A runtime toggle shortcut, per-view overrides, or a new footer formatting system.
- Changing the popup's requested dimensions or relocating the empty-list prefix.

## Decisions

### Add `popup.show_hints` to the existing configuration object

Use a boolean default of `true`, following existing omission/null and strict-type conventions. Treat this field separately from the dimension validation loop, which must continue validating only width and height. Preserve the resolved value through the existing settings snapshot and validate its type in owner handoff handling.

The option name is a planning assumption: the request specifies behavior but no field name. `popup.show_hints` describes persistent session presentation and fits the existing popup object. A new top-level `hints` object would add unnecessary structure; `enabled_by_default` would imply a runtime toggle that is outside scope.

### Make the footer callback optional when hints are hidden

In `core.lua`, create/use the existing footer callback only for visible hints and only then add the startup `--footer` argument. Pass the optional callback into `runtime.run_picker`; successful publication must append `change-footer` only when the callback exists. Continue the remaining publication actions, header clearing, and acceptance/refresh rebinding in both cases.

This uses the existing callback boundary rather than teaching the keymap formatter about popup settings. Returning an empty string alone was considered but is weaker: it can leave footer allocation semantics dependent on fzf and still emits unnecessary footer update actions. Omitting footer creation and updates makes the intended absence explicit.

### Hide the entire footer, including `no entries`

Interpret “the whole hints section” as the complete existing footer, not just shortcut labels. Keep loading and retry/error text in the header. Retaining a footer solely for `no entries` would contradict whole-section removal and reclaim less space in empty views.

### Extend existing regression coverage

Use `tests/configuration.lua` for default/null/false/type checks, dimension independence, and settings snapshot round trips. Extend `tests/test.lua` picker fixtures for all five views, switching, empty and zero-match states, and functional shortcuts without footer output. Add a focused real-fzf/PTY case using the existing harness for hidden-footer layout and refresh publication, including failure/retry status visibility. Existing default-on assertions remain the compatibility oracle.

## Risks / Trade-offs

- [The popup validator currently assumes every popup field is a dimension] → Separate boolean validation and retain dimension boundary/error regression checks.
- [Refresh can recreate a footer removed at startup] → Gate both output sites with the same optional callback and exercise successful empty/nonempty refreshes.
- [Text-only assertions can miss reserved footer rows or separators] → Verify the actual terminal layout with the existing real-fzf harness on the supported baseline.
- [Hiding the footer also hides its empty-list explanation] → Document that the option removes the entire section; preserve independent refresh/error messages.

## Migration Plan

Deploy the configuration and rendering updates together. Existing files require no edits because the default is visible. Document `{"popup":{"show_hints":false}}` and reopening to apply changes, and add the default to README's complete configuration example. To roll back the feature, remove the new field from user configuration before using a version whose strict decoder does not recognize it.
