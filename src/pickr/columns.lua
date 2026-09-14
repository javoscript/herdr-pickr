local json = require("pickr.vendor.json")
local M = {}

M.defaults = {
  spaces = { "status", "space", "tabs", "directory" },
  tabs = { "status", "space", "tab", "panes", "directory" },
  agents = { "status", "space", "tab", "agent", "title", "pane" },
  panes = { "status", "space", "tab", "title", "pane", "directory" },
}

function M.variant(kind, scope)
  assert(M.defaults[kind], "Unknown picker type")
  return kind
end

function M.layout(kind, scope, settings)
  local variant = M.variant(kind, scope)
  return (settings and settings.columns or M.defaults)[variant]
end

local function omitted(value) return value == nil or value == json.null end

-- Typed JSON keeps empty arrays distinct from objects, including in snapshots.
function M.resolve(overrides, snapshot)
  if omitted(overrides) and not snapshot then overrides = setmetatable({}, json.object) end
  if type(overrides) ~= "table" or getmetatable(overrides) ~= json.object then
    error("columns: expected a JSON object", 0)
  end
  for variant in pairs(overrides) do
    require("pickr.pickers").check_leaf("columns", variant)
    if not M.defaults[variant] then error("columns." .. variant .. ": unknown setting", 0) end
  end
  local resolved = {}
  for variant, defaults in pairs(M.defaults) do
    local field, list = "columns." .. variant, overrides[variant]
    local use_default = omitted(list) and not snapshot
    if use_default then list = defaults
    elseif type(list) ~= "table" or getmetatable(list) ~= json.array then
      error(field .. ": expected an array of column strings", 0)
    end
    if #list == 0 then error(field .. ": requires at least one column", 0) end
    local allowed, seen, result = {}, {}, {}
    for _, name in ipairs(defaults) do allowed[name] = true end
    for index, name in ipairs(list) do
      local location = field .. "[" .. index .. "]"
      if type(name) ~= "string" then error(location .. ": expected a column string", 0) end
      if not allowed[name] then error(location .. ": unavailable column " .. name, 0) end
      if seen[name] then error(location .. ": duplicate column " .. name, 0) end
      seen[name], result[index] = true, name
    end
    resolved[variant] = result
  end
  return resolved
end

return M
