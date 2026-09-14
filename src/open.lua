local uv = require("luv")
local script = assert(uv.fs_realpath(debug.getinfo(1, "S").source:sub(2)), "Cannot resolve picker script path")
local directory = assert(script:match("^(.*)/[^/]+$"))
package.path = directory .. "/?.lua;" .. package.path
local runtime = require("pickr.runtime")

local ok, message = pcall(function()
  assert(os.getenv("HERDR_ENV") == "1", "Pickr must be launched inside Herdr")
  assert(not arg[2], "Invalid Pickr entrypoint arguments")
  require("pickr.pickers").preset(arg[1])
  local config = require("pickr.config")
  local settings = config.load()
  local origin = runtime.origin()
  local workspace = assert(origin.workspace_id, "Missing action workspace context")
  runtime.open_popup(arg[1], workspace, settings, origin.tab_id)
end)
if not ok then
  io.stderr:write("Pickr: " .. tostring(message) .. "\n")
  os.exit(1)
end
