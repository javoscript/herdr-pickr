local uv = require("luv")
local script = assert(uv.fs_realpath(arg[0]), "Cannot resolve picker script path")
local directory = assert(script:match("^(.*)/[^/]+$"))
package.path = directory .. "/?.lua;" .. package.path

if arg[1] == "preview" and arg[2] and not arg[3] then
  local owner = os.getenv("PICKR_PREVIEW_SOCKET")
  if owner then
    local ok, content = pcall(require("pickr.runtime").control_helper, owner, "preview", arg[2])
    io.write(ok and content or "Preview unavailable: pane closed or could not be read.\n")
  else
    io.write(require("pickr.core").preview(arg[2]))
  end
  return
end

if arg[1] == "control" and arg[2] and arg[3] then
  io.write(require("pickr.runtime").control_helper(arg[2], arg[3], arg[4]))
  return
end

local valid, kind, scope = pcall(function()
  assert(not arg[3], "Too many picker arguments")
  return require("pickr.pickers").launch(arg[1], arg[2])
end)
if not valid then
  io.stderr:write(tostring(kind) .. "\nUsage: lua src/main.lua spaces\n"
    .. "       lua src/main.lua tabs|panes|agents [all|space|tab]\n"
    .. "       lua src/main.lua preview <pane-id>\n")
  os.exit(2)
end

local ok, err = pcall(function() require("pickr.core").pick(kind, scope) end)
if not ok then
  io.stderr:write("Pickr failed: " .. tostring(err) .. "\n")
  if uv.guess_handle(0) == "tty" then
    io.stderr:write("Press Enter to close…")
    io.read("*l")
  end
  os.exit(1)
end
