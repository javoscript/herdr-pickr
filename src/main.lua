local uv = require("luv")
local script = assert(uv.fs_realpath(arg[0]), "Cannot resolve picker script path")
local directory = assert(script:match("^(.*)/[^/]+$"))
package.path = directory .. "/?.lua;" .. package.path

if arg[1] == "preview" and arg[2] and not arg[3] then
  io.write(require("pickr.core").preview(arg[2]))
  return
end

if arg[1] == "control" and arg[2] and arg[3] then
  io.write(require("pickr.runtime").control_helper(arg[2], arg[3], arg[4]))
  return
end

local kinds = { tabs = { current = true, all = true }, workspaces = { current = true, all = true },
  agents = { current = true, all = true }, panes = { tab = true, current = true, all = true } }
if not kinds[arg[1]] or not kinds[arg[1]][arg[2]] or arg[3] then
  io.stderr:write("Usage: lua src/main.lua tabs|workspaces|agents current|all\n"
    .. "       lua src/main.lua panes tab|current|all\n"
    .. "       lua src/main.lua preview <pane-id>\n")
  os.exit(2)
end

local ok, err = pcall(function() require("pickr.core").pick(arg[1], arg[2]) end)
if not ok then
  io.stderr:write("Pickr failed: " .. tostring(err) .. "\n")
  if uv.guess_handle(0) == "tty" then
    io.stderr:write("Press Enter to close…")
    io.read("*l")
  end
  os.exit(1)
end
