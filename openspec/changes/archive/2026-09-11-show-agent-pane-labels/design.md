## Context

See `proposal.md` for motivation and `specs/agent-pane-labels/spec.md` for the behavior contract. `core.lua` builds both agent variants from one snapshot, currently ending each row with `agent.pane_id`. The snapshot already includes `panes`, used for tab directory and preview lookup. Existing fixtures do not exercise pane labels; this plan assumes the pane's optional label is available as `snapshot.panes[].label`, consistent with workspace and tab label naming.

`aligned_rows` cleans and measures plain metadata before adding trusted ANSI styling. It currently stores one `parent_field`/`parent_suffix` pair per entry, which cannot represent both a space-parent annotation and a pane-label annotation. A short design is included to settle that representation before implementation.

## Goals / Non-Goals

**Goals:**
- Support independently styled suffixes in multiple columns while retaining the clean-before-style rendering order.
- Obtain labels from the existing snapshot with a keyed lookup rather than repeated scans or API calls.
- Preserve hidden ID fields and production fzf field boundaries.

**Non-Goals:**
- Changing agent sorting, workspace grouping, or the column schema.
- Introducing a general rich-text renderer, label editing, or live label refresh.
- Adding sibling-style padding before pane annotations; use one separating space.

## Decisions

1. **Look up pane labels by pane ID in the existing snapshot.** Build a pane-label map for agent candidate construction and use the matching pane's label. Missing pane records and absent/null/empty labels yield no suffix. This avoids conflating agent names or terminal titles with pane labels. Alternatives: per-agent `pane get` calls would add latency and inconsistent reads; relying on an agent label field has no support in the current fixtures or code.

2. **Use field-indexed muted suffix metadata.** Replace the single parent suffix slot with a small map keyed by column index, allowing space and pane suffixes to coexist. Keep the existing worktree-prefix handling and share the same trusted RGB escape sequence (`82;79;103`, equivalent to `#524f67`). An independent pane-only rendering branch would work but duplicate the formatting logic and color. Do not infer annotations by parsing brackets in arbitrary text.

3. **Construct plain text first and style after measurement.** Clean the pane label with `clean`, build `[label]`, append it to the displayed pane ID, and record that exact cleaned suffix. Render only the suffix in gray and reset afterward. Treat whitespace-only labels as present under existing `value` semantics; do not introduce trimming or truncation. Embedding ANSI while building text would conflict with existing metadata cleaning and width calculation.

4. **Keep display text separate from identity.** Leave `entry[1]` and `entry.preview_pane` as the raw pane ID. Retain the existing pane column and fzf arguments so label searches use existing per-column matching. A separate label column would change the requested layout and field indexes.

## Risks / Trade-offs

- [Shared annotation changes could affect worktree rendering] → Exercise existing grouping, prefix, Unicode padding, and parent-color regressions alongside a row containing both suffixes.
- [Pane label data shape is assumed rather than covered by current fixtures] → Confirm the installed snapshot's pane-label field during implementation using read-only API/schema inspection before wiring the lookup; retain absent-metadata fallback.
- [Control characters or Unicode could disrupt rendering] → Reuse the existing cleaning and Unicode length approach, and test label metadata with both. Terminal display-width limitations remain those of the existing renderer.
- [Long labels increase row width] → Preserve full labels, consistent with other untruncated metadata; use the existing fzf viewport behavior.

## Migration Plan

Update `core.lua`, the fixture regressions in `test.lua`, and the relevant column/search documentation in `README.md`. Run `lua "$HOME/.config/herdr/plugins/pickr/test.lua"`. Lua changes take effect on the next picker launch; no manifest relink or data migration is required. Rollback consists of reverting these changes and reopening the picker.
