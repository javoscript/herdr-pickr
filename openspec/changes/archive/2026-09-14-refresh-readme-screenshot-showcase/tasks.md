## 1. Placeholder assets

- [x] 1.1 Create `docs/images/panes-all-placeholder.svg`, `panes-tab-placeholder.svg`, `agents-all-placeholder.svg`, `spaces-worktrees-placeholder.svg`, and `tabs-space-placeholder.svg` with consistent framing and explicit placeholder/scene/scope/theme labels; verify all five render locally without external resources and preserve the existing PNGs.

## 2. README showcase

- [x] 2.1 After the pane and unified type/scope README edits are available, replace Theme spotlight with Pickr in action and add its top navigation link; verify the section follows feature highlights, precedes Installation, and retains the feature changes' configuration and migration documentation.
- [x] 2.2 Add the linked Panes / All spaces hero and the four gallery cells in design.md's order, with the specified captions, theme labels, placeholder-aware alt text, and brief placeholder notice; verify a rendered preview shows one large hero and a two-by-two gallery with readable captions and working full-size links.
- [x] 2.3 Add a replacement comment beside every image specifying the final scene-specific PNG path and guide location; verify each comment maps to exactly one placeholder and that no nonexistent final PNG is referenced by an active image/link.

## 3. Capture guide and verification

- [x] 3.1 Create `docs/SCREENSHOTS.md` with all five concrete scene setups, suggested themes, capture checklist, exact placeholder-to-PNG mappings, and instructions for updating href/src/alt text and removing temporary notices; verify it enables manual replacement without consulting OpenSpec and includes no recording instructions or video tasks.
- [x] 3.2 Run the existing documentation checks through the current supported test entrypoint (`lua tests/test.lua` at planning time) and `git diff --check`; inspect GitHub-compatible rendering, the showcase anchor, and all five local asset paths, recording actual outcomes and any rendering limitations.
- [x] 3.3 Review the completed deliverables against the five-slot inventory and hand off the capture guide and replacement paths to the user; verify completion requires placeholders and instructions, not actual screenshots, a version bump, or publication.

## Verification outcomes

- `lua tests/test.lua`: passed the complete suite, including documentation and
  real-fzf/PTY checks. The initial run reached the tool's 120-second timeout;
  rerunning with a 900-second allowance completed successfully.
- `git diff --check`: passed.
- Local headless Chrome rendered all five 960×600 SVGs with text inside their
  frames and no external resource requests. ImageMagick could not load its fonts;
  browser verification was used instead, as requested by the user.
- Inspected a local Chrome preview of the README showcase HTML with GitHub-like
  styling: one large hero, the specified two-by-two gallery order, readable
  placeholder labels and captions, and matching themes. All five local image
  sources and full-size destinations loaded, and the showcase anchor navigated.
- Each placeholder has exactly one adjacent replacement comment naming its final
  PNG and `docs/SCREENSHOTS.md`. Active image/link paths use existing SVGs only.
  The original theme PNGs and README configuration/migration content are preserved.
- Rendering limitation: the preview used local GitHub-like CSS and an equivalent
  heading anchor; hosted GitHub Markdown rendering was not inspected.
