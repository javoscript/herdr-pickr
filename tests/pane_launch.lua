local uv = require("luv")
local root = assert(uv.fs_realpath(arg[0])):match("^(.*)/tests/[^/]+$")
package.path = root .. "/src/?.lua;" .. package.path
local process, runtime, json = require("pickr.process"), require("pickr.runtime"), require("pickr.vendor.json")
local expected = {
  tabs = { "tabs" }, panes = { "panes" }, agents = { "agents" },
  ["tabs-space"] = { "tabs", "space" }, ["tabs-all"] = { "tabs", "all" },
  spaces = { "spaces" }, ["agents-space"] = { "agents", "space" }, ["agents-tab"] = { "agents", "tab" },
  ["agents-all"] = { "agents", "all" }, ["panes-tab"] = { "panes", "tab" },
  ["panes-space"] = { "panes", "space" }, ["panes-all"] = { "panes", "all" },
}
local file = assert(io.open(root .. "/herdr-plugin.toml"))
local sections, current = { actions = {}, panes = {} }, nil
for line in file:lines() do
  local section = line:match("^%[%[(%w+)%]%]$")
  if section then
    current = {}; sections[section][#sections[section] + 1] = current
  elseif current then
    local key, value = line:match("^(%w+) = (.+)$")
    if key then current[key] = json.decode(value) end
  end
end
file:close()
for section, entries in pairs(sections) do
  assert(#entries == 12)
  local seen = {}
  for _, entry in ipairs(entries) do
    local mode = assert(expected[entry.id])
    assert(not seen[entry.id]); seen[entry.id] = true
    assert(entry.command[1] == "lua")
    if section == "actions" then
      assert(entry.command[2] == "src/open.lua" and entry.command[3] == entry.id and #entry.command == 3)
    else
      assert(entry.placement == "popup" and entry.width == "80%" and entry.height == "70%")
      assert(entry.command[2] == "src/main.lua" and entry.command[3] == mode[1] and entry.command[4] == mode[2])
    end
  end
end
local fixture = [=[
local root, action, launch_mode, kind, scope = table.unpack(arg, 1, 5)
package.path = root .. "/src/?.lua;" .. package.path
local runtime, config, core = require("pickr.runtime"), require("pickr.config"), require("pickr.core")
local settings = config.decode('{"popup":{"width":101,"height":"83%","show_hints":false},'
  .. '"refresh":{"interval_ms":1000},"preview":{"enabled_by_default":false},"theme":{"name":"terminal"},'
  .. '"prompt":{"variants":{"panes":"Splits: "}},'
  .. '"columns":{"panes":["pane"]},"keys":{"panes":["alt-9"]}}')
local env = { HERDR_ENV = "1", HERDR_PLUGIN_ID = "javoscript.herdr-pickr",
  HERDR_PLUGIN_CONTEXT_JSON = '{"workspace_id":"origin","tab_id":"A"}' }
local getenv = os.getenv
os.getenv = function(key) return env[key] or getenv(key) end
config.load = function() return settings end
local snapshot = { workspaces = { { workspace_id = "origin", active_tab_id = "B", tab_count = 0 } },
  tabs = { { workspace_id = "origin", tab_id = "A", pane_count = 0 },
    { workspace_id = "origin", tab_id = "B", pane_count = 0 } }, panes = {}, layouts = {}, agents = {} }
runtime.herdr = function(...) assert(select(1, ...) == "api"); return { snapshot = snapshot } end
runtime.socket_request = function(method, params)
  assert(method == "plugin.pane.open" and params.entrypoint == action)
  assert(params.width == 101 and params.height == "83%")
  assert(params.env.PICKR_ORIGIN_WORKSPACE_ID == "origin" and params.env.PICKR_ORIGIN_TAB_ID == "A")
  for k, v in pairs(params.env) do env[k] = v end
  env.HERDR_PLUGIN_CONTEXT_JSON = '{"workspace_id":"elsewhere","tab_id":"C"}'
  config.load = function() error("owner must retain launch snapshot") end
  return { type = "plugin_pane_opened", plugin_pane = { plugin_id = "javoscript.herdr-pickr",
    entrypoint = action, pane = { pane_id = "popup" } } }
end
runtime.focus_pane = function() error("unexpected focus") end
local launched = false
runtime.run_picker = function(_, args, _, _, session)
  launched = true
  assert(session.popup.origin.workspace_id == "origin" and session.popup.origin.tab_id == "A")
  local s = session.settings
  assert(s.popup.width == 101 and s.popup.height == "83%" and not s.popup.show_hints)
  assert(s.theme_name == "terminal" and not session.popup.preview_visible)
  assert(s.refresh.interval_ms == 1000)
  assert(s.keymap.keys.panes[1] == "alt-9" and s.columns.panes[1] == "pane")
  if kind == "panes" then
    local found = false
    for _, option in ipairs(args) do if option == "--border-label=Panes" then found = true end end
    assert(found)
  end
  return 130, {}, "", 0
end
if launch_mode == "action" then
  arg = { action }; dofile(root .. "/src/open.lua")
end
arg = { [0] = root .. "/src/main.lua", kind, scope }
dofile(root .. "/src/main.lua")
assert(launched)
print("LAUNCH OK")
os.exit(0)
]=]
for action, mode in pairs(expected) do
  for _, launch_mode in ipairs({ "action", "direct" }) do
    local code, output, errors = process.run(uv.exepath(), { "-e", fixture, "--", "-", root,
      action, launch_mode, mode[1], mode[2] }, nil, runtime.fzf_env(), 5000)
    assert(code == 0 and output:find("LAUNCH OK", 1, true), action .. ": " .. errors)
  end
end
for _, kind in ipairs({ "tabs", "spaces", "workspaces", "unknown" }) do
  local code, _, errors = process.run(uv.exepath(), { root .. "/src/main.lua", kind, "tab" }, nil, runtime.fzf_env(), 5000)
  assert(code == 2 and errors:find("Usage:", 1, true), errors)
end
for _, kind in ipairs({ "tabs", "panes", "agents" }) do
  local code, _, errors = process.run(uv.exepath(), { root .. "/src/main.lua", kind, "current" }, nil, runtime.fzf_env(), 5000)
  assert(code == 2 and errors:find("use 'space'", 1, true), errors)
end
print("Picker launch: twelve manifest action/owner mappings, direct dimensions, configured popup/settings handoff, changed startup focus and invalid/legacy scopes OK")
