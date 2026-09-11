## 1. Confirm the prerequisite

- [x] 1.1 Confirm `configure-search-prompt` has been implemented before editing the README; verify its resulting parser, prompt selection, and specs support the documented global/default and five variant settings, and stop if that dependency is incomplete.

## 2. Rewrite the user guide

- [x] 2.1 Replace the introduction with concise feature highlights and consolidate relevant searching, columns, switching, refresh, and preview notes; verify all five variants and snapshot/query semantics are accurately described without implementation internals.
- [x] 2.2 Write a contiguous macOS installation section covering Homebrew prerequisites, `brew install herdr lua luv fzf git`, dependency minimums and Lua/luv/PATH requirements, the published GitHub install command, and one first launch inside Herdr; verify commands and action IDs against the manifest and remove pre-publication caveats.
- [x] 2.3 Write separate Herdr launch-binding and Pickr configuration-file instructions, retaining all five complete TOML examples, directory discovery, and a valid starter JSON example; verify a reader can identify both file locations and distinguish Herdr reload from Pickr reopen.
- [x] 2.4 Write the action keys, popup size, and initial preview reference with focused JSON examples; verify all nine actions/defaults, replacement/disable/required-key rules, key syntax and alias conflicts, dimension formats/clamping, and visibility lifecycle against the implementation.
- [x] 2.5 Write themes/color overrides and prompt customization with focused JSON examples; verify every theme, semantic role, color format/alias, and implemented prompt field/default/inheritance/validation rule is covered, including the distinction between prompt text and color.
- [x] 2.6 Write fzf compatibility and inherited-binding guidance; verify the complete imported-action inventory, minimum version, source and key precedence, replacement/append behavior, excluded events/chains/actions, diagnostics, and ignored unrelated options against the importer.
- [x] 2.7 Remove all requested sections and historical/development/migration material, retain compact license/dependency attribution, and eliminate repeated instructions; verify the final outline follows the design and useful configuration survives the removed Picker behavior section.

## 3. Verify the complete README

- [x] 3.1 Run the existing documentation check with `lua -e 'package.path = "./src/?.lua;./src/?/init.lua;" .. package.path; dofile("tests/documentation.lua")'`; verify all JSON examples decode after the prompt dependency and all public action/theme/role/imported-action inventories pass without weakening the check.
- [x] 3.2 Review the rendered Markdown, anchors, command examples, and all distribution delta scenarios; verify complete copyable configuration and requested removals, and inspect repository references to removed sections, reporting any needed out-of-scope follow-up rather than silently expanding the edit.
