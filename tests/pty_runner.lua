-- Fixture-only controlling-terminal runner for macOS, using bundled script/stty.
local uv = require("luv")
local script = assert(uv.fs_realpath(debug.getinfo(1, "S").source:sub(2)))
local directory = assert(script:match("^(.*)/[^/]+$"))
local source = assert(directory:match("^(.*)/[^/]+$")) .. "/src"
package.path = source .. "/?.lua;" .. package.path
local json = require("pickr.vendor.json")
local M = { source = source, directory = directory }

local function read(path)
  local file = assert(io.open(path, "r"))
  local text = assert(file:read("*a")); assert(file:close())
  return text
end

local function write(path, text)
  local file = assert(io.open(path, "w"))
  assert(file:write(text)); assert(file:close())
end

local function close(handle)
  if handle and not handle:is_closing() then handle:close() end
end

-- script gives this wrapper a controlling terminal and its own process group.
-- Only the tested command's stdin/stdout are redirected; fzf still uses /dev/tty.
if arg and arg[1] == "--pty-child" then
  local root = assert(arg[2])
  write(root .. "/pid", tostring(uv.os_getpid()))
  local code, _, errors = require("pickr.process").run("/bin/stty",
    { "-f", "/dev/tty", "raw", "-echo", "rows", "30", "cols", "100" }, nil, nil, 2000)
  assert(code == 0, errors)
  local argv = json.decode(read(root .. "/argv"))
  local command = table.remove(argv, 1)
  local input = assert(uv.fs_open(root .. "/input", "r", 0))
  local output = assert(uv.fs_open(root .. "/output", "w", 384))
  local child, failure
  child, failure = uv.spawn(command, { args = argv, stdio = { input, output, 2 } }, function(exit_code, signal)
    write(root .. "/result", json.encode({ code = exit_code, signal = signal }))
    close(child)
  end)
  uv.fs_close(input); uv.fs_close(output)
  assert(child, failure)
  uv.run()
  os.exit(0)
end

function M.environment(overrides)
  local env = uv.os_environ()
  env.TERM = "xterm-256color"
  env.FZF_DEFAULT_OPTS, env.FZF_DEFAULT_OPTS_FILE, env.FZF_API_KEY = nil, nil, nil
  for key, value in pairs(overrides or {}) do env[key] = value end
  return env
end

function M.environment_list(env)
  local result = {}
  for key, value in pairs(env) do result[#result + 1] = key .. "=" .. value end
  return result
end

function M.run(argv, env, keys, input, timeout)
  local root = assert(uv.fs_mkdtemp("/tmp/pickr-pty-XXXXXX"))
  local stdin, stdout, stderr, process, key_timer, deadline
  local pipe, sent, exited, script_code, script_signal, failure = nil, 0, false, nil, nil, nil
  local screen = {}
  local function terminate()
    -- Closing the master alone does not reliably reap every test descendant.
    local file = io.open(root .. "/pid", "r")
    if file then
      local pid = tonumber(file:read("*a")); file:close()
      if pid then uv.kill(-pid, "sigkill") end
    end
    if process and not exited then process:kill("sigkill") end
    close(stdin); close(stdout); close(stderr); close(key_timer); close(deadline)
  end
  local function fail(message)
    failure = failure or tostring(message)
    terminate()
  end
  local ok, err = pcall(function()
    write(root .. "/argv", json.encode(argv))
    write(root .. "/input", input or "")
    -- uv.spawn-created streams use sockets, which Darwin script rejects with
    -- ENOTSUP. A real pipe produces ENOTTY, enabling script's openpty fallback.
    pipe = assert(uv.pipe({}))
    stdin, stdout, stderr = uv.new_pipe(false), uv.new_pipe(false), uv.new_pipe(false)
    assert(stdin:open(pipe.write)); pipe.write = nil
    local launch_error
    process, launch_error = uv.spawn("/usr/bin/script", {
      args = { "-q", "/dev/null", assert(uv.exepath()), script, "--pty-child", root },
      env = M.environment_list(env), stdio = { pipe.read, stdout, stderr },
    }, function(code, signal)
      exited, script_code, script_signal = true, code, signal
      close(process); close(stdin); close(key_timer)
    end)
    assert(process, launch_error)
    uv.fs_close(pipe.read); pipe.read = nil
    for _, stream in ipairs({ stdout, stderr }) do
      stream:read_start(function(read_error, data)
        if read_error then fail(read_error)
        elseif data then screen[#screen + 1] = data
        else close(stream) end
      end)
    end
    key_timer = uv.new_timer()
    key_timer:start(800, 200, function()
      -- Detect premature command exit even if script is still draining its PTY.
      if uv.fs_stat(root .. "/result") or exited then close(key_timer); return end
      if sent == #keys then close(key_timer); return end
      sent = sent + 1
      if keys[sent] ~= "" then
        stdin:write(keys[sent], function(write_error) if write_error then fail(write_error) end end)
      end
    end)
    deadline = uv.new_timer()
    deadline:start(timeout or 8000, 0, function() fail("PTY timed out") end)
    -- Keep the deadline until stdout/stderr have drained, not just process exit.
    while uv.run("once") do
      if exited and stdout:is_closing() and stderr:is_closing() then close(deadline) end
    end
  end)
  if not ok then terminate(); uv.run() end
  local contents = table.concat(screen)
  local result, output
  if ok and not failure then
    ok, err = pcall(function()
      assert(script_code == 0 and script_signal == 0, "PTY wrapper failed")
      result = json.decode(read(root .. "/result"))
      output = read(root .. "/output")
      assert(sent == #keys, "an unexpected key exited early: " .. output)
    end)
  end
  if pipe then
    if pipe.read then uv.fs_close(pipe.read) end
    if pipe.write then uv.fs_close(pipe.write) end
  end
  for _, name in ipairs({ "argv", "input", "output", "pid", "result" }) do uv.fs_unlink(root .. "/" .. name) end
  assert(uv.fs_rmdir(root))
  if failure or not ok then error(tostring(failure or err) .. "\n" .. contents:sub(-1500), 0) end
  return result.signal == 0 and result.code or -result.signal, output, contents
end

return M
