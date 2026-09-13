## Why

Users who already know Pickr's shortcuts should be able to reclaim the space occupied by keyboard hints. A default-on option preserves the familiar popup while allowing the entire hints section to be hidden.

## What Changes

- Add `popup.show_hints`, a boolean defaulting to `true`; omitted or null values retain the default.
- With `false`, remove the complete footer section, including both hint rows and the empty-list `no entries` prefix, without reserving blank footer space.
- Apply the setting to all five views throughout switching, refresh, failure, and retry, using the existing launch settings snapshot.
- Preserve configured keyboard actions and the separate refresh/error status area when hints are hidden.
- Document the setting, default, validation, and reopen-to-apply behavior in README configuration guidance.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `plugin-configuration`: Define the popup hint visibility option and its validation and session lifetime.
- `picker-footer-layout`: Make the existing grouped footer conditional on hint visibility, including empty-list and refresh behavior.

## Impact

- Configuration decoding and resolved settings in `src/pickr/config.lua`.
- Footer setup in `src/pickr/core.lua` and refresh publication in `src/pickr/runtime.lua`; retain `src/pickr/keymap.lua`'s visible-footer formatting.
- Existing Lua configuration, picker, and real-fzf regression checks, plus `README.md` configuration examples.
- No new dependencies; default behavior remains compatible.
