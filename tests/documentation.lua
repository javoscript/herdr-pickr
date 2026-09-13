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
print("Documentation: JSON examples validate; every action, theme, role and supported imported action is documented")
