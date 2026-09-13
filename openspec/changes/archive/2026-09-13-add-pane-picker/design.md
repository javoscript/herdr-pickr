## Context

See proposal.md for motivation. Pickr currently registers five views across the manifest, both entrypoints, keymap variants, and column defaults. `core.snapshot_candidates` already joins pane metadata to tab layouts for preview targets; `core.preview` reads any pane's visible ANSI screen. `runtime.focus_agent_pane` uses the general Herdr `pane.focus` API. Only workspace origin is currently captured and handed to the popup.

Read-only inspection of the installed Herdr 0.9.0 bundled API schema confirmed that `PaneInfo` contains `pane_id`, `workspace_id`, `tab_id`, `agent_status`, optional `label`, `terminal_title_stripped`, `terminal_title`, `title`, `foreground_cwd`, and `cwd`. `PaneLayoutSnapshot` contains a tab/workspace identity and an ordered pane array. Upstream v0.9.0 `src/app/api/plugins/context.rs` confirms that plugin invocation context includes `tab_id` and `focused_pane_id`, including the pane's containing tab. These are sufficient without guessing tab IDs from pane-ID syntax or fetching metadata per candidate.

The view-memory prerequisite is implemented and its keybinding and refresh deltas are synchronized into the main specs. This design builds on its popup-owned memory and restoration protocol. The current configuration spec still mentions resetting queries; this change reconciles those overlapping configuration requirements.

This crosses launch context, candidate generation, shared configuration, and UI lifecycle, so the design artifact is applicable.

## Goals / Non-Goals

**Goals:**
- Treat an ordinary pane as a first-class destination with the same identity for selection and preview.
- Extend the existing view model with one additional scope rather than invent a navigation hierarchy.
- Share configuration, matching, refresh, and view-memory behavior across all eight variants.

**Non-Goals:**
- Pane creation, deletion, movement, zoom controls, command execution, or batch selection.
- Searching terminal contents, live previews, process inspection, or adding an agent-name column to pane views.
- Changing agent sorting, introducing adaptive footer layout, or persisting view memory.
- Automatically drilling into the highlighted tab/space; narrow scopes refer to launch origin.

## Decisions

### 1. Add three variants with explicit public scope names

| Action / manifest entrypoint | Configuration variant | Internal kind/scope | Title | Default key |
| --- | --- | --- | --- | --- |
| `panes-tab` | `panes_tab` | `panes`, `tab` | Panes in this tab | `alt-1` |
| `panes-current` | `panes_current` | `panes`, `current` | Panes in this space | `alt-2` |
| `panes-all` | `panes_all` | `panes`, `all` | Panes in all spaces | `alt-3` |

Keep `current` meaning current space, matching existing tab/agent actions. Extend entrypoint validation with valid kind/scope pairs so adding `tab` does not accidentally admit unsupported tab-scoped agent or workspace views. All eight views expose the new internal switching actions, including self-switching. Use explicit titles instead of the current generic title interpolation for the new kind.

Alternative: Two pane views would omit either the useful split-local context or the global lookup use case. A drill-down action would mean a different target model and require additional back-navigation semantics.

### 2. Capture one immutable origin context before popup creation

Represent popup origin as workspace ID plus optional tab ID. Resolve it for every launch, even when initially opening tabs, agents, or spaces, because the user can later switch to panes-in-tab. Preserve the current workspace precedence. For tab context, prefer an explicit Pickr origin handoff, then applicable Pickr plugin invocation context. If that context lacks a tab, resolve the originating workspace's active tab from a snapshot once; do not take an unrelated globally focused tab. Direct picker invocation similarly resolves its originating workspace's active tab once. Validate any supplied tab against its workspace when assembling candidates.

Hand the captured tab through `PICKR_ORIGIN_TAB_ID` alongside the existing workspace environment value. Use an explicit absent-tab representation in the handoff so the owner cannot silently recapture a newer tab after startup. Do not re-resolve origin on switches or refreshes. A deleted origin tab/space yields an empty narrow view; it must not broaden or rebind to a newly active tab. If no tab was available at launch, panes-in-tab shows an empty state and remains switchable. Missing tab context must not break the five existing launch actions.

Alternative: Reading active focus every time would make scope depend on other clients or the popup itself. Capturing origin only for pane launches would break switches from existing views.

### 3. Derive candidates from tab-layout membership and one snapshot

Index `snapshot.panes` by pane ID, then traverse known workspaces in existing grouped-worktree order, their tabs in snapshot order, and each tab's layout pane array in API order. Include each matching pane once, with matching pane/tab/workspace metadata; skip orphan metadata, missing pane entries, and entries not attached to a known tab layout. Agent panes are ordinary candidates here; embedded plugin terminals are eligible when they occupy a tab-layout slot. Transient popup overlays are not tab-layout candidates and must not appear, including Pickr's own popup.

Use the ordered layout array, not screen rectangles or global `focused`, as the source of stable pane order. Retain `--no-sort` for all pane variants so fuzzy matching filters this order rather than ranking agent statuses or rearranging space groups. Include the original focused terminal if it is a normal eligible pane; there is no special hide-current behavior.

Alternative: Using the agent list excludes non-agent terminals. Blindly listing pane metadata admits detached/overlay entities and loses layout order. Fetching pane details individually would add work proportional to candidate count and lose snapshot consistency.

### 4. Reuse column semantics with scope-appropriate context

| Variant | Default and allowed columns, in default order |
| --- | --- |
| `panes_tab` | `status`, `title`, `pane`, `directory` |
| `panes_current` | `status`, `tab`, `title`, `pane`, `directory` |
| `panes_all` | `status`, `space`, `tab`, `title`, `pane`, `directory` |

Use the pane's own status, existing glyph/palette mapping, and `-` for unknown status. Title preference is nonempty stripped terminal title, terminal title, then title, otherwise `-`; clean text with existing metadata sanitization. Render `pane-id [label]` under `pane [label]`, with label annotation styling matching the agents. Directory uses nonempty foreground cwd then cwd, with the same abbreviation and truncation as tab directories. Space names and worktree annotations use the existing tab-style grouping.

Only visible column values and annotations are searchable. Hidden IDs still carry selection/preview identity. A one-column pane view remains valid. No extra semantic theme roles are required.

Alternative: A separate label column would diverge from the existing pane-label convention. Showing space/tab in every scope would add redundant columns in the narrow views.

### 5. Share exact-pane focus and existing refresh/memory machinery

Generalize the internally agent-named focus helper to serve both pane and agent selections, retaining server-confirmed pane identity and error handling. Reuse the existing preview helper without a per-row pane lookup during listing. A pane that closes before preview yields the existing unavailable message; failed focus reports the error rather than selecting another pane.

Register all three new variant keys with the memory change's popup map. Refresh and returning-view restoration use pane IDs, independently for each scope. Pane moves affect fresh scope membership: a pane leaving the original tab disappears there but remains eligible globally. Reuse cancellation, query retention, acceptance gating, retry, and preview-visibility behavior. Pass immutable origin context through both initial and asynchronous snapshot rendering paths.

Alternative: Separate pane refresh or memory controllers would duplicate sensitive lifecycle code. Sharing pane and agent memory by ID would incorrectly couple distinct views.

### 6. Keep the two-row footer and use remappable scope-number keys

Append `panes in tab`, `panes in space`, and `all panes` to the second footer row after the existing five hints. Use `Alt+1/2/3` as proposed defaults corresponding to narrow-to-wide scope; they do not collide with the current default Pickr actions. Keep aliases, disabled-action omission, clipping, and `popup.show_hints` unchanged. Inherited fzf bindings still yield to Pickr bindings; a collision with a user-configured Pickr action remains a diagnostic requiring an explicit remap/disable.

This deliberately accepts more clipping at narrow widths. Users can remap/disable shortcuts or hide hints with existing settings. A third row, responsive wrapping, or a scope-cycling action would change the established footer/interaction model and is outside this proposal.

### 7. Sequence after view memory and reconcile specification overlap

Implement and synchronize the memory change before applying this one. The `picker-keybindings` delta includes the resulting lifecycle and per-view memory requirements in full, extending them to eight variants and 64 routes. The configuration delta removes legacy reset-on-switch claims for prompt/column changes so they defer to the same memory behavior. Do not apply this package's overlapping deltas first or let an older five-view delta overwrite them afterward.

Alternative: Making the pane proposal independent would require either restoring the obsolete reset semantics or duplicating the memory implementation. This is a documented change dependency, not a new workflow configuration.

## Risks / Trade-offs

- [Tab origin can drift between launcher and owner] -> Capture before popup creation, carry explicit absence, and test changed startup context and missing/deleted origin.
- [Popup metadata or zoomed layouts could be mistaken for ordinary pane membership] -> Use full tab-layout pane membership, add fixtures for overlays and zoomed tabs, and verify against Herdr 0.9.0 metadata without filtering solely by visible rectangles.
- [New default keys conflict with user settings] -> Retain actionable collision diagnostics and document disabling/remapping `keys.panes_tab`, `keys.panes_current`, and `keys.panes_all`.
- [Longer footer hides trailing shortcuts at common widths] -> Document the keys in README, retain deterministic clipping, and test hidden/disabled hint layouts rather than adding a separate layout feature.
- [Eight views expose hard-coded five-view assumptions] -> Extend manifest/config/launch/column/theme/documentation tests and the full 64-route switch matrix, including self-switches and no-expect configurations.
- [Overlapping planning artifacts can undo newer behavior if synchronized out of order] -> Keep memory-first apply/sync/archive order explicit and validate the combined requirements before implementation completion.

## Migration Plan

After the memory prerequisite is implemented and synchronized, add registrations, origin context, rendering, configuration, and tests together. Update README's feature inventory and complete default configuration. Existing user configuration receives defaults for omitted pane variants; users with conflicting keys must remap or disable them. No stored data migration or dependency upgrade is required.

Rollback removes the three registrations and pane-specific configuration keys; users who added those keys must remove them for the older strict config parser. The existing five views retain the memory feature supplied by the prerequisite.
