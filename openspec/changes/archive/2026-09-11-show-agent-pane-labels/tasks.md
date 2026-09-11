## 1. Pane label rendering

- [x] 1.1 Confirm the optional pane-label field using read-only inspection of the installed Herdr snapshot or API schema, then build a pane-ID-to-label lookup in `core.lua` from the existing snapshot; verify a labeled pane resolves its label and missing pane metadata resolves no annotation.
- [x] 1.2 Generalize muted suffix metadata in `aligned_rows` to support multiple annotated columns, sharing the worktree-parent gray and preserving prefix styling; verify an all-spaces agent row can render both annotations with independent color resets and existing worktree alignment remains correct.
- [x] 1.3 Append cleaned ` [label]` text to the pane display column in both agent variants while retaining raw hidden selection and preview IDs; verify `pane-id [label]` for labeled panes and bare IDs for absent, null, empty, or unavailable labels.

## 2. Regression coverage and documentation

- [x] 2.1 Extend `test.lua` fixtures and assertions for both agent scopes, mixed labeled/unlabeled panes, Unicode/control-character cleaning, simultaneous worktree/pane annotations, and exact gray styling; verify these cases pass with aligned headers and unchanged hidden pane IDs.
- [x] 2.2 Exercise pane-label-only search through the existing production-fzf-argument test pattern, including preview/focus identity and retained priority ordering; verify both scopes match the labeled agent and target its raw pane ID.
- [x] 2.3 Update `README.md` column/search documentation with `pane-id [label]`, the shared `#524f67` annotation color, and unlabeled fallback; verify the documentation agrees with the delta specification.
- [x] 2.4 Run `lua "$HOME/.config/herdr/plugins/pickr/test.lua"` and verify the full regression suite passes, including worktree grouping, column matching, agent ordering, and preview/focus checks.
