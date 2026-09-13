## 1. Placeholder assets

- [ ] 1.1 Create `docs/images/panes-all-placeholder.svg`, `panes-tab-placeholder.svg`, `agents-all-placeholder.svg`, `spaces-worktrees-placeholder.svg`, and `tabs-space-placeholder.svg` with consistent framing and explicit placeholder/scene/scope/theme labels; verify all five render locally without external resources and preserve the existing PNGs.

## 2. README showcase

- [ ] 2.1 After the pane and unified type/scope README edits are available, replace Theme spotlight with Pickr in action and add its top navigation link; verify the section follows feature highlights, precedes Installation, and retains the feature changes' configuration and migration documentation.
- [ ] 2.2 Add the linked Panes / All spaces hero and the four gallery cells in design.md's order, with the specified captions, theme labels, placeholder-aware alt text, and brief placeholder notice; verify a rendered preview shows one large hero and a two-by-two gallery with readable captions and working full-size links.
- [ ] 2.3 Add a replacement comment beside every image specifying the final scene-specific PNG path and guide location; verify each comment maps to exactly one placeholder and that no nonexistent final PNG is referenced by an active image/link.

## 3. Capture guide and verification

- [ ] 3.1 Create `docs/SCREENSHOTS.md` with all five concrete scene setups, suggested themes, capture checklist, exact placeholder-to-PNG mappings, and instructions for updating href/src/alt text and removing temporary notices; verify it enables manual replacement without consulting OpenSpec and includes no recording instructions or video tasks.
- [ ] 3.2 Run the existing documentation checks through the current supported test entrypoint (`lua tests/test.lua` at planning time) and `git diff --check`; inspect GitHub-compatible rendering, the showcase anchor, and all five local asset paths, recording actual outcomes and any rendering limitations.
- [ ] 3.3 Review the completed deliverables against the five-slot inventory and hand off the capture guide and replacement paths to the user; verify completion requires placeholders and instructions, not actual screenshots, a version bump, or publication.
