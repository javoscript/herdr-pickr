# Project Guidelines

## Project Description

Pickr is a local Herdr plugin that provides fuzzy tab, space, and agent pickers
with terminal previews. It uses Lua 5.3+, `luv`, and `fzf` from PATH.

See `README.md` for usage, project structure, and regression-check instructions.

## Language Guidelines

- Prefer Lua for all project code, including scripts, tooling, and tests.

## Documentation Guidelines

- After making changes to the codebase, review and update `README.md` as needed
  to keep installation, configuration, feature highlights and usage instructions
  accurate.

## Commit Guidelines

- Commits should be made following the Conventional Commits format.
- Use `type(scope): description`, where scope is optional.
- Example: `docs: add project agent guidelines`.
