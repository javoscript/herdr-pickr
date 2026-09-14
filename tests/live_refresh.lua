local uv = require("luv")
local directory = assert(uv.fs_realpath(arg[0])):match("^(.*)/[^/]+$")
local pty = dofile(directory .. "/pty_runner.lua")
package.path = pty.source .. "/?.lua;" .. package.path
local core, json = require("pickr.core"), require("pickr.vendor.json")

-- Data errors never invalidate the last display, including an empty display.
for _, rows in ipairs({ {}, { "a\tp\told row" } }) do
  local session = core.new_session(rows, "@header\t-\told")
  for _, bad in ipairs({ { "bad" }, { "a\tp\tduplicate", "a\tq\tduplicate" } }) do
    local generation = assert(session:begin_refresh())
    assert(not pcall(session.stage, session, generation, bad, "heading"))
    assert(session:fail(generation) and session.rows == rows and session.state == "ready")
    assert(session:accept(rows[1]) == (rows[1] and "a" or nil))
  end
  local g = assert(session:begin_refresh())
  assert(session:stage(g, { "b\tq\tnew row" }, "new"))
  assert(not session:begin_refresh())
  assert(session:accept("b\tq\tnew row") == "b")
  assert(not session:accept("b\tq\tforged"))
  assert(session:publish(g, { "b\tq\tnew row" }, "new"))
  if rows[1] then assert(session:accept(rows[1]) == "a") end
  session:close()
  assert(not session:accept("b\tq\tnew row"))
end

-- Preview ownership survives killed/detached helpers and coalesces by target.
do
  local jobs, notices, result = {}, 0, nil
  local preview = require("pickr.live_preview").new(function(target, callback)
    local job = { target = target, callback = callback }
    function job:cancel() self.cancelled = true end
    jobs[#jobs + 1] = job
    return job
  end, function() notices = notices + 1 end)
  local detach = preview:request("a", true, function(text) result = text end)
  for _ = 1, 10 do preview:refresh("a", true) end
  assert(#jobs == 1)
  detach() -- A killed fzf helper must not restart or permanently lock capture.
  preview:request("a", true, function(text) result = text end)
  jobs[1].callback("\27[31moutput\27[0m")
  assert(result:find("output", 1, true) and notices == 0)
  preview:refresh("a", true)
  preview:select("b", true)
  assert(jobs[2].cancelled)
  jobs[2].callback("obsolete")
  assert(not preview.content)
  preview:request("b", true, function(text) result = text end)
  jobs[3].callback("unavailable")
  preview:refresh("b", true)
  jobs[4].callback("recovered")
  assert(preview.content == "recovered" and notices == 1)
  preview:select("b", false)
  preview:refresh("b", false)
  preview:refresh(nil, true)
  assert(#jobs == 4)
  preview:request("c", true, function() end)
  preview:close()
  assert(jobs[5].cancelled)
  jobs[5].callback("late")
  assert(not preview.content and notices == 1)
end

local fixture = [=[
package.path = arg[1] .. "/?.lua;" .. arg[1] .. "/../tests/?.lua;" .. package.path
local uv, json = require("luv"), require("pickr.vendor.json")
local core, runtime = require("pickr.core"), require("pickr.runtime")
local render_snapshot, native_preview = core.snapshot_candidates, runtime.preview_async
local data = require("snapshot_fixture")
local mode, settings = arg[2], require("pickr.config").decode(arg[3])
if mode == "scroll" or mode == "shrink" then settings.fzf_bindings = { ["alt-z"] = "preview-bottom" } end
local started, fetches, captures, published = uv.hrtime(), 0, 0, 0
local function log(event, data)
  print(json.encode({ event = event, data = data, ms = (uv.hrtime() - started) / 1000000 })); io.stdout:flush()
end
runtime.origin = function() return { workspace_id = "w1", tab_id = "t1" } end
local original = { "a\tpa\tfirst row", "b\tpb\tsecond row" }
core.candidates = function(kind, scope)
  log("entry", { kind = kind, scope = scope })
  if mode:match("^snapshot") then return render_snapshot(data(false), kind, scope, "w1", settings, "t1") end
  if mode == "no-pane" then return { "a\t-\tfirst row" }, "@header\t-\tmissing pane" end
  return mode == "empty" and {} or original, "@header\t-\toriginal heading"
end
core.snapshot_candidates = function(_, kind, scope)
  if mode:match("^snapshot") then return render_snapshot(data(true), kind, scope, "w1", settings, "t1") end
  if mode == "no-pane" then return { "a\t-\tfirst row" }, "@header\t-\tmissing pane" end
  if mode == "prepare-error" then error("preparation failed") end
  return { "b\t" .. (mode == "target" and "new-pb" or "pb") .. "\tsecond row updated",
    "a\tpa\tfirst row updated", "c\tpc\tadded row" }, "@header\t-\tupdated heading"
end
runtime.snapshot_async = function(callback)
  fetches = fetches + 1
  local n, timer = fetches, uv.new_timer()
  log("fetch", n)
  timer:start(mode == "slow" and 1600 or 30, 0, function()
    timer:close()
    if mode == "failure" or mode == "recover" and n == 1 then callback("fixture timeout")
    else callback(nil, {}) end
  end)
  return { cancel = function()
    log("cancel-fetch", n)
    if not timer:is_closing() then timer:close() end
  end }
end
runtime.preview_async = function(target, callback)
  if target == "-" then return native_preview(target, callback) end
  captures = captures + 1
  local n, timer = captures, uv.new_timer()
  log("capture", { target = target, n = n })
  timer:start((mode == "capture-slow" or mode == "snapshot-slow") and 900 or 30, 0, function()
    timer:close()
    log("captured", { target = target, n = n })
    if mode == "preview-error" and n == 1 then callback("Preview unavailable: pane closed or could not be read.\n"); return end
    local lines = { "\27[31mSCREEN_" .. target .. "_" .. n .. "\27[0m" }
    for i = 1, (mode == "shrink" and n > 1) and 1 or 99 do lines[#lines + 1] = "LINE_" .. i end
    lines[#lines + 1] = "PREVIEW_BOTTOM_" .. target .. "_" .. n
    callback(table.concat(lines, "\n"))
  end)
  return { cancel = function()
    log("cancel-capture", n)
    if not timer:is_closing() then timer:close() end
  end }
end
local new_session = core.new_session
core.new_session = function(...)
  local session = new_session(...)
  local publish = session.publish
  session.publish = function(self, ...)
    local ok = publish(self, ...)
    if ok then published = published + 1; log("published", self.publication_ms) end
    return ok
  end
  return session
end
if mode == "stalled" then
  runtime.publication_timeout_ms = 350
  local spawn = runtime.spawn
  runtime.spawn = function(command, args, ...)
    if command == "fzf" then
      for i, option in ipairs(args) do
        if option:match("^%-%-bind=load:") then args[i] = option:gsub(",result%-final:.*$", ",result-final:ignore") end
      end
    end
    return spawn(command, args, ...)
  end
end
runtime.focus_pane = function(id) log("focus", id) end
runtime.herdr = function(_, _, id) log("focus", id) end
local run = runtime.run_picker
runtime.run_picker = function(...)
  local session = select(5, ...)
  local popup = session.popup
  session.popup = setmetatable({}, { __index = popup, __newindex = function(_, key, value)
    popup[key] = value
    if key == "preview_visible" then log("visibility", value) end
  end })
  local code, result, errors, signal = run(...)
  if session.ready_at then log("ready-at", (session.ready_at - started) / 1000000) end
  log("result", result)
  return code, result, errors, signal
end
local ok, err = pcall(core.pick, arg[4] or "panes", arg[5] or "all", settings)
log("done", { ok = ok, error = not ok and tostring(err) or nil, fetches = fetches,
  captures = captures, published = published })
os.exit(0)
]=]

local function check(mode, keys, settings, kind, scope)
  if settings and require("pickr.config").decode(settings).refresh.interval_ms > 0 then
    keys[#keys] = { retry = keys[#keys] }
  end
  local code, output, screen = pty.run({ uv.exepath(), "-e", fixture, "--", "-", pty.source,
    mode, settings or '{"preview":{"enabled_by_default":false}}', kind or "panes", scope or "all" },
    pty.environment(), keys, nil, 10000)
  assert(code == 0, output .. screen)
  local events = {}
  for line in output:gmatch("[^\n]+") do
    local e = json.decode(line)
    events[e.event] = events[e.event] or {}
    events[e.event][#events[e.event] + 1] = e
  end
  assert(events.done, output .. screen)
  return events, screen, output
end
local function count(e, name) return #(e[name] or {}) end
local function focus(e, id) assert(e.focus and e.focus[1].data == id, json.encode(e)) end

if arg[1] == "--popup-instance" then
  local interval = assert(tonumber(arg[2]))
  local e = check("normal", { "", "", "", "", "", "\r" },
    '{"refresh":{"interval_ms":' .. interval .. '},"preview":{"enabled_by_default":false}}')
  focus(e, "a")
  print(json.encode({ interval = interval, first = e.fetch[1].ms - e["ready-at"][1].data,
    fetches = count(e, "fetch"), captures = count(e, "capture"), ok = e.done[1].data.ok }))
  return
end

for _, mode in ipairs({ "slow", "failure", "prepare-error" }) do
  for _, accept in ipairs({ "\r", "\27v" }) do
    local e = check(mode, { "\12", "\27[B", accept },
      '{"preview":{"enabled_by_default":false},"keys":{"accept":["enter","alt-v"]}}')
    focus(e, "b")
    assert(count(e, "fetch") == 1 and count(e, "published") == 0)
    if mode == "slow" then assert(count(e, "cancel-fetch") == 1) end
  end
end
local e, manual_screen = check("slow", { "\12", "\27[B", "", "", "", "", "", "", "", "", "\r" })
focus(e, "b")
assert(count(e, "published") == 1)
assert(manual_screen:find("Refreshing", 1, true), "Manual refresh lost its progress feedback")
local latency = e.published[1].data
assert(latency > 0 and latency < 2000, json.encode(e))
print("Native publication sample: " .. string.format("%.1f", latency) .. " ms; deadline 2000 ms")

local auto = '{"refresh":{"interval_ms":500},"preview":{"enabled_by_default":false},"keys":{"refresh":[]}}'
local recovery_screen
e, recovery_screen = check("recover", { "", "", "", "", "", "\r" }, auto)
assert(recovery_screen:find("Refresh failed", 1, true), "Automatic failure lost its status")
assert(not recovery_screen:find("Refreshing", 1, true), "Automatic retry added a progress row")
assert(count(e, "fetch") >= 2 and count(e, "published") >= 1)
assert(e.fetch[1].ms - e["ready-at"][1].data >= 495 and e.fetch[1].ms - e["ready-at"][1].data < 650)
focus(e, "a")
for _, mode in ipairs({ "empty", "normal" }) do
  e = check(mode, { "nomatch", "", "\21added", "", "", "\r" }, auto)
  focus(e, "c")
  assert(count(e, "fetch") >= 2 and count(e, "capture") == 0)
end
e = check("normal", { "", "", "\27" })
assert(count(e, "fetch") == 0 and count(e, "capture") == 0)
e = check("slow", { "\12", "\12", "\12", "\27" },
  '{"refresh":{"interval_ms":300},"preview":{"enabled_by_default":false}}')
assert(count(e, "fetch") == 1 and count(e, "cancel-fetch") == 1)
e = check("normal", { "\20", "", "", "", "", "", "\27" }, auto)
assert(count(e, "entry") == 2 and not e.focus)
local destination = e.entry[2].ms
for _, fetch in ipairs(e.fetch) do
  assert(fetch.ms < destination or fetch.ms >= destination + 500)
end
e = check("stalled", { "\12" })
assert(not e.done[1].data.ok and e.done[1].data.error:find("publication timed out", 1, true))

local visible = '{"refresh":{"interval_ms":500}}'
local screen
e, screen = check("normal", { "", "", "", "", "", "\r" }, visible)
focus(e, "a")
assert(count(e, "captured") >= 3 and screen:find("SCREEN_pa_", 1, true))
assert(not screen:find("Refreshing", 1, true), "Automatic refresh added a layout-shifting progress row")
e, screen = check("capture-slow", { "", "", "", "", "", "", "", "", "", "\r" }, visible)
focus(e, "a")
assert(count(e, "captured") >= 1 and count(e, "published") >= 3)
assert(count(e, "capture") < count(e, "published"), json.encode(e))
assert(screen:find("SCREEN_pa_1", 1, true))
e, screen = check("target", { "\27[B", "\12", "", "", "\r" }, '{}', "tabs", "all")
focus(e, "b")
assert(screen:find("SCREEN_new%-pb_"))
e = check("normal", { "\16", "", "", "\16", "", "\r" }, visible)
assert(e.visibility and #e.visibility == 2 and e.visibility[1].data == false and e.visibility[2].data == true)
for _, capture in ipairs(e.capture or {}) do
  assert(capture.ms < e.visibility[1].ms or capture.ms >= e.visibility[2].ms, json.encode(e))
end
assert(count(e, "captured") >= 2)
e = check("normal", { "nomatch", "", "", "\27" }, visible)
for _, capture in ipairs(e.capture or {}) do assert(capture.ms < 850, json.encode(e)) end
e, screen = check("no-pane", { "\12", "", "\r" }, '{}')
focus(e, "a")
assert(count(e, "capture") == 0 and screen:find("No pane available", 1, true))
e, screen = check("preview-error", { "\12", "", "\r" }, '{}')
focus(e, "a")
assert(screen:find("Preview unavailable", 1, true) and screen:find("SCREEN_pa_2", 1, true))
e = check("normal", { "\24", "", "", "", "", "\27" }, auto, "tabs", "tab")
assert(count(e, "entry") == 1 and count(e, "fetch") >= 2)
assert(e.fetch[1].ms - e["ready-at"][1].data < 650, "State-only scope change reset cadence")

for _, view in ipairs({ { "spaces", "all", "w1", "pb" }, { "tabs", "all", "t1", "pc" },
  { "tabs", "space", "t1", "pc" }, { "panes", "all", "pa", "pa" },
  { "panes", "space", "pa", "pa" }, { "panes", "tab", "pa", "pa" },
  { "agents", "all", "pa", "pa" }, { "agents", "space", "pa", "pa" }, { "agents", "tab", "pa", "pa" } }) do
  local keys = { "", "", "", "", "", "\r" }
  if view[1] == "agents" then
    keys[1] = "\27[B"
    if view[2] == "all" then keys[2] = "\27[B" end
  end
  e, screen = check("snapshot", keys, visible, view[1], view[2])
  focus(e, view[3])
  assert(count(e, "fetch") >= 2 and count(e, "published") >= 2, json.encode(e))
  assert(screen:find("SCREEN_" .. view[4] .. "_", 1, true), "Refreshed target not previewed: " .. view[1] .. "/" .. view[2])
end
e, screen = check("snapshot-slow", { "", "", "", "", "", "", "", "", "", "", "\r" }, visible, "tabs", "all")
focus(e, "t1")
assert(count(e, "cancel-capture") >= 1 and screen:find("SCREEN_pc_", 1, true))
assert(not screen:find("SCREEN_pa_1", 1, true), "Obsolete captured target appeared")

-- Two real popups own independent timers and terminate without lingering work.
local isolated = {}
for _, interval in ipairs({ 500, 700 }) do
  require("pickr.runtime").spawn(uv.exepath(), { directory .. "/live_refresh.lua", "--popup-instance", tostring(interval) },
    nil, pty.environment_list(pty.environment()), 10000, function(err, code, output, errors)
      assert(not err and code == 0, tostring(err) .. errors .. output)
      local result = json.decode(output)
      assert(result.ok and result.captures == 0 and result.fetches >= 1)
      assert(result.first >= interval - 5 and result.first < interval + 150, output)
      isolated[interval] = true
    end)
end
uv.run()
assert(isolated[500] and isolated[700])
e, screen = check("scroll", { "\27z", "\12", "", "\r" }, '{}')
assert(screen:find("PREVIEW_BOTTOM_pa_1", 1, true), "The preview did not scroll before refresh")
assert(screen:find("SCREEN_pa_2", 1, true) and not screen:find("PREVIEW_BOTTOM_pa_2", 1, true),
  "Update the native preview-scroll diagnostic: fzf behavior changed")
e, screen = check("shrink", { "\27z", "\12", "", "\r" }, '{}')
assert(screen:find("PREVIEW_BOTTOM_pa_1", 1, true) and screen:find("SCREEN_pa_2", 1, true)
  and screen:find("PREVIEW_BOTTOM_pa_2", 1, true), "Shrinking preview did not show current short content")
print("Native preview scrolling: same-target refresh resets to top and shrinking content stays visible")
print("Live refresh: retained fetch/failure/preparation results, native tracking, scheduler, recovery, empty/no-match, cancellation, deadline, previews and coalescing OK")
