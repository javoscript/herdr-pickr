local uv = require("luv")
local M = {}

local function close(handle)
  if handle and not handle:is_closing() then handle:close() end
end

-- Run argv directly, collecting output and enforcing an optional timeout.
function M.run(command, args, input, env, timeout)
  local stdin, stdout, stderr = uv.new_pipe(false), uv.new_pipe(false), uv.new_pipe(false)
  local output, errors, code, signal, failure = {}, {}, nil, nil, nil
  local process, timer
  process, failure = uv.spawn(command, {
    args = args, env = env, stdio = { stdin, stdout, stderr },
  }, function(exit_code, exit_signal)
    code, signal = exit_code, exit_signal
    close(process)
    close(timer)
    close(stdin)
  end)
  if not process then
    close(stdin); close(stdout); close(stderr)
    uv.run()
    error("Cannot launch " .. command .. ": " .. tostring(failure), 0)
  end
  failure = nil
  local function collect(pipe, chunks)
    pipe:read_start(function(err, data)
      if err then failure = err end
      if data then chunks[#chunks + 1] = data else close(pipe) end
    end)
  end
  collect(stdout, output)
  collect(stderr, errors)
  stdin:write(input or "", function(err)
    -- A cancelled consumer can close its input before consuming every row.
    if err and not tostring(err):match("EPIPE") then failure = err end
    if not stdin:is_closing() then stdin:shutdown(function() close(stdin) end) end
  end)
  if timeout then
    timer = uv.new_timer()
    timer:start(timeout, 0, function()
      failure = command .. " timed out"
      if not process:is_closing() then process:kill("sigkill") end
    end)
  end
  uv.run()
  if failure then error(failure, 0) end
  return code, table.concat(output), table.concat(errors), signal
end

return M
