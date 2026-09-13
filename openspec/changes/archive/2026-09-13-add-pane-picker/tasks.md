## 1. Confirm prerequisite and extend launch context

- [x] 1.1 Confirm `remember-per-view-search-and-selection` is implemented and its deltas are synchronized before applying this change; verify the working implementation has popup-local view memory and the main keybinding spec contains its memory/restoration requirements, and reconcile any drift with this package's memory-first design.
- [x] 1.2 Capture an immutable workspace/tab origin for every launch in `src/open.lua` and `src/pickr/runtime.lua`, including an explicit absent-tab handoff and direct-owner fallback; verify action-context precedence, changed focus between launcher/owner, non-pane initial views, missing tab context, and deleted origin fixtures without recapturing later active tabs.
- [x] 1.3 Register `panes-tab`, `panes-current`, and `panes-all` in `herdr-plugin.toml` and both entrypoints with valid kind/scope mappings; verify all eight action/pane registrations, configured action dimensions, direct-launch defaults, and rejection of unsupported tab-scoped kinds through launch/manifest tests.

## 2. Build pane candidates and exact targeting

- [x] 2.1 Add pane candidate generation from one snapshot's known workspace/tab/layout membership joined to pane metadata; verify all three scope boundaries, unique IDs, ordinary and agent panes, embedded plugin terminals, popup/orphan exclusion, zoomed-tab membership, and existing worktree/tab/layout order in Lua fixtures shaped like Herdr 0.9.0 metadata.
- [x] 2.2 Render pane status/title/label/directory and scope context through shared column projection and themes; verify fallback values, Unicode/control cleaning, default column layouts, worktree and pane-label annotation styling, reordered/single-column views, and visible-only independent search in rendering and real-fzf column tests.
- [x] 2.3 Share the general pane-focus helper between agent and pane selections and route pane previews by exact pane ID; verify selecting a non-focused split in an inactive tab/space, duplicate labels, closed-pane preview, rejected/wrong-ID focus responses, and no focus on close/switch/refresh using fake Herdr fixtures.

## 3. Integrate configuration and lifecycle

- [x] 3.1 Add `panes_tab`, `panes_current`, and `panes_all` key/column/prompt variants with Alt+1/2/3 defaults and explicit scope titles; verify defaults, omission/null inheritance, aliases, disabling/remapping, conflicts with existing user key overrides, invalid inactive pane settings, and launcher-owner settings snapshots in configuration tests.
- [x] 3.2 Append pane hints to the second footer row while retaining clipping, aliases, empty-state prefixes, and visibility rules; verify exact default rows, disabled/all-disabled variant groups, narrow-width behavior, and no footer space when hints are hidden in Lua and PTY tests.
- [x] 3.3 Connect all pane views to popup-local memory and the existing refresh controller using immutable origin context and pane identity; verify independent pane-scope/agent memory, first visits, self-switches, fresh membership after moves, removed/mismatched-ID fallbacks, latest query retention through loading/failure, successful retry, cancellation, and rejection of late work.

## 4. Complete integration verification and documentation

- [x] 4.1 Extend the switch matrix from 25 to all 64 source/destination routes, including empty and zero-match states, both preview visibility states, remapped/disabled keys, and launches without expected-key output; verify the expanded matrix and targeted real-fzf pane round trips pass without changing the five existing view behaviors.
- [x] 4.2 Update README to describe eight views, all three pane actions, Alt+1/2/3 defaults and remapping, full default JSON, pane columns, original-tab/space semantics, popup exclusion, exact-pane preview/focus, and per-view memory; verify documentation/configuration fixtures agree with the manifest and resolved defaults.
- [x] 4.3 Run `lua tests/test.lua` and `openspec validate add-pane-picker --strict`; verify integrated rendering/configuration/focus/PTY checks pass, review each delta scenario against implementation evidence, and confirm memory-first spec synchronization preserves the eight-view contract.
