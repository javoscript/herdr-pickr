-- Standalone protocol investigation; this is not a passing live-refresh regression.
-- Run: lua tests/refresh_publication_probe.lua
-- Deliberately holds replacement input/acknowledgement so keys reach each boundary.
local uv = require("luv")
local directory = assert(uv.fs_realpath(arg[0])):match("^(.*)/[^/]+$")
local pty = dofile(directory .. "/pty_runner.lua")
package.path = pty.source .. "/?.lua;" .. package.path
local json = require("pickr.vendor.json")

local fixture = [=[
package.path = arg[1] .. "/?.lua;" .. package.path
local uv = require("luv")
local runtime, json = require("pickr.runtime"), require("pickr.vendor.json")
local mode = arg[2]
local root = assert(uv.fs_mkdtemp("/tmp/pickr-publication-probe-XXXXXX"))
local marker = root .. "/replacement"
local barrier_marker = root .. "/barrier"
local function quote(s) return "'" .. s:gsub("'", "'\\''") .. "'" end
local function command(code)
  return quote(uv.exepath()) .. " -e " .. quote(code)
end
local replacement = command('local uv=require("luv"); '
  .. ((mode == "tracking" or mode == "waiting") and 'uv.sleep(1200); ' or '')
  .. 'local f=assert(io.open(' .. string.format("%q", marker) .. ',"w")); f:close(); '
  .. 'io.write("x\\tnew-x\\tunrelated first\\ny\\tnew-y\\tunrelated second\\nb\\tnew-b\\tupdated beta\\n")')
local acknowledge = command('local f=io.open(' .. string.format("%q", marker) .. ',"r"); '
  .. 'if f then f:close(); '
  .. (mode == "synchronous" and 'require("luv").sleep(1200); io.write("pos(3)")' or '')
  .. ' end')
local args = { "--layout=reverse", "--no-sort", "--no-multi", "--print0",
  "--delimiter=\t", "--with-nth=3..", "--bind=start:pos(2)",
  "--bind=ctrl-l:reload-sync(" .. replacement .. ")",
  "--bind=result-final:transform(" .. acknowledge .. ")" }
if mode == "tracking" then
  args[#args + 1], args[#args + 2] = "--track", "--id-nth=1"
elseif mode == "barrier" then
  local barrier = command('require("luv").sleep(1200); '
    .. 'local f=io.open(' .. string.format("%q", marker) .. ',"r"); '
    .. 'local out=assert(io.open(' .. string.format("%q", barrier_marker) .. ',"w")); '
    .. 'out:write(f and "started" or "not-started"); out:close(); if f then f:close() end')
  args[#args + 1] = "--bind=ctrl-l:reload-sync(" .. replacement .. ")+transform(" .. barrier .. ")"
elseif mode == "waiting" then
  args[#args + 1] = "--print-query"
  args[#args + 1] = "--bind=ctrl-l:reload-sync(" .. replacement .. ")+wait"
end
local started = uv.hrtime()
local result
runtime.spawn("fzf", args, "a\told-a\talpha\nb\told-b\tbeta\n", runtime.fzf_env(), nil,
  function(err, code, output, errors)
    assert(not err, err)
    result = { code = code, row = output:gsub("%z$", ""), errors = errors,
      elapsed_ms = (uv.hrtime() - started) / 1000000 }
    if mode == "waiting" then
      result.query = output:match("^(.-)%z")
      result.row = output:match("^.-%z(.-)%z$")
    end
  end)
uv.run()
if mode == "barrier" then
  local f=assert(io.open(barrier_marker,"r")); result.barrier=f:read("*a"); f:close()
end
uv.fs_unlink(barrier_marker)
uv.fs_unlink(marker); assert(uv.fs_rmdir(root))
print(json.encode(result))
os.exit(0)
]=]

local function probe(mode, keys)
  local code, output = pty.run({ uv.exepath(), "-e", fixture, "--", "-", pty.source, mode },
    pty.environment(), keys, nil, 6000)
  assert(code == 0, output)
  return json.decode(output)
end

-- At 800 ms request replacement; at 1000 ms accept. A retained-results
-- implementation should accept beta immediately, without waiting for the ack.
local sync = probe("synchronous", { "\12", "\r" })
assert(sync.code == 0 and sync.row:match("^b\t"), json.encode(sync))
assert(sync.elapsed_ms >= 1800, json.encode(sync))
print("Synchronous result-final acknowledgement: Enter waited for the delayed helper ("
  .. math.floor(sync.elapsed_ms) .. " ms total)")

-- Defer the acknowledgement without blocking input: the replacement is now
-- selectable before pos(3) restores beta. It must not accept a fallback row.
local unacknowledged = probe("unacknowledged", { "\12", "\r" })
assert(unacknowledged.code == 0 and not unacknowledged.row:match("^b\t"), json.encode(unacknowledged))
print("Unacknowledged replacement: Enter accepted " .. unacknowledged.row:match("^[^\t]+")
  .. " instead of beta")

-- Native ID tracking keeps beta but ignores Enter while replacement is loading.
-- Esc arrives after the replacement finishes and is the actual closing key.
local tracked = probe("tracking", { "\12", "\r", "", "", "", "", "", "", "\27" })
assert(tracked.code == 130 and tracked.row == "", json.encode(tracked))
print("Native --track/--id-nth: Enter during reload was ignored; Esc closed later")

-- A synchronous helper in the reload action chain buffers input, but fzf does
-- not dispatch the replacement command until that entire action chain returns.
local barrier = probe("barrier", { "\12", "", "", "", "", "", "", "", "\r" })
assert(barrier.barrier == "not-started", json.encode(barrier))
print("reload-sync+transform barrier: replacement had not started after the helper waited 1200 ms")

-- fzf's wait action does allow the reload to run, but drops keys arriving in
-- the meantime. Q and the first Enter arrive before replacement finishes;
-- only the second Enter (at 2400 ms) ends the picker, with an empty query.
local waiting = probe("waiting", { "\12", "Q", "\r", "", "", "", "", "", "\r" })
assert(waiting.code == 0 and waiting.query == "", json.encode(waiting))
print("reload-sync+wait: Q and the first Enter were discarded, not buffered")
print("Publication probe: synchronous helpers buffer input but cannot start reload inside their action chain; wait/track discard input")
