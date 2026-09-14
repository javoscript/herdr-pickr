local uv = require("luv")
local json = require("pickr.vendor.json")
local M = { publication_timeout_ms = 2000 }

local directory = assert(uv.fs_realpath(debug.getinfo(1, "S").source:sub(2))):match("^(.*)/[^/]+$")
local launcher = assert(directory:match("^(.*)/[^/]+$")) .. "/main.lua"

local function shell_quote(text)
  return "'" .. text:gsub("'", "'\\''") .. "'"
end

local function preview_command()
  -- fzf shell-quotes the hidden second field before substituting {2}.
  return shell_quote(assert(uv.exepath())) .. " " .. shell_quote(launcher)
    .. " preview {2}"
end
M.preview_command = preview_command

local function close(handle)
  if handle and not handle:is_closing() then handle:close() end
end

-- Pipes carry only candidate data/results; fzf uses the popup's /dev/tty for UI.
M.run = require("pickr.process").run

-- The caller owns the event loop. Completion waits for exit and both output
-- streams; cancellation closes inherited pipes too, so descendants cannot keep
-- a closing picker alive. Never call the blocking runner from these callbacks.
function M.spawn(command, args, input, env, timeout, callback)
  local stdin, stdout, stderr = uv.new_pipe(false), uv.new_pipe(false), uv.new_pipe(false)
  local output, errors, process, timer = {}, {}, nil, nil
  local exited, streams, finished, failure, code, signal = false, 2, false, nil, nil, nil
  local job = {}
  local function complete()
    if finished or not exited or streams ~= 0 then return end
    finished = true
    close(stdin); close(stdout); close(stderr); close(timer); close(process)
    callback(failure, code, table.concat(output), table.concat(errors), signal)
  end
  function job:cancel(reason)
    if finished then return end
    failure = reason or "cancelled"
    close(stdin); close(stdout); close(stderr); close(timer)
    streams = 0
    if process and not exited then process:kill("sigkill") end
    complete()
  end
  local launch_error
  process, launch_error = uv.spawn(command, {
    args = args, env = env, stdio = { stdin, stdout, stderr },
  }, function(exit_code, exit_signal)
    code, signal, exited = exit_code, exit_signal, true
    close(process); close(stdin)
    complete()
  end)
  if not process then
    exited, streams, failure = true, 0, "Cannot launch " .. command .. ": " .. tostring(launch_error)
    -- Defer even launch failure so callers can retain the returned job first.
    timer = uv.new_timer()
    timer:start(0, 0, complete)
    return job
  end
  local function collect(pipe, chunks)
    pipe:read_start(function(err, data)
      if finished or pipe:is_closing() then return end
      if err then job:cancel(tostring(err)); return end
      if data then chunks[#chunks + 1] = data
      else streams = streams - 1; close(pipe); complete() end
    end)
  end
  collect(stdout, output); collect(stderr, errors)
  stdin:write(input or "", function(err)
    if err and not tostring(err):match("EPIPE") then job:cancel(tostring(err)); return end
    if not stdin:is_closing() then stdin:shutdown(function() close(stdin) end) end
  end)
  if timeout then
    timer = uv.new_timer()
    timer:start(timeout, 0, function() job:cancel(command .. " timed out") end)
  end
  return job
end

function M.snapshot_async(callback)
  return M.spawn(os.getenv("HERDR_BIN_PATH") or "herdr", { "api", "snapshot" }, nil, nil, 10000,
    function(err, code, output, errors)
      if err or code ~= 0 then callback(err or (errors ~= "" and errors or "Herdr command failed")); return end
      local ok, snapshot = pcall(function()
        local decoded = json.decode(output)
        if decoded.error then error(json.encode(decoded.error), 0) end
        return assert(decoded.result and decoded.result.snapshot, "Herdr returned no snapshot")
      end)
      if ok then callback(nil, snapshot) else callback(snapshot) end
    end)
end

function M.preview_async(pane_id, callback)
  local job, cancelled = nil, false
  local unavailable = "Preview unavailable: pane closed or could not be read.\n"
  local binary = os.getenv("HERDR_BIN_PATH") or "herdr"
  if pane_id == "-" then
    local timer = uv.new_timer()
    timer:start(0, 0, function() close(timer); callback("No pane available for preview.\n") end)
    return { cancel = function() close(timer) end }
  end
  job = M.spawn(binary, { "pane", "get", pane_id }, nil, nil, 10000, function(err, code, output)
    if cancelled then return end
    local ok, pane = pcall(function()
      local response = json.decode(output)
      return assert(not response.error and response.result and response.result.pane)
    end)
    if err or code ~= 0 or not ok then callback(unavailable); return end
    job = M.spawn(binary, { "pane", "read", pane_id, "--source", "visible", "--ansi", "--raw" },
      nil, nil, 10000, function(read_error, read_code, screen)
        if cancelled then return end
        if read_error or read_code ~= 0 then callback(unavailable); return end
        local formatted, content = pcall(require("pickr.core").preview_content, pane_id, pane, screen)
        callback(formatted and content or unavailable)
      end)
  end)
  return { cancel = function()
    cancelled = true
    if job then job:cancel() end
  end }
end

-- A small JSON-line protocol connects short-lived fzf transform helpers to the
-- picker owner. Helpers never fetch snapshots or own the interactive lifecycle.
function M.control_helper(path, event, argument)
  if event == "match" then
    local file = assert(io.open(argument, "r"))
    argument = file:read("*a")
    file:close()
  end
  local peer, timer = uv.new_pipe(false), uv.new_timer()
  local buffer, failure = "", nil
  local function finish(err)
    failure = err
    close(peer); close(timer)
  end
  timer:start(event == "preview" and 22000 or 2000, 0, function() finish("Picker control timed out") end)
  peer:connect(path, function(err)
    if err then finish(err); return end
    peer:read_start(function(read_error, data)
      if read_error then finish(read_error); return end
      if not data then finish(); return end
      buffer = buffer .. data
    end)
    peer:write(json.encode({ event = event, argument = argument }) .. "\n",
      function(write_error) if write_error then finish(write_error) end end)
  end)
  uv.run()
  if failure then error(failure, 0) end
  return buffer
end

-- fzf emits query, optional expected key, and optional row as NUL records.
-- Preserve empty records and literal query bytes; candidate validation belongs
-- to the live session and must happen before teardown clears its IDs.
function M.picker_result(output, session)
  local records = {}
  for record in output:gmatch("(.-)%z") do records[#records + 1] = record end
  local result = { query = records[1], key = session.has_expect and records[2] or "",
    row = records[session.has_expect and 3 or 2] }
  result.target = session:accept(result.row)
  if session.state == "loading" then
    result.selected_id = session.saved_id
  else
    result.selected_id = result.target
  end
  return result
end

function M.run_picker(command, args, input, env, session, render, footer)
  local keymap, map = require("pickr.keymap"), session.settings.keymap
  local function gate(operation, actions) return keymap.gate(map, operation, actions) end
  local status
  local function header(message)
    status = message
    return session.scope_header and session.scope_header(message) or message or ""
  end
  local root = assert(uv.fs_mkdtemp("/tmp/pickr-XXXXXX"))
  local socket, data_path, fzf_socket = root .. "/owner.sock", root .. "/rows", root .. "/fzf.sock"
  local server, peers = uv.new_pipe(false), {}
  local fetch, fzf, terminal_error, answer, pending, loaded, publication_timer, refresh_timer, preview
  local start_refresh
  if session.entry_id then
    pending = { generation = session.generation, rows = session.rows, header = session.header }
    session.saved_id = session.entry_id
    session.state, session.active = "loading", {}
  end
  local helper = shell_quote(assert(uv.exepath())) .. " " .. shell_quote(launcher)
    .. " control " .. shell_quote(socket)
  local function write_rows(rows, header)
    local file = assert(io.open(data_path, "w"))
    local ok, err = file:write(header .. "\n" .. table.concat(rows, "\n"))
    local closed, close_error = file:close()
    assert(ok, err); assert(closed, close_error)
  end
  local reload = "track-current+reload-sync(cat " .. shell_quote(data_path) .. ")"
  local function shutdown()
    session:close()
    if fetch then fetch:cancel(); fetch = nil end
    close(publication_timer)
    close(refresh_timer)
    if preview then preview:close() end
    close(server)
    for peer in pairs(peers) do close(peer) end
  end
  local function fatal(err)
    terminal_error = tostring(err)
    shutdown()
    if fzf then fzf:cancel() end
  end
  local function post(actions)
    local peer, timer = uv.new_pipe(false), uv.new_timer()
    peers[peer], peers[timer] = true, true
    local response, done = "", false
    local function finish(err)
      if done then return end
      done = true
      close(peer); close(timer)
      peers[peer], peers[timer] = nil, nil
      if err and session.state ~= "closed" then fatal(err) end
    end
    timer:start(2000, 0, function() finish("fzf control timed out") end)
    peer:connect(fzf_socket, function(err)
      if session.state == "closed" then return end
      if err then finish(err); return end
      peer:read_start(function(read_error, data)
        if read_error then finish(read_error); return end
        if data then response = response .. data end
        if response:find("\r\n", 1, true) then
          finish(not response:match("^HTTP/1%.[01] 200 ") and "fzf rejected refresh actions" or nil)
        elseif not data then finish("fzf control closed before replying") end
      end)
      peer:write("POST / HTTP/1.1\r\nHost: localhost\r\nContent-Length: " .. #actions
        .. "\r\n\r\n" .. actions, function(write_error) if write_error then finish(write_error) end end)
    end)
  end
  local function failed(generation)
    if session:fail(generation) then
      pending, loaded = nil, false
      post("change-header:"
        .. header("Refresh failed" .. (#map.keys.refresh > 0 and " — " .. keymap.display(map.keys.refresh) .. " to retry" or "")
          .. (session.settings.refresh.interval_ms > 0 and " — automatic retry" or "")))
    end
  end
  local function start_fetch()
    local generation = session.generation
    fetch = M.snapshot_async(function(err, snapshot)
      fetch = nil
      if not session:is_current(generation) then return end
      if err then failed(generation); return end
      local ok, rows, header = pcall(render, snapshot)
      if not ok then failed(generation); return end
      local written = pcall(write_rows, rows, header)
      if not written then failed(generation); return end
      local valid, staged = pcall(session.stage, session, generation, rows, header)
      if not valid or not staged then failed(generation); return end
      pending, loaded = { generation = generation, rows = rows, header = header,
        refresh = true, started = uv.hrtime() }, false
      publication_timer = uv.new_timer()
      publication_timer:start(M.publication_timeout_ms, 0, function() fatal("Picker publication timed out") end)
      post(reload)
    end)
  end
  start_refresh = function()
    if not session:begin_refresh() then return false end
    start_fetch()
    return true
  end
  local function ready_timer()
    session.ready_at = session.ready_at or uv.hrtime()
    if refresh_timer or session.settings.refresh.interval_ms == 0 then return end
    refresh_timer = uv.new_timer()
    local interval = session.settings.refresh.interval_ms
    refresh_timer:start(interval, interval, function()
      -- Routine ticks are quiet: adding/removing a progress line on every
      -- interval shifts the list. Failures still report their status below.
      start_refresh()
    end)
  end
  if M.preview_command == preview_command then
    preview = require("pickr.live_preview").new(M.preview_async, function()
      if session.state ~= "closed" then post("refresh-preview") end
    end)
    env[#env + 1] = "PICKR_PREVIEW_SOCKET=" .. socket
  end
  local function event(request)
    if session.state == "closed" then return "" end
    if request.event == "toggle-preview" then
      session.popup.preview_visible = not session.popup.preview_visible
      if preview then preview:select(preview.target, session.popup.preview_visible) end
      return "toggle-preview"
    elseif request.event == "selected" then
      if preview then preview:select(request.argument, session.popup.preview_visible) end
      return ""
    elseif request.event == "renew-preview" then
      if preview then preview:refresh(request.argument, session.popup.preview_visible) end
      return ""
    elseif request.event == "scope" then
      local pickers = require("pickr.pickers")
      local chosen = request.argument
      if session.kind and pickers.types[session.kind][chosen]
        and chosen ~= session.popup.chosen_scope
        and chosen == pickers.effective(session.kind, session.popup.chosen_scope) then
        session.popup.chosen_scope = chosen
        return "change-header:" .. header(status)
      end
      return ""
    elseif request.event == "refresh" then
      if not start_refresh() then return "" end
      -- Preserve a failure until successful recovery; repeated attempts must
      -- not make retained results appear fresh by clearing their error.
      return "change-header:" .. header(status or "Refreshing…")
    elseif request.event == "load" then
      loaded = true
    elseif request.event == "match" and not pending and loaded then
      loaded = false
      ready_timer()
    elseif request.event == "match" and pending and loaded then
      if pending.refresh then
        loaded = false
        -- Native ID tracking has already restored/fallen back before this
        -- acknowledgement. Stop tracking so later query edits remain ordinary.
        return "untrack-current+transform(" .. helper .. " ready)"
      end
      -- result-final's synchronous helper sees this exact matching result set;
      -- no position is computed from an earlier query or asynchronous GET.
      local position, index = 1, 0
      -- --print0 also frames the {*f1} temporary file with NULs.
      for id in request.argument:gmatch("[^%z]+") do
        index = index + 1
        if id == session.saved_id then position = index; break end
      end
      loaded = false
      -- A second synchronous acknowledgement publishes the acceptance map only
      -- after fzf has applied the position and refreshed the preview target.
      return "pos(" .. position .. ")+refresh-preview+transform(" .. helper .. " ready)"
    elseif request.event == "ready" and pending then
      if pending.started then session.publication_ms = (uv.hrtime() - pending.started) / 1000000 end
      session:publish(pending.generation, pending.rows, pending.header)
      close(publication_timer); publication_timer = nil
      pending, loaded = nil, false
      header()
      ready_timer()
      -- Each arbitrary display string owns the tail of its action expression.
      -- A separate synchronous transform avoids interpreting punctuation in
      -- configured key labels as change-footer/header delimiters.
      return gate("rebind", { "accept", "refresh" })
        .. "+transform(" .. helper .. " renew-preview {2})"
        .. "+transform(" .. helper .. " header)"
        .. (footer and "+change-footer:" .. footer(#session.rows) or "")
    elseif request.event == "header" then
      return "change-header:" .. header(status)
    end
    return ""
  end
  local ok, err = pcall(function()
    assert(server:bind(socket))
    assert(server:listen(16, function(listen_error)
      if listen_error then fatal(listen_error); return end
      local peer, buffer, unsubscribe = uv.new_pipe(false), "", nil
      local function reply(content)
        if peer:is_closing() then return end
        peer:read_stop()
        peer:write(content, function()
          if not peer:is_closing() then
            peer:shutdown(function() close(peer); peers[peer] = nil end)
          end
        end)
      end
      peers[peer] = true
      assert(server:accept(peer))
      peer:read_start(function(read_error, data)
        if session.state == "closed" then return end
        if read_error or not data then
          if unsubscribe then unsubscribe() end
          close(peer); peers[peer] = nil; return
        end
        buffer = buffer .. data
        if not buffer:find("\n", 1, true) then return end
        local handled, actions = pcall(function()
          local request = json.decode(buffer)
          if request.event == "preview" and preview then
            unsubscribe = preview:request(request.argument, session.popup.preview_visible, reply)
            return nil
          end
          return event(request)
        end)
        if not handled then fatal(actions); return end
        if actions then reply(actions) end
      end)
    end))
    args[#args + 1] = "--listen=" .. fzf_socket
    args[#args + 1] = "--id-nth=1"
    -- Hide one-off tracking feedback without changing tracking or other info.
    -- Use shell builtins only: fzf runs info commands synchronously.
    args[#args + 1] = [[--info-command=info=$FZF_INFO; case "$info" in *" +t"*) suffix=${info#*" +t"}; info=${info%%" +t"*}${suffix#\*};; esac; printf '%s' "$info"]]
    if preview then args[#args + 1] = "--bind=focus:transform(" .. helper .. " selected {2})" end
    if pending then args[#args + 1] = "--bind=start:" .. gate("unbind", { "accept", "refresh" }) end
    -- Synchronous transforms acknowledge each toggle before fzf can process a
    -- variant exit, including while loading or displaying a refresh failure.
    for _, key in ipairs(session.settings.keymap.keys.toggle_preview) do
      args[#args + 1] = "--bind=" .. key .. ":transform(" .. helper .. " toggle-preview)"
    end
    for _, key in ipairs(map.keys.refresh) do
      args[#args + 1] = "--bind=" .. key .. ":transform(" .. helper .. " refresh {1})"
    end
    if session.kind then
      local pickers = require("pickr.pickers")
      local effective = pickers.effective(session.kind, session.popup.chosen_scope)
      if effective and effective ~= session.popup.chosen_scope then
        for _, key in ipairs(map.keys["scope_" .. effective]) do
          args[#args + 1] = "--bind=" .. key .. ":transform(" .. helper .. " scope " .. effective .. ")"
        end
      end
    end
    args[#args + 1] = "--bind=load:transform(" .. helper .. " load),result-final:transform(" .. helper .. " match {*f1})"
    fzf = M.spawn(command, args, input, env, nil, function(failure, code, output, errors, signal)
      answer = { code, M.picker_result(output, session), errors, signal }
      if failure and not terminal_error then terminal_error = failure end
      shutdown()
    end)
    uv.run()
  end)
  if not ok then shutdown(); if fzf then fzf:cancel() end; uv.run() end
  uv.fs_unlink(socket); uv.fs_unlink(data_path); uv.fs_unlink(fzf_socket); uv.fs_rmdir(root)
  if not ok then error(err, 0) end
  if terminal_error then error(terminal_error, 0) end
  assert(answer)
  return table.unpack(answer, 1, 4)
end

function M.current_workspace(getenv)
  getenv = getenv or os.getenv
  local origin = getenv("PICKR_ORIGIN_WORKSPACE_ID")
  if origin and origin ~= "" then return origin end
  if getenv("HERDR_PLUGIN_ID") == "javoscript.herdr-pickr" then
    local context = getenv("HERDR_PLUGIN_CONTEXT_JSON")
    if context and context ~= "" then
      local workspace = json.decode(context).workspace_id
      if workspace then return workspace end
    end
  end
  return getenv("HERDR_ACTIVE_WORKSPACE_ID")
end

-- Capture before creating the popup. An empty handoff explicitly means that
-- no tab existed at launch; it must never fall through to later active focus.
function M.origin(getenv, snapshot)
  getenv = getenv or os.getenv
  local origin = { workspace_id = M.current_workspace(getenv) }
  local function validate(tab)
    if not tab or tab == "" or not origin.workspace_id then return origin end
    snapshot = snapshot or M.herdr("api", "snapshot").snapshot
    local workspace_exists = false
    for _, workspace in ipairs(snapshot.workspaces) do
      if workspace.workspace_id == origin.workspace_id then workspace_exists = true; break end
    end
    for _, member in ipairs(snapshot.tabs) do
      if workspace_exists and member.tab_id == tab and member.workspace_id == origin.workspace_id then
        origin.tab_id = tab
        break
      end
    end
    return origin
  end
  local tab = getenv("PICKR_ORIGIN_TAB_ID")
  if tab ~= nil then
    return validate(tab)
  end
  if getenv("HERDR_PLUGIN_ID") == "javoscript.herdr-pickr" then
    local context = getenv("HERDR_PLUGIN_CONTEXT_JSON")
    if context and context ~= "" then
      context = json.decode(context)
      if context.workspace_id == origin.workspace_id and context.tab_id and context.tab_id ~= "" then
        return validate(context.tab_id)
      end
    end
  end
  if origin.workspace_id then
    snapshot = snapshot or M.herdr("api", "snapshot").snapshot
    for _, workspace in ipairs(snapshot.workspaces) do
      if workspace.workspace_id == origin.workspace_id then
        return validate(workspace.active_tab_id)
      end
    end
  end
  return origin
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

function M.socket_request(method, params, id, timeout)
  local path = assert(os.getenv("HERDR_SOCKET_PATH"), "Missing HERDR_SOCKET_PATH")
  local connection, timer = uv.new_pipe(false), uv.new_timer()
  local chunks, response, failure, finished = {}, nil, nil, false
  local function finish(err, data)
    if finished then return end
    finished, failure, response = true, err, data
    close(connection)
    close(timer)
  end
  timer:start(timeout or 5000, 0, function() finish("Herdr " .. method .. " timed out") end)
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
      id = id, method = method, params = params,
    }) .. "\n", function(write_error)
      if write_error then finish(write_error) end
    end)
  end)
  uv.run()
  if failure then error(failure, 0) end
  local decoded = json.decode(response)
  assert(decoded.id == id, "Herdr returned an unexpected response ID")
  return result(response)
end

function M.open_popup(entrypoint, workspace, settings, tab)
  local reply = M.socket_request("plugin.pane.open", {
    plugin_id = "javoscript.herdr-pickr", entrypoint = entrypoint,
    -- Herdr popups target the active pane and reject explicit workspace targets.
    -- Preserve picker scope through the environment instead.
    placement = "popup", focus = true,
    width = settings.popup.width, height = settings.popup.height,
    env = { PICKR_ORIGIN_WORKSPACE_ID = workspace, PICKR_ORIGIN_TAB_ID = tab or "",
      PICKR_SETTINGS_SNAPSHOT = require("pickr.config").snapshot(settings) },
  }, "pickr:open")
  local pane = reply.plugin_pane
  assert(reply.type == "plugin_pane_opened" and type(pane) == "table"
    and pane.plugin_id == "javoscript.herdr-pickr" and pane.entrypoint == entrypoint
    and type(pane.pane) == "table" and type(pane.pane.pane_id) == "string"
    and pane.pane.pane_id ~= "", "Herdr did not confirm the requested popup")
  return pane
end

function M.focus_pane(pane_id)
  -- pane.focus also moves the client's workspace/tab view in Herdr 0.9.0.
  local reply = M.socket_request("pane.focus", { pane_id = pane_id }, "pickr:focus")
  if not reply.pane or reply.pane.pane_id ~= pane_id then
    error("Herdr did not confirm the selected pane", 0)
  end
end

function M.fzf_env()
  local env = {}
  for key, value in pairs(uv.os_environ()) do
    if key ~= "FZF_DEFAULT_OPTS" and key ~= "FZF_DEFAULT_OPTS_FILE" and key ~= "FZF_API_KEY"
      and key ~= "PICKR_PREVIEW_SOCKET" then
      env[#env + 1] = key .. "=" .. value
    end
  end
  return env
end

return M
