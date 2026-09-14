local pickers = require("pickr.pickers")
local expected = {
  spaces = {}, tabs = { "all", "space", "space" },
  panes = { "all", "space", "tab" }, agents = { "all", "space", "tab" },
}
for _, kind in ipairs(pickers.order) do
  for index, chosen in ipairs(pickers.scopes) do
    assert(pickers.effective(kind, chosen) == expected[kind][index])
    assert(chosen == pickers.scopes[index])
    local ok = pcall(pickers.launch, kind, chosen)
    assert(ok == not not pickers.types[kind][chosen])
  end
  local actual, chosen = pickers.launch(kind)
  assert(actual == kind and chosen == "all")
end
local inventory = {
  spaces = "spaces/all", tabs = "tabs/all", ["tabs-all"] = "tabs/all", ["tabs-space"] = "tabs/space",
  panes = "panes/all", ["panes-all"] = "panes/all", ["panes-space"] = "panes/space", ["panes-tab"] = "panes/tab",
  agents = "agents/all", ["agents-all"] = "agents/all", ["agents-space"] = "agents/space", ["agents-tab"] = "agents/tab",
}
local count = 0
for name in pairs(pickers.presets) do
  local kind, scope = pickers.preset(name)
  assert(kind .. "/" .. scope == inventory[name])
  count = count + 1
end
assert(count == 12)
for _, name in ipairs({ "tabs-tab", "spaces-space", "spaces-all", "panes-current", "tabs-current", "agents-current", "unknown" }) do
  assert(not pcall(pickers.preset, name))
end
for _, kind in ipairs(pickers.order) do
  assert(not pcall(pickers.launch, kind, "current"))
  assert(not pcall(pickers.launch, kind, "unknown"))
end
assert(not pcall(pickers.launch, "workspaces"))
local chosen = "tab"
for index, kind in ipairs({ "panes", "tabs", "spaces", "agents" }) do
  assert(pickers.effective(kind, chosen) == ({ "tab", "space", false, "tab" })[index] or
    (kind == "spaces" and pickers.effective(kind, chosen) == nil))
  assert(chosen == "tab")
end
print("picker registry checks passed")
local keymap = require("pickr.keymap")
local map = keymap.resolve()
for _, kind in ipairs(pickers.order) do
  for _, chosen in ipairs(pickers.scopes) do
    local keys = {}
    for _, key in ipairs(keymap.expect(map, kind, chosen)) do keys[key] = true end
    for _, destination in ipairs(pickers.order) do assert(keys[map.keys[destination][1]]) end
    for _, scope in ipairs(pickers.scopes) do
      local changes_effective = pickers.types[kind][scope] and pickers.effective(kind, chosen) ~= scope
      assert(not not keys[map.keys["scope_" .. scope][1]] == not not changes_effective)
    end
  end
end
