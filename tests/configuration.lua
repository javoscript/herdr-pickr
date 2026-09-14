-- Loaded by tests/test.lua after establishing the distribution's source path.
local themes = require("pickr.themes")
local function equal(actual, expected) assert(actual == expected, tostring(actual) .. " ~= " .. tostring(expected)) end
local function fails(fn, text)
  local ok, err = pcall(fn)
  assert(not ok and tostring(err):find(text, 1, true), tostring(err))
end
equal(table.concat(themes.names, ","), "catppuccin,catppuccin-latte,dracula,gruvbox,gruvbox-light,kanagawa,kanagawa-lotus,nord,one-dark,one-light,rose-pine,rose-pine-dawn,solarized,solarized-light,terminal,tokyo-night,tokyo-night-day,vesper")
for _, name in ipairs(themes.names) do
  local roles = themes.resolve(name)
  local count = 0
  for _ in pairs(roles) do count = count + 1 end
  equal(count, 24)
  for _, role in ipairs(themes.roles) do
    assert(roles[role])
    if name == "terminal" then assert(roles[role].kind ~= "rgb") end
  end
end
equal(themes.fzf(themes.resolve().background), "#181825")
equal(themes.fzf(themes.resolve("rose-pine").annotation), "#524f67")
equal(themes.ansi(themes.resolve("rose-pine").status_blocked), "\27[38;2;235;111;146m")
for _, text in ipairs({ "#abc", "#AABBCC", " rgb(170, 187, 204) ", "RGB(+170,187,204)" }) do
  equal(themes.fzf(themes.color(text)), "#aabbcc")
end
local names = { black = 0, red = 1, green = 2, yellow = 3, blue = 4, magenta = 5, purple = 5,
  cyan = 6, gray = 7, grey = 7, darkgray = 8, darkgrey = 8, lightred = 9, lightgreen = 10,
  lightyellow = 11, lightblue = 12, lightmagenta = 13, lightcyan = 14, white = 15 }
for name, index in pairs(names) do
  local color = themes.color(" " .. name:upper() .. " ")
  equal(themes.fzf(color), tostring(index))
  equal(themes.ansi(color), "\27[38;5;" .. index .. "m")
end
for _, name in ipairs({ "reset", "default", "none", "transparent" }) do
  local color = themes.color(name)
  equal(themes.fzf(color), "-1")
  equal(themes.ansi(color), "\27[39m")
  equal(themes.ansi(color, true), "\27[49m")
end
for _, color in ipairs({ "#ab", "#aabbcdef", "rgb(256,0,0)", "rgb(-1,0,0)", "rgb(1.2,0,0)", "rgb(0,0)", "blurple", "" }) do
  fails(function() themes.color(color, "theme.custom.annotation") end, "theme.custom.annotation")
end
fails(function() themes.resolve("invalid") end, "theme.name")
fails(function() themes.resolve(nil, { invalid = "red" }) end, "theme.custom.invalid")
equal(themes.fzf(themes.resolve(nil, { annotation = "red" }).annotation), "1")
equal(themes.fzf(themes.resolve(nil, { annotation = "red" }).background), "#181825")
print("Themes: canonical inventory, role coverage, RGB/ANSI/default serialization and validation OK")

local config, keymap, json = require("pickr.config"), require("pickr.keymap"), require("pickr.vendor.json")
for _, text in ipairs({ "{}", '{"keys":null,"theme":null}',
  '{"keys":{"refresh":null},"theme":{"name":null,"custom":{"annotation":null}}}',
  '{"theme":{"custom":null}}' }) do
  local settings = config.decode(text)
  equal(settings.theme_name, "catppuccin")
  equal(themes.fzf(settings.roles.annotation), "#6c7086")
  for action, keys in pairs(keymap.defaults) do equal(table.concat(settings.keymap.keys[action], ","), table.concat(keys, ",")) end
end
equal(themes.fzf(config.decode('{"theme":{"name":"rose-pine","custom":{"annotation":null}}}').roles.annotation), "#524f67")
local optional = { "toggle_preview", "refresh", "spaces", "tabs", "panes", "agents", "scope_all", "scope_space", "scope_tab" }
for _, action in ipairs(optional) do
  local settings = config.decode('{"keys":{"' .. action .. '":[]}}')
  equal(#settings.keymap.keys[action], 0)
  equal(settings.keymap.reverse[keymap.defaults[action][1]], nil)
end
for _, action in ipairs({ "accept", "close" }) do
  fails(function() config.decode('{"keys":{"' .. action .. '":[]}}') end, "requires at least one key")
end
for _, text in ipairs({ "[]", "null", "false", '{"unknown":null}', '{"keys":[]}', '{"keys":{"typo":null}}',
  '{"keys":{"accept":{}}}', '{"keys":{"accept":[null]}}', '{"keys":{"accept":"enter"}}',
  '{"theme":[]}', '{"theme":{"name":false}}', '{"theme":{"custom":[]}}',
  '{"theme":{"custom":{"typo":null}}}', '{"theme":{"custom":{"header":false}}}',
  '{"keys":{"accept":["start"]}}', '{"keys":{"accept":["enter:accept"]}}',
  '{"keys":{"accept":["every(1)"]}}', '{"keys":{"accept":["ctrl-shift-r"]}}' }) do
  fails(function() config.decode(text) end, "")
end
for _, text in ipairs({ '{"keys":}', '{"keys":{"accept":["enter",]}}', '{"theme":{},}',
  '{"theme":01}', '{"theme":1.}', '{"theme":1e}', '{"theme":0x1}', '{"theme":1e999}' }) do
  fails(function() config.decode(text) end, "line")
end
local pairs_to_check = { { "return", "ctrl-m" }, { "ctrl-i", "tab" }, { "ctrl-h", "ctrl-bs" },
  { "bs", "bspace" }, { "pgup", "page-up" }, { "ctrl-6", "ctrl-^" }, { "ctrl-_", "ctrl-/" },
  { "btab", "shift-tab" }, { "alt-return", "ctrl-alt-m" }, { "ctrl-alt-h", "ctrl-alt-bs" },
  { "shift-alt-up", "alt-shift-up" }, { "alt-ctrl-right", "ctrl-alt-right" } }
for _, pair in ipairs(pairs_to_check) do
  equal(keymap.normalize(pair[1]), keymap.normalize(pair[2]))
  fails(function() keymap.resolve({ accept = { pair[1] }, close = { pair[2] } }) end, "conflicts")
end
local mapped = config.decode('{"keys":{"accept":["f1","alt-x"],"refresh":["f2","f3"]}}').keymap
equal(mapped.reverse.f1, "accept")
equal(mapped.reverse["alt-x"], "accept")
equal(mapped.reverse.enter, nil)
equal(mapped.reverse["ctrl-l"], nil)
equal(keymap.normalize("A"), "A")
equal(keymap.normalize("a"), "a")
equal(keymap.normalize("ALT-A"), "alt-A")
equal(keymap.normalize("RETURN"), "enter")
for _, action in ipairs({ "spaces", "tabs", "panes", "agents", "scope_all", "scope_space", "scope_tab" }) do
  local defaults = keymap.defaults[action]
  equal(config.decode('{"keys":{"' .. action .. '":null}}').keymap.keys[action][1], defaults[1])
  equal(config.decode('{"keys":{"' .. action .. '":["ALT-9","f1"]}}').keymap.keys[action][1], "alt-9")
  fails(function() config.decode('{"keys":{"refresh":["' .. defaults[1] .. '"]}}') end, "conflicts")
  local resolved = config.decode('{"keys":{"refresh":["' .. defaults[1] .. '"],"' .. action .. '":[]}}')
  equal(resolved.keymap.reverse[defaults[1]], "refresh")
end
equal(table.concat(config.decode("{}").keymap.keys.close, ","), "esc")
equal(config.decode("{}").keymap.reverse["ctrl-c"], "scope_tab")
fails(function() config.decode('{"keys":{"close":["esc","ctrl-c"]}}') end, "conflicts")
equal(config.decode('{"keys":{"close":["ctrl-c"],"scope_tab":[]}}').keymap.reverse["ctrl-c"], "close")
local env = { HERDR_PLUGIN_ID = "javoscript.herdr-pickr", HERDR_PLUGIN_CONFIG_DIR = "/fixture settings" }
local reads = 0
local deps = { getenv = function(key) return env[key] end,
  read_file = function(path)
    reads = reads + 1
    equal(path, "/fixture settings/config.json")
    return nil, "no such file", "ENOENT"
  end }
equal(config.load(deps).theme_name, "catppuccin")
equal(reads, 1)
deps.read_file = function() return nil, "permission denied", "EACCES" end
fails(function() config.load(deps) end, "/fixture settings/config.json: permission denied")
deps.read_file = function() return '{"theme":{"name":"typo"}}' end
fails(function() config.load(deps) end, "/fixture settings/config.json: theme.name")
deps.read_file = function() return '{"theme":' end
fails(function() config.load(deps) end, "/fixture settings/config.json:")
equal(json.decode('{"a":null}').a, nil)
assert(getmetatable(json.decode("[]", true)) == json.array)
assert(getmetatable(json.decode("{}", true)) == json.object)
assert(json.decode("null", true) == json.null)
print("Configuration/keymap: strict types, missing/null defaults, disabled actions, aliases and diagnostics OK")

for _, text in ipairs({ "{}", '{"preview":null,"popup":null}',
  '{"preview":{"enabled_by_default":null},"popup":{"width":null,"height":null}}' }) do
  local settings = config.decode(text)
  equal(settings.preview.enabled_by_default, true)
  equal(settings.popup.width, "80%")
  equal(settings.popup.height, "70%")
end
equal(config.decode('{"preview":{"enabled_by_default":false}}').preview.enabled_by_default, false)
for _, dimension in ipairs({ '0', '65535', '120', '"1%"', '"90%"', '"100%"' }) do
  for _, field in ipairs({ "width", "height" }) do
    local settings = config.decode('{"popup":{"' .. field .. '":' .. dimension .. '}}')
    equal(settings.popup[field], json.decode(dimension))
    equal(settings.popup[field == "width" and "height" or "width"], field == "width" and "70%" or "80%")
  end
end
for _, dimension in ipairs({ '65536', '1000000', '1e100' }) do
  for _, field in ipairs({ "width", "height" }) do
    local settings = config.decode('{"popup":{"' .. field .. '":' .. dimension .. '}}')
    equal(settings.popup[field], 65535)
    equal(settings.popup[field == "width" and "height" or "width"], field == "width" and "70%" or "80%")
  end
end
for _, value in ipairs({ 'false', '[]', '{}', '"0%"', '"101%"', '"01%"', '"1.5%"',
  '"80"', '" 80%"', '"80% "', '1.5', '-1', '65536.5' }) do
  for _, field in ipairs({ "width", "height" }) do
    fails(function() config.decode('{"popup":{"' .. field .. '":' .. value .. '}}') end, "popup." .. field)
  end
end
fails(function() config.decode('{"popup":{"width":1e999}}') end, "invalid number")
for _, value in ipairs({ '0', '"true"', '[]', '{}' }) do
  fails(function() config.decode('{"preview":{"enabled_by_default":' .. value .. '}}') end,
    "preview.enabled_by_default")
end
for _, section in ipairs({ "preview", "popup" }) do
  fails(function() config.decode('{"' .. section .. '":[]}') end, section)
  fails(function() config.decode('{"' .. section .. '":{"typo":null}}') end, section .. ".typo")
end
deps.read_file = function() return "{}", "close failed" end
fails(function() config.load(deps) end, "/fixture settings/config.json: close failed")
print("Configuration: preview and popup defaults, partial overrides, strict validation and read errors OK")

for _, text in ipairs({ '{}', '{"popup":null}', '{"popup":{}}',
  '{"popup":{"show_hints":null}}', '{"popup":{"show_hints":true}}' }) do
  equal(config.decode(text).popup.show_hints, true)
end
local hidden = config.decode('{"popup":{"show_hints":false,"width":120,"height":"90%"}}')
equal(hidden.popup.show_hints, false)
equal(hidden.popup.width, 120)
equal(hidden.popup.height, "90%")
deps.read_file = function() return nil, "missing", "ENOENT" end
equal(config.load(deps).popup.show_hints, true)
for _, value in ipairs({ '0', '1', '"false"', '[]', '{}' }) do
  deps.read_file = function() return '{"popup":{"show_hints":' .. value .. '}}' end
  fails(function() config.load(deps) end, "/fixture settings/config.json: popup.show_hints")
end
print("Configuration: hint visibility defaults, false, strict types and independent dimensions OK")

for _, text in ipairs({ '{}', '{"prompt":null}', '{"prompt":{}}',
  '{"prompt":{"default":null,"variants":null}}' }) do
  local settings = config.decode(text)
  equal(settings.prompt.default, "Search: ")
  for variant in pairs(keymap.variants) do equal(settings.prompt.variants[variant], "Search: ") end
end
for _, global in ipairs({ 'null', '"Find: "', '""' }) do
  for variant in pairs(keymap.variants) do
    for _, value in ipairs({ 'null', '""', json.encode("  ◉ ' $(touch nope); +change-prompt(x) ") }) do
      local settings = config.decode('{"prompt":{"default":' .. global
        .. ',"variants":{"' .. variant .. '":' .. value .. '}}}')
      local inherited = global == 'null' and "Search: " or json.decode(global)
      equal(settings.prompt.default, inherited)
      for name in pairs(keymap.variants) do
        equal(settings.prompt.variants[name], name == variant and value ~= 'null' and json.decode(value) or inherited)
      end
      equal(settings.theme_name, "catppuccin")
      equal(settings.popup.width, "80%")
      equal(settings.preview.enabled_by_default, true)
      equal(settings.keymap.keys.refresh[1], "ctrl-l")
    end
  end
end
for _, variants in ipairs({ '', ',"variants":null' }) do
  for name in pairs(keymap.variants) do
    equal(config.decode('{"prompt":{"default":"Find: "' .. variants .. '}}').prompt.variants[name], "Find: ")
    equal(config.decode('{"prompt":{"variants":{"' .. name .. '":"Custom: "}}}').prompt.variants[name], "Custom: ")
  end
end
local invalid_prompts = {
  { '{"prompt":{"typo":null}}', "prompt.typo" },
  { '{"prompt":{"variants":{"workspaces":null}}}', "prompt.variants.workspaces" },
}
for _, value in ipairs({ 'false', '12', '"text"', '[]' }) do
  invalid_prompts[#invalid_prompts + 1] = { '{"prompt":' .. value .. '}', "prompt" }
  invalid_prompts[#invalid_prompts + 1] = { '{"prompt":{"variants":' .. value .. '}}', "prompt.variants" }
end
for _, value in ipairs({ 'false', '12', '[]', '{}', '"a\\u0000b"', '"a\\rb"', '"a\\nb"' }) do
  invalid_prompts[#invalid_prompts + 1] = { '{"prompt":{"default":' .. value .. '}}', "prompt.default" }
  for variant in pairs(keymap.variants) do
    invalid_prompts[#invalid_prompts + 1] = {
      '{"prompt":{"variants":{"' .. variant .. '":' .. value .. '}}}', "prompt.variants." .. variant }
  end
end
for _, fixture in ipairs(invalid_prompts) do
  fails(function() config.decode(fixture[1]) end, fixture[2])
  deps.read_file = function() return fixture[1] end
  fails(function() config.load(deps) end, "/fixture settings/config.json: " .. fixture[2])
end
print("Configuration: prompt inheritance, four types, literal/empty strings and field/path diagnostics OK")

local contents = '{"theme":{"name":"terminal"},"keys":{"refresh":[]},"popup":{"width":120,"show_hints":false},'
  .. '"prompt":{"default":"Original: ","variants":{"spaces":"","agents":"Agents: "}}}'
local loads = 0
local launch_deps = { getenv = function(key) return env[key] end,
  read_file = function() loads = loads + 1; return contents end }
local launched = config.load(launch_deps)
local handoff = config.snapshot(launched)
contents = '{"theme":{"name":"rose-pine"},"preview":{"enabled_by_default":false},'
  .. '"prompt":{"default":"Edited: ","variants":{"spaces":"Spaces: ","agents":"New agents: "}}}'
local owner = config.owner({ getenv = function(key)
  equal(key, "PICKR_SETTINGS_SNAPSHOT"); return handoff
end, read_file = function() error("Owner must not reread launcher settings") end })
equal(loads, 1)
equal(owner.theme_name, "terminal")
equal(owner.popup.width, 120)
equal(owner.popup.show_hints, false)
equal(#owner.keymap.keys.refresh, 0)
equal(owner.roles.background.kind, "default")
equal(owner.prompt.default, "Original: ")
for variant in pairs(keymap.variants) do
  equal(owner.prompt.variants[variant], launched.prompt.variants[variant])
end
local reopened = config.owner(launch_deps)
equal(reopened.theme_name, "rose-pine")
equal(reopened.popup.show_hints, true)
equal(reopened.prompt.default, "Edited: ")
equal(reopened.prompt.variants.tabs, "Edited: ")
equal(reopened.prompt.variants.spaces, "Spaces: ")
equal(reopened.prompt.variants.agents, "New agents: ")
equal(loads, 2)
local mutations = {
  function(s) s.popup.show_hints = nil end,
  function(s) s.popup.show_hints = "false" end,
  function(s) s.prompt = nil end,
  function(s) s.prompt.default = nil end,
  function(s) s.prompt.variants = nil end,
  function(s) s.prompt.default = false end,
  function(s) s.prompt.variants.spaces = "bad\n" end,
}
for variant in pairs(keymap.variants) do
  mutations[#mutations + 1] = function(s) s.prompt.variants[variant] = nil end
end
for _, mutate in ipairs(mutations) do
  local settings = config.decode("{}")
  mutate(settings)
  fails(function() config.owner({ getenv = function() return config.snapshot(settings) end,
    read_file = function() error("Invalid handoffs must not reread") end }) end, "PICKR_SETTINGS_SNAPSHOT")
end
for _, snapshot in ipairs({ "", "null", "{}", '{"version":2}', '{"version":1,"settings":{}}' }) do
  fails(function() config.owner({ getenv = function() return snapshot end }) end, "PICKR_SETTINGS_SNAPSHOT")
end
print("Configuration: launcher snapshot, direct owner loading and reopen-to-adopt settings OK")
