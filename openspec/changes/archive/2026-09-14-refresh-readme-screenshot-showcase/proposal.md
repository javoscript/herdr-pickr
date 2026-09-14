## Why

Pickr's existing theme gallery repeats similar tab views and does not showcase the pane picker or unified type/scope navigation planned for 0.2.0. A feature-led showcase will explain the release visually while giving the maintainer clear screenshot slots to replace after the UI is finalized.

## What Changes

- Replace the README's Theme spotlight with Pickr in action: one large hero after the feature highlights and a two-by-two gallery before installation.
- Showcase five scenarios: Panes / All spaces (hero), Panes / This tab, Agents / All spaces, Spaces with worktrees, and Tabs / This space.
- Supply clearly labeled, locally rendered image placeholders, meaningful alt text, feature-focused captions, and theme labels. Do not represent old screenshots or mock UI as actual 0.2.0 captures.
- Provide a concise maintainer capture guide with scene setup, proposed themes, image paths, replacement instructions, and framing guidance.
- Leave actual screenshot capture and replacement to the user; placeholders are the deliverable for this change.
- Exclude video, GIFs, recordings, release automation, version bumps, and runtime behavior changes.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

None. This is a documentation presentation change within the existing plugin-distribution capability. It does not alter the plugin contract or installation/configuration requirements; `skip_specs: true` deliberately opts out of delta specs.

## Impact

- `README.md`: showcase layout, captions, alt text, and showcase navigation link.
- `docs/images/`: five new scene-specific placeholder assets; preserve existing theme PNGs unless removal is separately requested.
- `docs/SCREENSHOTS.md`: maintainer capture/replacement guide.
- Use the final terminology and behavior from `add-pane-picker` and `unify-picker-types-and-scopes`. Apply the final README integration after their README edits to avoid overwriting them. The placeholder plan can be reviewed before those implementations finish.
- Existing documentation regression checks remain relevant. No new dependencies, runtime code, configuration changes, or new automated screenshot system are needed.
