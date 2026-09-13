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
