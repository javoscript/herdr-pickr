## Context

See `proposal.md` for motivation. `src/pickr/keymap.lua:M.footer` currently walks `M.order`, displays effective aliases through `M.display`, and wraps at 70 Unicode characters. Its initial accumulator contains `no entries` for zero candidates. `src/pickr/core.lua` uses this renderer for `--footer` and passes the same closure to `runtime.run_picker`; successful publication uses it in `change-footer:`. Loading/failure use the header for status and leave the footer in place.

The working tree contains the configurable-keybindings implementation and an unarchived `configurable-keybindings-and-themes` change. Its `picker-keybindings` delta requires effective aliases and omission of disabled hints, but does not mandate wrapping. Main `picker-refresh` specs contain older default-key and preview wording already addressed by that change; this layout change does not resolve those unrelated differences. README wrapping promises do need replacement when implementing this plan.

## Goals / Non-Goals

**Goals:**
- Centralize the grouping in the existing renderer so launches and refreshes agree.
- Specify narrow-width, long-alias, and empty-group behavior before implementation.

**Non-Goals:**
- Change key resolution, action dispatch, refresh gating, popup dimensions, or preview state.
- Add responsive width measurement, custom truncation, alias elision, or footer settings.

## Decisions

### Use two explicit action groups in the footer renderer

Keep the existing labels and alias display. Assemble each group using enabled hints and join nonempty groups with one newline. The action group is `accept`, `close`, `toggle_preview`, `refresh`; the variant group is `tabs_current`, `tabs_all`, `spaces`, `agents_current`, `agents_all`. Leave `M.order` intact because key resolution, expected keys, and other behavior also use it.

Increasing the current wrap threshold would still split groups for custom bindings and would not guarantee the requested grouping. Separate renderers in core and runtime would introduce needless drift.

### Preserve full hint text without automatic wrapping

Interpret two rows as two logical footer lines with default/enabled variant shortcuts. Keep all aliases in generated text, even when a group exceeds the old 70-character threshold. Use fzf's normal horizontal clipping when the available width is insufficient; widening reveals the text again. This is an explicit planning assumption: the request does not prescribe a minimum terminal width or shortening scheme.

Custom abbreviations or dropping aliases would weaken existing key-discovery behavior. Width-aware wrapping would contradict the two-row layout and require geometry tracking that the renderer currently lacks.

### Preserve empty and disabled states compactly

Prefix `no entries` to the action row for zero candidates. Omit disabled hints before joining to avoid stray separators. Omit the variant row entirely when that group is empty, preserving the existing one-line acceptance/close-only case tested in `tests/test.lua`. Reserve no blank row. Search filtering does not change candidate count or trigger the empty-list prefix.

### Keep the existing initial/refresh transport

The shared footer closure already supplies both initial arguments and refresh publication. Retain that wiring and the existing status-header behavior. Verify multiline text through real fzf during initial display and refresh rather than assuming string-level checks establish visual behavior.

## Risks / Trade-offs

- [Narrow popups and large alias lists hide the right-hand text] → Document clipping and check resize behavior; do not silently discard aliases from the generated footer.
- [Multiline refresh transport renders differently from initial arguments] → Inspect refresh, empty/nonempty transitions, failure/retry, and variant switching in real fzf 0.74.3+.
- [The prerequisite keymap work is still unarchived] → Apply on top of that implementation and preserve its effective-keymap contract; this change owns only the new `picker-footer-layout` capability.
- [Existing documentation promises extra rows] → Replace those statements in the popup action keys, column headers, and variant-switching descriptions during implementation.

## Migration Plan

Implement the footer renderer adjustment atop the configurable-keybindings work, run the Lua regression suite, and perform focused live footer acceptance checks. Reopen a picker to use the new renderer; no configuration migration is required. Rollback consists of restoring the prior footer renderer and corresponding documentation.
