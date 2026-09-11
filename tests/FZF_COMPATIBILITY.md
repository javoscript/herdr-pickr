# fzf 0.74.3 binding import baseline

Sources inspected:

- [`src/options.go`](https://github.com/junegunn/fzf/blob/v0.74.3/src/options.go):
  `ParseOptions`, `parseShellWords`, `parseKeyChords`, `maskActionContents`,
  `parseKeymap`, and `parseActionList`.
- [`src/terminal.go`](https://github.com/junegunn/fzf/blob/v0.74.3/src/terminal.go):
  `defaultKeymap` and keymap overlay behavior.
- [`go.mod`](https://github.com/junegunn/fzf/blob/v0.74.3/go.mod) pins
  `go-shellwords` to `2aa3b3277741`. Its parser disables environment and command
  expansion; fzf enables comments.

## Compatibility contract

1. Read `FZF_DEFAULT_OPTS_FILE`, then `FZF_DEFAULT_OPTS`. fzf applies explicit
   command-line options last. Pickr emits its owner-controlled options last.
2. Shellword parsing supports single/double quotes, concatenated quoted fragments,
   empty quoted words, escapes, and comments at word boundaries. Outside single
   quotes, backslash escapes the next character, with `\t`/`\n` converted to tab
   and newline. Dollar variables, backticks, and `$(...)` are never evaluated.
   Unquoted shell operators terminate parsing, as in go-shellwords; unbalanced
   quoting/escapes and unquoted ordinary parentheses are errors.
3. Both `--bind VALUE` and `--bind=VALUE` are recognized. Assignments replace an
   earlier assignment to the same effective key. A leading `+` appends to the
   earlier explicitly configured chain, not fzf's built-in default action.
4. Multiple keys can share an action (`alt-j,alt-k:down`). Action names are
   case-insensitive; printable keys retain case. Equivalent terminal key aliases
   use `pickr.keymap` normalization (including Ctrl+M/Enter, Ctrl+I/Tab, and Unix
   backspace aliases).
5. Separator keys have dedicated grammar: `,:down`, `::up`, `+:first`, including
   their `alt-` forms. Splitting blindly on commas or plus signs is incorrect.
6. Argument-bearing actions mask their contents before binding/chain separation.
   Supported delimiters in fzf are `()`, `{}`, `[]`, `<>`, and matching
   `~ ! @ # $ % ^ & * ; / |`. A closing delimiter must precede `+`, `,`, or EOF;
   this is not a general nested-parenthesis parser. The `action:argument` form
   consumes the rest of the binding string. Pickr parses this boundary even for
   excluded actions, so command text cannot masquerade as another key binding.
7. An effective chain containing an unsupported action, including a previously
   appended unsupported action, is excluded as a whole. Events are excluded.
   No part of such a chain executes. Unrelated options do not enter the child.

## Supported action inventory

All supported imported actions are argument-free. Ordered chains are supported.

- Navigation: `up`, `down`, `up-match`, `down-match`, `first`, `top`, `last`,
  `best`, `page-up`, `page-down`, `half-page-up`, `half-page-down`, `offset-up`,
  `offset-down`, `offset-middle`.
- Query editing: `beginning-of-line`, `end-of-line`, `backward-char`,
  `forward-char`, `backward-word`, `forward-word`, `backward-subword`,
  `forward-subword`, `backward-delete-char`, `delete-char`, `clear-query`,
  `kill-line`, `kill-word`, `kill-subword`, `backward-kill-word`,
  `backward-kill-subword`, `unix-line-discard`, `line-discard`,
  `unix-word-rubout`, `word-rubout`, `yank`.
- Preview scrolling: `preview-top`, `preview-bottom`, `preview-up`,
  `preview-down`, `preview-page-up`, `preview-page-down`,
  `preview-half-page-up`, `preview-half-page-down`.
- No-op: `ignore`.

Lifecycle actions, `/eof` editing variants, preview visibility/layout changes,
events, output/selection changes, arbitrary commands, and argument-bearing
actions are outside this inventory. Diagnostics identify the key/event and
unsupported action. Malformed or unreadable ambient sources are diagnosed;
they do not silently change Pickr's action keys.

## Recorded checks

`lua tests/fzf_compat.lua` passed with installed fzf 0.74.3. The checks use
real fzf parsing for quoted fragments, comments, both bind forms, aliases,
separator keys, chains and command-argument delimiters, plus a controlling PTY
to verify file/environment/CLI precedence and replacement versus append.
They run independently of the importer and execute no imported shell commands.
The controlling-terminal harness is Lua plus luv, using macOS's bundled `script`
and `stty` utilities. These checks also run through `lua tests/test.lua`.
