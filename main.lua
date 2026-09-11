local uv = require("luv")
local script = assert(uv.fs_realpath(arg[0]), "Cannot resolve picker script path")
local directory = assert(script:match("^(.*)/[^/]+$"))
local lib = directory .. "/../../lib"
package.path = directory .. "/?.lua;" .. lib .. "/?.lua;" .. lib .. "/vendor/?.lua;" .. package.path

if arg[1] == "preview" and arg[2] and not arg[3] then
  io.write(require("core").preview(arg[2]))
  return
end

local kinds = { tabs = true, workspaces = true, agents = true }
if not kinds[arg[1]] or (arg[2] ~= "current" and arg[2] ~= "all") or arg[3] then
  io.stderr:write("Usage: lua main.lua tabs|workspaces|agents current|all\n"
    .. "       lua main.lua preview <pane-id>\n")
  os.exit(2)
end

local ok, err = pcall(function() require("core").pick(arg[1], arg[2]) end)
if not ok then
  io.stderr:write("Pickr failed: " .. tostring(err) .. "\n")
  if uv.guess_handle(0) == "tty" then
    io.stderr:write("Press Enter to close…")
    io.read("*l")
  end
  os.exit(1)
end
