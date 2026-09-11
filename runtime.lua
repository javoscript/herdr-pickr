local uv = require("luv")
local json = require("json")
local M = {}

local directory = assert(uv.fs_realpath(debug.getinfo(1, "S").source:sub(2))):match("^(.*)/[^/]+$")

local function shell_quote(text)
  return "'" .. text:gsub("'", "'\\''") .. "'"
end

function M.preview_command()
  -- fzf shell-quotes the hidden second field before substituting {2}.
  return shell_quote(assert(uv.exepath())) .. " " .. shell_quote(directory .. "/main.lua")
    .. " preview {2}"
end

local function close(handle)
  if handle and not handle:is_closing() then handle:close() end
end

-- Pipes carry only candidate data/results; fzf uses the popup's /dev/tty for UI.
M.run = require("process").run

function M.current_workspace(getenv)
  getenv = getenv or os.getenv
  local origin = getenv("PICKR_ORIGIN_WORKSPACE_ID")
  if origin and origin ~= "" then return origin end
  if getenv("HERDR_PLUGIN_ID") == "local.pickr" then
    local context = getenv("HERDR_PLUGIN_CONTEXT_JSON")
    if context and context ~= "" then
      local workspace = json.decode(context).workspace_id
      if workspace then return workspace end
    end
  end
  return getenv("HERDR_ACTIVE_WORKSPACE_ID")
end

local function result(response)
  local decoded = json.decode(response)
  if decoded.error then error(json.encode(decoded.error), 0) end
  return assert(decoded.result, "Herdr returned no result")
end

function M.herdr(...)
  local code, output, errors = M.run(
    os.getenv("HERDR_BIN_PATH") or "herdr", { ... }, nil, nil, 10000)
  if code ~= 0 then error(errors ~= "" and errors or "Herdr command failed", 0) end
  return result(output)
end

function M.read_visible(pane_id)
  -- Unlike metadata commands, pane read emits raw text for ANSI output.
  local code, output, errors = M.run(os.getenv("HERDR_BIN_PATH") or "herdr",
    { "pane", "read", pane_id, "--source", "visible", "--ansi", "--raw" }, nil, nil, 10000)
  if code ~= 0 then error(errors ~= "" and errors or "Herdr pane read failed", 0) end
  return output
end

function M.focus_agent_pane(pane_id)
  -- In Herdr 0.9.0, agent.focus does not move the client's workspace/tab view.
  -- pane.focus does, but the CLI only exposes directional pane focus.
  local path = assert(os.getenv("HERDR_SOCKET_PATH"), "Missing HERDR_SOCKET_PATH")
  local connection, timer = uv.new_pipe(false), uv.new_timer()
  local chunks, response, failure, finished = {}, nil, nil, false
  local function finish(err, data)
    if finished then return end
    finished, failure, response = true, err, data
    close(connection)
    close(timer)
  end
  timer:start(5000, 0, function() finish("Herdr pane.focus timed out") end)
  connection:connect(path, function(err)
    if finished then return end
    if err then finish(err); return end
    connection:read_start(function(read_error, data)
      if read_error then finish(read_error); return end
      if not data then finish("Herdr closed the socket before replying"); return end
      chunks[#chunks + 1] = data
      local buffer = table.concat(chunks)
      local line = buffer:match("^(.-)\n")
      if line then finish(nil, line) end
    end)
    connection:write(json.encode({
      id = "pickr:focus", method = "pane.focus", params = { pane_id = pane_id },
    }) .. "\n", function(write_error)
      if write_error then finish(write_error) end
    end)
  end)
  uv.run()
  if failure then error(failure, 0) end
  local reply = result(response)
  if not reply.pane or reply.pane.pane_id ~= pane_id then
    error("Herdr did not confirm the selected pane", 0)
  end
end

function M.fzf_env()
  local env = {}
  for key, value in pairs(uv.os_environ()) do
    if key ~= "FZF_DEFAULT_OPTS" and key ~= "FZF_DEFAULT_OPTS_FILE" then
      env[#env + 1] = key .. "=" .. value
    end
  end
  return env
end

return M
