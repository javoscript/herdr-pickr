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
runtime.preview_command = function()
  local lines = {}
  for i = 1, 99 do lines[#lines + 1] = "'line " .. i .. "'" end
  lines[#lines + 1] = "'PREVIEW_BOTTOM'"
  return "printf '%s\n' " .. table.concat(lines, " ")
end
runtime.current_workspace = function() return "fixture-origin" end
core.candidates = function(kind, scope)
  print("OPEN " .. kind .. " " .. scope); io.stdout:flush()
  return { "fixture-id\t-\tfixture label", "fixture-next\t-\tsecond label" }, "@header\t-\theader"
end
runtime.herdr = function(_, _, id) print("FOCUS " .. id) end
runtime.focus_agent_pane = function(id) print("FOCUS " .. id) end
local settings = config.decode(arg[2])
settings.fzf_bindings = require("pickr.fzf_bindings").load()
core.pick(arg[3], arg[4], settings)
os.exit(0)
]=]

local function check(kind, scope, settings, keys, accepted, ambient, target)
  local env = pty.environment({ FZF_DEFAULT_OPTS = ambient or "" })
  local code, output, screen = pty.run({ assert(uv.exepath()), "-e", fixture, "--", "-",
    pty.source, json.encode(settings), kind, scope }, env, keys)
  assert(code == 0, output .. screen:sub(-1500))
  assert((output:find("FOCUS ", 1, true) ~= nil) == accepted, output)
  if accepted then assert(output:find("FOCUS " .. (target or "fixture-id"), 1, true), output) end
  return screen
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
