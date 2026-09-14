local keymap = require("pickr.keymap")
local map = keymap.resolve()
local actions = "enter: switch · esc: close · ctrl+p: preview · ctrl+l: refresh"
local variants = "ctrl+s: spaces · ctrl+t: tabs · ctrl+r: panes · ctrl+a: agents"
assert(keymap.footer(map, 1) == actions .. "\n" .. variants)
assert(keymap.footer(map, 0) == "no entries · " .. actions .. "\n" .. variants)
local overrides = { accept = { "alt-v", "f1" }, toggle_preview = {}, panes = { "alt-q", "f2" }, agents = {} }
local footer = keymap.footer(keymap.resolve(overrides), 1)
assert(footer:match("^alt%+v/f1: switch · esc: close · ctrl%+l: refresh\n"))
assert(footer:find("alt+q/f2: panes", 1, true))
assert(not footer:find("ctrl+r", 1, true) and not footer:find("agents", 1, true))
for name in pairs(keymap.variants) do overrides[name] = {} end
assert(keymap.footer(keymap.resolve(overrides), 1) == "alt+v/f1: switch · esc: close · ctrl+l: refresh")
assert(keymap.footer(keymap.resolve(overrides), 0) == "no entries · alt+v/f1: switch · esc: close · ctrl+l: refresh")
local config = require("pickr.config")
local function plain(text) return (text:gsub("\27%[[%d;]*m", "")) end
local settings = config.decode("{}")
local choices = "All spaces (ctrl+z) · This space (ctrl+x) · This tab (ctrl+c)"
assert(plain(keymap.header(settings, "tabs", "tab")) == choices .. "\nThis tab remembered")
assert(plain(keymap.header(settings, "panes", "tab")) == choices)
assert(plain(keymap.header(settings, "tabs", "tab", "Refreshing…"))
  == choices .. "\nThis tab remembered\nRefreshing…")
assert(plain(keymap.header(settings, "spaces", "space")) == choices .. "\nThis space remembered")
settings.popup.show_hints = false
assert(plain(keymap.header(settings, "tabs", "tab", "Refresh failed"))
  == "All spaces · This space · This tab\nThis tab remembered\nRefresh failed")
print("Footer/header: four-type rows, aliases, disabled groups, empty prefix and separate remembered/status lines OK")
