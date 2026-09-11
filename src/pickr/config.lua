local M = {}
local plugin_id = "javoscript.herdr-pickr"

-- Resolve through Herdr, never through the checkout or caller's directory.
-- Both dependencies are injectable so discovery fixtures need no user config.
function M.directory(deps)
  deps = deps or {}
  local getenv = deps.getenv or os.getenv
  local directory = getenv("HERDR_PLUGIN_CONFIG_DIR")
  if getenv("HERDR_PLUGIN_ID") == plugin_id and directory and directory ~= "" then
    return directory
  end
  local binary = getenv("HERDR_BIN_PATH")
  if not binary or binary == "" then binary = "herdr" end
  local run = deps.run or require("pickr.process").run
  local ok, code, output, errors = pcall(run, binary,
    { "plugin", "config-dir", plugin_id }, nil, nil, 10000)
  if not ok or code ~= 0 then
    error("Cannot discover Pickr configuration directory via " .. binary
      .. " plugin config-dir " .. plugin_id .. ": "
      .. tostring(not ok and code or errors), 0)
  end
  -- Remove the CLI line terminator, preserving spaces in the actual path.
  directory = output:gsub("\r?\n$", "")
  if directory == "" or directory:find("[\r\n%z]") or directory:sub(1, 1) ~= "/" then
    error("Invalid Pickr configuration directory returned by " .. binary
      .. " plugin config-dir " .. plugin_id, 0)
  end
  return directory
end

local json = require("pickr.vendor.json")
local function omitted(value) return value == nil or value == json.null end
local function object(value, field, allowed)
  if type(value) ~= "table" or getmetatable(value) ~= json.object then
    error(field .. ": expected a JSON object", 0)
  end
  for key in pairs(value) do
    if not allowed[key] then error(field .. "." .. key .. ": unknown setting", 0) end
  end
end

function M.decode(text)
  local config = json.decode(text, true)
  object(config, "config", { keys = true, theme = true, preview = true, popup = true })
  local keys, name, custom = {}, nil, {}
  local keymap, themes = require("pickr.keymap"), require("pickr.themes")
  if not omitted(config.keys) then
    object(config.keys, "keys", keymap.defaults)
    for action, value in pairs(config.keys) do
      if not omitted(value) then
        if type(value) ~= "table" or getmetatable(value) ~= json.array then
          error("keys." .. action .. ": expected an array of key strings", 0)
        end
        keys[action] = value
      end
    end
  end
  if not omitted(config.theme) then
    object(config.theme, "theme", { name = true, custom = true })
    if not omitted(config.theme.name) then
      if type(config.theme.name) ~= "string" then error("theme.name: expected a string", 0) end
      name = config.theme.name
    end
    if not omitted(config.theme.custom) then
      local allowed = {}
      for _, role in ipairs(themes.roles) do allowed[role] = true end
      object(config.theme.custom, "theme.custom", allowed)
      for role, value in pairs(config.theme.custom) do if not omitted(value) then custom[role] = value end end
    end
  end
  local preview = { enabled_by_default = true }
  if not omitted(config.preview) then
    object(config.preview, "preview", { enabled_by_default = true })
    if not omitted(config.preview.enabled_by_default) then
      if type(config.preview.enabled_by_default) ~= "boolean" then
        error("preview.enabled_by_default: expected a boolean", 0)
      end
      preview.enabled_by_default = config.preview.enabled_by_default
    end
  end
  local popup = { width = "80%", height = "70%" }
  if not omitted(config.popup) then
    object(config.popup, "popup", { width = true, height = true })
    for field, value in pairs(config.popup) do
      if not omitted(value) then
        local percent = type(value) == "string" and value:match("^([1-9]%d*)%%$")
        local valid = percent and tonumber(percent) <= 100
          or type(value) == "number" and value >= 0 and value % 1 == 0
        if not valid then
          error("popup." .. field .. ": expected a nonnegative integer cell count or a percentage from 1% to 100%", 0)
        end
        popup[field] = type(value) == "number" and math.min(value, 65535) or value
      end
    end
  end
  return { keymap = keymap.resolve(keys), roles = themes.resolve(name, custom),
    theme_name = name or "catppuccin", preview = preview, popup = popup }
end

local function read_file(path)
  local uv = require("luv")
  local fd, err, code = uv.fs_open(path, "r", 0)
  if not fd then return nil, err, code end
  local stat, stat_error = uv.fs_fstat(fd)
  local text, read_error
  if stat and stat.type == "file" then text, read_error = uv.fs_read(fd, stat.size, 0)
  else read_error = stat_error or "expected a regular file" end
  local closed, close_error = uv.fs_close(fd)
  return text, read_error or (not closed and close_error or nil)
end

function M.load(deps)
  deps = deps or {}
  local path = M.directory(deps):gsub("/$", "") .. "/config.json"
  local text, err, code = (deps.read_file or read_file)(path)
  if err and (text or code ~= "ENOENT") or not text and code ~= "ENOENT" then
    error(path .. ": " .. tostring(err), 0)
  end
  local ok, config = pcall(M.decode, text or "{}")
  if not ok then error(path .. ": " .. tostring(config), 0) end
  config.path = path
  config.fzf_bindings = require("pickr.fzf_bindings").load({
    getenv = deps.getenv, read_file = deps.read_fzf_file or read_file, warn = deps.warn,
  })
  return config
end

-- Only the launcher writes this handoff. Serialize resolved values so the owner
-- never resolves defaults, discovers a directory, or rereads the configuration.
function M.snapshot(settings)
  return json.encode({ version = 1, settings = settings })
end

function M.owner(deps)
  deps = deps or {}
  local snapshot = (deps.getenv or os.getenv)("PICKR_SETTINGS_SNAPSHOT")
  if snapshot == nil then return M.load(deps) end
  local ok, result = pcall(function()
    local handoff = json.decode(snapshot)
    assert(type(handoff) == "table" and handoff.version == 1, "unsupported snapshot version")
    local settings = handoff.settings
    assert(type(settings) == "table" and type(settings.keymap) == "table"
      and type(settings.keymap.keys) == "table" and type(settings.keymap.reverse) == "table"
      and type(settings.roles) == "table" and type(settings.preview) == "table"
      and type(settings.popup) == "table", "invalid settings snapshot")
    return settings
  end)
  if not ok then error("PICKR_SETTINGS_SNAPSHOT: " .. tostring(result), 0) end
  return result
end

return M
