local uv = require("luv")
local directory = assert(uv.fs_realpath(arg[0])):match("^(.*)/[^/]+$")
local pty = dofile(directory .. "/pty_runner.lua")
package.path = pty.source .. "/?.lua;" .. package.path
local json = require("pickr.vendor.json")
local fixture = [=[
package.path = arg[1] .. "/?.lua;" .. package.path
local core, runtime = require("pickr.core"), require("pickr.runtime")
local uv, json = require("luv"), require("pickr.vendor.json")
runtime.origin = function() return { workspace_id = "origin", tab_id = "tab-a" } end
runtime.preview_command = function() return "printf 'PREVIEW_%s' {2}" end
local rows = { "a\tpreview-a\talpha label", "b\tpreview-b\tbeta label" }
local mode, visits = arg[5], 0
local function candidates(kind, scope)
  visits = visits + 1
  if mode == "pending" and visits > 1 then rows[2] = "b\tcurrent-b\trenamed label" end
  print("OPEN " .. kind .. " " .. tostring(scope)); io.stdout:flush()
  return mode == "empty" and {} or scope == "tab" and { rows[2] } or rows, "@header\t-\ttitle"
end
core.candidates = candidates
core.snapshot_candidates = function(_, kind, scope)
  print("RENDER REFRESH"); io.stdout:flush()
  return candidates(kind, scope)
end
local fetches = 0
runtime.snapshot_async = function(callback)
  fetches = fetches + 1
  local n, timer, cancelled = fetches, uv.new_timer(), false
  print("FETCH " .. n); io.stdout:flush()
  timer:start((mode == "delayed" or mode == "late") and 3000 or 100, 0, function()
    timer:close()
    if cancelled then print("LATE CALLBACK"); io.stdout:flush() end
    if n == 1 then callback("fixture failure") else callback(nil, {}) end
  end)
  return { cancel = function()
    cancelled = true
    print("CANCELLED"); io.stdout:flush()
    if mode == "late" then timer:unref()
    elseif not timer:is_closing() then timer:stop(); timer:close() end
  end }
end
if mode == "pending" then
  local spawn, entries = runtime.spawn, 0
  runtime.spawn = function(command, args, ...)
    if command == "fzf" then
      entries = entries + 1
      if entries == 2 then
        for i, option in ipairs(args) do
          if option:match("^%-%-bind=load:") then args[i] = option:gsub(",result%-final:.*$", ",result-final:ignore") end
        end
      end
    end
    return spawn(command, args, ...)
  end
end
runtime.herdr = function(_, _, id) print("FOCUS " .. id) end
runtime.focus_pane = function(id) print("FOCUS " .. id) end
local run = runtime.run_picker
runtime.run_picker = function(...)
  local session = select(5, ...)
  print("STATE " .. json.encode({ kind = session.kind, chosen = session.popup.chosen_scope,
    entry = session.entry_id, visible = session.popup.preview_visible })); io.stdout:flush()
  local code, result, errors, signal = run(...)
  print("RESULT " .. json.encode(result)); io.stdout:flush()
  return code, result, errors, signal
end
core.pick(arg[2], arg[3], require("pickr.config").decode(arg[4]))
os.exit(0)
]=]
local function check(kind, scope, keys, settings, mode)
  local paced = {}
  for index, key in ipairs(keys) do
    paced[#paced + 1] = key
    if index < #keys then paced[#paced + 1], paced[#paced + 2] = "", "" end
  end
  local code, output, screen = pty.run({ uv.exepath(), "-e", fixture, "--", "-", pty.source,
    kind, scope, settings or "{}", mode or "" }, pty.environment(), paced, nil, 20000)
  assert(code == 0, output .. screen:sub(-2000))
  local states, results = {}, {}
  for line in output:gmatch("STATE ([^\n]+)") do states[#states + 1] = json.decode(line) end
  for line in output:gmatch("RESULT ([^\n]+)") do results[#results + 1] = json.decode(line) end
  return states, results, output, screen
end
local states, results, output, screen
if arg[1] ~= "layout" then
states, results, output, screen = check("panes", "tab", { "label", "\20", "\19", "\1", "\r" })
assert(#states == 4 and states[2].chosen == "tab" and states[3].chosen == "tab" and states[4].chosen == "tab")
assert(results[1].query == "label" and results[2].query == "" and results[3].query == "")
assert(output:find("FOCUS b", 1, true), output)
assert(screen:find("This tab remembered", 1, true), "Remembered scope text is not visible in the PTY output")
states, results, output = check("panes", "tab", { "\20", "label", "\24", "\24", "\1", "\r" })
assert(#states == 3 and states[3].chosen == "space", output)
assert(results[2].query == "label", output)
states, results, output = check("spaces", "all", { "\3", "\26", "\24", "\27" })
assert(#states == 1 and not output:find("FOCUS ", 1, true), output)
states, results, output = check("panes", "all", { "label", "\27[B", "\3", "\26", "\r" })
assert(#states == 3 and results[1].selected_id == "b" and results[2].query == "label"
  and results[3].target == "b", output)
states, results, output, screen = check("panes", "tab", { "\12", "\12", "\r" })
assert(output:find("FOCUS b", 1, true) and screen:find("Refresh failed", 1, true)
  and screen:find("All spaces", 1, true), output .. screen)
print("Unified real fzf: scope fallback/restoration, state-only scope choice, unavailable Ctrl+C/Z/X, query/identity scope round trip and refresh/retry OK")

-- A ready fallback becomes the shared type selection rather than reviving A.
states, results, output = check("panes", "all", { "label", "\3", "\26", "\r" })
assert(results[1].selected_id == "a" and results[2].selected_id == "b" and results[3].target == "b", output)
-- Ready zero-match scope transitions preserve literal queries without a stale ID.
states, results, output = check("panes", "all", { "nomatch", "\3", "\26", "\21", "\r" })
assert(results[1].query == "nomatch" and not results[1].selected_id and not states[3].entry
  and results[3].target == "a", output)
-- Header text is never a match or an acceptance target, even with an empty list.
for _, mode in ipairs({ "", "empty" }) do
  states, results, output, screen = check("tabs", "tab", { "remembered", "\r" },
    '{"popup":{"show_hints":false},"preview":{"enabled_by_default":false}}', mode)
  assert(not output:find("FOCUS ", 1, true) and screen:find("This tab remembered", 1, true), output)
  assert(not screen:find("ctrl+", 1, true), "Hidden key text leaked into scope row")
end
-- Already-chosen and unsupported scope keys do not restart or fetch.
states, results, output = check("tabs", "space", { "\24", "\3", "\24", "\27" })
assert(#states == 1 and not output:find("FETCH", 1, true), output)
local remapped = '{"keys":{"accept":["f1","alt-v"],"close":["alt-x"],"scope_all":["alt-z"],"scope_space":[],"scope_tab":["alt-c"]}}'
states, results, output = check("panes", "all", { "label", "\27[B", "\27c", "\27z", "\27v" }, remapped)
assert(#states == 3 and results[3].target == "b", output)
-- Rapid effective scope transitions while loading or failed retain recovery IDs.
for _, mode in ipairs({ "delayed", "error", "late" }) do
  states, results, output, screen = check("panes", "tab",
    { "label", "\12", "\21beta", "\16", "\r", "\26", "", "", "", "\r" }, nil, mode)
  assert(results[1].query == "beta" and results[1].selected_id == "b" and not results[1].target, output)
  assert(states[2].entry == "b" and not states[2].visible and results[2].target == "b", output)
  if mode ~= "error" then assert(output:find("CANCELLED", 1, true), output) end
  if mode == "late" then
    assert(output:find("LATE CALLBACK", 1, true) and not output:find("RENDER REFRESH", 1, true), output)
  end
end
states, results, output = check("panes", "all",
  { "label", "\27[B", "\3", "\r", "\16", "\21renamed", "\26", "\r" }, nil, "pending")
assert(results[2].selected_id == "b" and results[2].query == "renamed" and not results[2].target, output)
assert(states[3].entry == "b" and not states[3].visible and results[3].target == "b", output)
-- State-only fallback changes must preserve the loading generation and retry.
states, results, output, screen = check("tabs", "tab",
  { "beta", "\12", "\24", "\12", "\1", "\r" })
assert(#states == 2 and states[2].chosen == "space" and results[1].selected_id == "b", output)
assert(screen:find("Refresh failed", 1, true) and screen:find("This tab remembered", 1, true), output)
states, results, output, screen = check("panes", "tab", { "\12", "\12", "\r" },
  '{"keys":{"close":[")"],"scope_space":["(","]"]}}')
assert(results[1].target == "b" and screen:find("): close", 1, true), output)
states, results, output = check("tabs", "tab", { "beta", "\12", "\24", "\1", "\r" }, nil, "delayed")
assert(#states == 2 and states[2].chosen == "space" and results[1].selected_id == "b"
  and not results[1].target and output:find("CANCELLED", 1, true), output)
states, results, output = check("panes", "tab", { "\3" }, '{"keys":{"close":["ctrl-c"],"scope_tab":[]}}')
assert(#states == 1 and not output:find("FOCUS ", 1, true), output)
print("Unified real fzf: fallback replacement, zero matches, empty/hidden headers, remaps/no-ops and scope loading/error/restoration/late-result races OK")
end

-- Track only vertical cursor movement in this fixed 30-row, no-wrap fixture.
-- This verifies screen placement rather than the order of writes to the PTY.
local function screen_rows(screen)
  local row, index, found = 1, 1, {}
  local labels = { scope = "All spaces", remembered = "This tab remembered", heading = "title", candidate = "alpha label" }
  while index <= #screen do
    local byte = screen:sub(index, index)
    if byte == "\27" then
      local args, command, last = screen:match("^\27%[([%d;?]*)([@-~])()", index)
      if last then
        local amount = tonumber(args:match("^%d+")) or 1
        if command == "A" or command == "F" then row = math.max(1, row - amount)
        elseif command == "B" or command == "E" then row = math.min(30, row + amount)
        elseif command == "H" or command == "f" or command == "d" then row = amount end
        index = last
      else index = index + 2 end
    else
      for name, label in pairs(labels) do
        if screen:sub(index, index + #label - 1) == label then found[name] = row end
      end
      if byte == "\n" then row = math.min(30, row + 1) end
      index = index + 1
    end
  end
  return found
end
states, results, output, screen = check("tabs", "tab", { "\27" })
local placement = screen_rows(screen)
assert(placement.scope and placement.remembered and placement.heading and placement.candidate, json.encode(placement))
assert(placement.scope < placement.remembered and placement.remembered < placement.heading
  and placement.heading < placement.candidate, json.encode(placement))
print("Unified real fzf layout: scope, remembered choice, column heading and candidates appear in that screen order")
