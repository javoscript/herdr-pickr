-- Real-fzf keyboard acceptance with fixture candidates; never focuses Herdr panes.
local uv = require("luv")
local script = assert(uv.fs_realpath(arg[0]))
local directory = assert(script:match("^(.*)/[^/]+$"))
local pty = dofile(directory .. "/pty_runner.lua")
local json = require("pickr.vendor.json")
local fixture = [=[
package.path = arg[1] .. "/?.lua;" .. package.path
local core, runtime = require("pickr.core"), require("pickr.runtime")
local config = require("pickr.config")
local uv = require("luv")
runtime.preview_command = function()
  local lines = {}
  for i = 1, 99 do lines[#lines + 1] = "'line " .. i .. "'" end
  lines[#lines + 1] = "'PREVIEW_BOTTOM'"
  return "printf '%s\n' " .. table.concat(lines, " ")
end
runtime.current_workspace = function() return "fixture-origin" end
core.candidates = function(kind, scope)
  print("OPEN " .. kind .. " " .. scope); io.stdout:flush()
  if arg[5] == "layout" then
    local rows = {}
    for i = 1, 40 do rows[i] = "id" .. i .. "\t-\tROW" .. string.format("%02d", i) end
    return rows, "@header\t-\theader"
  end
  return { "fixture-id\t-\tfixture label", "fixture-next\t-\tsecond label" }, "@header\t-\theader"
end
if arg[5] == "lifecycle" then
  local fetches = 0
  runtime.snapshot_async = function(callback)
    fetches = fetches + 1
    local n, timer = fetches, uv.new_timer()
    timer:start(70, 0, function()
      timer:close()
      if n == 1 then callback("fixture failure") else callback(nil, { empty = n == 2 }) end
    end)
    return { cancel = function() if not timer:is_closing() then timer:stop(); timer:close() end end }
  end
  core.snapshot_candidates = function(snapshot)
    return snapshot.empty and {} or { "fixture-id\t-\trefreshed label" }, "@header\t-\theader"
  end
  local new_session = core.new_session
  core.new_session = function(...)
    local session = new_session(...)
    local publish = session.publish
    session.publish = function(self, generation, rows, header)
      print("PUBLISHED " .. #rows); io.stdout:flush()
      return publish(self, generation, rows, header)
    end
    return session
  end
end
if arg[5] == "columns" then
  local render = core.snapshot_candidates
  local function data(empty)
    return {
      workspaces = {}, panes = {}, layouts = {}, agents = {},
      tabs = empty and {} or {
        { tab_id = "fixture-id", workspace_id = "fixture-origin", label = "alpha", pane_count = 1, agent_status = "working" },
        { tab_id = "fixture-next", workspace_id = "fixture-origin", label = "beta", pane_count = 1, agent_status = "blocked" },
      },
    }
  end
  core.candidates = function(kind, scope, settings)
    print("OPEN " .. kind .. " " .. scope); io.stdout:flush()
    return render(data(false), kind, scope, "fixture-origin", settings)
  end
  local fetches = 0
  runtime.snapshot_async = function(callback)
    fetches = fetches + 1
    local n, timer = fetches, uv.new_timer()
    timer:start(70, 0, function()
      timer:close()
      if n == 1 then callback("fixture failure") else callback(nil, data(n == 2)) end
    end)
    return { cancel = function() if not timer:is_closing() then timer:stop(); timer:close() end end }
  end
end
runtime.herdr = function(_, _, id) print("FOCUS " .. id) end
runtime.focus_agent_pane = function(id) print("FOCUS " .. id) end
local settings = config.decode(arg[2])
settings.fzf_bindings = require("pickr.fzf_bindings").load()
core.pick(arg[3], arg[4], settings)
os.exit(0)
]=]

local function check(kind, scope, settings, keys, accepted, ambient, target, mode)
  local env = pty.environment({ FZF_DEFAULT_OPTS = ambient or "" })
  local code, output, screen = pty.run({ assert(uv.exepath()), "-e", fixture, "--", "-",
    pty.source, json.encode(settings), kind, scope, mode or "" }, env, keys)
  assert(code == 0, output .. screen:sub(-1500))
  assert((output:find("FOCUS ", 1, true) ~= nil) == accepted, output)
  if accepted then assert(output:find("FOCUS " .. (target or "fixture-id"), 1, true), output) end
  return screen, output
end

local settings = { keys = { accept = { "alt-v", "alt-w" }, close = { "alt-x" } } }
for _, key in ipairs({ "refresh", "toggle_preview", "tabs_current", "tabs_all", "spaces", "agents_current", "agents_all" }) do
  settings.keys[key] = {}
end
for _, variant in ipairs({ { "tabs", "current" }, { "tabs", "all" }, { "workspaces", "all" },
  { "agents", "current" }, { "agents", "all" } }) do
  local kind, scope = table.unpack(variant)
  for _, accept in ipairs({ "\27v", "\27w" }) do
    check(kind, scope, settings, { "\r", "\3", "\7", "\17", "\4", accept }, true)
  end
  check(kind, scope, settings, { "\27x" }, false)
  check(kind, scope, settings, { "z", "\27j", "\r", "\27v" }, true,
    "--bind 'enter:down,alt-j:backward-delete-char,alt-v:up,start:accept,alt-k:down+accept' "
      .. "--print-query --expect=enter --multi --preview='exit 1' --color=bg:red", "fixture-next")
end
local screen = check("tabs", "current", settings, { "\27b", "\27v" }, true, "--bind 'alt-b:preview-bottom'")
assert(screen:find("PREVIEW_BOTTOM", 1, true), "inherited preview scrolling did not reach the last line")
print("Real fzf: all five variants accept through both remapped aliases and close with all optional actions disabled; built-in lifecycle guards pass")
print("Real fzf: inherited navigation/editing, released Enter, owner precedence and ambient lifecycle/output isolation pass")

local function no_hints(screen)
  for _, text in ipairs({ ": switch", ": close", ": preview", ": refresh", ": tabs", ": agents", "no entries" }) do
    assert(not screen:find(text, 1, true), "hidden footer contained " .. text)
  end
end
local hidden = { popup = { show_hints = false } }
for _, variant in ipairs({ { "tabs", "current" }, { "tabs", "all" }, { "workspaces", "all" },
  { "agents", "current" }, { "agents", "all" } }) do
  no_hints(check(variant[1], variant[2], hidden, { "\16", "\16", "\r" }, true))
  no_hints(check(variant[1], variant[2], hidden, { "z", "\19", "\27" }, false))
end
local lifecycle, output = check("tabs", "current", hidden,
  { "\12", "", "", "\12", "", "", "\12", "", "", "\r" }, true, nil, nil, "lifecycle")
no_hints(lifecycle)
assert(lifecycle:find("Refreshing", 1, true) and lifecycle:find("Refresh failed", 1, true)
  and lifecycle:find("to retry", 1, true), "hidden hints suppressed refresh status")
assert(output:find("PUBLISHED 0", 1, true) and output:find("PUBLISHED 1", 1, true), output)

-- A full list exposes reserved footer space: hiding the two hint rows and
-- their separator must make three additional candidate rows visible.
local function last_visible(show_hints)
  local screen = check("tabs", "current", { popup = { show_hints = show_hints },
    preview = { enabled_by_default = false } }, { "\27" }, false, nil, nil, "layout")
  if not show_hints then no_hints(screen) end
  local last = 0
  for row in screen:gmatch("ROW(%d%d)") do last = math.max(last, tonumber(row)) end
  assert(last > 0, "layout fixture rendered no candidates")
  return last
end
local shown_rows, hidden_rows = last_visible(true), last_visible(false)
assert(hidden_rows == shown_rows + 3, "footer space was not reclaimed: " .. shown_rows .. " / " .. hidden_rows)
print("Real fzf: hidden hints preserve actions, switching, refresh failure/retry and empty publication; all three footer rows reclaimed")

local column_settings = { columns = { tabs_current = { "tab" }, tabs_all = { "status" } },
  preview = { enabled_by_default = false } }
-- A hidden status cannot match in the source. Switching must clear that query
-- and search the destination's single status column instead.
check("tabs", "current", column_settings, { "blocked", "\r" }, false, nil, nil, "columns")
check("tabs", "current", column_settings, { "alpha", "\20", "", "", "blocked", "\r" }, true, nil, "fixture-next", "columns")
check("tabs", "current", column_settings, { "nomatch", "\20", "", "", "working", "\r" }, true, nil, "fixture-id", "columns")
-- Keep beta across failure, an empty retry and a successful refresh. If the
-- query is lost, Enter would select alpha instead of the second fixture row.
check("tabs", "current", column_settings,
  { "beta", "\12", "", "", "\12", "", "", "\12", "", "", "\r" }, true, nil, "fixture-next", "columns")
print("Real fzf columns: destination layouts, visible-only search, zero-match switches and query preservation through failure/empty retry/success OK")
