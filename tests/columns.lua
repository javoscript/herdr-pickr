local uv = require("luv")
local root = assert(uv.fs_realpath(arg[0])):match("^(.*)/tests/[^/]+$")
package.path = root .. "/src/?.lua;" .. package.path
local config, columns = require("pickr.config"), require("pickr.columns")
local core, runtime = require("pickr.core"), require("pickr.runtime")
local json, themes = require("pickr.vendor.json"), require("pickr.themes")
local function equal(a, b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
local function fails(fn, field)
  local ok, err = pcall(fn)
  assert(not ok and tostring(err):find(field, 1, true), tostring(err))
end
local expected = {
  spaces = "status,space,tabs,directory", tabs = "status,space,tab,panes,directory",
  agents = "status,space,tab,agent,title,pane", panes = "status,space,tab,title,pane,directory",
}
for _, text in ipairs({ '{}', '{"columns":null}', '{"columns":{}}' }) do
  for variant, names in pairs(expected) do
    equal(table.concat(config.decode(text).columns[variant], ","), names)
    equal(table.concat(config.decode('{"columns":{"' .. variant .. '":null}}').columns[variant], ","), names)
  end
end
for variant, defaults in pairs(columns.defaults) do
  local settings = config.decode(json.encode({ columns = { [variant] = { defaults[#defaults] } } }))
  equal(table.concat(settings.columns[variant]), defaults[#defaults])
  for other, names in pairs(expected) do
    if other ~= variant then equal(table.concat(settings.columns[other], ","), names) end
  end
  for _, value in ipairs({ '[]', '{}', 'false', '1', '"tab"', '[null]', '[1]', '[false]', '[{}]', '[[]]',
    '["status","status"]', '["Status"]', '["missing"]' }) do
    fails(function() config.decode('{"columns":{"' .. variant .. '":' .. value .. '}}') end, "columns." .. variant)
  end
end
for _, value in ipairs({ '[]', 'false', '1', '"columns"' }) do
  fails(function() config.decode('{"columns":' .. value .. '}') end, "columns")
end
for _, text in ipairs({ '{"tabs_here":null}', '{"tabs_current":["space"]}', '{"agents_all":["directory"]}',
  '{"panes_tab":["tab"]}', '{"panes_tab":["space"]}', '{"panes_current":["space"]}' }) do
  fails(function() config.decode('{"columns":' .. text .. '}') end, "columns.")
end
local text = '{"columns":{"tabs":["directory","tab"],"spaces":["tabs"]}}'
local deps = { getenv = function(key)
  return ({ HERDR_PLUGIN_ID = "javoscript.herdr-pickr", HERDR_PLUGIN_CONFIG_DIR = "/fixture" })[key]
end, read_file = function() return text end }
local original = config.load(deps)
local handoff = config.snapshot(original)
text = '{"columns":{"tabs":["status"]}}'
local owner = config.owner({ getenv = function() return handoff end,
  read_file = function() error("snapshot must not reread config") end })
equal(table.concat(owner.columns.tabs, ","), "directory,tab")
equal(table.concat(config.load(deps).columns.tabs), "status")
for _, bad in ipairs({ 'null', '{}', '{"spaces":[]}', '{"spaces":["space","space"]}' }) do
  local invalid = json.decode(handoff, true)
  invalid.settings.columns = json.decode(bad, true)
  fails(function() config.owner({ getenv = function() return json.encode(invalid) end }) end, "columns")
end
text = '{"columns":{"agents":["directory"]}}'
fails(function() config.load(deps) end, "/fixture/config.json: columns.agents")

-- Run both actual entrypoints with a failing config and tripwires on popup/fzf.
local launch = [=[
package.path = arg[1] .. "/src/?.lua;" .. package.path
local config, runtime = require("pickr.config"), require("pickr.runtime")
local invalid = arg[3]
config.load = function() return config.decode(invalid) end
runtime.open_popup = function() error("POPUP_STARTED") end
runtime.run_picker = function() error("FZF_STARTED") end
local root, mode = arg[1], arg[2]
arg = mode == "open" and { "spaces" } or { [0] = root .. "/src/main.lua", "spaces" }
dofile(root .. "/src/" .. (mode == "open" and "open.lua" or "main.lua"))
]=]
for _, invalid in ipairs({ { '{"columns":{"agents":["directory"]}}', "columns.agents" },
  { '{"columns":{"panes":["tabs"]}}', "columns.panes" },
  { '{"keys":{"panes":"alt-3"}}', "keys.panes" },
  { '{"prompt":{"variants":{"panes":false}}}', "prompt.variants.panes" } }) do
for _, mode in ipairs({ "open", "main" }) do
  local env = runtime.fzf_env(); env[#env + 1] = "HERDR_ENV=1"
  local code, _, err = require("pickr.process").run(uv.exepath(),
    { "-e", launch, "--", "-", root, mode, invalid[1] }, nil, env, 5000)
  equal(code, 1)
  assert(err:find(invalid[2], 1, true), err)
  assert(not err:find("STARTED", 1, true), err)
end
end
print("Columns configuration: defaults, strict validation, snapshot stability and pre-launch errors OK")

local snapshot = {
  workspaces = {
    { workspace_id = "w1", label = "parent", tab_count = 1, active_tab_id = "t1", agent_status = "working",
      worktree = { repo_key = "repo", is_linked_worktree = false } },
    { workspace_id = "w2", label = "child", tab_count = 1, active_tab_id = "t2", agent_status = "blocked",
      worktree = { repo_key = "repo", is_linked_worktree = true } },
  },
  tabs = {
    { tab_id = "t1", workspace_id = "w1", label = "alpha", pane_count = 1, agent_status = "working" },
    { tab_id = "t2", workspace_id = "w2", label = "beta", pane_count = 1, agent_status = "blocked" },
  },
  panes = { { pane_id = "p1", workspace_id = "w1", tab_id = "t1", agent_status = "working",
      terminal_title = "omega", cwd = "/directoryonly", label = "review-é\nqueue\t[one]" },
    { pane_id = "p2", workspace_id = "w2", tab_id = "t2", agent_status = "blocked",
      terminal_title = "theta", cwd = "/elsewhere", label = "labelonly" } },
  layouts = { { workspace_id = "w1", tab_id = "t1", focused_pane_id = "p1", panes = { { pane_id = "p1" } } },
    { workspace_id = "w2", tab_id = "t2", focused_pane_id = "p2", panes = { { pane_id = "p2" } } } },
  agents = {
    { pane_id = "p1", tab_id = "t1", workspace_id = "w1", agent = "agentonly", agent_status = "working", terminal_title = "omega" },
    { pane_id = "p2", tab_id = "t2", workspace_id = "w2", agent = "otheragent", agent_status = "blocked", terminal_title = "theta" },
  },
}
local empty = { workspaces = {}, tabs = {}, panes = {}, layouts = {}, agents = {} }
local function plain(value) return (value:gsub("\27%[[%d;]*m", "")) end
local function cells(row)
  local result, display = {}, plain(row):match("^[^\t]+\t[^\t]+\t(.*)$")
  for cell in (display .. "  ·  "):gmatch("(.-)  ·  ") do result[#result + 1] = cell:gsub(" +$", "") end
  return result
end
local function identity(row) return row:match("^([^\t]+\t[^\t]+)\t") end
local function alignment(rows, header)
  local positions
  local all = { header }; for _, row in ipairs(rows) do all[#all + 1] = row end
  for _, row in ipairs(all) do
    local display, offsets = plain(row):match("^[^\t]+\t[^\t]+\t(.*)$"), {}
    local start = 1
    while true do
      local at = display:find("  ·  ", start, true)
      if not at then break end
      offsets[#offsets + 1] = utf8.len(display:sub(1, at - 1)); start = at + #"  ·  "
    end
    local joined = table.concat(offsets, ",")
    if positions then equal(joined, positions) else positions = joined end
  end
end
runtime.current_workspace = function() return "w1" end
runtime.origin = function() return { workspace_id = "w1", tab_id = "t1" } end
runtime.herdr = function() return { snapshot = snapshot } end
runtime.preview_command = function() return "true" end
local variants = require("pickr.pickers").presets
local modes = { { "spaces", "all" }, { "tabs", "all" }, { "tabs", "space" },
  { "panes", "all" }, { "panes", "space" }, { "panes", "tab" },
  { "agents", "all" }, { "agents", "space" }, { "agents", "tab" } }
for _, mode in ipairs(modes) do
  local variant = mode[1]
  local defaults = columns.defaults[variant]
  local baseline, base_header = core.snapshot_candidates(snapshot, mode[1], mode[2], "w1", nil, "t1")
  assert(#baseline > 0)
  local layouts = { defaults }
  local reversed = {}; for i = #defaults, 1, -1 do reversed[#reversed + 1] = defaults[i] end
  layouts[#layouts + 1] = reversed
  local middle = { defaults[2], "status" }; for i = 3, #defaults do middle[#middle + 1] = defaults[i] end
  layouts[#layouts + 1] = middle
  local hidden = {}; for i = 2, #defaults do hidden[#hidden + 1] = defaults[i] end
  layouts[#layouts + 1] = hidden
  for _, name in ipairs(defaults) do layouts[#layouts + 1] = { name } end
  for _, layout in ipairs(layouts) do
    for _, theme in ipairs({ "catppuccin", "rose-pine-dawn", "terminal", "custom" }) do
      local settings = config.decode(json.encode({ columns = { [variant] = layout },
        theme = theme == "custom" and { custom = { annotation = "red", status_blocked = "blue" } } or { name = theme } }))
      local rows, header = core.snapshot_candidates(snapshot, mode[1], mode[2], "w1", settings, "t1")
      equal(#rows, #baseline); alignment(rows, header)
      local header_cells, expected_header = cells(header), cells(base_header)
      for i, row in ipairs(rows) do
        equal(identity(row), identity(baseline[i]))
        local actual, original_cells = cells(row), cells(baseline[i])
        equal(#actual, #layout)
        for j, name in ipairs(layout) do
          local source; for k, default in ipairs(defaults) do if name == default then source = k end end
          equal(actual[j], original_cells[source]); equal(header_cells[j], expected_header[source])
        end
      end
      if layout == defaults and theme == "catppuccin" then
        equal(table.concat(rows, "\n"), table.concat(baseline, "\n")); equal(header, base_header)
      end
      local no_rows, heading = core.snapshot_candidates(empty, mode[1], mode[2], "w1", settings)
      equal(#no_rows, 0); equal(table.concat(cells(heading), "|"), table.concat(header_cells, "|"))
      for _, name in ipairs(layout) do
        if name == "pane" then
          assert(header:find(themes.ansi(settings.roles.annotation) .. "[label]", 1, true))
          local labeled = table.concat(rows, "\n")
          assert(labeled:find(themes.ansi(settings.roles.annotation) .. "[review-é queue [one]]", 1, true))
        end
        if name == "space" and mode[2] == "all" then
          assert(table.concat(rows, "\n"):find(themes.ansi(settings.roles.annotation) .. "[parent]", 1, true))
        end
      end
    end
  end
end
print("Columns rendering: nine effective type/scopes, subsets, single columns, moved status, themes, annotations, alignment and identity OK")

for _, label in ipairs({ false, "", json.null }) do
  local saved = snapshot.panes[1].label
  snapshot.panes[1].label = label
  if label == json.null then snapshot.panes[1].label = nil end
  local rows = core.snapshot_candidates(snapshot, "agents", "space", "w1",
    config.decode('{"columns":{"agents":["pane","title"]}}'))
  equal(cells(rows[1])[1], "p1")
  snapshot.panes[1].label = saved
end

-- Exercise production search flags rather than reconstructing fzf options.
local function filter(variant, layout, query, matches)
  local mode = assert(variants[variant])
  local settings = config.decode(json.encode({ columns = { [mode[1]] = layout } }))
  runtime.run_picker = function(_, args, input)
    args[#args + 1] = "--filter=" .. query
    args[#args + 1] = "--no-print-query"
    local code, output, err = require("pickr.process").run("fzf", args, input, runtime.fzf_env(), 5000)
    equal(code, matches and 0 or 1); assert(err == "", err)
    if matches then assert(output ~= "") else equal(output, "") end
    return 130, {}, ""
  end
  core.pick(mode[1], mode[2], settings)
end
for _, case in ipairs({
  { "tabs-all", { "tab", "directory" }, "alpha directoryonly", true },
  { "tabs-all", { "tab", "directory" }, "alphadirectoryonly", false },
  { "tabs-all", { "tab" }, "directoryonly", false },
  { "tabs-all", { "tab" }, "parent", false },
  { "tabs-all", { "tab" }, "working", false },
  { "tabs-all", { "tab" }, "alpha", true },
  { "agents-all", { "title", "agent" }, "labelonly", false },
  { "agents-all", { "title", "agent" }, "p2", false },
  { "agents-all", { "title", "agent" }, "omega agentonly", true },
  { "agents-all", { "pane" }, "labelonly", true },
  { "agents-all", { "agent", "status" }, "blocked", true },
  { "spaces", { "tabs" }, "parent", false },
  { "spaces", { "tabs" }, "tabs", true },
  { "panes-tab", { "directory", "pane" }, "directoryonly review", true },
  { "panes-space", { "title", "directory" }, "omega directoryonly", true },
  { "panes-space", { "title", "directory" }, "omegadirectoryonly", false },
  { "panes-all", { "pane" }, "labelonly", true },
  { "panes-all", { "title" }, "p2", false },
  { "panes-all", { "title" }, "labelonly", false },
  { "panes-all", { "title" }, "elsewhere", false },
  { "panes-all", { "title" }, "blocked", false },
  { "panes-all", { "title" }, "beta", false },
  { "panes-all", { "title" }, "child", false },
  { "panes-all", { "space" }, "parent", true },
  { "panes-space", { "space", "tab" }, "parent alpha", true },
  { "panes-tab", { "space", "tab" }, "parent alpha", true },
  { "agents-tab", { "space", "tab" }, "parent alpha", true },
  { "tabs-space", { "space", "tab" }, "parent alpha", true },
}) do filter(table.unpack(case)) end
for variant, defaults in pairs(columns.defaults) do
  filter(variant, { defaults[2] }, "p1", false)
  filter(variant, { "status" }, "working", true)
end

-- Same resolved settings are carried through switches and refresh failure/retry.
local settings = config.decode('{"columns":{"tabs":["tab"],"spaces":["tabs"],"agents":["agent"],"panes":["directory"]}}')
local sequence = { "tabs", "spaces", "agents", "panes" }
local keys = { tabs = "ctrl-t", spaces = "ctrl-s", agents = "ctrl-a", panes = "ctrl-r" }
local visits, focused = 0, nil
runtime.focus_pane = function(id) focused = id end
runtime.run_picker = function(_, args, input, _, session, render)
  visits = visits + 1
  local variant, mode = sequence[visits], variants[sequence[visits]]
  local expected_rows, expected_header = core.snapshot_candidates(snapshot, mode[1], mode[2], "w1", settings, "t1")
  equal(input, expected_header .. "\n" .. table.concat(expected_rows, "\n"))
  assert(table.concat(args, "\n"):find("--nth=1\n", 1, true))
  equal(session.settings, settings)
  local id = expected_rows[1]:match("^[^\t]+")
  local generation = session:begin_refresh(id)
  assert(session:fail(generation))
  generation = session:begin_refresh(id)
  local rows, header = render(empty); equal(#rows, 0)
  equal(table.concat(cells(header)), table.concat(cells(expected_header)))
  assert(session:publish(generation, rows, header))
  generation = session:begin_refresh(nil)
  rows, header = render(snapshot)
  equal(table.concat(rows, "\n"), table.concat(expected_rows, "\n")); equal(header, expected_header)
  assert(session:publish(generation, rows, header))
  if sequence[visits + 1] then return 1, { query = "", key = keys[sequence[visits + 1]] }, "" end
  return 0, { query = "", key = "", row = rows[1], target = session:accept(rows[1]) }, ""
end
core.pick("tabs", "all", settings)
equal(visits, 4); equal(focused, "p1")
print("Columns matching/session: real fzf visible-only independent matching, hidden IDs, switches, empty refresh, failure/retry and acceptance OK")
