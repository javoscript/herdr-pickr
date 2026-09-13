local uv = require("luv")
local root = assert(uv.fs_realpath(arg[0])):match("^(.*)/tests/[^/]+$")
package.path = root .. "/src/?.lua;" .. package.path
local core, runtime = require("pickr.core"), require("pickr.runtime")
local config, json, themes = require("pickr.config"), require("pickr.vendor.json"), require("pickr.themes")
local function equal(a, b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
local function plain(s) return (s:gsub("\27%[[%d;]*m", "")) end
local function ids(rows)
  local result = {}
  for _, row in ipairs(rows) do result[#result + 1] = row:match("^[^\t]+") end
  return table.concat(result, ",")
end
local snapshot = {
  workspaces = {
    { workspace_id = "child", label = "feature", active_tab_id = "C", tab_count = 1,
      worktree = { repo_key = "repo", is_linked_worktree = true } },
    { workspace_id = "parent", label = "project", active_tab_id = "A", tab_count = 2,
      worktree = { repo_key = "repo", is_linked_worktree = false } },
    { workspace_id = "other", label = "other", active_tab_id = "D", tab_count = 1 },
    { workspace_id = "orphan-tree", label = "orphan", active_tab_id = "E", tab_count = 1,
      worktree = { repo_key = "missing", is_linked_worktree = true } },
  },
  tabs = {
    { tab_id = "C", workspace_id = "child", label = "branch", pane_count = 1 },
    { tab_id = "B", workspace_id = "parent", label = "background", pane_count = 1 },
    { tab_id = "A", workspace_id = "parent", label = "origin", pane_count = 4 },
    { tab_id = "D", workspace_id = "other", label = "inactive", pane_count = 2 },
    { tab_id = "E", workspace_id = "orphan-tree", pane_count = 1 },
    { tab_id = "unknown-tab", workspace_id = "unknown-workspace", pane_count = 1 },
  },
  panes = {}, layouts = {}, agents = {},
}
local function pane(id, workspace, tab, title)
  local p = { pane_id = id, terminal_id = "terminal-" .. id, workspace_id = workspace,
    tab_id = tab, focused = id == "p1", agent_status = "unknown", revision = 1,
    terminal_title_stripped = title }
  snapshot.panes[#snapshot.panes + 1] = p
  return p
end
local p1 = pane("p1", "parent", "A", "shell 雪\nwatch\t")
p1.cwd, p1.foreground_cwd, p1.label = "/fallback", os.getenv("HOME") .. "/project", "shared\nlabel"
local p2 = pane("p2", "parent", "A", "")
p2.agent, p2.agent_status, p2.terminal_title, p2.label = "opencode", "blocked", "agent title", "shared\nlabel"
p2.foreground_cwd, p2.cwd = "", "/agent-cwd"
snapshot.agents[1] = p2
local p3 = pane("p3", "parent", "A", nil)
p3.title, p3.plugin_id = "embedded plugin", "example.plugin"
local p4 = pane("p4", "parent", "A", nil)
p4.label, p4.cwd = "", "/" .. string.rep("雪", 60)
pane("p5", "parent", "B", "background")
pane("p6", "child", "C", "child")
pane("p7", "other", "D", "duplicate title").label = "shared label"
pane("p9", "other", "D", "duplicate title").label = "shared label"
pane("p8", "orphan-tree", "E", "orphan worktree")
pane("popup", "parent", "A", "Pickr popup")
pane("orphan", "parent", "deleted", "detached metadata")
pane("mismatch", "other", "A", "wrong workspace")
pane("wrong-tab", "parent", "B", "wrong tab")
pane("unknown", "unknown-workspace", "unknown-tab", "unknown membership")
local function layout(workspace, tab, members, zoomed)
  local l = { workspace_id = workspace, tab_id = tab, focused_pane_id = members[1],
    zoomed = zoomed or false, area = { x = 0, y = 0, width = 100, height = 40 }, panes = {}, splits = {} }
  for index, id in ipairs(members) do
    l.panes[index] = { pane_id = id, focused = index == 1,
      rect = { x = index, y = 0, width = 10, height = 40 } }
  end
  snapshot.layouts[#snapshot.layouts + 1] = l
  return l
end
local origin_layout = layout("parent", "A", { "p1", "p2", "p3", "p4", "p1", "missing", "mismatch", "wrong-tab" }, true)
layout("parent", "B", { "p5" })
layout("child", "C", { "p6" })
layout("other", "D", { "p9", "p7" })
layout("orphan-tree", "E", { "p8" })
layout("parent", "deleted", { "orphan" })
layout("unknown-workspace", "unknown-tab", { "unknown" })
local function rows(scope, data, tab, workspace, settings)
  return core.snapshot_candidates(data or snapshot, "panes", scope, workspace or "parent", settings, tab)
end
equal(ids(rows("tab", nil, "A")), "p1,p2,p3,p4")
equal(ids(rows("current")), "p5,p1,p2,p3,p4")
equal(ids(rows("all")), "p5,p1,p2,p3,p4,p6,p9,p7,p8")
equal(#rows("tab"), 0)
equal(#rows("tab", nil, "D"), 0)
equal(#rows("tab", nil, "deleted"), 0)
equal(#rows("current", nil, nil, "deleted"), 0)
local original_status = p2.agent_status
p2.agent_status = "done"
equal(ids(rows("all")), "p5,p1,p2,p3,p4,p6,p9,p7,p8")
p2.agent_status = original_status
origin_layout.panes[2].rect = { x = 0, y = 0, width = 0, height = 0 }
equal(ids(rows("tab", nil, "A")), "p1,p2,p3,p4")
print("Pane membership: three scopes, grouped worktrees/tab/layout order, unique IDs, agent/plugin inclusion, popup/orphan/mismatch exclusion and zoom OK")

local settings = config.decode('{"theme":{"custom":{"annotation":"red"}}}')
local rendered, header = rows("tab", nil, "A", nil, settings)
assert(plain(header):find("pane [label]", 1, true))
assert(plain(rendered[1]):find("shell 雪 watch", 1, true))
assert(plain(rendered[1]):find("~/project", 1, true))
assert(rendered[1]:find(themes.ansi(settings.roles.annotation) .. "[shared label]", 1, true))
assert(plain(rendered[2]):find("agent title", 1, true) and plain(rendered[2]):find("/agent-cwd", 1, true))
assert(plain(rendered[3]):find("embedded plugin", 1, true))
assert(plain(rendered[4]):find("…" .. string.rep("雪", 47), 1, true))
for _, row in ipairs(rendered) do
  local id, preview, display = row:match("^([^\t]+)\t([^\t]+)\t(.*)$")
  equal(id, preview)
  assert(not display:find("[\n\r\t]"))
end
local single = config.decode('{"columns":{"panes_tab":["title"]}}')
equal(plain(rows("tab", nil, "A", nil, single)[4]), "p4\tp4\t-")
single = config.decode('{"columns":{"panes_tab":["pane"]}}')
equal(plain(rows("tab", nil, "A", nil, single)[4]), "p4\tp4\tp4")
single = config.decode('{"columns":{"panes_tab":["directory"]}}')
equal(plain(rows("tab", nil, "A", nil, single)[3]), "p3\tp3\t—")
assert(rows("all", nil, nil, nil, settings)[6]:find(themes.ansi(settings.roles.annotation) .. "[project]", 1, true))
print("Pane metadata: title/cwd fallbacks, unknown status, Unicode/control cleaning, truncation and annotation roles OK")

-- Exercise the owner with real candidate generation and fixture Herdr calls.
local env = { HERDR_PLUGIN_ID = "javoscript.herdr-pickr",
  HERDR_PLUGIN_CONTEXT_JSON = '{"workspace_id":"parent","tab_id":"A"}' }
local getenv = os.getenv
os.getenv = function(key) return env[key] or getenv(key) end
local snapshots, focus = 0, {}
runtime.herdr = function(kind, action, id)
  if kind == "api" then snapshots = snapshots + 1; return { snapshot = snapshot } end
  if action == "get" then
    for _, p in ipairs(snapshot.panes) do if p.pane_id == id then return { pane = p } end end
    error("pane closed")
  end
  error("unexpected focus: " .. kind)
end
runtime.read_visible = function(id) return "\27[31mscreen " .. id .. "\27[0m" end
runtime.socket_request = function(method, params)
  equal(method, "pane.focus"); focus[#focus + 1] = params.pane_id
  return { pane = { pane_id = params.pane_id } }
end
runtime.run_picker = function(_, _, _, _, session)
  local target
  for _, row in ipairs(session.rows) do if row:match("^p7\t") then target = row end end
  assert(core.preview("p7"):find("screen p7", 1, true))
  equal(#focus, 0)
  return 0, runtime.picker_result("\0\0" .. target .. "\0", session), "", 0
end
core.pick("panes", "all", settings)
equal(table.concat(focus), "p7")
assert(core.preview("closed"):find("Preview unavailable", 1, true))
for _, response in ipairs({ {}, { pane = { pane_id = "wrong" } } }) do
  runtime.socket_request = function() return response end
  assert(not pcall(runtime.focus_pane, "p2"))
end
runtime.socket_request = function() error("pane closed") end
assert(not pcall(runtime.focus_pane, "p2"))
runtime.focus_pane = function() error("must not focus during switch/refresh/close") end

for _, absent in ipairs({ false, true }) do
  env.PICKR_ORIGIN_WORKSPACE_ID, env.PICKR_ORIGIN_TAB_ID = "parent", absent and "" or "A"
  env.HERDR_PLUGIN_CONTEXT_JSON = '{"workspace_id":"other","tab_id":"D"}'
  local visits = 0
  runtime.run_picker = function(_, args, _, _, session, render)
    visits = visits + 1
    equal(session.popup.origin.workspace_id, "parent")
    equal(session.popup.origin.tab_id, not absent and "A" or nil)
    if visits == 1 then
      env.PICKR_ORIGIN_TAB_ID = "D" -- Changed ambient focus/handoff must not be recaptured.
      return 1, { key = "alt-1", query = "source" }, "", 0
    end
    equal(ids(session.rows), absent and "" or "p1,p2,p3,p4")
    assert(table.concat(args, "\n"):find("--border-label=Panes in this tab", 1, true))
    local fresh = json.decode(json.encode(snapshot))
    fresh.workspaces[2].active_tab_id = "B"
    equal(ids(render(fresh)), absent and "" or "p1,p2,p3,p4")
    table.remove(fresh.tabs, 3) -- Origin tab disappears; no rebinding to B.
    equal(#render(fresh), 0)
    table.remove(fresh.workspaces, 2)
    equal(#render(fresh), 0)
    return 130, {}, "", 0
  end
  core.pick("tabs", "all", settings)
  equal(visits, 2)
end
print("Pane origin/focus: immutable non-pane launch handoff, explicit absence, deleted origin, exact inactive split preview/focus and rejected targets OK")

-- Fresh scope membership after a move; pane/agent and pane-scope memories are
-- independent even when all four views highlight exactly the same pane ID.
env.PICKR_ORIGIN_TAB_ID = "A"
local sequence = { "panes_tab", "panes_current", "panes_all", "agents_current",
  "panes_tab", "panes_current", "panes_all", "agents_current", "panes_all" }
local keymap = require("pickr.keymap")
local visits, seen = 0, {}
runtime.run_picker = function(_, args, _, _, session, render)
  visits = visits + 1
  local variant = sequence[visits]
  local query
  for _, option in ipairs(args) do query = option:match("^%-%-query=(.*)$") or query end
  equal(query, seen[variant] and variant or nil)
  equal(session.entry_id, seen[variant] and "p2" or nil)
  local selected
  for _, row in ipairs(session.rows) do if row:match("^p2\t") then selected = row end end
  assert(selected)
  local generation = session:begin_refresh("p2")
  assert(session:fail(generation))
  equal(runtime.picker_result("edited\0alt-3\0", session).selected_id, "p2")
  generation = session:begin_refresh(nil)
  local fresh = json.decode(json.encode(snapshot))
  fresh.panes[2].tab_id = "B"
  fresh.layouts[2].panes[#fresh.layouts[2].panes + 1] = { pane_id = "p2" }
  local refreshed, heading = render(fresh)
  assert(session:publish(generation, refreshed, heading))
  if variant == "panes_tab" then
    assert(not ids(refreshed):find("p2", 1, true))
    assert(not session:accept(selected))
  elseif variant:match("^panes") then
    equal(ids(refreshed):sub(1, #"p5,p2"), "p5,p2")
  end
  generation = session:begin_refresh(nil)
  session:close()
  assert(not session:publish(generation, refreshed, heading))
  assert(not session:fail(generation))
  seen[variant] = true
  local next_view = sequence[visits + 1]
  return next_view and 1 or 130, { key = next_view and keymap.defaults[next_view][1] or "",
    query = variant, selected_id = "p2" }, "", 0
end
core.pick("panes", "tab", settings)
equal(visits, #sequence)
os.getenv = getenv
print("Pane lifecycle: independent scope/agent memory, fresh moves, retry identity, acceptance maps and rejection of late generations OK")
