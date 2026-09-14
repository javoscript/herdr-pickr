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
runtime.origin = function() return { workspace_id = "fixture-origin", tab_id = "fixture-tab" } end
local visits = {}
core.candidates = function(kind, scope)
  print("OPEN " .. kind .. " " .. tostring(scope)); io.stdout:flush()
  local view = kind
  visits[view] = (visits[view] or 0) + 1
  if arg[5]:match("^memory") and visits[view] > 1 then
    if arg[5] == "memory-empty" then return {}, "@header\t-\theader" end
    local rows = { "fixture-third\tcurrent-third\tthird label", "fixture-id\tcurrent-id\tfixture label" }
    if arg[5] ~= "memory-deleted" then
      rows[#rows + 1] = "fixture-next\tcurrent-next\t" .. (arg[5] == "memory-filtered" and "unmatched" or "renamed label")
    end
    return rows, "@header\t-\theader"
  end
  if arg[5]:match("^layout") then
    local rows = {}
    for i = 1, 40 do rows[i] = "id" .. i .. "\t-\tROW" .. string.format("%02d", i) end
    return rows, "@header\t-\theader"
  end
  return { "fixture-id\t-\tfixture label", "fixture-next\t-\tsecond label" }, "@header\t-\theader"
end
if arg[5]:match("^memory") then
  runtime.preview_command = function() return "printf 'PREVIEW_%s' {2}" end
end
if arg[5] == "memory-loading" or arg[5] == "memory-late" or arg[5] == "memory-error"
  or arg[5] == "memory-retry" then
  local fetches = 0
  runtime.snapshot_async = function(callback)
    fetches = fetches + 1
    print("FETCH " .. fetches); io.stdout:flush()
    local n, timer, cancelled = fetches, uv.new_timer(), false
    local loading = arg[5] == "memory-loading" or arg[5] == "memory-late"
    timer:start(loading and 3000 or 70, 0, function()
      timer:close()
      if cancelled then print("LATE CALLBACK"); io.stdout:flush() end
      if not loading and n == 1 then callback("fixture failure") else callback(nil, {}) end
    end)
    return { cancel = function()
      cancelled = true
      print("CANCELLED"); io.stdout:flush()
      if arg[5] == "memory-late" then timer:unref()
      elseif not timer:is_closing() then timer:stop(); timer:close() end
    end }
  end
  core.snapshot_candidates = function()
    print("RENDER REFRESH"); io.stdout:flush()
    return { "fixture-third\tcurrent-third\tthird label", "fixture-id\tcurrent-id\tfixture label",
      "fixture-next\tcurrent-next\trenamed label" }, "@header\t-\theader"
  end
end
-- Hold entry match completion on the second visit to exercise the pending
-- state deterministically while real fzf continues processing editing/keys.
if arg[5] == "memory-pending" then
  local spawn, entries = runtime.spawn, 0
  runtime.spawn = function(command, args, ...)
    if command == "fzf" then
      entries = entries + 1
      if entries == 3 then
        for i, option in ipairs(args) do
          if option:match("^%-%-bind=load:") then args[i] = option:gsub(",result%-final:.*$", ",result-final:ignore") end
        end
      end
    end
    return spawn(command, args, ...)
  end
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
      workspaces = { { workspace_id = "fixture-origin", active_tab_id = "fixture-id", tab_count = 2 } },
      panes = {}, layouts = {}, agents = empty and {} or {
        { pane_id = "fixture-id", workspace_id = "fixture-origin", tab_id = "fixture-id", agent_status = "working" },
        { pane_id = "fixture-next", workspace_id = "fixture-origin", tab_id = "fixture-next", agent_status = "blocked" },
      },
      tabs = empty and {} or {
        { tab_id = "fixture-id", workspace_id = "fixture-origin", label = "alpha", pane_count = 1, agent_status = "working" },
        { tab_id = "fixture-next", workspace_id = "fixture-origin", label = "beta", pane_count = 1, agent_status = "blocked" },
      },
    }
  end
  core.candidates = function(kind, scope, settings)
    print("OPEN " .. kind .. " " .. tostring(scope)); io.stdout:flush()
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
if arg[5] == "layout-narrow" or arg[5] == "layout-resize" then
  local code = runtime.run("/bin/stty", { "-f", "/dev/tty", "cols", "55" }, nil, nil, 2000)
  assert(code == 0)
  if arg[5] == "layout-resize" then
    local timer = uv.new_timer()
    timer:start(1000, 0, function()
      timer:close()
      runtime.spawn("/bin/stty", { "-f", "/dev/tty", "cols", "220" }, nil, nil, 2000,
        function(err, code) assert(not err and code == 0) end)
    end)
  end
end
if arg[5] == "pane-columns" or arg[5] == "pane-move" then
  local render, moved = core.snapshot_candidates, false
  local function data(empty)
    local result = { workspaces = {
        { workspace_id = "fixture-origin", active_tab_id = "fixture-tab", tab_count = 1 },
        { workspace_id = "other", active_tab_id = "other-tab", tab_count = 1 } },
      tabs = { { tab_id = "fixture-tab", workspace_id = "fixture-origin", pane_count = 2 },
        { tab_id = "other-tab", workspace_id = "other", pane_count = 0 } },
      panes = {}, layouts = {}, agents = {} }
    if empty then return result end
    result.panes = {
      { pane_id = "fixture-id", workspace_id = "fixture-origin", tab_id = "fixture-tab",
        terminal_title = "alpha", cwd = "/first", label = "shared", agent_status = "working" },
      { pane_id = "fixture-next", workspace_id = moved and "other" or "fixture-origin",
        tab_id = moved and "other-tab" or "fixture-tab", terminal_title = "beta", cwd = "/second",
        label = "shared", agent_status = "blocked" } }
    result.layouts = {
      { workspace_id = "fixture-origin", tab_id = "fixture-tab", focused_pane_id = "fixture-id",
        panes = { { pane_id = "fixture-id" } } },
      { workspace_id = "other", tab_id = "other-tab", focused_pane_id = "fixture-next", panes = {} } }
    local members = result.layouts[moved and 2 or 1].panes
    members[#members + 1] = { pane_id = "fixture-next" }
    return result
  end
  core.candidates = function(kind, scope, settings, origin)
    print("OPEN " .. kind .. " " .. tostring(scope)); io.stdout:flush()
    return render(data(false), kind, scope, origin.workspace_id, settings, origin.tab_id)
  end
  runtime.preview_command = function() return "printf 'EXACT_%s' {2}" end
  local fetches = 0
  runtime.snapshot_async = function(callback)
    fetches = fetches + 1
    local n, timer = fetches, uv.new_timer()
    timer:start(70, 0, function()
      timer:close()
      if arg[5] == "pane-move" then moved = true; callback(nil, data(false))
      elseif n == 1 then callback("fixture failure") else callback(nil, data(n == 2)) end
    end)
    return { cancel = function() if not timer:is_closing() then timer:stop(); timer:close() end end }
  end
end
runtime.herdr = function(_, _, id) print("FOCUS " .. id) end
runtime.focus_pane = function(id) print("FOCUS " .. id) end
local settings = config.decode(arg[2])
settings.fzf_bindings = require("pickr.fzf_bindings").load()
local run_picker = runtime.run_picker
runtime.run_picker = function(...)
  local args, session = select(2, ...), select(5, ...)
  local query
  for _, option in ipairs(args) do query = option:match("^%-%-query=(.*)$") or query end
  print("ENTRY " .. require("pickr.vendor.json").encode({ query = query, id = session.entry_id,
    visible = session.popup.preview_visible })); io.stdout:flush()
  local code, result, errors, signal = run_picker(...)
  print("RESULT " .. require("pickr.vendor.json").encode(result)); io.stdout:flush()
  return code, result, errors, signal
end
core.pick(arg[3], arg[4], settings)
os.exit(0)
]=]

local function check(kind, scope, settings, keys, accepted, ambient, target, mode)
  local env = pty.environment({ FZF_DEFAULT_OPTS = ambient or "" })
  if mode and mode:match("^memory") then
    -- Each return starts a process and acknowledges matching through helpers.
    -- Give deliberate navigation/acceptance time to follow that handshake;
    -- memory-pending independently holds it unfinished to test rapid exits.
    local paced = {}
    for i, key in ipairs(keys) do
      paced[#paced + 1] = key
      if i < #keys then
        paced[#paced + 1] = ""
        if key == "\18" or key == "\19" or key == "\20" or key == "\27" .. "1"
          or key == "\27" .. "2" or key == "\27" .. "3" then
          paced[#paced + 1], paced[#paced + 2] = "", ""
        end
      end
    end
    keys = paced
  end
  local code, output, screen = pty.run({ assert(uv.exepath()), "-e", fixture, "--", "-",
    pty.source, next(settings) and json.encode(settings) or "{}", kind, scope, mode or "" }, env, keys, nil, 20000)
  assert(code == 0, output .. screen:sub(-1500))
  assert((output:find("FOCUS ", 1, true) ~= nil) == accepted, output)
  if accepted then assert(output:find("FOCUS " .. (target or "fixture-id"), 1, true), output) end
  return screen, output
end

local settings = { keys = { accept = { "alt-v", "alt-w" }, close = { "alt-x" } } }
local function results(output)
  local values = {}
  for line in output:gmatch("RESULT ([^\n]+)") do values[#values + 1] = json.decode(line) end
  return values
end
local function entries(output)
  local values = {}
  for line in output:gmatch("ENTRY ([^\n]+)") do values[#values + 1] = json.decode(line) end
  return values
end
if arg[1] ~= "memory" and arg[1] ~= "panes" then
do
  local defaults = { preview = { enabled_by_default = true } }
  local _, output = check("tabs", "space", defaults, { "\r" }, true)
  local result = results(output)[1]
  assert(result.query == "" and result.key == "" and result.target == "fixture-id")
  _, output = check("tabs", "space", defaults, { "nomatch", "\19", "\27" }, false)
  result = results(output)[1]
  assert(result.query == "nomatch" and result.key == "ctrl-s" and result.selected_id == nil)
end
for _, key in ipairs({ "refresh", "toggle_preview", "tabs", "spaces", "agents", "panes", "scope_all", "scope_space", "scope_tab" }) do
  settings.keys[key] = {}
end
for _, variant in ipairs({ { "tabs", "space" }, { "tabs", "all" }, { "spaces", "all" },
  { "agents", "tab" }, { "agents", "space" }, { "agents", "all" }, { "panes", "tab" }, { "panes", "space" }, { "panes", "all" } }) do
  local kind, scope = table.unpack(variant)
  for _, accept in ipairs({ "\27v", "\27w" }) do
    check(kind, scope, settings, { "\r", "\3", "\7", "\17", "\4", accept }, true)
  end
  check(kind, scope, settings, { "\27x" }, false)
  check(kind, scope, settings, { "z", "\27j", "\r", "\27v" }, true,
    "--bind 'enter:down,alt-j:backward-delete-char,alt-v:up,start:accept,alt-k:down+accept' "
      .. "--print-query --expect=enter --multi --preview='exit 1' --color=bg:red", "fixture-next")
end
local screen = check("tabs", "space", settings, { "\27b", "\27v" }, true, "--bind 'alt-b:preview-bottom'")
assert(screen:find("PREVIEW_BOTTOM", 1, true), "inherited preview scrolling did not reach the last line")
print("Real fzf: all nine effective type/scopes accept through both remapped aliases and close with all optional actions disabled; built-in lifecycle guards pass")
print("Real fzf: inherited navigation/editing, released Enter, owner precedence and ambient lifecycle/output isolation pass")
check("spaces", "all", {}, { "\3", "\26", "\24", "\r" }, true,
  "--bind 'ctrl-c:down,ctrl-z:down,ctrl-x:down'", "fixture-id")

local function no_hints(screen)
  for _, text in ipairs({ ": switch", ": close", ": preview", ": refresh", ": tabs", ": agents", ": panes", ": all panes", "no entries" }) do
    assert(not screen:find(text, 1, true), "hidden footer contained " .. text)
  end
end
local hidden = { popup = { show_hints = false } }
for _, variant in ipairs({ { "tabs", "space" }, { "tabs", "all" }, { "spaces", "all" },
  { "agents", "tab" }, { "agents", "space" }, { "agents", "all" }, { "panes", "tab" }, { "panes", "space" }, { "panes", "all" } }) do
  no_hints(check(variant[1], variant[2], hidden, { "\16", "\16", "\r" }, true))
  no_hints(check(variant[1], variant[2], hidden, { "z", "\19", "\27" }, false))
end
local lifecycle, output = check("tabs", "space", hidden,
  { "\12", "", "", "\12", "", "", "\12", "", "", "\r" }, true, nil, nil, "lifecycle")
no_hints(lifecycle)
assert(lifecycle:find("Refreshing", 1, true) and lifecycle:find("Refresh failed", 1, true)
  and lifecycle:find("to retry", 1, true), "hidden hints suppressed refresh status")
assert(output:find("PUBLISHED 0", 1, true) and output:find("PUBLISHED 1", 1, true), output)

-- A full list exposes reserved footer space: hiding the two hint rows and
-- their separator must make three additional candidate rows visible.
local function last_visible(show_hints)
  local screen = check("panes", "all", { popup = { show_hints = show_hints },
    preview = { enabled_by_default = false } }, { "\27" }, false, nil, nil, "layout")
  if not show_hints then no_hints(screen) end
  local last = 0
  for row in screen:gmatch("ROW(%d%d)") do last = math.max(last, tonumber(row)) end
  assert(last > 0, "layout fixture rendered no candidates")
  return last
end
local shown_rows, hidden_rows = last_visible(true), last_visible(false)
assert(hidden_rows == shown_rows + 3, "footer space was not reclaimed: " .. shown_rows .. " / " .. hidden_rows)
local narrow = check("panes", "tab", { preview = { enabled_by_default = false } },
  { "\27" }, false, nil, nil, "layout-narrow")
assert(not narrow:find(": agents", 1, true), "narrow footer should clip trailing type hints")
local resized = check("panes", "tab", { preview = { enabled_by_default = false } },
  { "", "", "", "", "\27" }, false, nil, nil, "layout-resize")
assert(resized:find(": agents", 1, true), "resizing should reveal the retained second-row hints")
print("Real fzf: hidden hints preserve actions, switching, refresh failure/retry and empty publication; all three footer rows reclaimed")

local column_settings = { columns = { tabs = { "tab" }, agents = { "status" } },
  preview = { enabled_by_default = false } }
-- A hidden status cannot match in the source. Switching must clear that query
-- on the first visit and search the destination's single status column instead.
check("tabs", "space", column_settings, { "blocked", "\r" }, false, nil, nil, "columns")
check("tabs", "space", column_settings, { "alpha", "\1", "", "", "blocked", "\r" }, true, nil, "fixture-next", "columns")
check("tabs", "space", column_settings, { "nomatch", "\1", "", "", "working", "\r" }, true, nil, "fixture-id", "columns")
-- Keep beta across failure, an empty retry and a successful refresh. If the
-- query is lost, Enter would select alpha instead of the second fixture row.
check("tabs", "space", column_settings,
  { "beta", "\12", "", "", "\12", "", "", "\12", "", "", "\r" }, true, nil, "fixture-next", "columns")
print("Real fzf columns: destination layouts, visible-only search, zero-match switches and query preservation through failure/empty retry/success OK")
end

if arg[1] == nil or arg[1] == "memory" then
local memory_settings = { preview = { enabled_by_default = true } }
do
  local screen, output = check("tabs", "all", memory_settings,
    { "label", "\27[B", "\19", "fixture", "\20", "", "", "", "", "\r" }, true, nil, "fixture-next", "memory-reorder")
  local exits = results(output)
  assert(exits[1].query == "label" and exits[1].selected_id == "fixture-next")
  assert(exits[2].query == "fixture" and exits[2].selected_id == "fixture-id")
  assert(exits[3].query == "label" and exits[3].target == "fixture-next")
  assert(screen:find("PREVIEW_current-next", 1, true), "restored preview did not use the fresh pane")
  -- Same-view entry, then later navigation and query edits must be authoritative.
  _, output = check("tabs", "all", memory_settings,
    { "label", "\27[B", "\20", "", "\27[A", "\20", "", "\r" }, true, nil, "fixture-id", "memory-reorder")
  exits = results(output)
  assert(exits[2].selected_id == "fixture-id" and exits[3].query == "label")
  _, output = check("tabs", "space", memory_settings,
    { "label", "\27[B", "\19", "\20", "", "\21fixture", "\19", "\20", "", "\r" }, true, nil, "fixture-id", "memory-reorder")
  exits = results(output)
  assert(exits[3].query == "fixture" and exits[3].selected_id == "fixture-id")
end
for _, mode in ipairs({ "memory-deleted", "memory-filtered", "memory-empty" }) do
  local _, output = check("tabs", "all", memory_settings,
    { "label", "\27[B", "\19", "\20", "", mode == "memory-empty" and "\19" or "\r",
      mode == "memory-empty" and "\27" or nil }, mode ~= "memory-empty", nil, "fixture-third", mode)
  local result = results(output)[3]
  assert(result.query == "label")
  assert(result.selected_id == (mode ~= "memory-empty" and "fixture-third" or nil))
end
do
  local _, output = check("tabs", "all", memory_settings,
    { "label", "\27[B", "\19", "\20", "\r", "\16", "\21renamed", "\19", "\20", "", "\r" },
    true, nil, "fixture-next", "memory-pending")
  local exits = results(output)
  assert(exits[3].query == "renamed" and exits[3].selected_id == "fixture-next" and not exits[3].target)
  assert(exits[5].target == "fixture-next" and exits[5].query == "renamed")
  check("tabs", "all", memory_settings,
    { "label", "\27[B", "\19", "\20", "\27" }, false, nil, nil, "memory-pending")
end
print("Real fzf memory: fresh identity/order/preview, deleted/filtered/empty fallback, one-shot navigation and pending entry switch/close OK")

for _, mode in ipairs({ "memory-loading", "memory-error" }) do
  for _, query in ipairs({ "renamed", "fixture", "nomatch" }) do
    local _, output = check("tabs", "all", memory_settings,
      { "label", "\27[B", "\12", "\21" .. query, "\16", "\r", "\19", "\20", "",
        query == "nomatch" and "\19" or "\r", query == "nomatch" and "\27" or nil },
      query ~= "nomatch", nil, query == "renamed" and "fixture-next" or "fixture-id", mode)
    local exits = results(output)
    assert(exits[1].query == query and exits[1].selected_id == "fixture-next" and not exits[1].target)
    assert(exits[3].query == query)
    assert(exits[3].selected_id == (query == "renamed" and "fixture-next" or query == "fixture" and "fixture-id" or nil))
    if mode == "memory-loading" then assert(output:find("CANCELLED", 1, true), output) end
  end
end
do
  local _, output = check("tabs", "all", memory_settings,
    { "label", "\27[B", "\12", "\12", "", "\27[A", "\19", "\20", "", "\r" },
    true, nil, "fixture-id", "memory-retry")
  assert(results(output)[1].selected_id == "fixture-id")
  -- A successful refresh with no matches must discard its recovery ID.
  _, output = check("tabs", "all", memory_settings,
    { "label", "\27[B", "\12", "\21nomatch", "\12", "", "\19", "\20", "", "\19", "\27" },
    false, nil, nil, "memory-retry")
  assert(results(output)[1].query == "nomatch" and not results(output)[1].selected_id)
  _, output = check("tabs", "all", memory_settings,
    { "label", "\27[B", "\12", "\21renamed", "\19", "", "", "", "", "\r" },
    true, nil, "fixture-id", "memory-late")
  assert(output:find("CANCELLED", 1, true) and output:find("LATE CALLBACK", 1, true), output)
  assert(not output:find("RENDER REFRESH", 1, true), output)
  check("tabs", "all", memory_settings, { "\12", "\27" }, false, nil, nil, "memory-loading")
end
print("Real fzf refresh memory: loading/failure edits, matched/filtered/empty recovery, latest retry selection, cancellation and ignored late completion OK")

do
  local literal = "  雪 ' \" $(printf PICKR_EVALUATED); | +change-query(x) {q} \\  "
  local _, output = check("tabs", "all", memory_settings,
    { "\27[200~" .. literal .. "\27[201~", "\19", "fixture", "\16", "\20", "\16", "\20", "\19", "\r" },
    true, nil, "fixture-id", "memory-reorder")
  local exits, launches = results(output), entries(output)
  assert(exits[1].query == literal and not exits[1].selected_id)
  assert(exits[3].query == literal and exits[4].query == literal and not exits[4].selected_id)
  assert(exits[5].query == "fixture" and exits[5].target == "fixture-id")
  assert(launches[2].query == nil and launches[2].id == nil)
  assert(launches[3].query == literal and launches[4].query == literal and launches[5].query == "fixture")
  assert(launches[1].visible and launches[2].visible and not launches[3].visible
    and launches[4].visible and launches[5].visible)
  -- Clear a ready zero-match query after returning: use ordinary first-match
  -- selection instead of resurrecting the ID saved before it became empty.
  _, output = check("tabs", "all", memory_settings,
    { "label", "\27[B", "\19", "\20", "", "\21nomatch", "\19", "\20", "\21", "\r" },
    true, nil, "fixture-third", "memory-reorder")
  exits, launches = results(output), entries(output)
  assert(not exits[3].selected_id and not launches[5].id and launches[5].query == "nomatch")
end
print("Real fzf lifecycle: literal whitespace/Unicode/quotes/metacharacters, independent and same-view queries, shared preview state and zero-match memory OK")
do
  local remapped = { keys = { accept = { "alt-v" }, close = { "alt-x" }, tabs = { "alt-t" }, spaces = { "alt-s" } } }
  check("tabs", "all", remapped,
    { "label", "\27[B", "\27s", "", "fixture", "\27t", "", "", "\r", "\27v" },
    true, nil, "fixture-next", "memory-reorder")
end
end

if arg[1] == nil or arg[1] == "panes" then
local pane_scopes = { { "tab", "\18" }, { "space", "\18" }, { "all", "\18" } }
for _, view in ipairs(pane_scopes) do
  local scope, back = table.unpack(view)
  local _, output = check("panes", scope, {},
    { "label", "\27[B", "\19", "fixture", back, "", "", "\r" }, true, nil, "fixture-next", "memory-reorder")
  local exits, launches = results(output), entries(output)
  assert(exits[1].query == "label" and exits[1].selected_id == "fixture-next")
  assert(exits[2].query == "fixture" and exits[3].target == "fixture-next")
  assert(not launches[2].query and launches[3].query == "label")
  _, output = check("panes", scope, {},
    { "label", "\27[B", back, "", "\27[A", back, "", "\r" }, true, nil, "fixture-id", "memory-reorder")
  assert(results(output)[2].selected_id == "fixture-id")
end
for index, mode in ipairs({ "memory-deleted", "memory-filtered", "memory-empty" }) do
  local scope, back = table.unpack(pane_scopes[index])
  local _, output = check("panes", scope, {},
    { "label", "\27[B", "\19", back, "", mode == "memory-empty" and "\19" or "\r",
      mode == "memory-empty" and "\27" or nil }, mode ~= "memory-empty", nil, "fixture-third", mode)
  local result = results(output)[3]
  assert(result.query == "label" and result.selected_id == (mode ~= "memory-empty" and "fixture-third" or nil))
end
for index, mode in ipairs({ "memory-loading", "memory-error" }) do
  local scope, back = table.unpack(pane_scopes[index])
  local _, output = check("panes", scope, {},
    { "label", "\27[B", "\12", "\21renamed", "\16", "\r", "\19", back, "", "\r" },
    true, nil, "fixture-next", mode)
  local exits, launches = results(output), entries(output)
  assert(exits[1].query == "renamed" and exits[1].selected_id == "fixture-next" and not exits[1].target)
  assert(exits[3].query == "renamed" and exits[3].target == "fixture-next")
  assert(not launches[2].visible and not launches[3].visible)
  if mode == "memory-loading" then assert(output:find("CANCELLED", 1, true)) end
end
do
  local _, output = check("panes", "all", {},
    { "label", "\27[B", "\12", "\12", "", "\27[A", "\19", "\18", "", "\r" },
    true, nil, "fixture-id", "memory-retry")
  assert(results(output)[1].selected_id == "fixture-id")
  _, output = check("panes", "all", {},
    { "label", "\27[B", "\12", "\21renamed", "\19", "", "", "", "", "\r" },
    true, nil, "fixture-id", "memory-late")
  assert(output:find("CANCELLED", 1, true) and output:find("LATE CALLBACK", 1, true))
  assert(not output:find("RENDER REFRESH", 1, true))
  _, output = check("panes", "tab", {}, { "\12", "\12", "\12", "\27" }, false, nil, nil, "memory-loading")
  local count = 0; for _ in output:gmatch("FETCH ") do count = count + 1 end
  assert(count == 1 and output:find("CANCELLED", 1, true))
  -- Switch during pending entry restoration retains the pane ID and edited query.
  _, output = check("panes", "tab", {},
    { "label", "\27[B", "\19", "\18", "\r", "\21renamed", "\19", "\18", "", "\r" },
    true, nil, "fixture-next", "memory-pending")
  local result = results(output)[3]
  assert(result.query == "renamed" and result.selected_id == "fixture-next" and not result.target)
end
print("Real fzf panes: three-scope round trips/self-switches, identity fallback, loading/failure query and preview retention, retry, cancellation and late-work rejection OK")

do
  local pane_settings = { columns = { panes = { "title" } },
    popup = { show_hints = false } }
  check("panes", "tab", pane_settings, { "fixture-next", "\r" }, false, nil, nil, "pane-columns")
  local screen = check("panes", "tab", pane_settings,
    { "beta", "\24", "", "", "\r" }, true, nil, "fixture-next", "pane-columns")
  assert(screen:find("EXACT_fixture-next", 1, true))
  check("panes", "space", pane_settings,
    { "nomatch", "\26", "", "", "\21beta", "\r" }, true, nil, "fixture-next", "pane-columns")
  screen = check("panes", "tab", pane_settings,
    { "beta", "\12", "", "", "\12", "", "", "\12", "", "", "\r" }, true, nil, "fixture-next", "pane-columns")
  assert(screen:find("Refresh failed", 1, true) and not screen:find(": panes", 1, true)
    and not screen:find("no entries", 1, true))
  local _, output = check("panes", "tab", {},
    { "beta", "\12", "", "", "\26", "", "", "\r" }, true, nil, "fixture-next", "pane-move")
  assert(not results(output)[1].selected_id and results(output)[1].query == "beta")
  local remapped = { keys = { accept = { "alt-v" }, scope_tab = { "alt-q" }, scope_all = { "alt-w" } } }
  check("panes", "tab", remapped,
    { "label", "\27[B", "\27w", "", "\27q", "", "", "\27v" },
    true, nil, "fixture-next", "memory-reorder")
end
print("Real fzf pane columns: visible-only search, destination layouts, exact previews, hidden-footer failure/retry, fresh moved membership and remapped round trips OK")
end
