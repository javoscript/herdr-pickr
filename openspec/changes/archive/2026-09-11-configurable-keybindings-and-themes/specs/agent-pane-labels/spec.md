## MODIFIED Requirements

### Requirement: Pane annotations use the existing subdued style

The label and both brackets SHALL use the same resolved `annotation` theme role as worktree parent annotations. With the explicit `rose-pine` theme and no override this SHALL remain `#524f67`; other themes and user overrides SHALL supply their corresponding annotation color. The pane ID SHALL retain its surrounding text style. Pane annotations SHALL coexist with worktree parent annotations and preserve existing column alignment and single-row metadata cleaning, including replacement of control characters with spaces.

#### Scenario: Both annotations on an all-spaces agent row
- **WHEN** a labeled agent pane belongs to a worktree with a displayed parent annotation
- **THEN** both bracketed annotations use the same resolved annotation color
- **AND** the pane ID and surrounding columns retain their existing styles and alignment

#### Scenario: Unicode and control characters in labels
- **WHEN** a pane label contains Unicode text and a newline or tab
- **THEN** Unicode text is preserved and control characters are replaced with spaces
- **AND** the label remains within one row and the existing pane column

#### Scenario: Custom annotation color
- **WHEN** the user overrides `theme.custom.annotation`
- **THEN** pane-label brackets and text and worktree parent annotations use that override in initial and refreshed rows
