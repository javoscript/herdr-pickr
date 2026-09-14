local path = assert(require("luv").fs_realpath(debug.getinfo(1, "S").source:sub(2)))
local root = assert(path:match("^(.*)/tests/[^/]+$"))
local file = assert(io.open(root .. "/README.md", "r"))
local readme = file:read("*a"); file:close()
local count = 0
for example in readme:gmatch("```json\n(.-)\n```") do
  require("pickr.config").decode(example)
  count = count + 1
end
assert(count >= 5, "missing public configuration examples")
local config = require("pickr.config")
local defaults = config.decode("{}")
local example = assert(readme:match("complete default configuration:.-```json\n(.-)\n```"))
local documented = config.decode(example)
local raw = require("pickr.vendor.json").decode(example, true)
assert(raw.refresh and raw.refresh.interval_ms == 0, "missing disabled-by-default refresh interval")
assert(documented.refresh.interval_ms == defaults.refresh.interval_ms)
for _, text in ipairs({ "`refresh.interval_ms`", "2147483647", "Keystrokes during this final replacement can be ignored",
  "returns the preview to the top", "Close and reopen Pickr to apply interval edits" }) do
  assert(readme:find(text, 1, true), "missing live-refresh documentation: " .. text)
end
for _, action in ipairs(require("pickr.keymap").order) do
  assert(raw.keys[action], "missing default key setting: " .. action)
  assert(table.concat(documented.keymap.keys[action], ",") == table.concat(defaults.keymap.keys[action], ","))
end
for variant, names in pairs(defaults.columns) do
  assert(raw.columns[variant] and raw.prompt.variants[variant], "missing default variant: " .. variant)
  assert(table.concat(documented.columns[variant], ",") == table.concat(names, ","))
  assert(documented.prompt.variants[variant] == defaults.prompt.variants[variant])
end
local manifest_file = assert(io.open(root .. "/herdr-plugin.toml", "r"))
local manifest = manifest_file:read("*a"); manifest_file:close()
for action in manifest:gmatch('command = %[%"lua%", %"src/open.lua%", %"([^%"]+)%"%]') do
  assert(readme:find("javoscript.herdr-pickr." .. action, 1, true), "undocumented launch action: " .. action)
end
for _, inventory in ipairs({ require("pickr.keymap").order, require("pickr.themes").names, require("pickr.themes").roles }) do
  for _, name in ipairs(inventory) do assert(readme:find("`" .. name .. "`", 1, true), "undocumented setting: " .. name) end
end
for action in pairs(require("pickr.fzf_bindings").actions) do
  assert(readme:find("`" .. action .. "`", 1, true), "undocumented imported action: " .. action)
end
for variant, columns in pairs(require("pickr.columns").defaults) do
  assert(readme:find("`" .. variant .. "`", 1, true), "undocumented column variant: " .. variant)
  for _, column in ipairs(columns) do
    assert(readme:find("`" .. column .. "`", 1, true), "undocumented column: " .. column)
  end
end
local migration = assert(readme:match("### Migrating scope%-specific settings and launch bindings\n(.-)\n### "))
local current = readme:gsub("### Migrating scope%-specific settings and launch bindings\n.-\n### ", "### ")
for old in pairs(require("pickr.pickers").legacy) do
  assert(migration:find(old, 1, true), "undocumented migration: " .. old)
  assert(not current:find(old, 1, true), "legacy setting outside migration: " .. old)
end
assert(not current:find("-current", 1, true), "legacy launch outside migration")
for preset in pairs(require("pickr.pickers").presets) do
  assert(readme:find("| `javoscript.herdr-pickr." .. preset .. "` |", 1, true), "missing preset table row: " .. preset)
end
print("Documentation: all JSON examples/defaults and twelve presets validate; settings/themes/imports documented and legacy names confined to migration")
