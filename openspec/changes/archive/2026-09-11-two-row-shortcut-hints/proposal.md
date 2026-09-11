## Why

The footer currently wraps a single stream of shortcut hints at 70 characters, splitting related controls across extra rows. Grouping action controls and variant shortcuts into two predictable rows makes the footer easier to scan and gives more space to picker entries.

## What Changes

- Put switch, close, preview, and refresh hints on the first footer row, in that order.
- Put tabs here, all tabs, spaces, agents here, and all agents shortcuts on the second row, in that order.
- Replace automatic 70-character wrapping with explicit row grouping, preserving configured aliases and omitting disabled actions.
- Keep `no entries` on the first row for an empty candidate list; omit the second row when all variant shortcuts are disabled.
- Retain full generated hint text and let fzf clip rows when the popup is too narrow; no extra rows are generated for long alias lists.
- Update the documented footer behavior and verify initial and refreshed rendering across all five variants.

## Capabilities

### New Capabilities
- `picker-footer-layout`: Stable action/variant row grouping for bottom shortcut hints.

### Modified Capabilities
None. The existing `picker-refresh` requirement to advertise refresh remains satisfied. Effective-keymap hint requirements belong to the in-flight `configurable-keybindings-and-themes` change; this change adds a layout contract without replacing those requirements.

## Impact

- Implementation target: `src/pickr/keymap.lua` (`M.footer`), already used by initial rendering in `src/pickr/core.lua` and refresh publication in `src/pickr/runtime.lua`.
- Verification target: existing Lua fixtures in `tests/test.lua`; live fzf inspection for multiline footer rendering and clipping.
- Documentation target: `README.md` currently promises wrapping/additional lines for configured aliases and will need revision during implementation.
- Builds on the configurable-keybindings implementation present in the working tree. No new dependencies, settings, or keybinding changes are needed.
