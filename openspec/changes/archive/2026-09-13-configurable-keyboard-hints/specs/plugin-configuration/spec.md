## ADDED Requirements

### Requirement: Popup keyboard hint visibility is configurable

Pickr SHALL expose `popup.show_hints` as a boolean defaulting to `true` when omitted or null, including when `popup` is omitted or null or the configuration file is missing. A value of `false` SHALL hide the entire keyboard hints footer in all five picker variants. Nonboolean non-null values SHALL block launch with a file/field diagnostic. Existing popup dimension defaults and validation SHALL remain unchanged.

All launch paths SHALL use the resolved hint visibility from the same launch settings snapshot as other configuration. Switching variants, refresh loading, success, failure, and retry SHALL retain that visibility. Configuration edits SHALL take effect on the next launch, including edits made between launcher resolution and picker startup. Hiding hints SHALL NOT disable or remap keyboard actions.

#### Scenario: Default and explicit visible hints
- **WHEN** `popup.show_hints` is `true`, omitted, or null, or `popup` is omitted or null, or the configuration file is missing
- **THEN** each picker variant displays its normal grouped footer
- **AND** popup dimensions retain their independently resolved values

#### Scenario: Hidden hints across launch paths
- **WHEN** `popup.show_hints` is `false` and Pickr opens through an action, a direct Herdr pane launch, or direct picker invocation
- **THEN** the initial variant has no hints section
- **AND** configured keyboard shortcuts retain their normal behavior

#### Scenario: Visibility is stable until reopening
- **WHEN** hint visibility configuration is edited after launch settings resolve
- **THEN** picker startup, switches, refresh loading, success, failure, and retry use the original visibility
- **AND** closing and reopening Pickr adopts the edited value

#### Scenario: Invalid hint visibility
- **WHEN** `popup.show_hints` contains a number, string, array, or object
- **THEN** Pickr identifies `popup.show_hints` in a configuration diagnostic before popup creation for action launches or before fzf starts for direct launches
- **AND** no entity is focused
