local keymap = require("pickr.keymap")
local map = keymap.resolve()
local actions = "enter: switch · esc/ctrl+c: close · ctrl+p: preview · ctrl+l: refresh"
local variants = "ctrl+r: tabs here · ctrl+t: all tabs · ctrl+s: spaces · ctrl+a: agents here · ctrl+g: all agents"
  .. " · alt+1: panes in tab · alt+2: panes in space · alt+3: all panes"
assert(keymap.footer(map, 1) == actions .. "\n" .. variants)
assert(keymap.footer(map, 0) == "no entries · " .. actions .. "\n" .. variants)
local overrides = { accept = { "alt-v", "f1" }, toggle_preview = {}, panes_tab = { "alt-q", "f2" }, panes_all = {} }
local footer = keymap.footer(keymap.resolve(overrides), 1)
assert(footer:match("^alt%+v/f1: switch · esc/ctrl%+c: close · ctrl%+l: refresh\n"))
assert(footer:find("alt+q/f2: panes in tab · alt+2: panes in space", 1, true))
assert(not footer:find("alt+1", 1, true) and not footer:find("all panes", 1, true))
for name in pairs(keymap.variants) do overrides[name] = {} end
assert(keymap.footer(keymap.resolve(overrides), 1) == "alt+v/f1: switch · esc/ctrl+c: close · ctrl+l: refresh")
assert(keymap.footer(keymap.resolve(overrides), 0) == "no entries · alt+v/f1: switch · esc/ctrl+c: close · ctrl+l: refresh")
print("Footer: exact eight-view rows, aliases, disabled pane actions, all-disabled group and empty prefix OK")
