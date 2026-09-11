local uv = require("luv")
local directory = assert(uv.fs_realpath(arg[0])):match("^(.*)/[^/]+$")
local source = assert(directory:match("^(.*)/[^/]+$")) .. "/src"
package.path = source .. "/?.lua;" .. package.path
local core, runtime, json = require("pickr.core"), require("pickr.runtime"), require("pickr.vendor.json")
local original_run_picker = runtime.run_picker
-- Existing flag/filter fixtures isolate the UI process. Interactive refresh
-- checks exercise the real asynchronous controller separately.
runtime.run_picker = function(command, args, input, env, session)
  local code, output, errors, signal = runtime.run(command, args, input, env)
  local selected = output:match("^\n(.*)$")
  local target = selected and session:accept(selected:gsub("\n+$", ""))
  session:close()
  return code, output, errors, signal, target
end

-- Action context wins over inherited caller state; the captured origin wins
-- over the fresh context Herdr supplies when the popup eventually opens.
local context_env = {
  HERDR_PLUGIN_ID = "javoscript.herdr-pickr",
  HERDR_PLUGIN_CONTEXT_JSON = '{"workspace_id":"action-space"}',
  HERDR_ACTIVE_WORKSPACE_ID = "inherited-space",
}
local function getenv(key) return context_env[key] end
assert(runtime.current_workspace(getenv) == "action-space")
context_env.PICKR_ORIGIN_WORKSPACE_ID = "original-space"
assert(runtime.current_workspace(getenv) == "original-space")
context_env.PICKR_ORIGIN_WORKSPACE_ID = nil
context_env.HERDR_PLUGIN_ID = nil
assert(runtime.current_workspace(getenv) == "inherited-space")

do
  local saved_herdr, saved_workspace, saved_arg = runtime.herdr, runtime.current_workspace, arg
  local saved_env = os.getenv("HERDR_ENV")
  uv.os_setenv("HERDR_ENV", "1")
  runtime.current_workspace = function() return "original-space" end
  for _, entry in ipairs({ "tabs-current", "tabs-all", "spaces", "agents-current", "agents-all" }) do
    local called = false
    runtime.herdr = function(...)
      local args = { ... }
      assert(table.concat(args, "|") == "plugin|pane|open|--plugin|javoscript.herdr-pickr|--entrypoint|"
        .. entry .. "|--env|PICKR_ORIGIN_WORKSPACE_ID=original-space")
      called = true
      return {}
    end
    arg = { [0] = source .. "/open.lua", entry }
    dofile(source .. "/open.lua")
    assert(called)
  end
  runtime.herdr, runtime.current_workspace, arg = saved_herdr, saved_workspace, saved_arg
  if saved_env then uv.os_setenv("HERDR_ENV", saved_env) else uv.os_unsetenv("HERDR_ENV") end
end

local function plain(text)
  return (text:gsub("\27%[[%d;]*m", ""))
end

local function equal(actual, expected)
  assert(json.encode(actual) == json.encode(expected),
    json.encode(actual) .. " ~= " .. json.encode(expected))
end

local original_herdr, original_run, original_focus = runtime.herdr, runtime.run, runtime.focus_agent_pane
local original_current = os.getenv("HERDR_ACTIVE_WORKSPACE_ID")
uv.os_setenv("HERDR_ACTIVE_WORKSPACE_ID", "w1")
local workspaces = {
  { workspace_id = "w1", label = "short", tab_count = 2, active_tab_id = "w1:t2", agent_status = "idle" },
  { workspace_id = "w2", label = "long space", tab_count = 12, active_tab_id = "w2:t1", agent_status = "blocked" },
}
local tabs = {
  { tab_id = "w1:t1", workspace_id = "w1", label = "long tab", pane_count = 2, agent_status = "unknown" },
  { tab_id = "w1:t2", workspace_id = "w1", label = "é", pane_count = 12, agent_status = "done" },
  { tab_id = "w2:t1", workspace_id = "w2", label = "other", pane_count = 1, agent_status = "blocked" },
}
local home = assert(os.getenv("HOME"))
local panes = {
  { pane_id = "w1:p1", cwd = "/wrong-first-pane", label = "review-é\nqueue\t[one]" },
  { pane_id = "w1:p2", cwd = "/shell", foreground_cwd = home .. "/Projects/é", focused = false },
  { pane_id = "w1:p3", cwd = "/active-tab", foreground_cwd = "" },
  { pane_id = "w2:p1" },
}
local layouts = {
  { tab_id = "w1:t1", focused_pane_id = "w1:p2" },
  { tab_id = "w1:t2", focused_pane_id = "w1:p3" },
  { tab_id = "w2:t1", focused_pane_id = "w2:p1" },
}
local agents = json.decode([[ [
  {"pane_id":"w1:p1","tab_id":"w1:t1","workspace_id":"w1","agent":"opencode","agent_status":"working","terminal_title":"title"},
  {"pane_id":"w1:p2","tab_id":"w1:t2","workspace_id":"w1","agent":"pi","name":null,"terminal_title":null},
  {"pane_id":"w2:p1","tab_id":"w2:t1","workspace_id":"w2","agent":"claude"}
] ]])
local focus_calls = {}
runtime.herdr = function(kind, action, flag, id)
  if action == "focus" then focus_calls[#focus_calls + 1] = { kind, flag }; return {} end
  assert(kind == "api" and action == "snapshot" and not flag and not id)
  return { snapshot = { workspaces = workspaces, tabs = tabs, agents = agents,
    panes = panes, layouts = layouts } }
end
runtime.focus_agent_pane = function(id) focus_calls[#focus_calls + 1] = { "pane", id } end

for _, mode in ipairs({ { "tabs", "current" }, { "tabs", "all" },
    { "workspaces", "all" }, { "agents", "current" }, { "agents", "all" } }) do
  local rows, header = core.candidates(table.unpack(mode))
  local rebuilt, rebuilt_header = core.snapshot_candidates(runtime.herdr("api", "snapshot").snapshot,
    mode[1], mode[2], "w1")
  equal(rebuilt, rows)
  equal(rebuilt_header, header)
  local positions
  local with_header = { header }
  for _, row in ipairs(rows) do with_header[#with_header + 1] = row end
  for _, row in ipairs(with_header) do
    local columns, width = {}, 0
    local display = plain(row):match("^[^\t]+\t[^\t]+\t(.*)$")
    display = row == header and display:sub(3) or display:match("^%S+ (.*)$")
    for _, cp in utf8.codes(display) do
      if cp == 0xb7 then columns[#columns + 1] = width end
      width = width + 1
    end
    if positions then equal(columns, positions) else positions = columns end
  end
  local labels = plain(header):match("^[^\t]+\t[^\t]+\t(.*)$"):gsub("%s+", " "):gsub("^ ", "")
  local expected_headers = {
    ["workspaces:all"] = "status · space · tabs · directory",
    ["tabs:current"] = "status · tab · panes · directory",
    ["tabs:all"] = "status · space · tab · panes · directory",
    ["agents:current"] = "status · tab · agent · title · pane [label]",
    ["agents:all"] = "status · space · tab · agent · title · pane [label]",
  }
  equal(labels, expected_headers[mode[1] .. ":" .. mode[2]])
  local header_code, header_output = original_run("fzf", { "--ansi", "--header-lines=1",
    "--delimiter=\t", "--with-nth=3..", "--filter=status" },
    header .. "\n" .. table.concat(rows, "\n"), runtime.fzf_env(), 5000)
  assert(header_code == 1 and header_output == "", "Header must not be searchable/selectable")
  if mode[2] == "current" then
    assert(#rows == 2)
    for _, row in ipairs(rows) do assert(row:match("^w1:")) end
  end
  for _, code in ipairs({ 0, 1, 130 }) do
    focus_calls = {}
    runtime.run = function(command, args, input)
      assert(command == "fzf" and input == header .. "\n" .. table.concat(rows, "\n"))
      local flags = {}
      for _, flag in ipairs(args) do flags[flag] = true end
      assert(flags["--prompt=◉/> "])
      assert((flags["--no-sort"] == true) == (mode[1] ~= "tabs" or mode[2] == "all"))
      assert(flags["--ansi"])
      assert(flags["--header-lines=1"])
      assert(flags["--expect=ctrl-r,ctrl-t,ctrl-s,ctrl-a,ctrl-g"])
      assert(flags["--with-nth=3.."])
      assert(flags["--preview-window=right:50%:border-left:nowrap"])
      assert(flags["--preview=" .. runtime.preview_command()])
      assert(flags["--bind=esc:abort,ctrl-c:abort,enter:accept,ctrl-p:toggle-preview"])
      return code, code == 0 and "\n" .. plain(rows[2]) .. "\n" or "", "", 0
    end
    core.pick(table.unpack(mode))
    if code == 0 then
      equal(focus_calls, { { mode[1] == "agents" and "pane" or
        (mode[1] == "tabs" and "tab" or "workspace"), rows[2]:match("^(.-)\t") } })
    else equal(focus_calls, {}) end
  end
  runtime.run = function() return 0, "unknown\tselection\n", "", 0 end
  assert(not pcall(core.pick, table.unpack(mode)))
  runtime.run = function() return 0, "\n" .. header .. "\n", "", 0 end
  assert(not pcall(core.pick, table.unpack(mode)), "Header must not be a valid selection")
end
-- Pane labels are display-only suffixes, searchable through production fzf flags.
for _, scope in ipairs({ "current", "all" }) do
  local rows = core.candidates("agents", scope)
  assert(rows[1]:find("w1:p1 \27[38;2;82;79;103m[review-é queue [one]]\27[0m", 1, true))
  equal(rows[1]:match("^([^\t]+)\t([^\t]+)"), "w1:p1")
  equal(rows[1]:match("^[^\t]+\t([^\t]+)"), "w1:p1")
  assert(plain(rows[2]):match("  ·  w1:p2$"))
  for _, fixture in ipairs({ {}, { label = "" }, json.decode('{"label":null}') }) do
    local saved_pane = panes[1]
    fixture.pane_id = "w1:p1"
    panes[1] = fixture
    assert(plain(core.candidates("agents", scope)[1]):match("  ·  w1:p1$"))
    panes[1] = saved_pane
  end
  local saved_pane = table.remove(panes, 1)
  assert(plain(core.candidates("agents", scope)[1]):match("  ·  w1:p1$"))
  table.insert(panes, 1, saved_pane)

  -- Match several agents to check priority order survives label filtering.
  panes[2].label, panes[4].label = "review second", "review other-space"
  local expected = core.candidates("agents", scope)
  runtime.run = function(command, args, input, env)
    args[#args + 1] = "--filter=review"
    local code, output, errors, signal = original_run(command, args, input, env, 5000)
    equal(code, 0)
    local displays = {}
    for _, row in ipairs(expected) do displays[#displays + 1] = plain(row) end
    equal(output, table.concat(displays, "\n") .. "\n")
    -- Accept the first filtered row as an interactive picker would.
    return code, "\n" .. plain(expected[1]) .. "\n", errors, signal
  end
  focus_calls = {}
  core.pick("agents", scope)
  equal(focus_calls, { { "pane", "w1:p1" } })
  runtime.run = original_run
  panes[2].label, panes[4].label = nil, nil
end
print("Pane labels: styling, cleaning, absent metadata, search, ordering and targeting OK")
equal(core.aligned_rows({}), {})
equal(core.aligned_rows({ { "id", "a\nb\t", "x" } }), { "id\t-\ta b   ·  x" })

-- Use the production flags in every variant: one term cannot span columns,
-- but separate terms can match different columns (including the last one).
local original_candidates = core.candidates
for _, mode in ipairs({ { "tabs", "current", 4 }, { "tabs", "all", 5 },
    { "workspaces", "all", 4 }, { "agents", "current", 5 }, { "agents", "all", 6 } }) do
  local entry = { "hidden-selection", "alpha", "beta", indicator = "\27[31m●\27[0m",
    preview_pane = "hidden-preview" }
  local heading = { "@header", "status", "name", indicator = " " }
  for i = 3, mode[3] do
    entry[#entry + 1] = i == mode[3] and "omega phrase" or "filler"
    heading[#heading + 1] = "column" .. i
  end
  local rows, header = core.aligned_rows({ entry }, heading)
  core.candidates = function() return rows, header end
  for _, spec in ipairs({
      { "abt", false }, { "apa", true }, { "omg", true },
      { "alp bet omg", true }, { "'omega\\ phrase", true },
      { "alp !bet", false }, { "missing | omg", true },
      { "hidden-selection", false }, { "hidden-preview", false }, { "column", false },
    }) do
    runtime.run = function(command, args, input, env)
      args[#args + 1] = "--filter=" .. spec[1]
      local code, output, errors, signal = original_run(command, args, input, env, 5000)
      equal(code, spec[2] and 0 or 1)
      equal(output, spec[2] and plain(rows[1]) .. "\n" or "")
      return code, "\n" .. output, errors, signal
    end
    focus_calls = {}
    core.pick(mode[1], mode[2])
    equal(#focus_calls, spec[2] and 1 or 0)
  end
end
core.candidates = original_candidates
print("Field matching: independent columns, multi-term queries, extended syntax and hidden IDs OK")

-- Preview targets are independent of the IDs used when accepting selections.
local function preview_ids(kind, scope)
  local result = {}
  for _, row in ipairs(core.candidates(kind, scope)) do
    result[#result + 1] = row:match("^[^\t]+\t([^\t]+)\t")
  end
  return result
end
equal(preview_ids("workspaces", "all"), { "w1:p3", "w2:p1" })
equal(preview_ids("tabs", "current"), { "w1:p2", "w1:p3" })
equal(preview_ids("tabs", "all"), { "w1:p2", "w1:p3", "w2:p1" })
equal(preview_ids("agents", "current"), { "w1:p1", "w1:p2" })
equal(preview_ids("agents", "all"), { "w1:p1", "w1:p2", "w2:p1" })

-- Priority beats recency; equal keys retain API order, including missing data.
agents = {}
for i, spec in ipairs({
    { "unknown", 900 }, { "idle", 800 }, { "working", 700 },
    { "done", 600 }, { "blocked", 10 }, { "blocked", 20 },
    { "blocked", 20 }, {}, { "future-status" }, { "idle" },
  }) do
  local workspace = i == 6 and "w2" or "w1"
  agents[i] = { pane_id = workspace .. ":p" .. i, tab_id = workspace .. ":t1",
    workspace_id = workspace, agent = "match", agent_status = spec[1], state_change_seq = spec[2] }
end
local function ids(rows)
  local result = {}
  for _, row in ipairs(rows) do result[#result + 1] = row:match("^(.-)\t") end
  return result
end

-- Match expanded-sidebar grouping even when children precede their parent.
-- Orphans stay in input order; tabs keep their own order inside each space.
local saved_workspaces, saved_tabs, saved_panes, saved_layouts = workspaces, tabs, panes, layouts
workspaces, tabs, panes, layouts = {}, {}, {}, {}
for _, spec in ipairs({
    { "a-child1", "a", true }, { "standalone" }, { "b-parent", "b", false },
    { "a-parent", "a", false }, { "b-child", "b", true }, { "a-child2", "a", true },
    { "orphan1", "orphan", true }, { "plain" }, { "orphan2", "orphan", true },
  }) do
  local id = spec[1]
  workspaces[#workspaces + 1] = { workspace_id = id, label = id .. " match", tab_count = 2,
    active_tab_id = id .. ":t2", worktree = spec[2] and {
      repo_key = spec[2], is_linked_worktree = spec[3],
    } or nil }
  for _, number in ipairs({ 9, 2 }) do
    local tab_id, pane_id = id .. ":t" .. number, id .. ":p" .. number
    tabs[#tabs + 1] = { tab_id = tab_id, workspace_id = id, label = "match " .. number, pane_count = 1 }
    panes[#panes + 1] = { pane_id = pane_id, cwd = "/" .. id }
    layouts[#layouts + 1] = { tab_id = tab_id, focused_pane_id = pane_id }
  end
end
local expected_spaces = { "a-parent", "a-child1", "a-child2", "standalone",
  "b-parent", "b-child", "orphan1", "plain", "orphan2" }
local expected_tabs = {}
for _, id in ipairs(expected_spaces) do
  expected_tabs[#expected_tabs + 1] = id .. ":t9"
  expected_tabs[#expected_tabs + 1] = id .. ":t2"
end
equal(ids(core.candidates("workspaces", "all")), expected_spaces)
equal(ids(core.candidates("tabs", "all")), expected_tabs)
for _, mode in ipairs({ { "workspaces", "all" }, { "tabs", "all" } }) do
  for _, row in ipairs(core.candidates(table.unpack(mode))) do
    local id = row:match("^([^\t]+)")
    local child = id:match("^a%-child") or id:match("^b%-child")
    assert((row:find("└─ ", 1, true) ~= nil) == (child ~= nil), row)
    if child then
      assert(row:find("\27[38;2;82;79;103m└─ \27[0m", 1, true), row)
      assert(plain(row):find(" [" .. id:sub(1, 1) .. "-parent match]", 1, true), row)
      assert(row:find("\27[38;2;82;79;103m[" .. id:sub(1, 1) .. "-parent match]\27[0m", 1, true), row)
    else
      assert(not row:find("-parent match]", 1, true), row)
    end
  end
end
local previous_agents = agents
agents = {
  { pane_id = "a-child1:p9", tab_id = "a-child1:t9", workspace_id = "a-child1" },
  { pane_id = "orphan1:p9", tab_id = "orphan1:t9", workspace_id = "orphan1" },
}
local saved_worktree_panes = panes
panes = { { pane_id = "a-child1:p9", label = "review" } }
local named_agents = core.candidates("agents", "all")
panes = saved_worktree_panes
assert(plain(named_agents[1]):find("a-child1 match [a-parent match]", 1, true))
assert(named_agents[1]:find("\27[38;2;82;79;103m[a-parent match]\27[0m", 1, true))
assert(named_agents[1]:find("a-child1:p9 \27[38;2;82;79;103m[review]\27[0m", 1, true))
assert(plain(named_agents[2]):match("  ·  orphan1:p9$"))
assert(not named_agents[1]:find("└─ ", 1, true))
assert(not named_agents[2]:find("└─ ", 1, true))
assert(not named_agents[2]:find("-parent match]", 1, true))
-- Parent annotations align within each repository, including unequal Unicode
-- names and metadata that is normalized to a single line before measuring.
local saved_child_label = workspaces[6].label
workspaces[6].label = "longer-worktree-é\nbranch"
agents[#agents + 1] = { pane_id = "a-child2:p9", tab_id = "a-child2:t9", workspace_id = "a-child2" }
for _, mode in ipairs({ { "workspaces", "all" }, { "tabs", "all" }, { "agents", "all" } }) do
  local annotation_column, count = nil, 0
  for _, row in ipairs(core.candidates(table.unpack(mode))) do
    local display = plain(row):match("^[^\t]+\t[^\t]+\t(.*)$")
    local start = display:find("[a-parent match]", 1, true)
    if start then
      local column = utf8.len(display:sub(1, start - 1))
      if annotation_column then equal(column, annotation_column) else annotation_column = column end
      count = count + 1
    end
    if mode[1] ~= "agents" and display:find("b-child", 1, true) then
      assert(display:find("b-child match [b-parent match]", 1, true))
    end
  end
  assert(count >= 2)
end
workspaces[6].label = saved_child_label
agents = previous_agents
equal(workspaces[1].workspace_id, "a-child1") -- Do not mutate the snapshot.
uv.os_setenv("HERDR_ACTIVE_WORKSPACE_ID", "a-parent")
equal(ids(core.candidates("tabs", "current")), { "a-parent:t9", "a-parent:t2" })
uv.os_setenv("HERDR_ACTIVE_WORKSPACE_ID", "w1")
for _, kind in ipairs({ "workspaces", "tabs" }) do
  local rows = core.candidates(kind, "all")
  local expected = kind == "workspaces" and expected_spaces or expected_tabs
  for _, row in ipairs(rows) do
    local id, preview = row:match("^([^\t]+)\t([^\t]+)\t")
    equal(preview, kind == "workspaces" and id .. ":p2" or id:gsub(":t", ":p"))
  end
  runtime.run = function(command, args, input, env)
    args[#args + 1] = "--filter=match"
    local code, output, errors, signal = original_run(command, args, input, env, 5000)
    local filtered = {}
    for row in output:gmatch("[^\n]+") do filtered[#filtered + 1] = row end
    equal(ids(filtered), expected)
    return code, "\n" .. filtered[1] .. "\n", errors, signal
  end
  focus_calls = {}
  core.pick(kind, "all")
  equal(focus_calls, { { kind == "workspaces" and "workspace" or "tab", expected[1] } })
end
-- Filtering can show a matching worktree without its nonmatching parent.
local grouped_rows = core.candidates("workspaces", "all")
local code, output = original_run("fzf", { "--ansi", "--no-sort", "--delimiter=\t",
  "--with-nth=3..", "--exact", "--filter=a-child" }, table.concat(grouped_rows, "\n"), runtime.fzf_env(), 5000)
assert(code == 0)
local filtered = {}
for row in output:gmatch("[^\n]+") do filtered[#filtered + 1] = row end
equal(ids(filtered), { "a-child1", "a-child2" })
workspaces, tabs, panes, layouts = saved_workspaces, saved_tabs, saved_panes, saved_layouts
print("Worktree grouping: parent-first, multiple projects, orphans, tab order, search and previews OK")

-- Spaces/tabs use the server's aggregate even when agent fixtures disagree,
-- and never sort by that status. Paths use remembered tab focus, not list order.
local space_rows, tab_rows = core.candidates("workspaces", "all"), core.candidates("tabs", "all")
equal(ids(space_rows), { "w1", "w2" })
equal(ids(tab_rows), { "w1:t1", "w1:t2", "w2:t1" })
assert(space_rows[1]:find("\27[38;2;49;116;143m○", 1, true))
assert(tab_rows[2]:find("\27[38;2;156;207;216m●", 1, true))
assert(plain(space_rows[1]):match("/active%-tab$"))
assert(plain(tab_rows[1]):match("~/Projects/é$"))
assert(plain(space_rows[2]):match("—$"))

local saved_cwd = panes[2].foreground_cwd
for _, spec in ipairs({
    { home, "~" }, { home .. "-other/project", home .. "-other/project" },
    { "/a\nb\t", "/a b " },
    { "/" .. string.rep("é", 48), "…" .. string.rep("é", 47) },
    { string.rep("x", 48), string.rep("x", 48) },
  }) do
  panes[2].foreground_cwd = spec[1]
  local row = plain(core.candidates("tabs", "all")[1])
  assert(row:sub(-#spec[2]) == spec[2], row)
end
panes[2].foreground_cwd = saved_cwd
local saved_focus = layouts[1].focused_pane_id
layouts[1].focused_pane_id = "missing"
assert(plain(core.candidates("tabs", "all")[1]):match("—$"))
equal(preview_ids("tabs", "current"), { "-", "w1:p3" })
layouts[1].focused_pane_id = saved_focus

-- Every status uses the same exact color/glyph for workspace and tab rows.
local saved_ws_status, saved_tab_status = workspaces[1].agent_status, tabs[1].agent_status
for _, spec in ipairs({
    { "blocked", "235;111;146", "●" }, { "done", "156;207;216", "●" },
    { "working", "246;193;119", "●" }, { "idle", "49;116;143", "○" },
    { "unknown", "110;106;134", "·" }, { false, "110;106;134", "·" },
  }) do
  workspaces[1].agent_status, tabs[1].agent_status = spec[1], spec[1]
  for _, mode in ipairs({ { "tabs", "all" }, { "tabs", "current" }, { "workspaces", "all" } }) do
    local rows = core.candidates(table.unpack(mode))
    assert(rows[1]:find("\t\27[38;2;" .. spec[2] .. "m" .. spec[3] .. "\27[0m ", 1, true))
    local expected_id = mode[1] == "tabs" and "w1:t1" or "w1"
    assert(ids(rows)[1] == expected_id)
  end
end
workspaces[1].agent_status, tabs[1].agent_status = saved_ws_status, saved_tab_status

-- Real fzf must strip ANSI and accept directory matches in each new variant.
for _, mode in ipairs({ { "tabs", "all" }, { "tabs", "current" }, { "workspaces", "all" } }) do
  runtime.run = function(command, args, input, env)
    args[#args + 1] = "--filter=/active-tab"
    local code, output, errors, signal = original_run(command, args, input, env, 5000)
    -- Filter mode omits the interactive --expect key line.
    return code, "\n" .. output, errors, signal
  end
  focus_calls = {}
  core.pick(table.unpack(mode))
  equal(focus_calls, { { mode[1] == "tabs" and "tab" or "workspace",
    mode[1] == "tabs" and "w1:t2" or "w1" } })
end
print("Spaces/tabs: aggregate indicators, unchanged order, focused directories and truncation OK")

local all_rows = core.candidates("agents", "all")
equal(ids(all_rows), { "w2:p6", "w1:p7", "w1:p5", "w1:p4", "w1:p3",
  "w1:p2", "w1:p10", "w1:p1", "w1:p8", "w1:p9" })
equal(ids(core.candidates("agents", "current")), { "w1:p7", "w1:p5", "w1:p4",
  "w1:p3", "w1:p2", "w1:p10", "w1:p1", "w1:p8", "w1:p9" })
for _, row in ipairs(all_rows) do
  assert(row:match("\t\27%[38;2;[%d;]+m[^\27]+\27%[0m "))
end
assert(plain(all_rows[1]):match("\t● "))
assert(plain(all_rows[6]):match("\t○ "))
assert(plain(all_rows[8]):match("\t· "))

-- Exercise the actual picker flags with real fzf filtering and ANSI output.
runtime.run = function(command, args, input, env)
  args[#args + 1] = "--filter=match"
  local code, output, errors, signal = original_run(command, args, input, env, 5000)
  local filtered = {}
  for row in output:gmatch("[^\n]+") do filtered[#filtered + 1] = row end
  equal(ids(filtered), ids(all_rows))
  assert(not output:find("\27", 1, true))
  return code, "\n" .. filtered[1] .. "\n", errors, signal
end
focus_calls = {}
core.pick("agents", "all")
equal(focus_calls, { { "pane", "w2:p6" } })
print("Agents: priority, recency, stable ties, status dots and fixed fuzzy-filter order OK")

-- All 25 source/destination pairs must stay in the popup until an actual
-- selection, with fresh rows and the destination's scope/sort/preview options.
local variants = {
  { "ctrl-r", "tabs", "current" }, { "ctrl-t", "tabs", "all" },
  { "ctrl-s", "workspaces", "all" }, { "ctrl-a", "agents", "current" },
  { "ctrl-g", "agents", "all" },
}
for _, source in ipairs(variants) do
  for _, destination in ipairs(variants) do
    local runs = 0
    local target_rows, target_header = core.candidates(destination[2], destination[3])
    focus_calls = {}
    runtime.run = function(_, args, input)
      runs = runs + 1
      if runs == 1 then return 0, destination[1] .. "\n" .. plain(input:match("^[^\n]+\n([^\n]+)")) .. "\n", "", 0 end
      assert(runs == 2)
      equal(focus_calls, {})
      equal(input, target_header .. "\n" .. table.concat(target_rows, "\n"))
      local flags = {}
      for _, flag in ipairs(args) do flags[flag] = true end
      assert((flags["--no-sort"] == true) == (destination[2] ~= "tabs" or destination[3] == "all"))
      assert(flags["--preview=" .. runtime.preview_command()])
      return 0, "\n" .. plain(target_rows[1]) .. "\n", "", 0
    end
    core.pick(source[2], source[3])
    assert(runs == 2)
    equal(focus_calls, { { destination[2] == "agents" and "pane" or
      (destination[2] == "tabs" and "tab" or "workspace"), ids(target_rows)[1] } })
  end
end

local saved_agents = agents
agents = {}
local runs = 0
focus_calls = {}
runtime.run = function(_, _, input)
  runs = runs + 1
  if runs == 1 then
    assert(input:match("^@header\t%-\t[^\n]+\n$"))
    return 1, "ctrl-s\n", "", 0
  end
  assert(runs == 2 and input ~= "")
  return 130, "", "", 0
end
core.pick("agents", "current")
equal(focus_calls, {})
agents = saved_agents
print("Picker switching: all 25 routes, empty results, cancellation and destination options OK")

-- Preview reads the visible ANSI screen only, and reports failures without
-- invoking focus or waiting for keyboard input in the preview subprocess.
local calls = {}
local screen = "\27[31mvisible screen\27[0m"
local full_path = "/" .. string.rep("long-directory/", 8)
runtime.herdr = function(...)
  local args = { ... }
  calls[#calls + 1] = args
  equal(args, { "pane", "get", "w1:p2" })
  return { pane = { cwd = "/shell", foreground_cwd = full_path } }
end
runtime.run = function(command, args, input, env, timeout)
  assert(command == (os.getenv("HERDR_BIN_PATH") or "herdr") and timeout == 10000)
  calls[#calls + 1] = args
  return 0, screen, "", 0
end
equal(core.preview("w1:p2"), "w1:p2\n" .. full_path .. "\n\n" .. screen .. "\27[0m\n")
equal(calls, { { "pane", "get", "w1:p2" },
  { "pane", "read", "w1:p2", "--source", "visible", "--ansi", "--raw" } })
screen = ""
assert(core.preview("w1:p2"):find("(Empty screen)", 1, true))
runtime.herdr = function() error("pane closed") end
assert(core.preview("w1:p2"):match("^Preview unavailable:"))
equal(core.preview("-"), "No pane available for preview.\n")
runtime.herdr = function() return { pane = {} } end
runtime.run = function() return 1, "", "pane disappeared after get", 0 end
assert(core.preview("w1:p2"):match("^Preview unavailable:"))
print("Preview: target mapping, visible ANSI content, full path, empty and closed panes OK")
runtime.herdr, runtime.run, runtime.focus_agent_pane = original_herdr, original_run, original_focus
if original_current then uv.os_setenv("HERDR_ACTIVE_WORKSPACE_ID", original_current)
else uv.os_unsetenv("HERDR_ACTIVE_WORKSPACE_ID") end
print("All five variants: alignment, scoping, missing metadata, selection and cancellation OK")

do
  local rows = { "one\tpreview\told label", "two\tpreview\tsecond" }
  local session = core.new_session(rows, "@header\t-\theader")
  equal(session.state, "ready")
  equal(session:accept(rows[1]), "one")
  local generation = session:begin_refresh("one")
  equal(session.state, "loading")
  assert(not session:accept(rows[1]))
  assert(not session:begin_refresh("two"))
  equal(session.saved_id, "one")
  assert(session:fail(generation))
  equal(session.state, "error")
  assert(not session:accept(rows[1]))
  local retry = session:begin_refresh(nil)
  equal(session.saved_id, "one")
  assert(not session:publish(generation, rows, "old header"))
  assert(session:publish(retry, { "two\tnew-preview\tsecond", "one\tnew-preview\tnew label" }, "new header"))
  equal(session:accept("one\tnew-preview\tnew label"), "one")
  for _, invalid in ipairs({ "@header\t-\theader", "unknown\t-\tlabel", "one", "one\tx\ty\nz", "one\tx\ty\tz" }) do
    assert(not session:accept(invalid))
  end
  local pending = session:begin_refresh("one")
  session:close()
  equal(session.state, "closed")
  assert(not session:publish(pending, rows, "late header"))
  assert(not session:fail(pending))
  assert(not session:begin_refresh("one"))
  assert(not session:accept(rows[1]))
end
print("Refresh session: transitions, retry identity, generation guards and acceptance OK")

do
  local saved_picker, saved_candidates = runtime.run_picker, core.candidates
  local saved_current, saved_snapshot = runtime.current_workspace, core.snapshot_candidates
  local origin = "original-space"
  runtime.current_workspace = function() return origin end
  core.candidates = function() return { "one\tpreview\told label" }, "@header\t-\theader" end
  core.snapshot_candidates = function(snapshot, kind, scope, current)
    equal(current, "original-space")
    equal(snapshot, { fresh = true })
    assert(scope == "current" and (kind == "tabs" or kind == "agents"))
    return { "one\tnew-preview\tnew label" }, "@header\t-\tnew header"
  end
  runtime.run_picker = function(_, _, _, _, session, render)
    origin = "changed-space"
    local generation = session:begin_refresh("one")
    local rows, header = render({ fresh = true })
    assert(session:publish(generation, rows, header))
    equal(session:accept(rows[1]), "one")
    session:close()
    return 130, "", "", 0
  end
  for _, kind in ipairs({ "tabs", "agents" }) do
    origin = "original-space"
    core.pick(kind, "current")
  end
  runtime.run_picker, core.candidates = saved_picker, saved_candidates
  runtime.current_workspace, core.snapshot_candidates = saved_current, saved_snapshot
end
print("Refresh scope: captured original workspace survives ambient context changes OK")

for _, scenario in ipairs({ "success", "timeout", "cancel", "launch" }) do
  local calls, failure, output = 0, nil, nil
  local started = uv.hrtime()
  local job = runtime.spawn(scenario == "launch" and "pickr-nonexistent" or assert(uv.exepath()),
    { "-e", "require('luv').sleep(" .. (scenario == "success" and "20" or "1000") .. "); io.write('complete')" },
    nil, nil, scenario == "timeout" and 10 or 2000,
    function(err, code, data)
      calls, failure, output = calls + 1, err, data
      if scenario == "success" then assert(code == 0) end
    end)
  if scenario == "cancel" then job:cancel() end
  uv.run()
  equal(calls, 1)
  if scenario == "success" then assert(not failure); equal(output, "complete")
  else assert(failure); assert((uv.hrtime() - started) / 1e6 < 900) end
  job:cancel()
  uv.run()
  equal(calls, 1)
  assert(not uv.loop_alive(), "Asynchronous subprocess leaked resources")
end
print("Async subprocesses: delayed success, timeout, cancellation, launch failure and cleanup OK")

local code, output, errors = runtime.run("fzf", { "--filter=alpha", "--delimiter=\t", "--with-nth=2.." },
  "id1\talpha\nid2\tbeta", runtime.fzf_env(), 5000)
assert(code == 0, errors)
equal(output, "id1\talpha\n")
assert(not pcall(runtime.run, "herdr-picker-nonexistent-command", {}))
assert(not pcall(runtime.run, "sleep", { "1" }, nil, nil, 10))
print("Real subprocesses: fzf ID round-trip, launch failure and timeout OK")

local preview_command = runtime.preview_command():gsub("{2}", "'-'")
local preview_code, preview_output, preview_errors = runtime.run("/bin/sh",
  { "-c", preview_command }, nil, nil, 5000)
assert(preview_code == 0, preview_errors)
equal(preview_output, "No pane available for preview.\n")
print("Preview subprocess: quoted absolute interpreter/script command and entry point OK")

-- Local fake server exercises actual luv socket framing, including split replies.
-- Unix socket paths have a small platform limit, independent of checkout length.
local socket_directory = assert(uv.fs_mkdtemp("/tmp/pickr-test-XXXXXX"))
local path = socket_directory .. "/focus.sock"
local original_socket = os.getenv("HERDR_SOCKET_PATH")
uv.os_setenv("HERDR_SOCKET_PATH", path)
for _, scenario in ipairs({ "success", "error", "wrong-pane", "eof" }) do
  local server = uv.new_pipe(false)
  assert(server:bind(path))
  server:listen(1, function(err)
    assert(not err, err)
    local peer, buffer = uv.new_pipe(false), ""
    assert(server:accept(peer))
    peer:read_start(function(read_error, data)
      assert(not read_error, read_error)
      if not data then return end
      buffer = buffer .. data
      if not buffer:find("\n", 1, true) then return end
      peer:read_stop()
      local request = json.decode(buffer)
      assert(request.method == "pane.focus" and request.params.pane_id == "opaque-id")
      local response = scenario == "error" and { error = { message = "pane missing" } } or
        { result = { pane = { pane_id = scenario == "wrong-pane" and "wrong" or "opaque-id" } } }
      server:close()
      if scenario == "eof" then peer:close(); return end
      local encoded = json.encode(response) .. "\n"
      peer:write(encoded:sub(1, 5), function()
        peer:write(encoded:sub(6), function() peer:close() end)
      end)
    end)
  end)
  local ok = pcall(runtime.focus_agent_pane, "opaque-id")
  -- Closing the server may already have removed the socket path.
  uv.fs_unlink(path)
  assert(ok == (scenario == "success"), scenario)
end
assert(uv.fs_rmdir(socket_directory))
if original_socket then uv.os_setenv("HERDR_SOCKET_PATH", original_socket)
else uv.os_unsetenv("HERDR_SOCKET_PATH") end
print("pane.focus socket: split responses, server errors, wrong pane and EOF OK")
runtime.run_picker = original_run_picker
