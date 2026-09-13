## Context

See proposal.md for motivation. The README currently uses a GitHub-compatible HTML table with four linked theme PNGs at 480-pixel display width, three showing similar tab views. Images live in `docs/images/`. `tests/documentation.lua`, called by `tests/test.lua`, validates configuration examples and public setting inventories rather than gallery appearance.

The pane and unified type/scope changes are still in progress. Their README terminology and launch/configuration migrations remain owned by those changes. Main plugin-distribution specs retain some older five-view/platform wording; this presentation-only change must not silently reconcile those unrelated requirements.

Design is included to settle the placeholder format, replacement workflow, and exact capture scenes before implementation.

## Goals / Non-Goals

**Goals:** Render a complete, honest showcase before screenshots exist; make each slot easy for the maintainer to identify and replace; preserve the README's existing GitHub rendering conventions.

**Non-Goals:** Capture screenshots automatically, simulate the finished UI, add video/GIF content, redesign the configuration reference, or require the maintainer's final captures to complete the placeholder implementation.

## Decisions

### 1. One hero and four complementary gallery cells

Create `## Pickr in action` directly after feature highlights and before Installation. Add an `In action` navigation link to `#pickr-in-action`, retaining the existing Themes link to configuration. Put a centered hero at up to 960-pixel display width above a two-by-two table with 480-pixel images. Link every image to its full-size local asset. Use one short feature caption and a compact picker/scope/theme label per slot.

This retains the familiar README structure while prioritizing feature variety over four theme samples of similar content. Remove the old statement that these examples use a custom prompt: intended captures use defaults unless individually disclosed.

### 2. Explicit local SVG placeholders, later replaced with PNG captures

Create five simple static SVGs under `docs/images/`, named `<scene>-placeholder.svg`. Use matching 16:10 canvases, readable neutral text, and the labels `Screenshot placeholder`, scene, scope, and suggested theme. They are visual placeholders, not simulated Pickr screens. Use no scripts, external resources, or image-generation dependency.

Each README slot initially links to and displays the corresponding SVG. Its alt text starts with `Screenshot placeholder:` and describes the intended scene. Add an adjacent HTML comment naming the intended `<scene>.png` replacement and a reference to `docs/SCREENSHOTS.md`. A brief visible sentence explains that the showcase contains placeholders awaiting 0.2.0 captures.

The guide instructs the maintainer to save a real PNG at the specified path, update both the link `href` and image `src`, change the alt text to describe the actual capture, and remove that slot's replacement comment. Remove the placeholder notice once all five slots are real. Do not put PNG bytes into `.svg` files or link nonexistent PNGs before capture. Existing theme PNGs remain untouched.

Compared with broken image URLs or TODO text, actual SVG assets make framing and layout inspectable immediately. They require a small explicit path update when replaced, which the slot comments and guide document.

### 3. Exact scenario inventory and captions

| Position / scene basename | Picker / scope / suggested theme | Setup and selection | Caption |
| --- | --- | --- | --- |
| Hero: `panes-all` | Panes / All spaces / Catppuccin | Spaces such as storefront, api, and infra; pane labels editor, dev server, tests, logs. Query `server`, with multiple matching results across projects. Select readable colored development-server output. | Find the right terminal across every project, with a preview before you jump. |
| Top left: `panes-tab` | Panes / This tab / Rosé Pine | One split tab with editor, running app, test watcher, and shell/log viewer. Empty query shows the four panes. Select the test watcher with a compact summary; show a little underlying split layout. | Jump straight to the editor, tests, or logs in your current tab. |
| Top right: `agents-all` | Agents / All spaces / Gruvbox | Genuine agent sessions: waiting/blocked, unseen completion, and active work. Descriptive task titles such as Fix checkout validation and Add health endpoint. Select the agent waiting on a readable question. | See which agents need you, and inspect their work before switching. |
| Bottom left: `spaces-worktrees` | Spaces / no scope / Solarized | Several projects and two related worktrees with understandable branch names. Show grouping, paths, and tab counts clearly. | Keep projects and their worktrees together while moving between spaces. |
| Bottom right: `tabs-space` | Tabs / This space / Catppuccin | Tabs such as frontend, backend, database, and review. Short query leaves two or three results. Select an informative preview; keep scope controls readable. | Search your project's tabs without losing the context of where you started. |

Captions describe the intended scene; the placeholder label explicitly identifies its current status. Final captures must match the implemented UI, including effective scope and any unavailable scope styling; do not fake unavailable states or impose proposed labels if implementation changes them.

### 4. Put capture instructions in a maintainer guide

Create `docs/SCREENSHOTS.md` with the scenario table, placeholder-to-PNG path mapping, README replacement steps, and a short checklist:

- Capture after pane picking and unified type/scope navigation are finalized.
- Use consistent terminal dimensions, font size, popup geometry, preview proportions, and preferably 16:10 framing. Prioritize readable content over exact aspect ratio.
- Use default prompt/keybindings, with scope controls, footer hints, and previews visible. Disclose any intentional customization.
- Aim for 5–10 meaningful rows where useful, with the four-pane narrow-scope example intentionally smaller.
- Use short queries for visible match highlighting and compact previews: test summary, diff, server startup, or agent question.
- Check readability at actual README widths, not only full resolution. Avoid accidental private paths or credentials in captures.
- Theme suggestions provide variety; captions must reflect the theme actually captured.

The guide is maintainer material outside the user-facing configuration reference. It contains no recording instructions or video TODOs.

## Risks / Trade-offs

- [README changes overlap with in-progress feature work] -> Integrate after the feature README edits and preserve their new behavior/configuration content.
- [Placeholder images could be mistaken for release evidence] -> Label both the asset and alt text explicitly; keep the temporary visible notice until replacements are complete.
- [Gallery text becomes too small] -> Inspect at 480-pixel width and full-size links; simplify scene content during capture rather than shrinking the font further.
- [Automated documentation checks miss visual mistakes] -> Run the existing documentation checks and manually inspect GitHub-compatible rendering, all five asset links, alt text, and section navigation. No implementation-mirroring image tests are necessary.

## Migration Plan

Apply the README/placeholder/guide update after the final type/scope README integration. This change is complete with five valid placeholders and the capture guide; the user's later screenshot replacement is an explicit handoff, not an unfinished implementation task. Final captures can be supplied before publishing 0.2.0. Reverting these documentation changes restores the old gallery; preserved PNGs make that straightforward.
