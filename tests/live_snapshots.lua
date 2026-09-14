local uv = require("luv")
local directory = assert(uv.fs_realpath(arg[0])):match("^(.*)/[^/]+$")
package.path = directory .. "/../src/?.lua;" .. directory .. "/?.lua;" .. package.path
local core, runtime, config = require("pickr.core"), require("pickr.runtime"), require("pickr.config")
local json, snapshot = require("pickr.vendor.json"), require("snapshot_fixture")
local function ids(rows)
  local result = {}
  for _, row in ipairs(rows) do result[#result + 1] = row:match("^[^\t]+") end
  return table.concat(result, ",")
end
local scopes = {
  { "spaces", "all", "w1,w2", "w1", "pb", "2 tabs", "/new/pb" },
  { "tabs", "all", "t1,t2", "t1,t3", "pc", "tab renamed", "2 panes", "/new/pc" },
  { "tabs", "space", "t1", "t1,t3", "pc", "tab renamed", "2 panes", "/new/pc" },
  { "panes", "all", "pa,pb,pd", "pa,pc,pb", "pa", "updated title", "updated label", "/new/pa" },
  { "panes", "space", "pa,pb", "pa,pc,pb", "pa", "updated title", "updated label", "/new/pa" },
  { "panes", "tab", "pa,pb", "pa,pc", "pa", "updated title", "updated label", "/new/pa" },
  { "agents", "all", "pb,pd,pa", "pa,pb,pc", "pa", "new-agent", "updated title", "updated label" },
  { "agents", "space", "pb,pa", "pa,pb,pc", "pa", "new-agent", "updated title", "updated label" },
  { "agents", "tab", "pb,pa", "pa,pc", "pa", "new-agent", "updated title", "updated label" },
}
for _, layout in ipairs(scopes) do
  local kind, scope = layout[1], layout[2]
  for _, custom in ipairs({ false, true }) do
    local settings = config.decode('{"theme":{"name":"terminal","custom":{"status_blocked":"#123456"}}}')
    if custom then
      local reverse = {}
      for i = #settings.columns[kind], 1, -1 do reverse[#reverse + 1] = settings.columns[kind][i] end
      settings.columns[kind] = reverse
    end
    local old, old_header = core.snapshot_candidates(snapshot(false), kind, scope, "w1", settings, "t1")
    local fresh, header = core.snapshot_candidates(snapshot(true), kind, scope, "w1", settings, "t1")
    assert(ids(old) == layout[3] and ids(fresh) == layout[4], kind .. "/" .. scope)
    assert(fresh[1]:match("^[^\t]+\t([^\t]+)") == layout[5])
    for i = 6, #layout do assert(fresh[1]:find(layout[i], 1, true), fresh[1] .. " missing " .. layout[i]) end
    assert(fresh[1]:find("\27[38;2;18;52;86m", 1, true) and fresh[1]:find("blocked", 1, true))
    local session = core.new_session(old, old_header)
    local g = session:begin_refresh()
    assert(session:stage(g, fresh, header))
    assert(session:accept(fresh[1]) == fresh[1]:match("^[^\t]+"))
    assert(session:publish(g, fresh, header) and session.rows == fresh and session.header == header)
    assert(session:accept(old[#old]) == old[#old]:match("^[^\t]+"))
    assert(not session:accept(fresh[1]:gsub("blocked", "forged")))
    session:close()
  end
end

-- Retained closed target failure must never trigger a replacement focus.
local original_candidates, original_run, original_origin, original_focus = core.candidates, runtime.run_picker, runtime.origin, runtime.focus_pane
runtime.origin = function() return { workspace_id = "w1", tab_id = "t1" } end
core.candidates = function(kind, scope, settings) return core.snapshot_candidates(snapshot(false), kind, scope, "w1", settings, "t1") end
local calls = {}
runtime.run_picker = function(_, _, _, _, session)
  local g = session:begin_refresh()
  assert(session:fail(g))
  local row = session.rows[3] -- pd has closed in the fresh fixture.
  assert(row:match("^pd\t"))
  return 0, runtime.picker_result("\0\0" .. row .. "\0", session), "", 0
end
runtime.focus_pane = function(id) calls[#calls + 1] = id; error("selected pane closed") end
local ok, err = pcall(core.pick, "panes", "all", config.decode('{}'))
assert(not ok and tostring(err):find("selected pane closed", 1, true) and #calls == 1 and calls[1] == "pd")
core.candidates, runtime.run_picker, runtime.origin, runtime.focus_pane = original_candidates, original_run, original_origin, original_focus

-- Exercise the actual asynchronous metadata/screen pipeline without Herdr.
local spawn = runtime.spawn
for _, failure in ipairs({ "none", "metadata", "decode", "screen", "timeout", "cancel" }) do
  local requests, answer = {}, nil
  runtime.spawn = function(binary, args, _, _, timeout, callback)
    assert(timeout == 10000)
    local job = { args = args, callback = callback }
    function job:cancel() self.cancelled = true end
    requests[#requests + 1] = job
    return job
  end
  local job = runtime.preview_async("pa", function(text) answer = text end)
  assert(table.concat(requests[1].args, "|") == "pane|get|pa")
  if failure == "cancel" then
    job:cancel()
    assert(requests[1].cancelled)
  end
  requests[1].callback(failure == "timeout" and "timed out" or nil,
    failure == "metadata" and 1 or 0, failure == "decode" and "broken" or json.encode({ result = { pane = { pane_id = "pa", cwd = "/cwd" } } }))
  if failure == "cancel" then assert(not answer and #requests == 1)
  elseif failure == "none" or failure == "screen" then
    assert(table.concat(requests[2].args, "|") == "pane|read|pa|--source|visible|--ansi|--raw")
    requests[2].callback(nil, failure == "screen" and 1 or 0, "\27[31mnew output\27[0m")
    if failure == "none" then assert(answer:find("pa\n/cwd\n", 1, true) and answer:find("\27[31mnew output", 1, true))
    else assert(answer:match("^Preview unavailable:")) end
  else assert(answer:match("^Preview unavailable:") and #requests == 1) end
end
runtime.spawn = spawn
local missing
runtime.preview_async("-", function(text) missing = text end)
uv.run()
assert(missing == "No pane available for preview.\n")
print("Live snapshots: nine type/scopes, changing membership/metadata/order/targets, column/theme publication, closed-target failure and asynchronous preview errors/cancellation OK")
