local uv = require("luv")
local script = assert(uv.fs_realpath(debug.getinfo(1, "S").source:sub(2)), "Cannot resolve picker script path")
local directory = assert(script:match("^(.*)/[^/]+$"))
package.path = directory .. "/?.lua;" .. package.path
local runtime = require("pickr.runtime")

local ok, message = pcall(function()
  assert(os.getenv("HERDR_ENV") == "1", "Pickr must be launched inside Herdr")
  local valid = { ["tabs-current"] = true, ["tabs-all"] = true, spaces = true,
    ["agents-current"] = true, ["agents-all"] = true }
  assert(valid[arg[1]] and not arg[2], "Invalid Pickr entrypoint")
  local workspace = assert(runtime.current_workspace(), "Missing action workspace context")
  runtime.herdr("plugin", "pane", "open", "--plugin", "javoscript.herdr-pickr",
    "--entrypoint", arg[1], "--env", "PICKR_ORIGIN_WORKSPACE_ID=" .. workspace)
end)
if not ok then
  io.stderr:write("Pickr: " .. tostring(message) .. "\n")
  os.exit(1)
end
