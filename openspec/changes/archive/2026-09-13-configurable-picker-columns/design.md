## Context

See proposal.md for motivation. `src/pickr/core.lua` currently builds positional entries and a separate hard-coded header for each kind/scope. `aligned_rows` measures metadata before adding ANSI styling, then emits selection ID, preview ID, and displayed text. Status styling is a row prefix; annotations refer to positional field indexes. fzf hides the two ID fields with `--with-nth=3..` and searches individual displayed fields using `--nth` indexes derived from the fixed header.

`src/pickr/config.lua` strictly validates typed JSON, resolves defaults once, and serializes resolved settings into the launcher-to-owner snapshot. Refresh receives those same settings; switching recreates the picker with the destination kind/scope. Existing tests cover default headers, alignment, annotations, independent matching, hidden IDs, targeting, and session stability.

This design is warranted because configuration, rendering, and fzf field selection must agree on one effective layout.

## Goals / Non-Goals

**Goals:**
- Use one canonical source for supported column IDs and default layouts.
- Apply an ordered projection before alignment, retaining entity identity independently.
- Preserve default output, metadata cleaning, annotation styling, and independent matching.

**Non-Goals:**
- New columns, custom headings, widths, or separately configurable annotations/glyphs.
- Search-only hidden columns, runtime layout editing, or changes to candidate ordering.
- A general-purpose table rendering framework.

## Decisions

### Share a small column catalog

Introduce a focused Lua module such as `pickr.columns` shared by configuration and core rendering. It defines the five ordered defaults and their allowed IDs, with `pane` mapping to heading `pane [label]`. Reuse the existing variant mapping when resolving kind/scope rather than introducing alternate public names.

Duplicating defaults in the decoder and header builder would invite drift. A generic plugin column registry is unnecessary for the fixed inventory.

### Resolve complete per-variant arrays at launch

Accept `columns` directly keyed by the existing variant names. Omitted/null containers or variants resolve to copied defaults; arrays fully replace their variant. Require nonempty arrays of unique, case-sensitive valid IDs. Reject wrong JSON container types, invalid elements, unknown variants, and unsupported columns, including in inactive variants, with field/index diagnostics.

Include resolved arrays in settings and the existing snapshot; check their validity at the snapshot boundary without reading user configuration again. Rendering entrypoints that currently allow omitted settings continue to use default layouts. Do not introduce global inheritance: the five available inventories differ, and direct per-variant lists are explicit.

### Project columns before alignment and keep styling with cells

Retain candidate collection, scope filtering, grouping, and sorting. Associate each existing value with a column ID, then assemble ordered cells from the resolved list for both rows and headers. Preserve selection ID and preview ID outside that projection and retain the three-part tab-separated row protocol.

Represent trusted glyph styling and annotation metadata on the relevant cell, or remap equivalent positional metadata during projection. Measure cleaned text with the existing width rules before applying ANSI styling. Status cell width includes its glyph and following space; its header reserves the same prefix width. Moving status therefore moves its full occupied width, and hiding it leaves no prefix or gap. Space tree prefixes and parent suffixes move with space; pane label suffixes move with pane. The header uses the same projection even with no candidates.

Projecting only the final rendered string or changing fzf display transforms would leave positional annotation bookkeeping and column alignment coupled to the old layout. Projection before formatting keeps one source of truth for the visible fields.

### Search the projected display

Keep the existing delimiter and hidden-ID protocol. Derive fzf's individual `--nth` indexes from the effective visible column count, including single-column configurations, instead of the default header. Omitted column values never enter displayed/searchable text. Separate query terms can match different visible columns; one term cannot cross column boundaries.

Do not add a hidden search payload: users explicitly confirmed that hiding a column removes it from search. Raw values may still be needed for sorting or targeting and remain available internally.

### Reuse session settings on every render

Initial rendering and refresh use the same resolved layout; switching picks the destination layout from the same snapshot. Retry does not resolve configuration again. No runtime control protocol changes are required because selection IDs and preview IDs retain their positions.

## Risks / Trade-offs

- Moving a styled status cell changes width bookkeeping -> test first, middle, last, hidden, and status-only layouts, including aligned headers.
- Positional annotations can attach to the wrong column after projection -> keep metadata with cells or remap it centrally; exercise both annotations in one reordered agent row.
- A stale fixed search-field count can leak or omit matches -> derive it from the same layout and exercise real fzf matching with one-column and reordered subsets.
- Hiding identifying columns can make rows visually indistinguishable -> allow it as requested while preserving distinct hidden IDs and target correctness.
- The active keyboard-hints change touches nearby configuration, core, and documentation -> integrate additively with the current settings and footer behavior rather than replacing adjacent work.

## Migration Plan

No user migration is required: absent `columns` retains the current output and search behavior. Ship configuration, rendering, tests, and README updates together. Existing main specs must be updated through these deltas so fixed-order and pane-label guarantees become conditional on the effective layout. A rollback to a version without this feature requires removing `columns` from user configuration because unknown settings intentionally block launch.
