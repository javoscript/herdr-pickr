local directory = debug.getinfo(1, "S").source:sub(2):match("^(.*)/") or "."
local lib = directory .. "/../../lib"
package.path = directory .. "/?.lua;" .. lib .. "/?.lua;" .. lib .. "/vendor/?.lua;" .. package.path
local runtime = require("runtime")

local ok, message = pcall(function()
  assert(os.getenv("HERDR_ENV") == "1", "Pickr must be launched inside Herdr")
  local valid = { ["tabs-current"] = true, ["tabs-all"] = true, spaces = true,
    ["agents-current"] = true, ["agents-all"] = true }
  assert(valid[arg[1]] and not arg[2], "Invalid Pickr entrypoint")
  local workspace = assert(runtime.current_workspace(), "Missing action workspace context")
  runtime.herdr("plugin", "pane", "open", "--plugin", "local.pickr",
    "--entrypoint", arg[1], "--env", "PICKR_ORIGIN_WORKSPACE_ID=" .. workspace)
end)
if not ok then
  io.stderr:write("Pickr: " .. tostring(message) .. "\n")
  os.exit(1)
end
